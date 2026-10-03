import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:docify/widgets/update_dialog.dart';

/// Wires the prompt to a real BuildContext the way `MainNavScreen` does, and
/// returns the context for the call.
Future<BuildContext> _pumpHost(WidgetTester tester) async {
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (c) {
          context = c;
          return const SizedBox();
        },
      ),
    ),
  );
  return context;
}

void main() {
  testWidgets('without Google Play the check stays silent', (tester) async {
    final context = await _pumpHost(tester);

    await showUpdatePromptIfAny(context);
    await tester.pump();

    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a resume check stays silent when nothing is downloaded',
      (tester) async {
    final context = await _pumpHost(tester);

    await showUpdatePromptIfAny(context, onResume: true);
    await tester.pump();

    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
