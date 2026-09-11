"""Release safety checks, using deliberately malformed APK/manifest fixtures."""

import hashlib
import base64
import importlib.util
import json
import os
from pathlib import Path
import struct
import subprocess
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
    (directory / "provenance.json").write_text('{"bundle": "test fixture"}\n')
    (directory / "SHA256SUMS").write_text("".join(
        f"{release.sha256(directory / name)}  {name}\n"
        for name in (item["apkFileName"], "update.json", "provenance.json")
    ))
    return item


def signature():
    return ("Verified using v2 scheme (APK Signature Scheme v2): true\n"
            "Number of signers: 1\nSigner #1 certificate DN: CN=GGLP\n"
            f"Signer #1 certificate SHA-256 digest: {release.SIGNING_CERTIFICATE_SHA256}\n")


def badging():
    return ("package: name='io.pentacoxian.gglp' versionCode='11' versionName='0.9.1'\n"
            "minSdkVersion:'21'\ntargetSdkVersion:'36'\n")


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
        certificate = signature()
        release.validate_signature(certificate)
        with self.assertRaisesRegex(ValueError, "v2 signature"):
            release.validate_signature(certificate.replace("true", "false"))
        with self.assertRaisesRegex(ValueError, "debug signing"):
            release.validate_signature(certificate.replace("CN=GGLP", "CN=Android Debug, O=Android, C=US"))

    def test_wrong_missing_and_multiple_certificates_are_rejected(self):
        for certificate in (
                signature().replace(release.SIGNING_CERTIFICATE_SHA256, "a" * 64),
                signature().replace("Number of signers: 1\n", ""),
                signature().replace("Number of signers: 1", "Number of signers: 2"),
                signature().split("Signer #1 certificate SHA-256")[0],
                signature() + f"Signer #2 certificate SHA-256 digest: {'b' * 64}\n"):
            with self.subTest(certificate=certificate), self.assertRaises(ValueError):
                release.validate_signature(certificate)

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

    def test_symlinks_subdirectories_and_missing_provenance_are_rejected(self):
        for name in (manifest()["apkFileName"], "update.json", "provenance.json", "SHA256SUMS"):
            with self.subTest(name=name), tempfile.TemporaryDirectory() as temporary:
                directory = Path(temporary)
                write_assets(directory)
                target = directory / name
                target.unlink()
                with self.assertRaises(ValueError):
                    release.validate_assets(directory, "v0.9.1")
                target.mkdir()
                with self.assertRaises(ValueError):
                    release.validate_assets(directory, "v0.9.1")
                target.rmdir()
                target.symlink_to("update.json")
                with self.assertRaises(ValueError):
                    release.validate_assets(directory, "v0.9.1")

    def test_seal_requires_original_checksums_then_binds_provenance(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            item = write_assets(directory)
            (directory / "SHA256SUMS").write_text(release.checksum_text(
                directory, [item["apkFileName"], "update.json"]))
            release.seal(directory, "v0.9.1")
            release.validate_assets(directory, "v0.9.1")
            (directory / "provenance.json").write_text("altered")
            with self.assertRaisesRegex(ValueError, "checksums"):
                release.validate_assets(directory, "v0.9.1")

    def test_verify_independently_compares_manifest_to_apk(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            write_assets(directory)
            metadata = {key: manifest()[key] for key in
                        ("versionName", "versionCode", "packageId", "minSdk")}
            with patch.object(release, "inspect", return_value=metadata) as inspection:
                release.verify(directory, "v0.9.1", Path("tools"), Path("pubspec.yaml"))
                self.assertTrue(inspection.call_args.kwargs["signed"])
            with patch.object(release, "inspect", return_value={**metadata, "versionCode": 12}):
                with self.assertRaisesRegex(ValueError, "independently inspected"):
                    release.verify(directory, "v0.9.1", Path("tools"), Path("pubspec.yaml"))


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
    def setUp(self):
        verifier = patch.object(release, "verify", side_effect=lambda directory, tag, *_:
                                release.validate_assets(directory, tag))
        self.verifier = verifier.start()
        self.addCleanup(verifier.stop)
        authorization = patch.object(release, "authorize_publication")
        self.authorization = authorization.start()
        self.addCleanup(authorization.stop)

    def test_published_release_is_never_replaced(self):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            write_assets(directory)
            with patch.object(release, "run", return_value=json.dumps([
                    [{"tag_name": "v0.9.1", "draft": False}]])) as runner:
                with self.assertRaisesRegex(ValueError, "already published"):
                    release.publish(directory, "v0.9.1", Path("tools"), Path("pubspec.yaml"))
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
                    release.publish(directory, "v0.9.1", Path("tools"), Path("pubspec.yaml"))
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
                    for name in (item["apkFileName"], "update.json", "provenance.json")
                ))
            return ""

        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            write_assets(directory)
            with patch.object(release, "run", side_effect=fake_run):
                with self.assertRaisesRegex(ValueError, "differs"):
                    release.publish(directory, "v0.9.1", Path("tools"), Path("pubspec.yaml"))
        self.assertFalse(any("edit" in call for call in calls))

    def test_failed_independent_verification_never_mutates_remote(self):
        self.verifier.side_effect = ValueError("wrong signature")
        with patch.object(release, "run") as runner:
            with self.assertRaisesRegex(ValueError, "wrong signature"):
                release.publish(Path("release"), "v0.9.1", Path("tools"), Path("pubspec.yaml"))
            runner.assert_not_called()
            self.authorization.assert_not_called()

    def test_failed_provenance_never_mutates_remote(self):
        self.authorization.side_effect = ValueError("wrong provenance")
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            write_assets(directory)
            with patch.object(release, "run") as runner:
                with self.assertRaisesRegex(ValueError, "wrong provenance"):
                    release.publish(directory, "v0.9.1", Path("tools"), Path("pubspec.yaml"))
                runner.assert_not_called()

    def test_success_rechecks_authorization_and_publishes_only_exact_bytes(self):
        calls = []

        def fake_run(*args):
            calls.append(args)
            if args[1] == "api":
                return "[[]]"
            if args[1:3] == ("release", "download"):
                write_assets(Path(args[-1]))
            return ""

        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            write_assets(directory)
            with patch.object(release, "run", side_effect=fake_run):
                release.publish(directory, "v0.9.1", Path("tools"), Path("pubspec.yaml"))
        self.assertEqual(self.authorization.call_count, 2)
        self.assertEqual(calls[-1][1:3], ("release", "edit"))
        self.assertIn("--draft=false", calls[-1])


class SigningTests(unittest.TestCase):
    def test_unsigned_probe_rejects_success_tool_errors_and_ambiguous_failure(self):
        with tempfile.TemporaryDirectory() as temporary:
            apk = Path(temporary) / "candidate.apk"
            with zipfile.ZipFile(apk, "w") as archive:
                archive.writestr("AndroidManifest.xml", b"fixture")
            unsigned = subprocess.CompletedProcess([], 1, "", "Missing META-INF/MANIFEST.MF")
            with patch.object(release.subprocess, "run", return_value=unsigned):
                release.validate_unsigned(apk, Path("tools"))
            for code, output in ((0, "Verified"), (2, "Missing META-INF/MANIFEST.MF"),
                                 (1, "Invalid signature"), (-9, "Killed")):
                with patch.object(release.subprocess, "run", return_value=
                                  subprocess.CompletedProcess([], code, output, "")):
                    with self.subTest(code=code), self.assertRaises(ValueError):
                        release.validate_unsigned(apk, Path("tools"))

    def test_existing_v1_or_apk_signing_blocks_are_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            apk = Path(temporary) / "candidate.apk"
            with zipfile.ZipFile(apk, "w") as archive:
                archive.writestr("META-INF/RELEASE.RSA", b"fixture")
            with self.assertRaisesRegex(ValueError, "unsigned"):
                release.validate_unsigned(apk, Path("tools"))
            with zipfile.ZipFile(apk, "w") as archive:
                archive.writestr("AndroidManifest.xml", b"fixture")
            with zipfile.ZipFile(apk) as archive:
                offset = archive.start_dir
            data = apk.read_bytes()
            data = bytearray(data[:offset] + b"APK Sig Block 42" + data[offset:])
            struct.pack_into("<I", data, data.rindex(b"PK\x05\x06") + 16, offset + 16)
            apk.write_bytes(data)
            with self.assertRaisesRegex(ValueError, "signing block"):
                release.validate_unsigned(apk, Path("tools"))

    def exercise_signing(self, failure=False):
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            apk, output = directory / "candidate.apk", directory / "signed.apk"
            apk.write_bytes(b"unsigned fixture")
            environment = {
                "ANDROID_KEYSTORE_BASE64": base64.b64encode(b"throwaway fixture").decode(),
                "ANDROID_KEYSTORE_PASSWORD": "throwaway-store-password",
                "ANDROID_KEY_ALIAS": "test-only",
                "ANDROID_KEY_PASSWORD": "throwaway-key-password",
                "RUNNER_TEMP": str(directory),
            }

            def fake_sign(args, **kwargs):
                key_path = Path(args[args.index("--ks") + 1])
                self.assertEqual(key_path.stat().st_mode & 0o777, 0o600)
                self.assertEqual(key_path.parent.stat().st_mode & 0o777, 0o700)
                self.assertEqual(key_path.read_bytes(), b"throwaway fixture")
                self.assertNotIn("ANDROID_KEYSTORE_BASE64", kwargs["env"])
                self.assertNotIn(environment["ANDROID_KEYSTORE_PASSWORD"], args)
                self.assertNotIn(environment["ANDROID_KEY_PASSWORD"], args)
                if failure:
                    raise subprocess.CalledProcessError(1, ["apksigner"])
                Path(args[args.index("--out") + 1]).write_bytes(b"signed fixture")
                return ""

            def fake_run(*args):
                if "verify" in args:
                    return signature()
                if "badging" in args:
                    return badging()
                return "aligned"

            with patch.dict(os.environ, environment, clear=True), \
                    patch.object(release, "validate_unsigned"), \
                    patch.object(release, "validate_native_libraries"), \
                    patch.object(release, "run", side_effect=fake_run), \
                    patch.object(release.subprocess, "check_output", side_effect=fake_sign):
                if failure:
                    with self.assertRaises(subprocess.CalledProcessError):
                        release.sign(apk, Path("tools"), output)
                    self.assertFalse(output.exists())
                else:
                    release.sign(apk, Path("tools"), output)
                    self.assertEqual(output.read_bytes(), b"signed fixture")
            self.assertFalse(any(path.is_dir() for path in directory.iterdir()))
            self.assertFalse(any(path.suffix == ".jks" for path in directory.rglob("*")))

    def test_signing_cleans_private_temporary_key_on_success(self):
        self.exercise_signing()

    def test_signing_cleans_private_temporary_key_on_failure(self):
        self.exercise_signing(failure=True)


class AuthorizationTests(unittest.TestCase):
    def test_local_publication_without_workflow_context_is_rejected(self):
        with patch.dict(os.environ, {}, clear=True), patch.object(release, "run") as runner:
            with self.assertRaisesRegex(ValueError, "workflow context"):
                release.authorize_publication(Path("release"), "v0.9.1")
            runner.assert_not_called()

    def test_both_source_and_provenance_guard_are_mandatory(self):
        with patch.dict(os.environ, {"GITHUB_SHA": "a" * 40, "GITHUB_RUN_ID": "123",
                                    "GITHUB_RUN_ATTEMPT": "2"}, clear=True), \
                patch.object(release, "run") as runner:
            release.authorize_publication(Path("release"), "v0.9.1")
        self.assertEqual(runner.call_count, 2)
        self.assertEqual(runner.call_args_list[0].args[2:], ("source", "--tag", "v0.9.1"))
        self.assertEqual(runner.call_args_list[1].args[2:], (
            "provenance", "--directory", "release", "--source-sha", "a" * 40,
            "--run-id", "123", "--run-attempt", "2"))


if __name__ == "__main__":
    unittest.main()
