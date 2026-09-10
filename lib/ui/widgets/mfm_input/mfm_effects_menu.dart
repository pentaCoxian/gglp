import 'package:flutter/material.dart';

import '../../plus/plus.dart';

/// What [showMfmEffectsMenu] returns: the MFM `prefix` and `suffix`
/// pair to feed into [insertWrapping] for the chosen effect.
///
/// e.g. `MfmEffectInsert(prefix: r'$[shake ', suffix: ']')` → user gets
/// `$[shake |]` with caret in the middle.
class MfmEffectInsert {
  final String prefix;
  final String suffix;
  const MfmEffectInsert({required this.prefix, required this.suffix});
}

/// Two-column popup: motion/transform effects on the left, an 8-swatch
/// colour grid for `fg.color` / `bg.color` on the right.
///
/// Phone-friendly — wraps to single-column under a width threshold so
/// every option is reachable with one thumb.
Future<MfmEffectInsert?> showMfmEffectsMenu(BuildContext context) {
  return showModalBottomSheet<MfmEffectInsert>(
    context: context,
    // The default 9/16 cap is too short for ~400px of chips + swatches
    // at larger text scales; take control of the height and scroll.
    isScrollControlled: true,
    builder: (_) => const _EffectsSheet(),
  );
}

class _EffectsSheet extends StatelessWidget {
  const _EffectsSheet();

  static const _motionEffects = <_EffectEntry>[
    _EffectEntry(name: 'shake', label: 'Shake', icon: Icons.vibration),
    _EffectEntry(name: 'jelly', label: 'Jelly', icon: Icons.water_drop),
    _EffectEntry(name: 'tada', label: 'Tada', icon: Icons.celebration),
    _EffectEntry(name: 'jump', label: 'Jump', icon: Icons.arrow_upward),
    _EffectEntry(name: 'bounce', label: 'Bounce', icon: Icons.sports_volleyball),
    _EffectEntry(name: 'spin', label: 'Spin', icon: Icons.refresh),
    _EffectEntry(name: 'rotate.deg=15', label: 'Rotate 15°', icon: Icons.rotate_right),
    _EffectEntry(name: 'flip', label: 'Flip', icon: Icons.flip),
    _EffectEntry(name: 'blur', label: 'Blur', icon: Icons.blur_on),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final free =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: free * 0.8),
        child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Effect', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final e in _motionEffects)
                  // Flat rect chip with the accent on the icon.
                  PlusChip(
                    onTap: () => Navigator.of(context).pop(
                      MfmEffectInsert(
                        prefix: '\$[${e.name} ',
                        suffix: ']',
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(e.icon,
                            size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(e.label, style: theme.textTheme.labelLarge),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Foreground colour', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _SwatchRow(
              colours: _swatches(theme),
              onPick: (hex) => Navigator.of(context).pop(
                MfmEffectInsert(
                  prefix: '\$[fg.color=$hex ',
                  suffix: ']',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Background colour', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _SwatchRow(
              colours: _swatches(theme),
              onPick: (hex) => Navigator.of(context).pop(
                MfmEffectInsert(
                  prefix: '\$[bg.color=$hex ',
                  suffix: ']',
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _EffectEntry {
  final String name;
  final String label;
  final IconData icon;
  const _EffectEntry({
    required this.name,
    required this.label,
    required this.icon,
  });
}

List<({Color color, String hex, String label})> _swatches(ThemeData theme) {
  // 6 theme-derived swatches + 2 brand neutrals (black + a Misskey-ish
  // pink). Hex is uppercase, no `#` — that's the form Misskey's MFM
  // parser accepts.
  String h(Color c) {
    // ignore: deprecated_member_use
    final v = c.value & 0xFFFFFF;
    return v.toRadixString(16).padLeft(6, '0').toUpperCase();
  }
  final cs = theme.colorScheme;
  return [
    (color: cs.primary, hex: h(cs.primary), label: 'Primary'),
    (color: cs.secondary, hex: h(cs.secondary), label: 'Secondary'),
    (color: cs.tertiary, hex: h(cs.tertiary), label: 'Tertiary'),
    (color: cs.error, hex: h(cs.error), label: 'Error'),
    (color: Colors.amber, hex: 'FFC107', label: 'Amber'),
    (color: Colors.green, hex: '4CAF50', label: 'Green'),
    (color: const Color(0xFFE56DA4), hex: 'E56DA4', label: 'Pink'),
    (color: cs.onSurface, hex: h(cs.onSurface), label: 'On-surface'),
  ];
}

class _SwatchRow extends StatelessWidget {
  final List<({Color color, String hex, String label})> colours;
  final void Function(String hex) onPick;
  const _SwatchRow({required this.colours, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final plus = PlusTheme.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final c in colours)
          // Flat outlined swatch circle (the swatch itself is content,
          // so it keeps its circular shape).
          Tooltip(
            message: '${c.label}  #${c.hex}',
            child: Semantics(
              label: '${c.label} colour',
              button: true,
              child: InkWell(
                onTap: () => onPick(c.hex),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: plus.border),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
