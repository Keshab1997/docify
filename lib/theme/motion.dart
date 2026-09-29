import 'package:flutter/material.dart';

/// Shared motion tokens for JobDoc.
///
/// Every duration and curve in the app comes from here so the twelve tools
/// feel like one product instead of twelve. [Motion.of] also switches
/// animations off when the device asks for reduced motion (Android "Remove
/// animations", iOS Reduce Motion); widget tests benefit from the same switch.
class Motion {
  const Motion._();

  /// Press, chip select, ripple-level feedback.
  static const Duration micro = Duration(milliseconds: 120);

  /// Tab, toggle, small state change.
  static const Duration short = Duration(milliseconds: 200);

  /// Overlay entrance, card reveal, list item.
  static const Duration medium = Duration(milliseconds: 360);

  /// Counter, hero, big reveal.
  static const Duration long = Duration(milliseconds: 640);

  /// Staged processing flows (read, work, save).
  static const Duration staged = Duration(milliseconds: 1600);

  /// Extra delay per item in a staggered list or grid.
  static const Duration stagger = Duration(milliseconds: 28);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve pop = Curves.easeOutBack;
  static const Curve move = Curves.easeInOutCubic;

  /// Returns [duration], or [Duration.zero] when the user asked for less
  /// motion, so the same widget works for everyone.
  static Duration of(BuildContext context, Duration duration) {
    return MediaQuery.of(context).disableAnimations ? Duration.zero : duration;
  }
}
