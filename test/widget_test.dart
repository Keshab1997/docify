import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:docify/main.dart';
import 'package:docify/screens/main_nav_screen.dart';

void main() {
  testWidgets('DocifyApp boots into the main navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: DocifyApp()));
    await tester.pump();

    expect(find.byType(MainNavScreen), findsOneWidget);
  });

  testWidgets('All four nav tabs are reachable', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: DocifyApp()));
    await tester.pump();

    for (final label in ['Home', 'Tools', 'Documents', 'Profile']) {
      expect(
        find.text(label),
        findsOneWidget,
        reason: 'missing nav tab $label',
      );
    }
  });
}
