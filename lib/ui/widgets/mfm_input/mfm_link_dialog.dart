import 'package:flutter/material.dart';

import '../../plus/plus.dart';

/// Result of [showMfmLinkDialog].
class MfmLinkResult {
  final String label;
  final String url;
  const MfmLinkResult({required this.label, required this.url});
}

/// Prompt the user for a link label and URL.
///
/// Returns null on cancel. Empty label / empty URL also count as cancel
/// — the toolbar / shortcut handler should no-op rather than insert a
/// half-formed link.
Future<MfmLinkResult?> showMfmLinkDialog(
  BuildContext context, {
  String initialLabel = '',
  String initialUrl = '',
}) async {
  final labelCtl = TextEditingController(text: initialLabel);
  final urlCtl = TextEditingController(text: initialUrl);
  final result = await showDialog<MfmLinkResult>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Insert link'),
      // Plain fields: the theme's underline input decoration provides
      // the flat 2014 look.
      // Scrollable so the two fields + labels survive a landscape
      // phone with the keyboard up.
      content: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: labelCtl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Label',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: urlCtl,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'URL',
              hintText: 'https://…',
            ),
            onSubmitted: (_) {
              final l = labelCtl.text.trim();
              final u = urlCtl.text.trim();
              if (l.isEmpty || u.isEmpty) return;
              Navigator.of(ctx).pop(MfmLinkResult(label: l, url: u));
            },
          ),
        ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        PlusButton.text(
          onTap: () {
            final l = labelCtl.text.trim();
            final u = urlCtl.text.trim();
            if (l.isEmpty || u.isEmpty) {
              Navigator.of(ctx).pop();
              return;
            }
            Navigator.of(ctx).pop(MfmLinkResult(label: l, url: u));
          },
          child: const Text('Insert'),
        ),
      ],
    ),
  );
  labelCtl.dispose();
  urlCtl.dispose();
  return result;
}
