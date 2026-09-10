import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Roboto',
    ], await rootBundle.loadString('assets/fonts/LICENSE'));
    yield LicenseEntryWithLineBreaks([
      'AndroidX Core',
      'Android apksig',
    ], await rootBundle.loadString('assets/licenses/android-apache-2.0.txt'));
  });
  runApp(const ProviderScope(child: MisskeyGglpApp()));
}
