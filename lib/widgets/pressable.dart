import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/motion.dart';

/// Adds a press-in scale and a light haptic tick to any tap target.
///
/// It listens with a [Listener] instead of a [GestureDetector] on purpose: a
/// [Listener] never joins the gesture arena, so an inner [InkWell] keeps its
/// ripple and still receives the tap. Pass [onTap] only for tiles that have no
/// inner gesture handler of their own, otherwise the tap fires twice.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _setDown(bool value) {
    if (_down == value) return;
    setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = AnimatedScale(
      scale: _down ? widget.scale : 1,
      duration: Motion.of(context, Motion.micro),
      curve: Motion.enter,
      child: widget.child,
    );
    final onTap = widget.onTap;
    if (onTap != null) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      );
    }
    return Listener(
      onPointerDown: (_) {
        _setDown(true);
        if (widget.haptic) HapticFeedback.selectionClick();
      },
      onPointerUp: (_) => _setDown(false),
      onPointerCancel: (_) => _setDown(false),
      child: child,
    );
  }
}
