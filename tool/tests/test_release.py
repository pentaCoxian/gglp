"""Release safety checks, using deliberately malformed APK/manifest fixtures."""

import hashlib
import importlib.util
import json
from pathlib import Path
import struct
import tempfile
import unittest
from unittest.mock import patch
import zipfile

SPEC = importlib.util.spec_from_file_location(
    "release", Path(__file__).resolve().parents[1] / "release.py"
)
release = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(release)


def manifest():
    return {
        "schemaVersion": 1,
        "versionName": "0.9.1",
        "versionCode": 11,
        "packageId": "io.pentacoxian.gglp",
        "minSdk": 21,
        "apkFileName": "gglp-0.9.1.apk",
        "size": 3,
        "sha256": hashlib.sha256(b"apk").hexdigest(),
    }


def elf(alignment=16384, address=0, offset=0):
    data = bytearray(120)
    data[:6] = b"\x7fELF\x02\x01"
    struct.pack_into("<Q", data, 32, 64)
    struct.pack_into("<HH", data, 54, 56, 1)
    struct.pack_into("<IIQQQQQQ", data, 64, 1, 5, offset, address, 0, 0, 120, alignment)
    return bytes(data)


def write_assets(directory):
    item = manifest()
    (directory / item["apkFileName"]).write_bytes(b"apk")
    (directory / "update.json").write_text(json.dumps(item))
    (directory / "SHA256SUMS").write_text("".join(
        f"{release.sha256(directory / name)}  {name}\n"
        for name in (item["apkFileName"], "update.json")
    ))
    return item


class VersionTests(unittest.TestCase):
    def test_tag_and_pubspec_must_agree(self):
        self.assertEqual(release.source_version("version: 0.9.1+11\n", "v0.9.1"), ("0.9.1", 11))
        for text, tag in (("version: 0.9.1+11", "v0.9.2"),
                          ("version: 0.9.1+0", "v0.9.1"),
                          ("version: 0.9.1-beta+11", "v0.9.1-beta"),
                          ("version: 0.9.1+2100000001", "v0.9.1")):
            with self.subTest(text=text, tag=tag), self.assertRaises(ValueError):
                release.source_version(text, tag)

    def test_apk_metadata_is_read_from_badging(self):
        badging = ("package: name='io.pentacoxian.gglp' versionCode='11' versionName='0.9.1'\n"
                   "minSdkVersion:'21'\ntargetSdkVersion:'36'\n")
        self.assertEqual(release.apk_metadata(badging)["versionCode"], 11)
        self.assertEqual(release.apk_metadata(badging.replace("minSdkVersion", "sdkVersion"))["minSdk"], 21)
        for source, replacement in (("io.pentacoxian.gglp", "other.package"),
                                    ("minSdkVersion:'21'", "minSdkVersion:'24'"),
                                    ("targetSdkVersion:'36'", "targetSdkVersion:'35'"),
                                    ("versionCode='11'", "versionCode='-1'")):
            with self.subTest(source=source), self.assertRaises(ValueError):
                release.apk_metadata(badging.replace(source, replacement))
        with self.assertRaisesRegex(ValueError, "debuggable"):
            release.apk_metadata(badging + "application-debuggable\n")

    def test_debug_certificate_and_missing_v2_signature_are_rejected(self):
        signature = ("Verified using v2 scheme (APK Signature Scheme v2): true\n"
                     "Signer #1 certificate DN: CN=GGLP\n")
        release.validate_signature(signature)
        with self.assertRaisesRegex(ValueError, "v2 signature"):
            release.validate_signature(signature.replace("true", "false"))
        with self.assertRaisesRegex(ValueError, "debug signing"):
            release.validate_signature(signature.replace("CN=GGLP", "CN=Android Debug, O=Android, C=US"))

    def test_version_codes_and_stable_versions_increase(self):
        current = manifest()
        earlier = {**current, "versionName": "0.9.0", "versionCode": 10,
                   "apkFileName": "gglp-0.9.0.apk"}
        release.check_monotonic(current, [earlier])
        release.check_monotonic(current, [])
        for code in (11, 12):
            with self.assertRaises(ValueError):
                release.check_monotonic(current, [{**earlier, "versionCode": code}])
        with self.assertRaises(ValueError):
            release.check_monotonic(current, [{**current, "versionCode": 10}])


class ManifestTests(unittest.TestCase):
    def test_complete_manifest_is_valid(self):
        self.assertEqual(release.validate_manifest(manifest()), manifest())

    def test_reject_missing_unknown_and_unsafe_fields(self):
        changes = [
            {"schemaVersion": 2}, {"versionCode": True}, {"versionCode": "11"},
            {"versionCode": 0}, {"minSdk": 26}, {"size": 0},
            {"size": release.MAX_APK_SIZE + 1}, {"sha256": "a" * 63},
            {"apkFileName": "../gglp-0.9.1.apk"}, {"packageId": "other.app"},
            {"versionName": "0.9.1\ninjected"}, {"url": "https://untrusted.example/apk"},
        ]
        for change in changes:
            with self.subTest(change=change), self.assertRaises(ValueError):
                release.validate_manifest({**manifest(), **change})
        for field in manifest():
            invalid = manifest()
            del invalid[field]
            with self.subTest(missing=field), self.assertRaises(ValueError):
                release.validate_manifest(invalid)

    def test_altered_truncated_and_extra_assets_are_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            item = write_assets(directory)
            release.validate_assets(directory, "v0.9.1")
            for data in (b"ap", b"bad"):
                (directory / item["apkFileName"]).write_bytes(data)
                with self.assertRaises(ValueError):
                    release.validate_assets(directory, "v0.9.1")
            write_assets(directory)
            (directory / "secret.jks").write_text("must not upload")
            with self.assertRaises(ValueError):
                release.validate_assets(directory, "v0.9.1")

    def test_wrong_checksums_and_tag_are_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            write_assets(directory)
            with self.assertRaises(ValueError):
                release.validate_assets(directory, "v0.9.2")
            (directory / "SHA256SUMS").write_text("wrong\n")
            with self.assertRaises(ValueError):
                release.validate_assets(directory, "v0.9.1")


class AlignmentTests(unittest.TestCase):
    def test_load_alignment_and_address_congruence(self):
        release.validate_elf(elf(), "aligned.so")
        release.validate_elf(elf(alignment=65536), "aligned64.so")
        for data in (elf(alignment=4096), elf(alignment=17000), elf(address=4096),
                     elf()[:100], b"not an elf", elf(offset=16384)):
            with self.subTest(data=data[:12]), self.assertRaises(ValueError):
                release.validate_elf(data, "bad.so")

    def test_universal_abis_and_every_64_bit_library_are_checked(self):
        with tempfile.TemporaryDirectory() as temporary:
            apk = Path(temporary) / "test.apk"
            with zipfile.ZipFile(apk, "w") as archive:
                for abi in ("armeabi-v7a", "arm64-v8a", "x86_64"):
                    archive.writestr(f"lib/{abi}/libflutter.so", elf())
                archive.writestr("lib/arm64-v8a/libsqlite3.so", elf(alignment=4096))
            with self.assertRaisesRegex(ValueError, "libsqlite3"):
                release.validate_native_libraries(apk)
            with zipfile.ZipFile(apk, "w") as archive:
                archive.writestr("lib/arm64-v8a/libflutter.so", elf())
            with self.assertRaisesRegex(ValueError, "missing"):
                release.validate_native_libraries(apk)


class PublishingTests(unittest.TestCase):
    def test_published_release_is_never_replaced(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            write_assets(directory)
            with patch.object(release, "run", return_value=json.dumps([
                    [{"tag_name": "v0.9.1", "draft": False}]])) as runner:
                with self.assertRaisesRegex(ValueError, "already published"):
                    release.publish(directory, "v0.9.1")
            self.assertEqual(runner.call_count, 1)

    def test_upload_failure_leaves_draft_unpublished(self):
        calls = []

        def fake_run(*args):
            calls.append(args)
            if args[1] == "api":
                return "[[]]"
            if args[1:3] == ("release", "upload"):
                raise OSError("simulated upload failure")
            return ""

        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            write_assets(directory)
            with patch.object(release, "run", side_effect=fake_run):
                with self.assertRaises(OSError):
                    release.publish(directory, "v0.9.1")
        self.assertTrue(any("create" in call and "--draft" in call for call in calls))
        self.assertFalse(any("edit" in call for call in calls))

    def test_uploaded_bytes_must_match_before_publish(self):
        calls = []

        def fake_run(*args):
            calls.append(args)
            if args[1] == "api":
                return "[[]]"
            if args[1:3] == ("release", "download"):
                remote = Path(args[-1])
                write_assets(remote)
                # A self-consistent but different remote APK must still fail.
                item = manifest()
                item["sha256"] = hashlib.sha256(b"bad").hexdigest()
                (remote / item["apkFileName"]).write_bytes(b"bad")
                (remote / "update.json").write_text(json.dumps(item))
                (remote / "SHA256SUMS").write_text("".join(
                    f"{release.sha256(remote / name)}  {name}\n"
                    for name in (item["apkFileName"], "update.json")
                ))
            return ""

        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            write_assets(directory)
            with patch.object(release, "run", side_effect=fake_run):
                with self.assertRaisesRegex(ValueError, "differs"):
                    release.publish(directory, "v0.9.1")
        self.assertFalse(any("edit" in call for call in calls))

    def test_java_properties_escape_password_delimiters(self):
        self.assertEqual(release.property_value(" a=b:c\\d\n"), r"\ a\=b\:c\\d\n")


if __name__ == "__main__":
    unittest.main()
