import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_gglp/mfm/effects/effect_widgets.dart';

/// **The M4c invariant test (design plan §M4c, "the constraint enforcer").**
///
/// For every Tier 3 effect, the reported [RenderBox.size] of the
/// effect-on render must equal the reported size of the effect-off
/// render (== the bare child). If this ever fails, the height cache
/// (M6) will silently drift and the timeline will jitter during
/// streaming bursts.
void main() {
  const cases = [
    'shake',
    'jelly',
    'tada',
    'jump',
    'bounce',
    'spin',
    'rotate',
    'flip',
    'blur',
  ];

  // Use a fixed-size child so the bare layout is deterministic.
  Widget bareChild() => const SizedBox(width: 100, height: 24, child: Text('x'));

  for (final name in cases) {
    testWidgets('$name preserves child Size (animate=on == animate=off)',
        (tester) async {
      final builder = effectBuilderFor(name)!;

      // Layout the bare child so we know the reference size.
      await tester.pumpWidget(MaterialApp(home: Center(child: bareChild())));
      final bareSize = tester.getSize(find.byType(SizedBox).first);

      // Effect with animation on.
      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: Builder(
            builder: (context) => builder(
              context: context,
              args: const {},
              animate: true,
              child: bareChild(),
            ),
          ),
        ),
      ));
      // Pump one frame to let any AnimationController init.
      await tester.pump(const Duration(milliseconds: 16));
      final onSize = tester.getSize(find.byType(SizedBox).first);

      // Effect with animation off.
      await tester.pumpWidget(MaterialApp(
        home: Center(
          child: Builder(
            builder: (context) => builder(
              context: context,
              args: const {},
              animate: false,
              child: bareChild(),
            ),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 16));
      final offSize = tester.getSize(find.byType(SizedBox).first);

      expect(onSize, bareSize,
          reason: '$name animate=on Size differs from bare child');
      expect(offSize, bareSize,
          reason: '$name animate=off Size differs from bare child');
    });
  }
}
