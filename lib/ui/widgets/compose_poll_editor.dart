import 'package:flutter/material.dart';

import '../plus/plus.dart';

/// Mutable poll being drafted in the compose screen.
///
/// Plain (non-persisted) state: polls are intentionally NOT saved to
/// drafts in v1, so this only lives as long as the compose screen.
class PollDraft {
  /// Choice texts, 2..10 entries. Blank entries are allowed while
  /// editing and dropped by [toParams] / ignored by [isValid].
  List<String> choices;

  bool multiple;

  /// How long the poll stays open after posting. Null = no expiry.
  Duration? expiresAfter;

  PollDraft({
    required this.choices,
    this.multiple = false,
    this.expiresAfter,
  });

  List<String> get _filledChoices => [
        for (final c in choices)
          if (c.trim().isNotEmpty) c.trim(),
      ];

  /// A poll needs at least two non-empty choices to be postable.
  bool get isValid => _filledChoices.length >= 2;

  /// Misskey `notes/create` poll payload: `{choices, multiple,
  /// expiredAfter?}` (relative expiry in milliseconds).
  Map<String, dynamic> toParams() => {
        'choices': _filledChoices,
        'multiple': multiple,
        if (expiresAfter != null)
          'expiredAfter': expiresAfter!.inMilliseconds,
      };
}

/// One expiry preset in the popup selector.
class _ExpiryOption {
  final String label;
  final Duration? duration;
  const _ExpiryOption(this.label, this.duration);
}

const _expiryOptions = <_ExpiryOption>[
  _ExpiryOption('No expiry', null),
  _ExpiryOption('5 minutes', Duration(minutes: 5)),
  _ExpiryOption('30 minutes', Duration(minutes: 30)),
  _ExpiryOption('1 hour', Duration(hours: 1)),
  _ExpiryOption('6 hours', Duration(hours: 6)),
  _ExpiryOption('1 day', Duration(days: 1)),
  _ExpiryOption('3 days', Duration(days: 3)),
  _ExpiryOption('7 days', Duration(days: 7)),
];

/// Inline poll editor rendered inside the compose screen.
///
/// Mutates [draft] in place and calls [onChanged] after every edit so
/// the host screen can re-validate. [onRemove] detaches the poll
/// entirely (the header's delete button).
class ComposePollEditor extends StatefulWidget {
  final PollDraft draft;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const ComposePollEditor({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<ComposePollEditor> createState() => _ComposePollEditorState();
}

class _ComposePollEditorState extends State<ComposePollEditor> {
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    _rebuildControllers();
  }

  @override
  void didUpdateWidget(covariant ComposePollEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A brand-new draft object (poll toggled off and back on) needs
    // fresh controllers; the same instance keeps its editing state.
    if (!identical(oldWidget.draft, widget.draft)) _rebuildControllers();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _rebuildControllers() {
    for (final c in _controllers) {
      c.dispose();
    }
    _controllers
      ..clear()
      ..addAll(
        widget.draft.choices.map((t) => TextEditingController(text: t)),
      );
  }

  void _addChoice() {
    if (widget.draft.choices.length >= 10) return;
    setState(() {
      widget.draft.choices.add('');
      _controllers.add(TextEditingController());
    });
    widget.onChanged();
  }

  void _removeChoice(int index) {
    if (widget.draft.choices.length <= 2) return;
    setState(() {
      widget.draft.choices.removeAt(index);
      _controllers.removeAt(index).dispose();
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final plus = PlusTheme.of(context);
    final draft = widget.draft;
    final selectedExpiry = _expiryOptions.firstWhere(
      (o) => o.duration == draft.expiresAfter,
      orElse: () => _expiryOptions.first,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: plus.surfaceSubtle,
        borderRadius: BorderRadius.circular(PlusRadii.card),
        border: Border.all(color: plus.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with the detach affordance.
          Row(
            children: [
              Icon(Icons.poll_outlined, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                'Poll',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              PlusIconButton(
                icon: Icons.delete_outline,
                tooltip: 'Remove poll',
                size: 16,
                onTap: widget.onRemove,
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < _controllers.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controllers[i],
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Choice ${i + 1}',
                      ),
                      onChanged: (v) {
                        widget.draft.choices[i] = v;
                        widget.onChanged();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  PlusIconButton(
                    icon: Icons.close,
                    tooltip: 'Remove choice',
                    size: 14,
                    onTap: _controllers.length <= 2
                        ? null
                        : () => _removeChoice(i),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: PlusButton.text(
              onTap: draft.choices.length >= 10 ? null : _addChoice,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              tooltip: 'Add choice',
              semanticLabel: 'Add choice',
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 14),
                  SizedBox(width: 4),
                  Text('Add choice'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Multiple choice',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Switch(
                value: draft.multiple,
                onChanged: (v) {
                  setState(() => draft.multiple = v);
                  widget.onChanged();
                },
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Expires',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              // Expiry selector — a labeled soft pill mirroring the
              // compose toolbar's visibility picker.
              PopupMenuButton<int>(
                tooltip: 'Poll expiry',
                onSelected: (i) {
                  setState(
                      () => draft.expiresAfter = _expiryOptions[i].duration);
                  widget.onChanged();
                },
                itemBuilder: (_) => [
                  for (var i = 0; i < _expiryOptions.length; i++)
                    PopupMenuItem(
                      value: i,
                      child: Row(
                        children: [
                          Expanded(child: Text(_expiryOptions[i].label)),
                          if (_expiryOptions[i].duration ==
                              draft.expiresAfter)
                            Icon(Icons.check,
                                size: 16, color: scheme.primary),
                        ],
                      ),
                    ),
                ],
                // Plain Container (not a button widget): the
                // PopupMenuButton supplies the tap handling, this is
                // purely chrome.
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: plus.surfaceSubtle,
                    borderRadius: BorderRadius.circular(PlusRadii.chip),
                    border: Border.all(color: plus.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 14, color: scheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        selectedExpiry.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_drop_down,
                          size: 18, color: scheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
