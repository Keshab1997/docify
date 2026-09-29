import 'package:flutter/material.dart';

import '../../../../theme/motion.dart';

/// Fades and lifts a CV section when the user changes tabs.
///
/// A plain [IndexedStack] underneath keeps every section mounted, so the forms
/// keep their text and scroll position - this only animates how the change
/// looks. Replays once per [index] change and stays still for users who asked
/// for reduced motion.
class CvSectionFade extends StatefulWidget {
  const CvSectionFade({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<CvSectionFade> createState() => _CvSectionFadeState();
}

class _CvSectionFadeState extends State<CvSectionFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      value: 1,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Motion.enter);
  }

  @override
  void didUpdateWidget(CvSectionFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.015),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      ),
    );
  }
}
