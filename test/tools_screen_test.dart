import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:docify/screens/tools_screen.dart';

void main() {
  testWidgets('tools grid lists the core and extra tools', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ToolsScreen()));
    expect(find.text('All tools'), findsOneWidget);
    expect(find.text('Photo Resize'), findsOneWidget);
    await tester.drag(find.byType(GridView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    expect(find.text('Compress PDF'), findsOneWidget);
    expect(find.text('PDF to Images'), findsOneWidget);
  });
}
