import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../plus/plus.dart';

/// add-account screen. User types a host, we run MiAuth, persist the
/// account, then pop back.
class AddAccountScreen extends ConsumerStatefulWidget {
  const AddAccountScreen({super.key});

  @override
  ConsumerState<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends ConsumerState<AddAccountScreen> {
  final _hostCtl = TextEditingController(text: 'misskey.io');
  bool _busy = false;
  Object? _error;

  @override
  void dispose() {
    _hostCtl.dispose();
    super.dispose();
  }

  Future<void> _addAccount() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(accountRepositoryProvider);
      await repo.addAccount(_hostCtl.text);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Add Misskey account')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Flat underline input straight from the theme — no extra
            // chrome around the host field.
            TextField(
              controller: _hostCtl,
              decoration: const InputDecoration(
                labelText: 'Server host',
                hintText: 'misskey.io',
              ),
              autofocus: true,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
            ),
            const SizedBox(height: 8),
            // Former helperText — sits under the field so the input
            // stays a clean single line.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'You will be redirected to your browser to authorize.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 16),
            // Primary CTA: white raised 2014-style rectangle.
            PlusButton.raised(
              onTap: _busy ? null : _addAccount,
              semanticLabel: 'Continue',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_busy)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.login),
                  const SizedBox(width: 8),
                  const Text('Continue'),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                '$_error',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
