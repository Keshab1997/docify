import 'package:flutter/material.dart';

import '../theme/motion.dart';

/// Fades and lifts [child] into place exactly once.
///
/// [index] staggers the reveal for lists and grids: item *n* waits
/// `index * stagger` before it starts, so a grid fills in instead of popping
/// in all at once. The whole stagger runs on one controller with an [Interval]
/// curve, which means no timers are left pending - important for
/// `pumpAndSettle` in widget tests.
class AnimatedReveal extends StatefulWidget {
  const AnimatedReveal({
    super.key,
    required this.child,
    this.index = 0,
    this.stagger = Motion.stagger,
    this.duration = Motion.medium,
    this.offset = const Offset(0, 0.06),
  });

  final Widget child;
  final int index;
  final Duration stagger;
  final Duration duration;
  final Offset offset;

  @override
  State<AnimatedReveal> createState() => _AnimatedRevealState();
}

class _AnimatedRevealState extends State<AnimatedReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration + widget.stagger * widget.index,
    );
    final total = _controller.duration!.inMilliseconds;
    final delay = (widget.stagger * widget.index).inMilliseconds;
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(total == 0 ? 0 : delay / total, 1, curve: Motion.enter),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Opacity(
        opacity: _animation.value,
        child: Transform.translate(
          offset: widget.offset * (1 - _animation.value),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
