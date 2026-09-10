import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/settings/settings_controller.dart';
import '../../app/updates/update_widgets.dart';
import '../plus/plus.dart';

/// User-facing app settings.
///
/// Backed by `app_preferences` (a Drift singleton row); the controller
/// persists every change immediately so there's no save button.
///
/// Layout: each section's tiles are grouped on a [PlusCard] with
/// its `_SectionHeader` label sitting on the background above the card
/// — the classic soft-UI grouped-settings look.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);

    // Shared grouped-card chrome for every section.
    const cardMargin = EdgeInsets.fromLTRB(14, 4, 14, 12);
    const cardPadding = EdgeInsets.symmetric(vertical: 4);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _SectionHeader(label: 'Appearance', theme: theme),
          PlusCard(
            margin: cardMargin,
            padding: cardPadding,
            child: Column(
              children: [
                _ChoiceTile<ThemeMode>(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Theme'),
                  subtitle: Text(_themeLabel(settings.themeMode)),
                  options: const [
                    (ThemeMode.system, Icons.brightness_auto, 'System'),
                    (ThemeMode.light, Icons.light_mode, 'Light'),
                    (ThemeMode.dark, Icons.dark_mode, 'Dark'),
                  ],
                  selected: settings.themeMode,
                  onChanged: notifier.setThemeMode,
                ),
                ListTile(
                  leading: const Icon(Icons.text_fields),
                  title: const Text('Text size'),
                  subtitle: Slider(
                    min: 0.85,
                    max: 1.6,
                    divisions: 15,
                    value: settings.textScale.clamp(0.85, 1.6),
                    label: '${(settings.textScale * 100).round()}%',
                    onChanged: (v) => notifier.setTextScale(v),
                  ),
                  // Min width keeps the slider from jittering as the
                  // digits change; no max so the readout itself can
                  // grow with the text scale it displays.
                  trailing: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 44),
                    child: Text(
                      '${(settings.textScale * 100).round()}%',
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      softWrap: false,
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _SectionHeader(label: 'Motion & accessibility', theme: theme),
          PlusCard(
            margin: cardMargin,
            padding: cardPadding,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.animation),
                  title: const Text('Animated MFM effects'),
                  subtitle: const Text(
                    'Allow shake, jelly, spin, and other tier-3 effects to '
                    'play. Turn off to keep MFM static.',
                  ),
                  value: !settings.disableAnimatedMfm,
                  onChanged: (v) => notifier.setDisableAnimatedMfm(!v),
                ),
                _ChoiceTile<bool?>(
                  leading: const Icon(Icons.accessibility_new),
                  title: const Text('Reduced motion'),
                  subtitle: Text(switch (settings.reducedMotionOverride) {
                    null =>
                      'Follow OS preference (currently ${_inheritState(context)})',
                    false => 'Always allow motion',
                    true => 'Always reduce motion',
                  }),
                  options: const [
                    (null, null, 'OS'),
                    (false, null, 'On'),
                    (true, null, 'Off'),
                  ],
                  selected: settings.reducedMotionOverride,
                  onChanged: notifier.setReducedMotionOverride,
                ),
              ],
            ),
          ),
          _SectionHeader(label: 'Privacy & content', theme: theme),
          PlusCard(
            margin: cardMargin,
            padding: cardPadding,
            child: SwitchListTile(
              secondary: const Icon(Icons.blur_on),
              title: const Text('Blur sensitive channels'),
              subtitle: const Text(
                'Notes from channels marked sensitive on the server are '
                'blurred until you tap to reveal. Author + channel chip '
                'stay visible.',
              ),
              value: settings.blurSensitiveChannels,
              onChanged: (v) => notifier.setBlurSensitiveChannels(v),
            ),
          ),
          const UpdateSettingsCard(),
          _SectionHeader(label: 'About', theme: theme),
          PlusCard(
            margin: cardMargin,
            padding: cardPadding,
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('GGLP'),
                  subtitle: Text('Cross-platform Misskey client'),
                ),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Source code'),
                  subtitle: const Text('pentaCoxian/gglp on GitHub'),
                  onTap: () async {
                    try {
                      final opened = await launchUrl(
                        Uri.parse('https://github.com/pentaCoxian/gglp'),
                        mode: LaunchMode.externalApplication,
                      );
                      if (!opened && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not open GitHub.'),
                          ),
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not open GitHub.'),
                          ),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Open-source licenses'),
                  onTap:
                      () => showLicensePage(
                        context: context,
                        applicationName: 'GGLP',
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _themeLabel(ThemeMode m) => switch (m) {
    ThemeMode.system => 'Match system',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };

  static String _inheritState(BuildContext context) {
    return MediaQuery.of(context).disableAnimations ? 'reduced' : 'allowed';
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final ThemeData theme;
  const _SectionHeader({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
      child: Text(
        label.toUpperCase(),
        // Small secondary section heading.
        style: theme.textTheme.labelSmall?.copyWith(
          color: PlusTheme.of(context).textSecondary,
        ),
      ),
    );
  }
}

/// Settings row with a [_ChoiceRow] strip. The strip sits in the
/// trailing slot while the tile is wide enough for both; on narrow
/// tiles (small phone × large text scale) it drops under the copy so
/// the title is never squeezed into a sliver beside it.
class _ChoiceTile<T> extends StatelessWidget {
  /// Tile widths below this (in text-scaled logical px) stack the
  /// strip; a 360px phone at 1.0× stays inline, at 1.3× stacks.
  static const double _stackBelow = 300;

  final Widget leading;
  final Widget title;
  final Widget subtitle;
  final List<(T, IconData?, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  const _ChoiceTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final choice = _ChoiceRow<T>(
      options: options,
      selected: selected,
      onChanged: onChanged,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth <
            MediaQuery.textScalerOf(context).scale(_stackBelow);
        if (!stacked) {
          return ListTile(
            leading: leading,
            title: title,
            subtitle: subtitle,
            trailing: choice,
          );
        }
        return ListTile(
          leading: leading,
          title: title,
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [subtitle, const SizedBox(height: 8), choice],
          ),
        );
      },
    );
  }
}

/// Holo-style toggle strip: bordered rectangular segments, dark label
/// and a 2px blue bottom edge on the selected cell — the 2014 stand-in
/// for what would later become SegmentedButton.
class _ChoiceRow<T> extends StatelessWidget {
  final List<(T, IconData?, String)> options;
  final T selected;
  final ValueChanged<T> onChanged;

  const _ChoiceRow({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final plus = PlusTheme.of(context);
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: plus.border),
        borderRadius: BorderRadius.circular(PlusRadii.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, (value, icon, label)) in options.indexed) ...[
            if (i > 0) Container(width: 1, height: 32, color: plus.divider),
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () => onChanged(value),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 44),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color:
                            value == selected
                                ? plus.selected
                                : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null)
                        Icon(
                          icon,
                          size: 16,
                          color:
                              value == selected
                                  ? plus.textPrimary
                                  : plus.textSecondary,
                        ),
                      if (icon == null)
                        Text(
                          label,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color:
                                value == selected
                                    ? plus.textPrimary
                                    : plus.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
