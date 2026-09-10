import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../mfm/parser.dart';
import '../../mfm/renderer.dart';
import '../../misskey/models/account.dart';
import '../../misskey/models/note_file.dart';
import '../../misskey/models/page_block.dart';
import '../../timeline/note_actions_service.dart';
import '../plus/plus.dart';
import '../widgets/emoji_image.dart';
import '../widgets/mfm_input/mfm_emoji_autocomplete.dart';
import '../widgets/mfm_input/mfm_keyboard_bar.dart';
import '../widgets/mfm_input/mfm_keyboard_shortcuts.dart';
import '../widgets/net_image.dart';
import '../widgets/reactions/reaction_picker_sheet.dart';
import 'page_viewer_screen.dart';

/// Misskey Pages editor.
///
/// Two tabs:
///   - **Edit** — title / slug / summary / eye-catch picker, plus a
///     reorderable list of blocks. Supported block types: text, section
///     (with nested children), image (drive picker), note (by id / URL).
///     Unknown block types round-trip through [PageBlockOther].
///   - **Preview** — renders the in-progress page exactly as the
///     viewer will once saved, using the shared [PageBlockView].
///
/// MFM editing is supported via per-text-block live previews and via
/// the full-page Preview tab.
class PageEditorScreen extends ConsumerStatefulWidget {
  final Account account;

  /// When set, the editor seeds itself from this raw `pages/show`
  /// payload and saves with `pages/update`. Omit for a brand-new
  /// page (saved with `pages/create`).
  final Map<String, dynamic>? existingPageRaw;

  const PageEditorScreen({
    super.key,
    required this.account,
    this.existingPageRaw,
  });

  static Future<void> openNew(
    BuildContext context, {
    required Account account,
  }) =>
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PageEditorScreen(account: account),
      ));

  @override
  ConsumerState<PageEditorScreen> createState() =>
      _PageEditorScreenState();
}

class _PageEditorScreenState extends ConsumerState<PageEditorScreen>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _title;
  late final TextEditingController _slug;
  late final TextEditingController _summary;
  final FocusNode _summaryFocus = FocusNode(debugLabel: 'page-summary');
  late final TabController _tabs;

  /// Mutable block tree. Each [PageBlock] gets a UUID key so the UI
  /// can render `Reorderable` rows without relying on identity.
  final _blocks = <_EditableBlock>[];
  bool _saving = false;
  String? _existingPageId;
  String? _eyeCatchFileId;
  String? _eyeCatchUrl;
  bool _alignCenter = false;
  bool _hideTitleWhenPinned = false;

  @override
  void initState() {
    super.initState();
    final raw = widget.existingPageRaw;
    _title = TextEditingController(text: raw?['title'] as String? ?? '');
    _slug = TextEditingController(
      text: (raw?['name'] as String?) ?? _suggestSlug(),
    );
    _summary =
        TextEditingController(text: raw?['summary'] as String? ?? '');
    _existingPageId = raw?['id'] as String?;
    _alignCenter = raw?['alignCenter'] == true;
    _hideTitleWhenPinned = raw?['hideTitleWhenPinned'] == true;
    final eyecatch = raw?['eyeCatchingImage'];
    if (eyecatch is Map<String, dynamic>) {
      _eyeCatchUrl = eyecatch['url'] as String?;
    }
    _eyeCatchFileId = raw?['eyeCatchingImageId'] as String?;
    if (raw != null) {
      final blocksJson = (raw['content'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      for (final j in blocksJson) {
        _blocks.add(_EditableBlock.from(PageBlock.fromJson(j)));
      }
    } else {
      // Seed with a single empty text block so the user has somewhere
      // to start typing instead of an empty list.
      _blocks.add(_EditableBlock.text(''));
    }
    _tabs = TabController(length: 2, vsync: this);
    // Force a rebuild whenever the user switches tabs so the Preview
    // tab picks up the latest controller text without needing the
    // user to commit() manually.
    _tabs.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    setState(() {});
  }

  @override
  void dispose() {
    _title.dispose();
    _slug.dispose();
    _summary.dispose();
    _summaryFocus.dispose();
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    for (final b in _blocks) {
      b.dispose();
    }
    super.dispose();
  }

  static String _suggestSlug() {
    return 'p-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Wires the MFM toolbar's "emoji" button (and Ctrl/Cmd-J) to the
  /// existing reaction picker for inserting an emoji into the focused
  /// text field. The picker returns either a unicode codepoint or a
  /// `:name:` / `:name@host:` token; either is valid in the page's
  /// MFM body. Inserts at the focused field's caret.
  Future<void> _openEmojiPickerFor({
    required TextEditingController target,
    required FocusNode focus,
  }) async {
    final key = await ReactionPickerSheet.show(
      context,
      account: widget.account,
    );
    if (key == null || !mounted) return;
    final v = target.value;
    final at = v.selection.isValid && v.selection.isCollapsed
        ? v.selection.baseOffset
        : v.text.length;
    target.value = TextEditingValue(
      text: v.text.replaceRange(at, at, key),
      selection: TextSelection.collapsed(offset: at + key.length),
    );
    focus.requestFocus();
  }

  bool get _canSave =>
      !_saving &&
      _title.text.trim().isNotEmpty &&
      _slug.text.trim().isNotEmpty;

  /// Sync every editor controller back into its block before we hand
  /// the block tree to the API or the preview tab.
  void _commitAll() {
    for (final b in _blocks) {
      b.commit();
    }
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    try {
      final endpoints =
          await ref.read(misskeyEndpointsProvider(widget.account).future);
      if (endpoints == null) return;
      _commitAll();
      final content = _blocks
          .map((b) => b.block.toJson())
          .toList(growable: false);
      if (_existingPageId != null) {
        await endpoints.pagesUpdate(
          pageId: _existingPageId!,
          title: _title.text.trim(),
          name: _slug.text.trim(),
          summary: _summary.text.trim().isEmpty
              ? null
              : _summary.text.trim(),
          content: content,
          alignCenter: _alignCenter,
          hideTitleWhenPinned: _hideTitleWhenPinned,
          eyeCatchingImageId: _eyeCatchFileId,
        );
      } else {
        final created = await endpoints.pagesCreate(
          title: _title.text.trim(),
          name: _slug.text.trim(),
          summary: _summary.text.trim().isEmpty
              ? null
              : _summary.text.trim(),
          content: content,
          alignCenter: _alignCenter,
          hideTitleWhenPinned: _hideTitleWhenPinned,
          eyeCatchingImageId: _eyeCatchFileId,
        );
        _existingPageId = created['id'] as String?;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Page saved')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    if (_existingPageId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete page?'),
        content: const Text(
          'This page will be permanently removed from the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          PlusButton.danger(
            onTap: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final endpoints =
          await ref.read(misskeyEndpointsProvider(widget.account).future);
      if (endpoints == null) return;
      await endpoints.pagesDelete(_existingPageId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Page deleted')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  void _addBlock(_EditableBlock block) {
    setState(() => _blocks.add(block));
  }

  void _removeBlock(int i) {
    setState(() {
      final removed = _blocks.removeAt(i);
      removed.dispose();
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      var to = newIndex;
      if (to > oldIndex) to -= 1;
      final item = _blocks.removeAt(oldIndex);
      _blocks.insert(to, item);
    });
  }

  /// Upload an image via `drive/files/create` and return the file ref.
  /// Returns null on cancel / failure (failures already toast).
  Future<NoteFile?> _pickAndUploadImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: false,
      );
      if (result == null || result.files.isEmpty) return null;
      final f = result.files.single;
      final path = f.path;
      if (path == null) return null;
      final actions =
          await ref.read(noteActionsProvider(widget.account).future);
      if (actions == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No client for ${widget.account.host}')),
          );
        }
        return null;
      }
      final bytes = await File(path).readAsBytes();
      return await actions.uploadFile(
        bytes: bytes,
        filename: f.name,
        contentType: _guessMime(f.name),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _addImageBlock() async {
    final file = await _pickAndUploadImage();
    if (file == null) return;
    _addBlock(_EditableBlock.image(file));
  }

  Future<void> _setEyeCatch() async {
    final file = await _pickAndUploadImage();
    if (file == null) return;
    setState(() {
      _eyeCatchFileId = file.id;
      _eyeCatchUrl = file.url;
    });
  }

  void _clearEyeCatch() {
    setState(() {
      _eyeCatchFileId = null;
      _eyeCatchUrl = null;
    });
  }

  /// Prompt for a note id or note URL. Misskey accepts either an
  /// opaque id (`9abc…`) or the canonical `https://host/notes/9abc…`
  /// form on its share links — we normalise to the trailing id.
  Future<void> _addNoteBlock() async {
    final controller = TextEditingController();
    final entered = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Embed a note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Note id or URL',
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          PlusButton.text(
            onTap: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Embed'),
          ),
        ],
      ),
    );
    controller.dispose();
    final id = _extractNoteId(entered);
    if (id == null || id.isEmpty) return;
    _addBlock(_EditableBlock.from(PageBlockNote(noteId: id)));
  }

  static String? _extractNoteId(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.hasScheme && uri.pathSegments.isNotEmpty) {
      // .../notes/<id> — return the last non-empty path segment.
      final segs = uri.pathSegments
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
      if (segs.isNotEmpty) return segs.last;
    }
    return trimmed;
  }

  static String? _guessMime(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_existingPageId == null ? 'New page' : 'Edit page'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.edit_outlined), text: 'Edit'),
            Tab(icon: Icon(Icons.remove_red_eye_outlined), text: 'Preview'),
          ],
        ),
        actions: [
          if (_existingPageId != null)
            IconButton(
              tooltip: 'Delete page',
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _confirmDelete,
            ),
          TextButton(
            onPressed: _canSave ? _save : null,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildEditTab(),
          _buildPreviewTab(),
        ],
      ),
    );
  }

  Widget _buildEditTab() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 80),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          // Plain field: the theme's underline input decoration
          // provides the flat 2014 look.
          child: TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Title',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _slug,
            decoration: InputDecoration(
              labelText: 'URL slug',
              helperText:
                  'https://${widget.account.host}/@${widget.account.username}/pages/${_slug.text.trim()}',
              helperMaxLines: 2,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: MfmKeyboardShortcuts(
            controller: _summary,
            onOpenEmojiPicker: () => _openEmojiPickerFor(
              target: _summary,
              focus: _summaryFocus,
            ),
            child: MfmKeyboardBar(
              controller: _summary,
              focusNode: _summaryFocus,
              account: widget.account,
              dense: true,
              onOpenEmojiPicker: () => _openEmojiPickerFor(
                target: _summary,
                focus: _summaryFocus,
              ),
              child: MfmEmojiAutocomplete(
                account: widget.account,
                controller: _summary,
                focusNode: _summaryFocus,
                child: TextField(
                  controller: _summary,
                  focusNode: _summaryFocus,
                  // Stock field: the global InputDecorationTheme already
                  // renders the soft filled look.
                  decoration: const InputDecoration(
                    labelText: 'Summary (MFM allowed)',
                  ),
                  maxLines: 2,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _EyeCatchPicker(
            url: _eyeCatchUrl,
            onPick: _setEyeCatch,
            onClear: _clearEyeCatch,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TogglePill(
                label: 'Center-aligned',
                selected: _alignCenter,
                onSelected: (v) => setState(() => _alignCenter = v),
              ),
              _TogglePill(
                label: 'Hide title when pinned',
                selected: _hideTitleWhenPinned,
                onSelected: (v) =>
                    setState(() => _hideTitleWhenPinned = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text('Blocks', style: theme.textTheme.titleSmall),
              const Spacer(),
              _AddBlockMenu(
                onAdd: (kind) async {
                  switch (kind) {
                    case _BlockKind.text:
                      _addBlock(_EditableBlock.text(''));
                    case _BlockKind.section:
                      _addBlock(_EditableBlock.section(''));
                    case _BlockKind.image:
                      await _addImageBlock();
                    case _BlockKind.note:
                      await _addNoteBlock();
                  }
                },
              ),
            ],
          ),
        ),
        if (_blocks.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Add a block to start.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          )
        else
          // ReorderableListView.builder needs bounded vertical space; the
          // outer ListView gives it that via shrinkWrap + NeverScrollable.
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _blocks.length,
            onReorder: _onReorder,
            itemBuilder: (_, i) => _BlockEditorCard(
              key: ValueKey(_blocks[i].id),
              index: i,
              block: _blocks[i],
              account: widget.account,
              onRemove: () => _removeBlock(i),
              onPickImage: _pickAndUploadImage,
              onPickNote: _extractNoteId,
            ),
          ),
      ],
    );
  }

  Widget _buildPreviewTab() {
    _commitAll();
    final theme = Theme.of(context);
    final blocks =
        _blocks.map((e) => e.block).toList(growable: false);
    final summary = _summary.text;
    final title = _title.text.trim().isEmpty
        ? '(untitled)'
        : _title.text.trim();
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      children: [
        if (_eyeCatchUrl != null)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: NetImage(
              url: _eyeCatchUrl!,
              fit: BoxFit.cover,
              errorWidget: Container(color: theme.colorScheme.primary),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            textAlign: _alignCenter ? TextAlign.center : TextAlign.start,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (summary.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _MfmInline(
              text: summary,
              viewerHost: widget.account.host,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        const SizedBox(height: 12),
        for (final b in blocks)
          PageBlockView(block: b, viewerAccount: widget.account),
      ],
    );
  }
}

/// In-editor wrapper around [PageBlock]. Holds a TextEditingController
/// for text-typed blocks so reordering doesn't reset the cursor.
///
/// For sections, holds its own list of nested editable blocks rather
/// than re-creating them on every rebuild.
class _EditableBlock {
  final String id;
  PageBlock block;
  TextEditingController? textController;
  /// Created on demand for text-typed blocks. Owned by the wrapper so
  /// the MFM keyboard bar can react to focus changes regardless of
  /// which `_BlockEditorCard` / `_NestedBlockCard` instance is active.
  FocusNode? textFocus;
  TextEditingController? sectionTitleController;
  TextEditingController? noteIdController;
  List<_EditableBlock>? sectionChildren;

  _EditableBlock._(this.id, this.block);

  factory _EditableBlock.text(String t) {
    final eb = _EditableBlock._(const Uuid().v4(), PageBlockText(text: t));
    eb.textController = TextEditingController(text: t);
    eb.textFocus = FocusNode(debugLabel: 'page-text-block');
    return eb;
  }

  factory _EditableBlock.section(String title) {
    final eb = _EditableBlock._(
      const Uuid().v4(),
      PageBlockSection(title: title, children: const []),
    );
    eb.sectionTitleController = TextEditingController(text: title);
    eb.sectionChildren = [];
    return eb;
  }

  factory _EditableBlock.image(NoteFile file) {
    final eb = _EditableBlock._(
      const Uuid().v4(),
      PageBlockImage(fileId: file.id),
    );
    return eb;
  }

  factory _EditableBlock.from(PageBlock block) {
    final id = const Uuid().v4();
    final eb = _EditableBlock._(id, block);
    if (block is PageBlockText) {
      eb.textController = TextEditingController(text: block.text);
      eb.textFocus = FocusNode(debugLabel: 'page-text-block');
    } else if (block is PageBlockSection) {
      eb.sectionTitleController =
          TextEditingController(text: block.title);
      eb.sectionChildren =
          block.children.map(_EditableBlock.from).toList();
    } else if (block is PageBlockNote) {
      eb.noteIdController =
          TextEditingController(text: block.noteId ?? '');
    }
    return eb;
  }

  /// Sync controller text + nested editors back into the block before
  /// save / preview. Recurses into sections.
  void commit() {
    final b = block;
    if (b is PageBlockText && textController != null) {
      block = PageBlockText(text: textController!.text);
    } else if (b is PageBlockSection &&
        sectionTitleController != null &&
        sectionChildren != null) {
      for (final c in sectionChildren!) {
        c.commit();
      }
      block = PageBlockSection(
        title: sectionTitleController!.text,
        children:
            sectionChildren!.map((e) => e.block).toList(growable: false),
      );
    } else if (b is PageBlockNote && noteIdController != null) {
      final id = noteIdController!.text.trim();
      block = PageBlockNote(
        noteId: id.isEmpty ? null : id,
        detailed: b.detailed,
      );
    }
  }

  void dispose() {
    textController?.dispose();
    textFocus?.dispose();
    sectionTitleController?.dispose();
    noteIdController?.dispose();
    if (sectionChildren != null) {
      for (final c in sectionChildren!) {
        c.dispose();
      }
    }
  }
}

enum _BlockKind { text, section, image, note }

class _AddBlockMenu extends StatelessWidget {
  final ValueChanged<_BlockKind> onAdd;
  const _AddBlockMenu({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final plus = PlusTheme.of(context);
    return PopupMenuButton<_BlockKind>(
      tooltip: 'Add block',
      onSelected: onAdd,
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _BlockKind.text,
          child: ListTile(
            leading: Icon(Icons.text_fields),
            title: Text('Text (MFM)'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _BlockKind.section,
          child: ListTile(
            leading: Icon(Icons.title),
            title: Text('Section'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _BlockKind.image,
          child: ListTile(
            leading: Icon(Icons.image_outlined),
            title: Text('Image'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: _BlockKind.note,
          child: ListTile(
            leading: Icon(Icons.sticky_note_2_outlined),
            title: Text('Embedded note'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      // Plain Container chrome; it carries no gesture handling so the
      // PopupMenuButton's own tap target keeps working untouched.
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: plus.surfaceSubtle,
          borderRadius: BorderRadius.circular(PlusRadii.chip),
          border: Border.all(color: plus.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 18, color: scheme.primary),
            const SizedBox(width: 4),
            Text(
              'Add block',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Flat toggle chip replacing the stock FilterChip: subtle-gray rect
/// while off, brand-soft with a brand border while on, with a leading
/// check in the on state.
class _TogglePill extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  const _TogglePill({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plus = PlusTheme.of(context);
    final fg = selected ? plus.brand : plus.textPrimary;
    return PlusChip(
      onTap: () => onSelected(!selected),
      selected: selected,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) ...[
            Icon(Icons.check, size: 14, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EyeCatchPicker extends StatelessWidget {
  final String? url;
  final Future<void> Function() onPick;
  final VoidCallback onClear;
  const _EyeCatchPicker({
    required this.url,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Flat white card — the picker reads as a small banner in the form.
    return PlusCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(PlusRadii.media),
            child: SizedBox(
              width: 96,
              height: 54,
              child: url == null
                  ? Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : NetImage(
                      url: url!,
                      fit: BoxFit.cover,
                      errorWidget: Container(color: theme.colorScheme.error),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Copy + actions share one run when they fit (copy left,
          // actions right); on narrow widths / large text the actions
          // wrap under the copy instead of overflowing the row.
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 4,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Eye-catching image',
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      url == null
                          ? 'Optional cover shown at the top of the page.'
                          : 'Cover image set.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (url != null) ...[
                      PlusIconButton(
                        icon: Icons.close,
                        tooltip: 'Remove cover',
                        size: 18,
                        onTap: onClear,
                      ),
                      const SizedBox(width: 4),
                    ],
                    TextButton(
                      onPressed: onPick,
                      child: Text(url == null ? 'Pick' : 'Replace'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockEditorCard extends StatefulWidget {
  /// Position in the reorderable list; the drag handle must report
  /// the real index or every handle would drag item 0.
  final int index;
  final _EditableBlock block;
  final Account account;
  final VoidCallback onRemove;
  final Future<NoteFile?> Function() onPickImage;
  final String? Function(String?) onPickNote;

  const _BlockEditorCard({
    super.key,
    required this.index,
    required this.block,
    required this.account,
    required this.onRemove,
    required this.onPickImage,
    required this.onPickNote,
  });

  @override
  State<_BlockEditorCard> createState() => _BlockEditorCardState();
}

class _BlockEditorCardState extends State<_BlockEditorCard> {
  bool _showPreview = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eb = widget.block;
    final block = eb.block;
    Widget body;
    String typeLabel;
    if (block is PageBlockText) {
      typeLabel = 'Text';
      body = _TextBlockBody(
        controller: eb.textController!,
        focusNode: eb.textFocus!,
        account: widget.account,
        showPreview: _showPreview,
      );
    } else if (block is PageBlockSection) {
      typeLabel = 'Section';
      body = _SectionBlockBody(
        block: eb,
        account: widget.account,
        onPickImage: widget.onPickImage,
        onPickNote: widget.onPickNote,
      );
    } else if (block is PageBlockImage) {
      typeLabel = 'Image';
      body = _ImageBlockBody(
        block: eb,
        account: widget.account,
        onPickImage: widget.onPickImage,
      );
    } else if (block is PageBlockNote) {
      typeLabel = 'Embedded note';
      body = _NoteBlockBody(
        controller: eb.noteIdController!,
        block: eb,
      );
    } else {
      typeLabel = (block as PageBlockOther).raw['type']?.toString() ??
          'unsupported';
      body = Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Block kept verbatim and will be saved unchanged.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return PlusCard(
      key: widget.key,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ReorderableDragStartListener(
                index: widget.index,
                // Plain flat grab-knob; it carries no gesture handling
                // so the drag listener keeps working untouched.
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.drag_handle,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Unknown block types echo the server's `type` string, so
              // the label must be able to shrink.
              Expanded(
                child: Text(
                  typeLabel.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              if (block is PageBlockText) ...[
                PlusIconButton(
                  icon: _showPreview
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  tooltip:
                      _showPreview ? 'Hide preview' : 'Show preview',
                  size: 18,
                  onTap: () =>
                      setState(() => _showPreview = !_showPreview),
                ),
                const SizedBox(width: 6),
              ],
              PlusIconButton(
                icon: Icons.remove_circle_outline,
                tooltip: 'Remove block',
                size: 18,
                onTap: widget.onRemove,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: body,
          ),
        ],
      ),
    );
  }
}

/// Side-by-side editor / preview for a text block.
class _TextBlockBody extends ConsumerWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final Account account;
  final bool showPreview;

  const _TextBlockBody({
    required this.controller,
    required this.focusNode,
    required this.account,
    required this.showPreview,
  });

  Future<void> _openEmojiPicker(BuildContext context, WidgetRef ref) async {
    final key = await ReactionPickerSheet.show(context, account: account);
    if (key == null) return;
    final v = controller.value;
    final at = v.selection.isValid && v.selection.isCollapsed
        ? v.selection.baseOffset
        : v.text.length;
    controller.value = TextEditingValue(
      text: v.text.replaceRange(at, at, key),
      selection: TextSelection.collapsed(offset: at + key.length),
    );
    focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewerHost = account.host;
    final rawEditor = TextField(
      controller: controller,
      focusNode: focusNode,
      // Stock field: the global InputDecorationTheme renders the soft
      // filled look.
      decoration: const InputDecoration(
        hintText: 'MFM allowed — :emoji:, **bold**, \$[shake …], …',
      ),
      maxLines: null,
      minLines: 4,
      keyboardType: TextInputType.multiline,
    );
    final editor = MfmKeyboardShortcuts(
      controller: controller,
      onOpenEmojiPicker: () => _openEmojiPicker(context, ref),
      child: MfmKeyboardBar(
        controller: controller,
        focusNode: focusNode,
        account: account,
        dense: true,
        onOpenEmojiPicker: () => _openEmojiPicker(context, ref),
        child: MfmEmojiAutocomplete(
          account: account,
          controller: controller,
          focusNode: focusNode,
          child: rawEditor,
        ),
      ),
    );
    if (!showPreview) return editor;
    return LayoutBuilder(
      builder: (_, constraints) {
        final wide = constraints.maxWidth > 560;
        // The inline preview follows the controller directly, so only
        // the preview card rebuilds as the user types.
        final preview = ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, value, __) => _MfmPreviewCard(
            text: value.text,
            viewerHost: viewerHost,
          ),
        );
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: editor),
              const SizedBox(width: 8),
              Expanded(child: preview),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            editor,
            const SizedBox(height: 8),
            preview,
          ],
        );
      },
    );
  }
}

class _SectionBlockBody extends StatefulWidget {
  final _EditableBlock block;
  final Account account;
  final Future<NoteFile?> Function() onPickImage;
  final String? Function(String?) onPickNote;
  const _SectionBlockBody({
    required this.block,
    required this.account,
    required this.onPickImage,
    required this.onPickNote,
  });

  @override
  State<_SectionBlockBody> createState() => _SectionBlockBodyState();
}

class _SectionBlockBodyState extends State<_SectionBlockBody> {
  Future<void> _addNestedImage() async {
    final file = await widget.onPickImage();
    if (file == null) return;
    setState(() =>
        widget.block.sectionChildren!.add(_EditableBlock.image(file)));
  }

  Future<void> _addNestedNote() async {
    final controller = TextEditingController();
    final entered = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Embed a note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Note id or URL',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Embed'),
          ),
        ],
      ),
    );
    controller.dispose();
    final id = widget.onPickNote(entered);
    if (id == null || id.isEmpty) return;
    setState(() => widget.block.sectionChildren!.add(
          _EditableBlock.from(PageBlockNote(noteId: id)),
        ));
  }

  void _removeNested(int i) {
    setState(() {
      final removed = widget.block.sectionChildren!.removeAt(i);
      removed.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = widget.block.sectionChildren!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Plain field: the theme's underline input decoration provides
        // the flat 2014 look.
        TextField(
          controller: widget.block.sectionTitleController,
          decoration: const InputDecoration(
            labelText: 'Section title',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('Nested blocks',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
            const Spacer(),
            _AddBlockMenu(
              onAdd: (kind) async {
                switch (kind) {
                  case _BlockKind.text:
                    setState(() =>
                        children.add(_EditableBlock.text('')));
                  case _BlockKind.section:
                    // Misskey supports nested sections, but we cap nesting
                    // to one level deep — anything more is a UX trap. Add
                    // an empty text block instead.
                    setState(() =>
                        children.add(_EditableBlock.text('')));
                  case _BlockKind.image:
                    await _addNestedImage();
                  case _BlockKind.note:
                    await _addNestedNote();
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (children.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No nested blocks yet.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          for (var i = 0; i < children.length; i++)
            _NestedBlockCard(
              key: ValueKey(children[i].id),
              block: children[i],
              account: widget.account,
              onPickImage: widget.onPickImage,
              onRemove: () => _removeNested(i),
            ),
      ],
    );
  }
}

/// Compact, non-reorderable editor for a section's nested blocks.
/// Sections inside Misskey pages don't reorder children either, so we
/// keep insertion order and offer a remove button per row.
class _NestedBlockCard extends StatelessWidget {
  final _EditableBlock block;
  final Account account;
  final Future<NoteFile?> Function() onPickImage;
  final VoidCallback onRemove;
  const _NestedBlockCard({
    super.key,
    required this.block,
    required this.account,
    required this.onPickImage,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eb = block;
    final pb = eb.block;
    Widget body;
    if (pb is PageBlockText) {
      body = _NestedTextBlockBody(block: eb, account: account);
    } else if (pb is PageBlockImage) {
      body = _ImageBlockBody(
        block: eb,
        account: account,
        onPickImage: onPickImage,
      );
    } else if (pb is PageBlockNote) {
      body = _NoteBlockBody(
        controller: eb.noteIdController!,
        block: eb,
      );
    } else {
      body = Text('${pb.runtimeType}',
          style: theme.textTheme.bodySmall);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: body),
          const SizedBox(width: 6),
          PlusIconButton(
            icon: Icons.remove_circle_outline,
            tooltip: 'Remove nested block',
            size: 18,
            onTap: onRemove,
          ),
        ],
      ),
    );
  }
}

/// Compact MFM-aware editor used inside `_NestedBlockCard` for text-typed
/// nested blocks. Wraps the field in the same shortcuts + autocomplete +
/// keyboard-bar trio as the top-level text block, sized smaller.
class _NestedTextBlockBody extends ConsumerWidget {
  final _EditableBlock block;
  final Account account;
  const _NestedTextBlockBody({required this.block, required this.account});

  Future<void> _openEmojiPicker(BuildContext context) async {
    final key = await ReactionPickerSheet.show(context, account: account);
    if (key == null) return;
    final ctl = block.textController!;
    final v = ctl.value;
    final at = v.selection.isValid && v.selection.isCollapsed
        ? v.selection.baseOffset
        : v.text.length;
    ctl.value = TextEditingValue(
      text: v.text.replaceRange(at, at, key),
      selection: TextSelection.collapsed(offset: at + key.length),
    );
    block.textFocus?.requestFocus();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctl = block.textController!;
    final focus = block.textFocus!;
    return MfmKeyboardShortcuts(
      controller: ctl,
      onOpenEmojiPicker: () => _openEmojiPicker(context),
      child: MfmKeyboardBar(
        controller: ctl,
        focusNode: focus,
        account: account,
        dense: true,
        onOpenEmojiPicker: () => _openEmojiPicker(context),
        child: MfmEmojiAutocomplete(
          account: account,
          controller: ctl,
          focusNode: focus,
          child: TextField(
            controller: ctl,
            focusNode: focus,
            // Stock field: the global InputDecorationTheme renders the
            // soft filled look.
            decoration: const InputDecoration(
              hintText: 'MFM text',
            ),
            maxLines: null,
            minLines: 2,
          ),
        ),
      ),
    );
  }
}

class _ImageBlockBody extends ConsumerStatefulWidget {
  final _EditableBlock block;
  final Account account;
  final Future<NoteFile?> Function() onPickImage;
  const _ImageBlockBody({
    required this.block,
    required this.account,
    required this.onPickImage,
  });

  @override
  ConsumerState<_ImageBlockBody> createState() => _ImageBlockBodyState();
}

class _ImageBlockBodyState extends ConsumerState<_ImageBlockBody> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileId = (widget.block.block as PageBlockImage).fileId;
    Widget thumb;
    if (fileId == null) {
      thumb = Container(
        width: 96,
        height: 54,
        color: theme.colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(Icons.image_outlined,
            color: theme.colorScheme.onSurfaceVariant),
      );
    } else {
      final async =
          ref.watch(pageDriveFileProvider((widget.account, fileId)));
      thumb = SizedBox(
        width: 96,
        height: 54,
        child: async.when(
          loading: () => Container(
            color: theme.colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, __) =>
              Container(color: theme.colorScheme.errorContainer),
          data: (file) => file == null
              ? Container(color: theme.colorScheme.errorContainer)
              : NetImage(
                  url: file.url,
                  fit: BoxFit.cover,
                ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(PlusRadii.media),
            child: thumb,
          ),
          const SizedBox(width: 12),
          // Label + action share one run when they fit (label left,
          // button right); on narrow widths / large text the button
          // wraps under the label instead of overflowing the row.
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 4,
              children: [
                Text(
                  fileId == null
                      ? 'No image picked yet.'
                      : 'Drive file $fileId',
                  style: theme.textTheme.bodySmall,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: Text(fileId == null ? 'Pick' : 'Replace'),
                  onPressed: () async {
                    final f = await widget.onPickImage();
                    if (f == null) return;
                    setState(() {
                      widget.block.block = PageBlockImage(fileId: f.id);
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBlockBody extends StatefulWidget {
  final TextEditingController controller;
  final _EditableBlock block;
  const _NoteBlockBody({
    required this.controller,
    required this.block,
  });

  @override
  State<_NoteBlockBody> createState() => _NoteBlockBodyState();
}

class _NoteBlockBodyState extends State<_NoteBlockBody> {
  @override
  Widget build(BuildContext context) {
    final pb = widget.block.block as PageBlockNote;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plain field: the theme's underline input decoration
          // provides the flat 2014 look.
          TextField(
            controller: widget.controller,
            decoration: const InputDecoration(
              labelText: 'Note id or URL',
            ),
          ),
          Row(
            children: [
              Checkbox(
                value: pb.detailed,
                onChanged: (v) {
                  setState(() {
                    widget.block.block = PageBlockNote(
                      noteId: pb.noteId,
                      detailed: v ?? false,
                    );
                  });
                },
              ),
              const Text('Show in detailed view'),
            ],
          ),
        ],
      ),
    );
  }
}

/// Inline MFM (no chrome) used inside the Preview tab summary line.
class _MfmInline extends ConsumerStatefulWidget {
  final String text;
  final String viewerHost;
  final TextStyle? style;
  const _MfmInline({
    required this.text,
    required this.viewerHost,
    this.style,
  });

  @override
  ConsumerState<_MfmInline> createState() => _MfmInlineState();
}

class _MfmInlineState extends ConsumerState<_MfmInline> {
  /// Owns the tap recognizers the renderer creates; disposed on
  /// rebuild and unmount.
  MfmRenderer? _renderer;

  @override
  void dispose() {
    _renderer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = widget.style;
    final emojiSize =
        ((style ?? theme.textTheme.bodyMedium)?.fontSize ?? 14) * 1.4;
    _renderer?.dispose();
    final renderer = _renderer = MfmRenderer(
      context: context,
      animateEffects: EffectSettings.shouldAnimate(context, ref),
      callbacks: MfmCallbacks(
        resolveEmoji: (raw) => EmojiImage(
          rawName: raw,
          viewerHost: widget.viewerHost,
          size: emojiSize,
        ),
      ),
    );
    if (style == null) return renderer.render(parseMfm(widget.text));
    return DefaultTextStyle.merge(
      style: style,
      child: renderer.render(parseMfm(widget.text)),
    );
  }
}

/// Recessed MFM preview well shown next to (or under) the editor for a
/// single text block. Visually distinct from the full-page preview tab.
class _MfmPreviewCard extends ConsumerStatefulWidget {
  final String text;
  final String viewerHost;
  const _MfmPreviewCard({required this.text, required this.viewerHost});

  @override
  ConsumerState<_MfmPreviewCard> createState() => _MfmPreviewCardState();
}

class _MfmPreviewCardState extends ConsumerState<_MfmPreviewCard> {
  /// Owns the tap recognizers the renderer creates; disposed on
  /// rebuild and unmount.
  MfmRenderer? _renderer;

  @override
  void dispose() {
    _renderer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.text;
    final viewerHost = widget.viewerHost;
    final theme = Theme.of(context);
    final plus = PlusTheme.of(context);
    final emojiSize =
        (theme.textTheme.bodyMedium?.fontSize ?? 14) * 1.4;
    _renderer?.dispose();
    // Flat subtle-gray preview panel set apart from the editor by a
    // 1px border.
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: plus.surfaceSubtle,
        borderRadius: BorderRadius.circular(PlusRadii.card),
        border: Border.all(color: plus.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.remove_red_eye_outlined,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'PREVIEW',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (text.trim().isEmpty)
            Text(
              'Preview will appear here.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            (_renderer = MfmRenderer(
              context: context,
              animateEffects: EffectSettings.shouldAnimate(context, ref),
              callbacks: MfmCallbacks(
                resolveEmoji: (raw) => EmojiImage(
                  rawName: raw,
                  viewerHost: viewerHost,
                  size: emojiSize,
                ),
              ),
            )).render(parseMfm(text)),
        ],
      ),
    );
  }
}
