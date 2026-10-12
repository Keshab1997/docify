import 'package:docify/widgets/launch_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder get _titleOpacity => find.descendant(
      of: find.byType(LaunchSplash),
      matching: find.byType(Opacity),
    );

void main() {
  testWidgets('launch uses the native backdrop, a vector mark and wordmark', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(const MaterialApp(home: LaunchSplash()));

    expect(find.text('Docify'), findsOneWidget);
    expect(find.bySemanticsLabel('Docify is opening'), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      const Color(0xFFEAF2FF),
    );
    expect(find.byType(Image), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    semantics.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('wordmark fades/rises once, then stops all launch tickers', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LaunchSplash()));
    expect(tester.widget<Opacity>(_titleOpacity).opacity, closeTo(0.35, 0.001));

    await tester.pump(const Duration(milliseconds: 160));
    expect(tester.widget<Opacity>(_titleOpacity).opacity, greaterThan(0.35));
    expect(tester.widget<Opacity>(_titleOpacity).opacity, lessThan(1));

    await tester.pump(const Duration(milliseconds: 220));
    expect(tester.widget<Opacity>(_titleOpacity).opacity, 1);
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reduced motion shows the finished mark on the very first frame',
      (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: LaunchSplash(),
        ),
      ),
    );

    expect(tester.widget<Opacity>(_titleOpacity).opacity, 1);
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('small screens and enlarged text cannot clip the wordmark', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(220, 320);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(3),
            disableAnimations: true,
          ),
          child: LaunchSplash(),
        ),
      ),
    );

    expect(tester.widget<Text>(find.text('Docify')).textScaler,
        TextScaler.noScaling);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('disposing mid-animation leaves no ticker behind',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LaunchSplash()));
    await tester.pump(const Duration(milliseconds: 90));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));

    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });
}
