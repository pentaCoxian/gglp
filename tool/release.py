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
import stat
import struct
import subprocess
import sys
import tempfile
import zipfile

REPOSITORY = "pentaCoxian/gglp"
PACKAGE_ID = "io.pentacoxian.gglp"
MAX_APK_SIZE = 200 * 1024 * 1024
MAX_METADATA_SIZE = 16 * 1024 * 1024
# Permanent OSS signing identity, taken from the published v0.9.1 APK.
SIGNING_CERTIFICATE_SHA256 = "d02a593d8084f0fa6d3c9f46ee7fd281118f739bfcce498ac23aa9e9781ca3a9"
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
    count = re.findall(r"^Number of signers: ([0-9]+)$", certificate, re.MULTILINE)
    digests = re.findall(r"^Signer #([0-9]+) certificate SHA-256 digest: ([0-9a-fA-F]+)$",
                         certificate, re.MULTILINE)
    if count != ["1"] or len(digests) != 1 or digests[0][0] != "1":
        raise ValueError("Release APK must have exactly one signing certificate")
    if digests[0][1].lower() != SIGNING_CERTIFICATE_SHA256:
        raise ValueError("Release APK does not use the pinned OSS signing certificate")


def regular_file(path, maximum):
    info = path.lstat()
    if not stat.S_ISREG(info.st_mode) or not 0 < info.st_size <= maximum:
        raise ValueError(f"Expected a nonempty regular file within its size limit: {path.name}")


def validate_unsigned(apk, build_tools):
    """Reject signed or malformed signature containers before exposing a key."""
    with zipfile.ZipFile(apk) as archive:
        if any(re.fullmatch(r"META-INF/(?:[^/]+\.(?:SF|RSA|DSA|EC)|SIG-[^/]+)",
                            name, re.IGNORECASE) for name in archive.namelist()):
            raise ValueError("Signing input must be an unsigned APK")
        with apk.open("rb") as source:
            source.seek(max(0, archive.start_dir - 16))
            if source.read(16) == b"APK Sig Block 42":
                raise ValueError("Signing input must not contain an APK signing block")
    result = subprocess.run(
        [str(build_tools / "apksigner"), "verify", "--verbose", str(apk)],
        capture_output=True, text=True, check=False,
    )
    output = result.stdout + result.stderr
    if result.returncode != 1 or "Missing META-INF/MANIFEST.MF" not in output:
        raise ValueError("apksigner did not confirm an unsigned APK")


def inspect(apk, build_tools, tag, pubspec, signed=False):
    version_name, version_code = source_version(pubspec.read_text(), tag)
    regular_file(apk, MAX_APK_SIZE)
    if signed:
        certificate = run(str(build_tools / "apksigner"), "verify", "--verbose",
                          "--print-certs", str(apk))
        validate_signature(certificate)
    else:
        validate_unsigned(apk, build_tools)
    print(run(str(build_tools / "zipalign"), "-c", "-P", "16", "4", str(apk)))
    validate_native_libraries(apk)
    metadata = apk_metadata(run(str(build_tools / "aapt2"), "dump", "badging", str(apk)))
    if (metadata["versionName"], metadata["versionCode"]) != (version_name, version_code):
        raise ValueError("Built APK version does not match pubspec and tag")
    return metadata


def prepare(apk, build_tools, tag, directory, pubspec):
    metadata = inspect(apk, build_tools, tag, pubspec, signed=True)
    manifest = validate_manifest({
        "schemaVersion": 1,
        **metadata,
        "apkFileName": f"gglp-{metadata['versionName']}.apk",
        "size": apk.stat().st_size,
        "sha256": sha256(apk),
    })
    directory.mkdir(parents=True, exist_ok=True)
    if directory.is_symlink():
        raise ValueError("Release directory must not be a symlink")
    if any(directory.iterdir()):
        raise ValueError("Release output directory must be empty")
    shutil.copyfile(apk, directory / manifest["apkFileName"])
    (directory / "update.json").write_text(json.dumps(manifest, indent=2) + "\n")
    checksums = "".join(f"{sha256(directory / name)}  {name}\n"
                        for name in (manifest["apkFileName"], "update.json"))
    (directory / "SHA256SUMS").write_text(checksums)
    print(json.dumps(manifest, indent=2))


def sign(apk, build_tools, output):
    """Sign a candidate without running Gradle or writing repository credentials."""
    names = ("ANDROID_KEYSTORE_BASE64", "ANDROID_KEYSTORE_PASSWORD",
             "ANDROID_KEY_ALIAS", "ANDROID_KEY_PASSWORD", "RUNNER_TEMP")
    if any(not os.environ.get(name) for name in names):
        raise ValueError("Release signing secrets and RUNNER_TEMP must be configured")
    regular_file(apk, MAX_APK_SIZE)
    if output.exists() or output.is_symlink():
        raise ValueError("Signed APK output must not already exist")
    with tempfile.TemporaryDirectory(prefix="gglp-sign-", dir=os.environ["RUNNER_TEMP"]) as temporary:
        directory = Path(temporary)
        candidate = directory / "candidate.apk"
        shutil.copyfile(apk, candidate)
        validate_unsigned(candidate, build_tools)
        print(run(str(build_tools / "zipalign"), "-c", "-P", "16", "4", str(candidate)))
        validate_native_libraries(candidate)
        apk_metadata(run(str(build_tools / "aapt2"), "dump", "badging", str(candidate)))
        key = base64.b64decode(os.environ[names[0]], validate=True)
        if not key:
            raise ValueError("Release keystore is empty")
        path = directory / "upload.jks"
        with os.fdopen(os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), "wb") as target:
            target.write(key)
        del key
        signed = directory / "signed.apk"
        environment = os.environ.copy()
        environment.pop("ANDROID_KEYSTORE_BASE64", None)
        subprocess.check_output([
            str(build_tools / "apksigner"), "sign", "--ks", str(path),
            "--ks-key-alias", os.environ[names[2]],
            "--ks-pass", "env:ANDROID_KEYSTORE_PASSWORD",
            "--key-pass", "env:ANDROID_KEY_PASSWORD",
            "--out", str(signed), str(candidate),
        ], env=environment, text=True)
        regular_file(signed, MAX_APK_SIZE)
        validate_signature(run(str(build_tools / "apksigner"), "verify", "--verbose",
                               "--print-certs", str(signed)))
        print(run(str(build_tools / "zipalign"), "-c", "-P", "16", "4", str(signed)))
        output.parent.mkdir(parents=True, exist_ok=True)
        # Exclusive creation prevents following an output symlink or replacing a build.
        try:
            with output.open("xb") as target, signed.open("rb") as source:
                shutil.copyfileobj(source, target)
        except FileExistsError:
            raise
        except BaseException:
            output.unlink(missing_ok=True)
            raise
    print(f"Signed APK verified with the pinned OSS certificate: {output}")


def asset_inputs(directory, tag):
    if not re.fullmatch(rf"v{VERSION}", tag):
        raise ValueError("Release tag must be a stable vX.Y.Z version")
    if not stat.S_ISDIR(directory.lstat().st_mode):
        raise ValueError("Release directory must be a real directory, not a symlink")
    names = [f"gglp-{tag[1:]}.apk", "update.json", "provenance.json", "SHA256SUMS"]
    if {path.name for path in directory.iterdir()} != set(names):
        raise ValueError("Release directory must contain exactly APK, update.json, provenance.json, SHA256SUMS")
    for name in names:
        regular_file(directory / name, MAX_APK_SIZE if name.endswith(".apk") else MAX_METADATA_SIZE)
    manifest = validate_manifest(json.loads((directory / "update.json").read_text()))
    if tag != "v" + manifest["versionName"]:
        raise ValueError("Release tag does not match update manifest")
    apk = directory / names[0]
    if apk.stat().st_size != manifest["size"] or sha256(apk) != manifest["sha256"]:
        raise ValueError("APK does not match update manifest")
    return manifest, names


def checksum_text(directory, names):
    return "".join(f"{sha256(directory / name)}  {name}\n" for name in names)


def validate_assets(directory, tag):
    manifest, names = asset_inputs(directory, tag)
    expected = checksum_text(directory, names[:-1])
    if (directory / "SHA256SUMS").read_text() != expected:
        raise ValueError("Release checksums do not match assets")
    return manifest, names


def seal(directory, tag):
    """Bind the attestation bundle to the exact prepared release assets."""
    _, names = asset_inputs(directory, tag)
    if (directory / "SHA256SUMS").read_text() != checksum_text(directory, names[:2]):
        raise ValueError("Prepared APK and manifest checksums do not match")
    (directory / "SHA256SUMS").write_text(checksum_text(directory, names[:-1]))
    validate_assets(directory, tag)


def verify(directory, tag, build_tools, pubspec):
    manifest, names = validate_assets(directory, tag)
    metadata = inspect(directory / manifest["apkFileName"], build_tools, tag, pubspec, signed=True)
    if any(manifest[key] != value for key, value in metadata.items()):
        raise ValueError("Update manifest does not match independently inspected APK metadata")
    return manifest, names


def check_monotonic(candidate, previous):
    for item in previous:
        validate_manifest(item)
        if candidate["versionCode"] <= item["versionCode"]:
            raise ValueError("Release version code must exceed every published Android version code")
        if tuple(map(int, candidate["versionName"].split("."))) <= tuple(
                map(int, item["versionName"].split("."))):
            raise ValueError("Stable release version must exceed every published version")


def authorize_publication(directory, tag):
    names = ("GITHUB_SHA", "GITHUB_RUN_ID", "GITHUB_RUN_ATTEMPT")
    if any(not os.environ.get(name) for name in names):
        raise ValueError("Publishing requires a verified GitHub Actions workflow context")
    guard = str(Path(__file__).resolve().with_name("release_guard.py"))
    run(sys.executable, guard, "source", "--tag", tag)
    run(sys.executable, guard, "provenance", "--directory", str(directory),
        "--source-sha", os.environ[names[0]], "--run-id", os.environ[names[1]],
        "--run-attempt", os.environ[names[2]])


def publish(directory, tag, build_tools, pubspec):
    manifest, names = verify(directory, tag, build_tools, pubspec)
    authorize_publication(directory, tag)
    validated_digests = {name: sha256(directory / name) for name in names}
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
            if sha256(Path(temporary) / name) != validated_digests[name]:
                raise ValueError(f"Uploaded {name} differs from the validated build")
    # Recheck source approval and cryptographic provenance immediately before
    # the only transition that makes these assets a public release.
    authorize_publication(directory, tag)
    run("gh", "release", "edit", tag, "--repo", REPOSITORY, "--draft=false", "--latest")
    print(f"Published https://github.com/{REPOSITORY}/releases/tag/{tag}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    version = commands.add_parser("version", help="Check pubspec version and release tag")
    version.add_argument("--tag", required=True)
    version.add_argument("--pubspec", type=Path, default=Path("pubspec.yaml"))
    inspection = commands.add_parser("inspect", help="Validate an unsigned release candidate")
    inspection.add_argument("--apk", type=Path, required=True)
    inspection.add_argument("--build-tools", type=Path, required=True)
    inspection.add_argument("--tag", required=True)
    inspection.add_argument("--pubspec", type=Path, default=Path("pubspec.yaml"))
    signing = commands.add_parser("sign", help="Sign an APK in an isolated temporary directory")
    signing.add_argument("--apk", type=Path, required=True)
    signing.add_argument("--build-tools", type=Path, required=True)
    signing.add_argument("--output", type=Path, required=True)
    preparation = commands.add_parser("prepare", help="Validate signed APK and create release assets")
    preparation.add_argument("--apk", type=Path, required=True)
    preparation.add_argument("--build-tools", type=Path, required=True)
    preparation.add_argument("--tag", required=True)
    preparation.add_argument("--directory", type=Path, required=True)
    preparation.add_argument("--pubspec", type=Path, default=Path("pubspec.yaml"))
    sealing = commands.add_parser("seal", help="Include the provenance bundle in release checksums")
    sealing.add_argument("--tag", required=True)
    sealing.add_argument("--directory", type=Path, required=True)
    verification = commands.add_parser("verify", help="Independently verify all release assets and APK identity")
    verification.add_argument("--tag", required=True)
    verification.add_argument("--directory", type=Path, required=True)
    verification.add_argument("--build-tools", type=Path, required=True)
    verification.add_argument("--pubspec", type=Path, default=Path("pubspec.yaml"))
    publication = commands.add_parser("publish", help="Verify assets, then publish a GitHub draft")
    publication.add_argument("--tag", required=True)
    publication.add_argument("--directory", type=Path, required=True)
    publication.add_argument("--build-tools", type=Path, required=True)
    publication.add_argument("--pubspec", type=Path, default=Path("pubspec.yaml"))
    arguments = vars(parser.parse_args())
    command = arguments.pop("command")
    if command == "version":
        print(source_version(arguments["pubspec"].read_text(), arguments["tag"]))
    else:
        {"inspect": inspect, "sign": sign, "prepare": prepare, "seal": seal,
         "verify": verify, "publish": publish}[command](**arguments)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError, zipfile.BadZipFile) as error:
        raise SystemExit(f"Release validation failed: {error}") from error
