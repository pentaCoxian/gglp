import 'package:flutter/material.dart';

/// Thin blue indeterminate line for under-app-bar loading: never
/// replace a populated feed with a large centered spinner.
class PlusLinearProgress extends StatelessWidget {
  final bool visible;

  const PlusLinearProgress({super.key, this.visible = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: visible ? const LinearProgressIndicator() : null,
    );
  }
}
