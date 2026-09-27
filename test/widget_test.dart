import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobdoc/main.dart';
import 'package:jobdoc/screens/main_nav_screen.dart';

void main() {
  testWidgets('JobDocApp boots into the main navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: JobDocApp()));
    await tester.pump();

    expect(find.byType(MainNavScreen), findsOneWidget);
  });

  testWidgets('All four nav tabs are reachable', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: JobDocApp()));
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
