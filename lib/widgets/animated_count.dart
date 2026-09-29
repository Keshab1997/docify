import 'package:flutter/material.dart';

import '../theme/motion.dart';

/// Counts up to [value] instead of showing it at once.
///
/// Used for the numbers a user actually cares about after a job finishes -
/// "92.4 KB", "12 pages", "73% smaller" - so the result feels measured rather
/// than pasted in.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount(
    this.value, {
    super.key,
    this.decimals = 0,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.duration = Motion.long,
  });

  final double value;
  final int decimals;
  final String prefix;
  final String suffix;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final text = style ?? const TextStyle(fontWeight: FontWeight.w800);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: Motion.of(context, duration),
      curve: Motion.enter,
      builder: (context, v, _) =>
          Text('$prefix${v.toStringAsFixed(decimals)}$suffix', style: text),
    );
  }
}
