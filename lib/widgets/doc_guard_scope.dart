import 'package:flutter/material.dart';

/// Captures the document lock for nested previews and tool routes. A newly
/// pushed route has a different context, so capture this before navigating.
class DocGuardScope extends InheritedWidget {
  const DocGuardScope({super.key, required this.guard, required super.child});

  final Widget Function(Widget) guard;

  static Widget Function(Widget)? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DocGuardScope>()?.guard;

  static Widget protect(BuildContext context, Widget child) =>
      maybeOf(context)?.call(child) ?? child;

  @override
  bool updateShouldNotify(DocGuardScope oldWidget) => guard != oldWidget.guard;
}
