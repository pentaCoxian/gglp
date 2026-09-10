#!/usr/bin/env python3
"""Build-derived Android release metadata and draft-first GitHub publishing.

Uses only Python's standard library, Android build-tools, and GitHub CLI.
Run `python3 tool/release.py --help` for local verification commands.
"""

import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import tempfile
import zipfile

REPOSITORY = "pentaCoxian/gglp"
PACKAGE_ID = "io.pentacoxian.gglp"
MAX_APK_SIZE = 200 * 1024 * 1024
VERSION = r"(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)"
MANIFEST_FIELDS = {
    "schemaVersion", "versionName", "versionCode", "packageId", "minSdk",
    "apkFileName", "size", "sha256",
}


def run(*args):
    return subprocess.check_output(args, text=True).strip()


def sha256(path):
    digest = hashlib.sha256()
    with Path(path).open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def source_version(pubspec, tag):
    match = re.search(
        rf"^version:\s*({VERSION})\+([1-9][0-9]*)\s*$", pubspec, re.MULTILINE
    )
    if not match or tag != f"v{match[1]}":
        raise ValueError("Tag must match a stable pubspec version: vX.Y.Z / X.Y.Z+N")
    code = int(match[2])
    if code > 2_100_000_000:
        raise ValueError("Android version code exceeds its supported range")
    return match[1], code


def apk_metadata(badging):
    package = re.search(r"^package: (.+)$", badging, re.MULTILINE)
    minimum = re.search(r"^(?:minSdkVersion|sdkVersion):'([0-9]+)'$", badging, re.MULTILINE)
    target = re.search(r"^targetSdkVersion:'([0-9]+)'$", badging, re.MULTILINE)
    if not package or not minimum:
        raise ValueError("APK is missing package or minimum SDK metadata")
    fields = dict(re.findall(r"(\w+)='([^']*)'", package[1]))
    if fields.get("name") != PACKAGE_ID:
        raise ValueError("APK package does not match GGLP")
    if not re.fullmatch(VERSION, fields.get("versionName", "")):
        raise ValueError("APK version name must be a stable X.Y.Z version")
    if not re.fullmatch(r"[1-9][0-9]*", fields.get("versionCode", "")):
        raise ValueError("APK has an invalid version code")
    if int(minimum[1]) != 21:
        raise ValueError("APK minimum SDK must remain 21")
    if not target or int(target[1]) != 36:
        raise ValueError("APK target SDK must be 36")
    if re.search(r"^application-debuggable$", badging, re.MULTILINE):
        raise ValueError("Release APK must not be debuggable")
    return {
        "versionName": fields["versionName"],
        "versionCode": int(fields["versionCode"]),
        "packageId": fields["name"],
        "minSdk": int(minimum[1]),
    }


def validate_manifest(manifest):
    if not isinstance(manifest, dict) or set(manifest) != MANIFEST_FIELDS:
        raise ValueError("Unexpected update manifest fields")
    for field in ("schemaVersion", "versionCode", "minSdk", "size"):
        if type(manifest[field]) is not int:
            raise ValueError(f"Manifest {field} must be an integer")
    if manifest["schemaVersion"] != 1 or manifest["packageId"] != PACKAGE_ID:
        raise ValueError("Unsupported update schema or package")
    name = manifest["versionName"]
    if not isinstance(name, str) or not re.fullmatch(VERSION, name):
        raise ValueError("Invalid release version")
    if manifest["apkFileName"] != f"gglp-{name}.apk":
        raise ValueError("Invalid APK asset filename")
    if not 1 <= manifest["versionCode"] <= 2_100_000_000:
        raise ValueError("Invalid Android version code")
    if manifest["minSdk"] != 21 or not 0 < manifest["size"] <= MAX_APK_SIZE:
        raise ValueError("Invalid minimum SDK or APK size")
    if not isinstance(manifest["sha256"], str) or not re.fullmatch(
        r"[0-9a-f]{64}", manifest["sha256"]
    ):
        raise ValueError("Invalid SHA-256 digest")
    return manifest


def validate_elf(data, name):
    """Check each 64-bit ELF LOAD segment for 16 KB page compatibility."""
    if len(data) < 64 or data[:4] != b"\x7fELF" or data[4:6] != b"\x02\x01":
        raise ValueError(f"Expected a little-endian ELF64 library: {name}")
    offset = struct.unpack_from("<Q", data, 32)[0]
    entry_size, count = struct.unpack_from("<HH", data, 54)
    if entry_size < 56 or not count or offset + entry_size * count > len(data):
        raise ValueError(f"Invalid ELF program headers: {name}")
    loads = 0
    for index in range(count):
        segment = struct.unpack_from("<IIQQQQQQ", data, offset + entry_size * index)
        kind, _, file_offset, address, _, file_size, _, alignment = segment
        if kind != 1:  # PT_LOAD
            continue
        loads += 1
        if (alignment < 16384 or alignment & (alignment - 1)
                or (address - file_offset) % 16384
                or file_offset + file_size > len(data)):
            raise ValueError(f"ELF LOAD segment is not 16 KB compatible: {name}")
    if not loads:
        raise ValueError(f"ELF has no LOAD segments: {name}")


def validate_native_libraries(apk):
    with zipfile.ZipFile(apk) as archive:
        names = archive.namelist()
        if len(names) != len(set(names)):
            raise ValueError("APK contains duplicate ZIP entries")
        for abi in ("armeabi-v7a", "arm64-v8a", "x86_64"):
            if f"lib/{abi}/libflutter.so" not in names:
                raise ValueError(f"Universal APK is missing {abi}")
        libraries = [name for name in names if name.endswith(".so")
                     and name.startswith(("lib/arm64-v8a/", "lib/x86_64/"))]
        for name in libraries:
            validate_elf(archive.read(name), name)
        print(f"16 KB ELF alignment verified for {len(libraries)} 64-bit libraries")


def validate_signature(certificate):
    if not re.search(r"Verified using v2 scheme.*: true", certificate):
        raise ValueError("APK must have an Android v2 signature")
    if re.search(r"certificate DN:.*\bCN=Android Debug\b", certificate, re.IGNORECASE):
        raise ValueError("Release APK must not use an Android debug signing key")


def prepare(apk, build_tools, tag, directory, pubspec):
    version_name, version_code = source_version(pubspec.read_text(), tag)
    if not 0 < apk.stat().st_size <= MAX_APK_SIZE:
        raise ValueError("APK is empty or exceeds 200 MiB")
    # apksigner exits nonzero for a malformed or invalid signature.
    certificate = run(str(build_tools / "apksigner"), "verify", "--verbose",
                      "--print-certs", str(apk))
    validate_signature(certificate)
    print(certificate)
    print(run(str(build_tools / "zipalign"), "-c", "-P", "16", "4", str(apk)))
    validate_native_libraries(apk)
    metadata = apk_metadata(run(str(build_tools / "aapt2"), "dump", "badging", str(apk)))
    if (metadata["versionName"], metadata["versionCode"]) != (version_name, version_code):
        raise ValueError("Built APK version does not match pubspec and tag")
    manifest = validate_manifest({
        "schemaVersion": 1,
        **metadata,
        "apkFileName": f"gglp-{version_name}.apk",
        "size": apk.stat().st_size,
        "sha256": sha256(apk),
    })
    directory.mkdir(parents=True, exist_ok=True)
    if any(directory.iterdir()):
        raise ValueError("Release output directory must be empty")
    shutil.copyfile(apk, directory / manifest["apkFileName"])
    (directory / "update.json").write_text(json.dumps(manifest, indent=2) + "\n")
    checksums = "".join(f"{sha256(directory / name)}  {name}\n"
                        for name in (manifest["apkFileName"], "update.json"))
    (directory / "SHA256SUMS").write_text(checksums)
    print(json.dumps(manifest, indent=2))


def property_value(value):
    replacements = {"\\": "\\\\", "\n": "\\n", "\r": "\\r", "\t": "\\t",
                    " ": "\\ ", "=": "\\=", ":": "\\:", "#": "\\#", "!": "\\!"}
    return "".join(replacements.get(char, char) for char in value)


def configure_signing():
    names = ("ANDROID_KEYSTORE_BASE64", "ANDROID_KEYSTORE_PASSWORD",
             "ANDROID_KEY_ALIAS", "ANDROID_KEY_PASSWORD", "RUNNER_TEMP")
    if any(not os.environ.get(name) for name in names):
        raise ValueError("Release signing secrets and RUNNER_TEMP must be configured")
    key = base64.b64decode(os.environ[names[0]], validate=True)
    if not key:
        raise ValueError("Release keystore is empty")
    path = Path(os.environ["RUNNER_TEMP"]) / "gglp-release.jks"
    values = {
        "storeFile": str(path.resolve()),
        "storePassword": os.environ[names[1]],
        "keyAlias": os.environ[names[2]],
        "keyPassword": os.environ[names[3]],
    }
    os.umask(0o077)
    # Exclusive creation prevents replacing a pre-existing local keystore.
    with path.open("xb") as target:
        target.write(key)
    with Path("android/key.properties").open("x", encoding="ascii") as target:
        target.write("".join(f"{key}={property_value(value)}\n" for key, value in values.items()))


def validate_assets(directory, tag):
    manifest = validate_manifest(json.loads((directory / "update.json").read_text()))
    if tag != "v" + manifest["versionName"]:
        raise ValueError("Release tag does not match update manifest")
    names = [manifest["apkFileName"], "update.json", "SHA256SUMS"]
    if {path.name for path in directory.iterdir()} != set(names):
        raise ValueError("Release directory must contain exactly APK, update.json, SHA256SUMS")
    apk = directory / names[0]
    if apk.stat().st_size != manifest["size"] or sha256(apk) != manifest["sha256"]:
        raise ValueError("APK does not match update manifest")
    expected = "".join(f"{sha256(directory / name)}  {name}\n" for name in names[:2])
    if (directory / "SHA256SUMS").read_text() != expected:
        raise ValueError("Release checksums do not match assets")
    return manifest, names


def check_monotonic(candidate, previous):
    for item in previous:
        validate_manifest(item)
        if candidate["versionCode"] <= item["versionCode"]:
            raise ValueError("Release version code must exceed every published Android version code")
        if tuple(map(int, candidate["versionName"].split("."))) <= tuple(
                map(int, item["versionName"].split("."))):
            raise ValueError("Stable release version must exceed every published version")


def publish(directory, tag):
    manifest, names = validate_assets(directory, tag)
    pages = json.loads(run("gh", "api", "--paginate", "--slurp",
                          f"repos/{REPOSITORY}/releases?per_page=100"))
    releases = [release for page in pages for release in page]
    current = next((release for release in releases if release["tag_name"] == tag), None)
    if current and not current["draft"]:
        raise ValueError("Release is already published; never replace a published APK")
    previous = []
    for release in releases:
        if release["draft"]:
            continue
        assets = [asset for asset in release["assets"] if asset["name"] == "update.json"]
        if len(assets) != 1:
            raise ValueError(f"Published release {release['tag_name']} lacks one update.json")
        content = run("gh", "api", "-H", "Accept: application/octet-stream",
                      f"repos/{REPOSITORY}/releases/assets/{assets[0]['id']}")
        previous.append(json.loads(content))
    check_monotonic(manifest, previous)
    if not current:
        run("gh", "release", "create", tag, "--repo", REPOSITORY, "--verify-tag",
            "--draft", "--title", f"GGLP {manifest['versionName']}", "--generate-notes")
    else:
        # A failed upload can leave a draft. Remove only its obsolete assets;
        # current assets are replaced below, without touching any published release.
        for asset in current["assets"]:
            if asset["name"] not in names:
                run("gh", "api", "--method", "DELETE",
                    f"repos/{REPOSITORY}/releases/assets/{asset['id']}")
    run("gh", "release", "upload", tag, "--repo", REPOSITORY, "--clobber",
        *(str(directory / name) for name in names))
    # Verify the uploaded bytes while the release is still private to the repo.
    with tempfile.TemporaryDirectory(prefix="gglp-upload-check-") as temporary:
        run("gh", "release", "download", tag, "--repo", REPOSITORY, "--dir", temporary)
        validate_assets(Path(temporary), tag)
        for name in names:
            if sha256(Path(temporary) / name) != sha256(directory / name):
                raise ValueError(f"Uploaded {name} differs from the validated build")
    run("gh", "release", "edit", tag, "--repo", REPOSITORY, "--draft=false", "--latest")
    print(f"Published https://github.com/{REPOSITORY}/releases/tag/{tag}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    version = commands.add_parser("version", help="Check pubspec version and release tag")
    version.add_argument("--tag", required=True)
    version.add_argument("--pubspec", type=Path, default=Path("pubspec.yaml"))
    commands.add_parser("signing", help="Create CI signing files from environment secrets")
    preparation = commands.add_parser("prepare", help="Validate signed APK and create release assets")
    preparation.add_argument("--apk", type=Path, required=True)
    preparation.add_argument("--build-tools", type=Path, required=True)
    preparation.add_argument("--tag", required=True)
    preparation.add_argument("--directory", type=Path, required=True)
    preparation.add_argument("--pubspec", type=Path, default=Path("pubspec.yaml"))
    publication = commands.add_parser("publish", help="Verify assets, then publish a GitHub draft")
    publication.add_argument("--tag", required=True)
    publication.add_argument("--directory", type=Path, required=True)
    arguments = vars(parser.parse_args())
    command = arguments.pop("command")
    if command == "version":
        print(source_version(arguments["pubspec"].read_text(), arguments["tag"]))
    elif command == "signing":
        configure_signing()
    elif command == "prepare":
        prepare(**arguments)
    else:
        publish(**arguments)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError, zipfile.BadZipFile) as error:
        raise SystemExit(f"Release validation failed: {error}") from error
