import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:docify/screens/profile_screen.dart';
import 'package:docify/services/app_links.dart';

void main() {
  testWidgets('About opens a sheet with the web version link', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ProfileScreen())),
    );

    await tester.tap(find.text('About'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Open the web version'), findsOneWidget);
    expect(find.text(docifyWebPreviewUrl), findsOneWidget);
  });
}
