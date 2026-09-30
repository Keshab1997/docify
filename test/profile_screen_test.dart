import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:docify/screens/legal/legal_doc_screen.dart';
import 'package:docify/screens/profile_screen.dart';
import 'package:docify/services/app_links.dart';

void main() {
  // The profile page was redesigned: "About" is now the "About Docify" tile
  // under Legal & About, which shows the web-version link inline and opens a
  // full About page (no more bottom sheet).
  testWidgets(
      'About Docify shows the web version link and opens the About page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ProfileScreen())),
    );

    // The tile sits far down a long list, so scroll to it first.
    await tester.scrollUntilVisible(find.text('About Docify'), 300);
    // scrollUntilVisible stops as soon as the tile is built, which can still
    // be below the fold of the 800x600 test surface; bring it fully on screen.
    await tester.ensureVisible(find.text('About Docify'));
    await tester.pumpAndSettle();
    expect(find.text(docifyWebPreviewUrl), findsOneWidget);

    await tester.tap(find.text('About Docify'));
    await tester.pumpAndSettle();

    expect(find.byType(LegalDocScreen), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });
}
