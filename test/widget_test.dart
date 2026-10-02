import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:docify/main.dart';
import 'package:docify/screens/main_nav_screen.dart';

void main() {
  testWidgets('DocifyApp boots into the main navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: DocifyApp(showOnboarding: false)),
    );
    await tester.pump();

    expect(find.byType(MainNavScreen), findsOneWidget);
  });

  testWidgets('All four nav tabs are reachable', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: DocifyApp(showOnboarding: false)),
    );
    await tester.pump();

    for (final label in ['Home', 'Tools', 'Documents', 'Profile']) {
      expect(
        find.text(label),
        findsOneWidget,
        reason: 'missing nav tab $label',
      );
    }
  });

  testWidgets('Back on another tab returns to Home before the app closes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: DocifyApp(showOnboarding: false)),
    );
    await tester.pump();

    final tabs = find.byType(IndexedStack).first;
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(tester.widget<IndexedStack>(tabs).index, 0);

    for (final label in ['Tools', 'Profile']) {
      await tester.tap(find.text(label));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.widget<IndexedStack>(tabs).index, isNot(0));

      // The app takes this Back press and steps to Home...
      expect(await navigator.maybePop(), isTrue);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.widget<IndexedStack>(tabs).index, 0);
    }

    // ...while on Home it is left to the system, which closes the app.
    expect(await navigator.maybePop(), isFalse);
  });
}
