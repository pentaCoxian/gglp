import 'package:flutter/material.dart';

import '../../misskey/streaming/stream_messages.dart';
import '../plus/plus.dart';

/// Tiny status dot overlaid on an account avatar: green connected,
/// amber connecting/reconnecting, red failed, gray offline.
class ConnectionDot extends StatelessWidget {
  final ConnectionPhase phase;
  const ConnectionDot({super.key, required this.phase});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final plus = PlusTheme.of(context);
    final color = switch (phase) {
      ConnectionPhase.connected => plus.success,
      ConnectionPhase.connecting ||
      ConnectionPhase.reconnecting =>
        plus.warning,
      ConnectionPhase.failed => scheme.error,
      ConnectionPhase.disconnected => plus.textTertiary,
    };
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: scheme.surface, width: 1.5),
      ),
    );
  }
}
