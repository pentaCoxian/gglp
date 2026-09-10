#!/usr/bin/env python3
"""Create disposable APKs for connectedDebugAndroidTest; no signing keys are retained.

Run from the repository root after `flutter build apk --debug`:
  python3 android/test/generate_update_fixtures.py --sdk "$ANDROID_HOME"
  cd android && ./gradlew :app:connectedDebugAndroidTest
The debug APK and these fixtures use the standard local Android debug key.
"""

import argparse
import os
from pathlib import Path
import re
import subprocess
import tempfile


def run(*args):
    subprocess.run([str(arg) for arg in args], check=True, stdout=subprocess.DEVNULL)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--sdk", required=True, type=Path)
    options = parser.parse_args()
    repository = Path(__file__).resolve().parents[2]
    version_match = re.search(r"^version:\s*([^\s+]+)\+(\d+)\s*$",
                              (repository / "pubspec.yaml").read_text(), re.MULTILINE)
    if version_match is None:
        raise SystemExit("pubspec.yaml must contain a version name and build number.")
    version_name, version_number = version_match.group(1), int(version_match.group(2))
    assets = repository / "build/app/generated/update-test-assets"
    assets.mkdir(parents=True, exist_ok=True)
    build_tools = options.sdk / "build-tools/36.0.0"
    debug_key = Path.home() / ".android/debug.keystore"
    if not debug_key.is_file():
        raise SystemExit("Build the debug APK first to create the standard Android debug key.")
    with tempfile.TemporaryDirectory(prefix="gglp-update-fixtures-") as temporary:
        directory = Path(temporary)
        wrong_key = directory / "wrong.jks"
        java_home = os.environ.get("JAVA_HOME")
        keytool = Path(java_home) / "bin/keytool" if java_home else "keytool"
        run(keytool, "-genkeypair", "-keystore", wrong_key, "-storepass", "android",
            "-keypass", "android", "-alias", "androiddebugkey", "-dname", "CN=Disposable test key",
            "-keyalg", "RSA", "-keysize", "2048", "-validity", "2", "-noprompt")
        fixtures = [
            ("valid", "io.pentacoxian.gglp", 1000000, "999.0.0", debug_key),
            ("wrong-key", "io.pentacoxian.gglp", 1000000, "999.0.0", wrong_key),
            ("wrong-package", "io.pentacoxian.other", 1000000, "999.0.0", debug_key),
            ("equal", "io.pentacoxian.gglp", version_number, version_name, debug_key),
            ("older", "io.pentacoxian.gglp", max(1, version_number - 1), "0.0.1", debug_key),
        ]
        for name, package, version, version_name, key in fixtures:
            manifest = directory / "AndroidManifest.xml"
            manifest.write_text(
                f'<manifest xmlns:android="http://schemas.android.com/apk/res/android" '
                f'package="{package}" android:versionCode="{version}" android:versionName="{version_name}">'
                '<uses-sdk android:minSdkVersion="21" android:targetSdkVersion="36"/>'
                '<application android:label="Disposable updater fixture"/></manifest>')
            unsigned = directory / f"{name}.apk"
            run(build_tools / "aapt2", "link", "--manifest", manifest,
                "-I", options.sdk / "platforms/android-36/android.jar", "-o", unsigned)
            run(build_tools / "apksigner", "sign", "--ks", key, "--ks-key-alias", "androiddebugkey",
                "--ks-pass", "pass:android", "--key-pass", "pass:android", "--out", assets / f"{name}.apk", unsigned)
        tampered = bytearray((assets / "valid.apk").read_bytes())
        tampered[50] ^= 1
        (assets / "tampered.apk").write_bytes(tampered)
    print(f"Generated {len(fixtures) + 1} disposable APK fixtures in {assets}")


if __name__ == "__main__":
    main()
