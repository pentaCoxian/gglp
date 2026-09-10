import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mfm/ast.dart';
import '../../mfm/parser.dart';
import '../../mfm/renderer.dart';
import 'emoji_image.dart';

/// Inline display-name renderer.
///
/// Misskey allows custom emoji in user.name (e.g. `*Cat* :wave_anim:`),
/// so we cannot just `Text(name)`. We run the same MFM parser used for
/// notes, but at render time we keep the result on a single line: the
/// renderer's column layout is fine — for typical names it's one
/// inline run anyway, and overflow is clipped by the parent.
///
/// `viewerHost` is the host the name was *received from* (`Note.sourceHost`
/// for note authors, `Account.host` for the active account); the emoji
/// resolver scopes lookups to that host.
///
/// Stateful because [MfmRenderer] owns gesture recognizers that must be
/// disposed: one renderer per build, the previous one released on
/// rebuild and the last one in [State.dispose].
class UserDisplayName extends ConsumerStatefulWidget {
  final String name;
  final String viewerHost;
  final TextStyle? style;
  final TextOverflow overflow;
  final int? maxLines;

  const UserDisplayName({
    super.key,
    required this.name,
    required this.viewerHost,
    this.style,
    this.overflow = TextOverflow.ellipsis,
    this.maxLines = 1,
  });

  @override
  ConsumerState<UserDisplayName> createState() => _UserDisplayNameState();

  /// Cheap pre-check: skip MFM parsing for names that obviously have
  /// no markup. Saves an allocation per name on the common case.
  static bool _hasMfm(String s) =>
      s.contains(':') || s.contains('*') || s.contains(r'$[') || s.contains('<');
}

class _UserDisplayNameState extends ConsumerState<UserDisplayName> {
  /// Renderer for the current build; its tap recognizers belong to the
  /// spans of that build only, so it is replaced (and the old one
  /// disposed) every time we rebuild.
  MfmRenderer? _renderer;

  /// Parsed AST cached by source, so a rebuild for a theme change,
  /// animation setting or catalog tick doesn't re-parse the same name.
  List<MfmNode>? _parsed;
  String? _parsedFor;

  @override
  void dispose() {
    _renderer?.dispose();
    _renderer = null;
    super.dispose();
  }

  List<MfmNode> _ast(String name) {
    if (_parsed == null || _parsedFor != name) {
      _parsed = parseMfm(name);
      _parsedFor = name;
    }
    return _parsed!;
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.name;
    final theme = Theme.of(context);
    final effectiveStyle = widget.style ?? theme.textTheme.titleSmall;
    if (!UserDisplayName._hasMfm(name)) {
      // Plain name: nothing for a renderer to own.
      _renderer?.dispose();
      _renderer = null;
      return Text(
        name,
        style: effectiveStyle,
        overflow: widget.overflow,
        maxLines: widget.maxLines,
      );
    }
    final size = (effectiveStyle?.fontSize ?? 14) * 1.4;
    _renderer?.dispose();
    final renderer = _renderer = MfmRenderer(
      context: context,
      animateEffects: EffectSettings.shouldAnimate(context, ref),
      callbacks: MfmCallbacks(
        resolveEmoji: (rawName) => EmojiImage(
          rawName: rawName,
          viewerHost: widget.viewerHost,
          size: size,
        ),
      ),
    );
    return DefaultTextStyle.merge(
      style: effectiveStyle,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      child: renderer.render(_ast(name)),
    );
  }
}
