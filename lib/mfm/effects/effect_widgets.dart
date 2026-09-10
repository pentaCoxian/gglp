import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'clipped_effect_box.dart';

typedef EffectBuilder = Widget Function({
  required BuildContext context,
  required Map<String, String> args,
  required bool animate,
  required Widget child,
});

/// Resolve a Tier 3 effect name to its builder, or null if unknown.
EffectBuilder? effectBuilderFor(String name) {
  switch (name) {
    case 'shake':
      return _build((c, a, on) => _ShakeEffect(animate: on, child: c));
    case 'jelly':
      return _build((c, a, on) => _JellyEffect(animate: on, child: c));
    case 'tada':
      return _build((c, a, on) => _TadaEffect(animate: on, child: c));
    case 'jump':
      return _build((c, a, on) => _JumpEffect(animate: on, child: c));
    case 'bounce':
      return _build((c, a, on) => _BounceEffect(animate: on, child: c));
    case 'spin':
      return _build((c, a, on) =>
          _SpinEffect(args: a, animate: on, child: c));
    case 'rotate':
      return _build((c, a, on) =>
          _RotateEffect(args: a, animate: on, child: c));
    case 'flip':
      return _build((c, a, on) => _FlipEffect(args: a, child: c));
    case 'blur':
      // BackdropFilter blurs everything inside the nearest ancestor
      // clip — without our own it would blur the whole card.
      return _build((c, a, on) => _BlurEffect(child: c), clip: true);
    default:
      return null;
  }
}

/// Wraps every effect in [ClippedEffectBox] so the child's reported
/// `Size` is unchanged even if the effect overflows visually. Motion
/// effects paint past their box unclipped (see [ClippedEffectBox]);
/// pass [clip] for paint-only filters that need a bound.
EffectBuilder _build(
  Widget Function(Widget child, Map<String, String> args, bool animate) build, {
  bool clip = false,
}) {
  return ({
    required BuildContext context,
    required Map<String, String> args,
    required bool animate,
    required Widget child,
  }) =>
      ClippedEffectBox(clip: clip, child: build(child, args, animate));
}

// ---------- shake ----------

class _ShakeEffect extends StatefulWidget {
  final Widget child;
  final bool animate;
  const _ShakeEffect({required this.animate, required this.child});

  @override
  State<_ShakeEffect> createState() => _ShakeEffectState();
}

class _ShakeEffectState extends State<_ShakeEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.animate) _ctl.repeat();
  }

  @override
  void didUpdateWidget(covariant _ShakeEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_ctl.isAnimating) _ctl.repeat();
    if (!widget.animate && _ctl.isAnimating) _ctl.stop();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      child: widget.child,
      builder: (_, child) {
        final t = _ctl.value * 2 * math.pi;
        final dx = math.sin(t * 4) * 2.0;
        final dy = math.cos(t * 4) * 1.0;
        return Transform.translate(offset: Offset(dx, dy), child: child);
      },
    );
  }
}

// ---------- jelly ----------

class _JellyEffect extends StatefulWidget {
  final Widget child;
  final bool animate;
  const _JellyEffect({required this.animate, required this.child});
  @override
  State<_JellyEffect> createState() => _JellyEffectState();
}

class _JellyEffectState extends State<_JellyEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.animate) _ctl.repeat();
  }

  @override
  void didUpdateWidget(covariant _JellyEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_ctl.isAnimating) _ctl.repeat();
    if (!widget.animate && _ctl.isAnimating) _ctl.stop();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      child: widget.child,
      builder: (_, child) {
        final t = _ctl.value * 2 * math.pi;
        // Squish-stretch about the center.
        final sx = 1.0 + math.sin(t) * 0.18;
        final sy = 1.0 - math.sin(t) * 0.18;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(sx, sy, 1.0),
          child: child,
        );
      },
    );
  }
}

// ---------- tada ----------

class _TadaEffect extends StatefulWidget {
  final Widget child;
  final bool animate;
  const _TadaEffect({required this.animate, required this.child});
  @override
  State<_TadaEffect> createState() => _TadaEffectState();
}

class _TadaEffectState extends State<_TadaEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.animate) _ctl.repeat();
  }

  @override
  void didUpdateWidget(covariant _TadaEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_ctl.isAnimating) _ctl.repeat();
    if (!widget.animate && _ctl.isAnimating) _ctl.stop();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      child: widget.child,
      builder: (_, child) {
        final t = _ctl.value;
        final scale = 1.0 + math.sin(t * math.pi) * 0.12;
        final rot = math.sin(t * math.pi * 4) * 0.10;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scale(scale, scale, 1.0)
            ..rotateZ(rot),
          child: child,
        );
      },
    );
  }
}

// ---------- jump ----------

class _JumpEffect extends StatefulWidget {
  final Widget child;
  final bool animate;
  const _JumpEffect({required this.animate, required this.child});
  @override
  State<_JumpEffect> createState() => _JumpEffectState();
}

class _JumpEffectState extends State<_JumpEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.animate) _ctl.repeat();
  }

  @override
  void didUpdateWidget(covariant _JumpEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_ctl.isAnimating) _ctl.repeat();
    if (!widget.animate && _ctl.isAnimating) _ctl.stop();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      child: widget.child,
      builder: (_, child) {
        // Half-wave sine: child rises and returns each cycle.
        final t = _ctl.value;
        final dy = -math.sin(t * math.pi) * 8.0;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
    );
  }
}

// ---------- bounce ----------

class _BounceEffect extends StatefulWidget {
  final Widget child;
  final bool animate;
  const _BounceEffect({required this.animate, required this.child});
  @override
  State<_BounceEffect> createState() => _BounceEffectState();
}

class _BounceEffectState extends State<_BounceEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.animate) _ctl.repeat();
  }

  @override
  void didUpdateWidget(covariant _BounceEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_ctl.isAnimating) _ctl.repeat();
    if (!widget.animate && _ctl.isAnimating) _ctl.stop();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      child: widget.child,
      builder: (_, child) {
        final t = _ctl.value;
        final dy = -(1.0 - (2 * t - 1) * (2 * t - 1)) * 6.0;
        final sy = 1.0 - dy.abs() / 60.0;
        return Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.identity()
            ..translate(0.0, dy)
            ..scale(1.0, sy.clamp(0.85, 1.0)),
          child: child,
        );
      },
    );
  }
}

// ---------- spin ----------

class _SpinEffect extends StatefulWidget {
  final Widget child;
  final bool animate;
  final Map<String, String> args;
  const _SpinEffect({
    required this.animate,
    required this.args,
    required this.child,
  });

  @override
  State<_SpinEffect> createState() => _SpinEffectState();
}

class _SpinEffectState extends State<_SpinEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    final speedMs = _parseSpeedMs(widget.args['speed']) ?? 1500;
    _ctl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: speedMs),
    );
    if (widget.animate) _ctl.repeat();
  }

  @override
  void didUpdateWidget(covariant _SpinEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_ctl.isAnimating) _ctl.repeat();
    if (!widget.animate && _ctl.isAnimating) _ctl.stop();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final axis = _parseAxis(widget.args);
    final dir = widget.args.containsKey('left') ? -1.0 : 1.0;
    return AnimatedBuilder(
      animation: _ctl,
      child: widget.child,
      builder: (_, child) {
        final theta = _ctl.value * 2 * math.pi * dir;
        final m = Matrix4.identity();
        switch (axis) {
          case 'x':
            m.rotateX(theta);
          case 'y':
            m.rotateY(theta);
          default:
            m.rotateZ(theta);
        }
        return Transform(
          alignment: Alignment.center,
          transform: m,
          child: child,
        );
      },
    );
  }
}

// ---------- rotate ----------

class _RotateEffect extends StatelessWidget {
  final Widget child;
  final bool animate;
  final Map<String, String> args;
  const _RotateEffect({
    required this.animate,
    required this.args,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final degStr = args['deg'];
    final deg = degStr == null ? 90.0 : (double.tryParse(degStr) ?? 90.0);
    return Transform.rotate(
      angle: deg * math.pi / 180.0,
      child: child,
    );
  }
}

// ---------- flip ----------

class _FlipEffect extends StatelessWidget {
  final Widget child;
  final Map<String, String> args;
  const _FlipEffect({required this.args, required this.child});

  @override
  Widget build(BuildContext context) {
    final h = args.containsKey('h') || args.isEmpty;
    final v = args.containsKey('v');
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..scale(h ? -1.0 : 1.0, v ? -1.0 : 1.0, 1.0),
      child: child,
    );
  }
}

// ---------- blur ----------

class _BlurEffect extends StatelessWidget {
  final Widget child;
  const _BlurEffect({required this.child});

  @override
  Widget build(BuildContext context) {
    // Stack the child under a BackdropFilter so the blur reads the
    // child's own pixels. Tappable / selectable text under it still
    // works because the filter only paints.
    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

// ---------- helpers ----------

int? _parseSpeedMs(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  // Accept "500ms", "1.5s", "2".
  if (raw.endsWith('ms')) return int.tryParse(raw.substring(0, raw.length - 2));
  if (raw.endsWith('s')) {
    final v = double.tryParse(raw.substring(0, raw.length - 1));
    return v == null ? null : (v * 1000).round();
  }
  final v = double.tryParse(raw);
  return v == null ? null : (v * 1000).round();
}

String _parseAxis(Map<String, String> args) {
  if (args.containsKey('x')) return 'x';
  if (args.containsKey('y')) return 'y';
  return 'z';
}
