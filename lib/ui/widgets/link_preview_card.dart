import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../misskey/models/account.dart';
import '../plus/plus.dart';
import 'net_image.dart';

/// Compact link-preview card fed by the server's summaly proxy
/// (`GET /url?url=...` via `MisskeyEndpoints.urlPreview`).
///
/// Previews are progressive enhancement: while loading, on failure, or
/// when the server has no data we render nothing ([SizedBox.shrink])
/// — never a spinner. Results (including failures, stored as null) are
/// memoized in a static in-memory cache keyed `<host>|<url>` so the
/// same URL is never refetched across cards.
class LinkPreviewCard extends ConsumerStatefulWidget {
  final String url;
  final Account account;

  const LinkPreviewCard({
    super.key,
    required this.url,
    required this.account,
  });

  @override
  ConsumerState<LinkPreviewCard> createState() => _LinkPreviewCardState();
}

class _LinkPreviewCardState extends ConsumerState<LinkPreviewCard> {
  /// `<host>|<url>` -> summaly JSON (null = fetched and failed / no
  /// data; cached too, so a bad URL doesn't retry-storm the server).
  /// Insertion-ordered and capped at [_maxCacheEntries] with FIFO
  /// eviction, so a long scrolling session can't grow it unbounded.
  static final Map<String, Map<String, dynamic>?> _cache = {};
  static const _maxCacheEntries = 200;

  Map<String, dynamic>? _data;
  bool _resolved = false;

  String get _cacheKey => '${widget.account.host}|${widget.url}';

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(LinkPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.account.host != widget.account.host) {
      _resolved = false;
      _data = null;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final key = _cacheKey;
    if (_cache.containsKey(key)) {
      // Reached synchronously from initState / didUpdateWidget, both
      // of which are followed by a build — no setState needed.
      _data = _cache[key];
      _resolved = true;
      return;
    }
    Map<String, dynamic>? raw;
    try {
      final endpoints =
          await ref.read(misskeyEndpointsProvider(widget.account).future);
      raw = await endpoints?.urlPreview(widget.url);
    } catch (_) {
      raw = null;
    }
    if (!_cache.containsKey(key) && _cache.length >= _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = raw;
    if (!mounted) return;
    setState(() {
      _data = raw;
      _resolved = true;
    });
  }

  Future<void> _open() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final raw = _data;
    if (!_resolved || raw == null) return const SizedBox.shrink();

    // summaly responses vary by server — guard every field.
    final title = raw['title'] as String?;
    final description = raw['description'] as String?;
    final thumbnail = raw['thumbnail'] as String?;
    final sitename = raw['sitename'] as String?;
    final icon = raw['icon'] as String?;
    if ((title == null || title.isEmpty) &&
        (description == null || description.isEmpty) &&
        (sitename == null || sitename.isEmpty)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final plus = PlusTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _open,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: plus.surfaceSubtle,
            borderRadius: BorderRadius.circular(PlusRadii.card),
            border: Border.all(color: plus.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (thumbnail != null && thumbnail.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(PlusRadii.media),
                  child: NetImage(
                    url: thumbnail,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorWidget: const SizedBox(
                      width: 72,
                      height: 72,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null && title.isNotEmpty)
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (sitename != null && sitename.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (icon != null && icon.isNotEmpty) ...[
                            NetImage(
                              url: icon,
                              width: 12,
                              height: 12,
                              fit: BoxFit.contain,
                              errorWidget:
                                  const SizedBox(width: 12, height: 12),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              sitename,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
