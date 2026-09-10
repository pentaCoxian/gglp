import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/plus/plus.dart';
import 'update_controller.dart';

/// App-lifetime foreground observer and small dismissible update notice.
class UpdateHost extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback onReview;
  const UpdateHost({required this.child, required this.onReview, super.key});

  @override
  ConsumerState<UpdateHost> createState() => _UpdateHostState();
}

class _UpdateHostState extends ConsumerState<UpdateHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(ref.read(updateControllerProvider.notifier).foreground());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(updateControllerProvider.notifier);
    if (state == AppLifecycleState.resumed) {
      unawaited(controller.foreground());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(controller.background());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(updateControllerProvider);
    if (!state.supported) return widget.child;
    return Column(
      children: [
        if (state.showNotice)
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'GGLP ${state.update!.manifest.versionName} is available.',
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onReview,
                      child: const Text('Review'),
                    ),
                    IconButton(
                      tooltip: 'Dismiss this update',
                      onPressed:
                          () =>
                              ref
                                  .read(updateControllerProvider.notifier)
                                  .dismiss(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(key: const ValueKey('app-content'), child: widget.child),
      ],
    );
  }
}

class UpdateSettingsCard extends ConsumerWidget {
  const UpdateSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateControllerProvider);
    if (!state.supported) return const SizedBox.shrink();
    final controller = ref.read(updateControllerProvider.notifier);
    final update = state.update;
    final theme = Theme.of(context);
    final downloading = state.stage == UpdateStage.downloading;
    final verifying = state.stage == UpdateStage.verifying;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
          child: Text(
            'APP UPDATES',
            style: theme.textTheme.labelSmall?.copyWith(
              color: PlusTheme.of(context).textSecondary,
            ),
          ),
        ),
        PlusCard(
          margin: const EdgeInsets.fromLTRB(14, 4, 14, 12),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.update),
                title: const Text('Automatic update checks'),
                subtitle: const Text(
                  'Check GitHub once a day while GGLP is open. '
                  'Downloads only start when you choose.',
                ),
                value: state.automaticChecks,
                onChanged:
                    state.initialized ? controller.setAutomaticChecks : null,
              ),
              ListTile(
                title: const Text('Installed version'),
                subtitle: Text(
                  state.installed == null
                      ? 'Loading…'
                      : '${state.installed!.versionName} (${state.installed!.versionCode})',
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed:
                        state.busy || state.installed == null
                            ? null
                            : () => controller.check(),
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      state.stage == UpdateStage.checking
                          ? 'Checking…'
                          : 'Check for updates',
                    ),
                  ),
                ),
              ),
              if (update != null) ...[
                const Divider(),
                ListTile(
                  title: Text(
                    'GGLP ${update.manifest.versionName} is available',
                  ),
                  subtitle: Text(
                    'Build ${update.manifest.versionCode} · '
                    '${(update.manifest.size / (1024 * 1024)).toStringAsFixed(1)} MB',
                  ),
                ),
                if (update.releaseNotes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed:
                            () => showDialog<void>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: Text(
                                      'GGLP ${update.manifest.versionName}',
                                    ),
                                    content: SingleChildScrollView(
                                      child: SelectableText(
                                        update.releaseNotes,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                            ),
                        child: const Text('Release notes'),
                      ),
                    ),
                  ),
                if (downloading || verifying)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LinearProgressIndicator(
                          value:
                              verifying
                                  ? null
                                  : state.received / update.manifest.size,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          verifying
                              ? 'Verifying the APK…'
                              : 'Downloading ${(state.received * 100 / update.manifest.size).round()}%',
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (downloading)
                        TextButton(
                          onPressed: controller.cancelDownload,
                          child: const Text('Cancel download'),
                        )
                      else if (update.downloadedPath != null)
                        FilledButton.icon(
                          onPressed: state.busy ? null : controller.install,
                          icon: const Icon(Icons.install_mobile),
                          label: const Text('Install'),
                        )
                      else if (update.apkUrl != null)
                        FilledButton.icon(
                          onPressed: state.busy ? null : controller.download,
                          icon: const Icon(Icons.download),
                          label: const Text('Download APK'),
                        ),
                    ],
                  ),
                ),
              ],
              if (state.message != null || state.error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Text(
                    state.error ?? state.message!,
                    style: TextStyle(
                      color:
                          state.error == null ? null : theme.colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
