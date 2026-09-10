import 'package:flutter/material.dart';

import 'net_image.dart';

/// Flat circular avatar that fetches [url] via [NetImage],
/// with a deterministic letter fallback while loading or on failure.
///
/// `seed` is the string from which the fallback letter is drawn (the
/// caller's display name or username — whichever is preferred when the
/// image hasn't arrived yet).
class UserAvatar extends StatelessWidget {
  final String? url;
  final String seed;
  final double radius;

  const UserAvatar({
    super.key,
    required this.url,
    required this.seed,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = _letterAvatar(context);
    final u = url;
    if (u == null || u.isEmpty) return fallback;
    return ClipOval(
      child: NetImage(
        url: u,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: fallback,
        errorWidget: fallback,
      ),
    );
  }

  Widget _letterAvatar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final letter = seed.characters.firstOrNull?.toUpperCase() ?? '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.secondaryContainer,
      foregroundColor: scheme.onSecondaryContainer,
      child: Text(letter),
    );
  }
}
