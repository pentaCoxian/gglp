# Third-party notices

GGLP's project-owned source and cat/plus app icon are provided under the MIT
license. Third-party components retain their own licenses; the project license
does not replace them.

- **Roboto**: bundled font files in `assets/fonts`, distributed under Apache-2.0.
  The complete license is retained in `assets/fonts/LICENSE`.
  Upstream: https://github.com/googlefonts/roboto
- **Flutter and Dart**: BSD-style licenses. Flutter bundles notices for the
  engine and package dependencies into each application build.
  Upstream: https://github.com/flutter/flutter and https://github.com/dart-lang/sdk
- **pretext (Dart)**: MIT, Copyright (c) 2026 Craig Merry.
  Upstream: https://github.com/craigm26/pretext_dart
- **SQLite**: public domain; the Dart/Flutter bindings retain their separate
  package licenses. Upstream: https://sqlite.org/copyright.html
- **AndroidX Core and Android APK Signature Scheme verification (apksig)**:
  Apache-2.0, Android Open Source Project. Native dependency notices are
  retained in `assets/licenses/android-apache-2.0.txt` and available in Settings → Licenses.
  Upstream: https://android.googlesource.com/platform/tools/apksig/

Package versions and dependency sources are recorded in `pubspec.lock` and the
Android Gradle configuration. Settings → Licenses includes the Flutter-generated
package license registry. Required copyright and license text must be retained
when redistributing dependencies.
