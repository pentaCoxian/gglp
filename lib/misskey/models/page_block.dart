/// In-memory model of a Misskey Page block.
///
/// Misskey ships ~14 block types (text, section, image, note, dynamic,
/// canvas, if, post, button, switch, counter, number, radioButton,
/// textInput, textareaInput). The viewer here covers the four
/// content-only ones (text / section / image / note) and the editor
/// only emits text + section + image. Other types pass through as
/// [PageBlockOther] so an existing page round-trips without losing
/// data we don't render.
sealed class PageBlock {
  const PageBlock();

  /// Round-trip parsing. Unknown / unsupported types fall through to
  /// [PageBlockOther] which captures the raw map so editors can save
  /// without dropping the user's existing blocks.
  factory PageBlock.fromJson(Map<String, dynamic> j) {
    final type = j['type'] as String?;
    switch (type) {
      case 'text':
        return PageBlockText(text: j['text'] as String? ?? '');
      case 'section':
        final title = j['title'] as String? ?? '';
        final children = (j['children'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(PageBlock.fromJson)
            .toList(growable: false);
        return PageBlockSection(title: title, children: children);
      case 'image':
        return PageBlockImage(fileId: j['fileId'] as String?);
      case 'note':
        return PageBlockNote(
          noteId: j['note'] as String? ?? j['noteId'] as String?,
          detailed: j['detailed'] == true,
        );
      default:
        return PageBlockOther(raw: j);
    }
  }

  Map<String, dynamic> toJson();
}

class PageBlockText extends PageBlock {
  final String text;
  const PageBlockText({required this.text});
  @override
  Map<String, dynamic> toJson() => {'type': 'text', 'text': text};
}

class PageBlockSection extends PageBlock {
  final String title;
  final List<PageBlock> children;
  const PageBlockSection({required this.title, required this.children});
  @override
  Map<String, dynamic> toJson() => {
        'type': 'section',
        'title': title,
        'children': children.map((c) => c.toJson()).toList(),
      };
}

class PageBlockImage extends PageBlock {
  final String? fileId;
  const PageBlockImage({this.fileId});
  @override
  Map<String, dynamic> toJson() =>
      {'type': 'image', if (fileId != null) 'fileId': fileId};
}

class PageBlockNote extends PageBlock {
  final String? noteId;
  final bool detailed;
  const PageBlockNote({this.noteId, this.detailed = false});
  @override
  Map<String, dynamic> toJson() => {
        'type': 'note',
        if (noteId != null) 'note': noteId,
        'detailed': detailed,
      };
}

/// Catch-all for block types we don't yet model. Holds the raw JSON
/// so it survives a save round-trip — an editor that encounters one
/// of these renders a generic "unsupported block" placeholder rather
/// than dropping the user's data.
class PageBlockOther extends PageBlock {
  final Map<String, dynamic> raw;
  const PageBlockOther({required this.raw});
  @override
  Map<String, dynamic> toJson() => raw;
}
