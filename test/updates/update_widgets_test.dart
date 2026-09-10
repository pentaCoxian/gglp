import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_gglp/app/updates/update_bridge.dart';
import 'package:misskey_gglp/app/updates/update_client.dart';
import 'package:misskey_gglp/app/updates/update_controller.dart';
import 'package:misskey_gglp/app/updates/update_manifest.dart';
import 'package:misskey_gglp/app/updates/update_preferences.dart';
import 'package:misskey_gglp/app/updates/update_widgets.dart';

class _UnusedSource implements UpdateSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  void close() {}
}

class _UnusedBridge implements UpdateBridge {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedStore implements UpdatePreferenceStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Controller extends UpdateController {
  _Controller()
    : super(
        source: _UnusedSource(),
        bridge: _UnusedBridge(),
        store: _UnusedStore(),
        supported: false,
      ) {
    state = const UpdateState(supported: true, initialized: true);
  }

  void showUpdate(bool show) {
    state = state.copyWith(
      update:
          show
              ? const AppUpdate(
                manifest: UpdateManifest(
                  versionName: '0.9.1',
                  versionCode: 11,
                  packageId: updatePackageId,
                  minSdk: 21,
                  apkFileName: 'gglp.apk',
                  size: 4,
                  sha256: '',
                ),
              )
              : null,
    );
  }

  @override
  Future<void> foreground() async {}
  @override
  Future<void> background() async {}
}

class _Content extends StatefulWidget {
  final VoidCallback onInit;
  const _Content({required this.onInit});
  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => const Text('Current app screen');
}

void main() {
  testWidgets('showing and dismissing a notice preserves the app subtree', (
    tester,
  ) async {
    final controller = _Controller();
    var initializations = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [updateControllerProvider.overrideWith((_) => controller)],
        child: MaterialApp(
          home: UpdateHost(
            onReview: () {},
            child: _Content(onInit: () => initializations++),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(initializations, 1);
    controller.showUpdate(true);
    await tester.pump();
    expect(find.text('GGLP 0.9.1 is available.'), findsOneWidget);
    expect(initializations, 1);
    controller.showUpdate(false);
    await tester.pump();
    expect(find.text('Current app screen'), findsOneWidget);
    expect(initializations, 1);
  });
}
