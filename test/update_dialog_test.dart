import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:docify/widgets/update_dialog.dart';

/// The channel the in_app_update plugin talks on. "No Google Play" — a test
/// run, the web build, a sideloaded APK — means this channel has no answer.
const MethodChannel _playChannel =
    MethodChannel('de.ffuf.in_app_update/methods');

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
  // Without Google Play the plugin channel has no answer. An *unmocked*
  // channel in a widget test never answers at all, which made these tests
  // hang until the 10-minute timeout (and CI along with them). Mocking the
  // channel to throw is what "no Play" means here; the app degrades to
  // silence either way.
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_playChannel, (call) async {
      throw MissingPluginException('no Google Play in tests');
    });
  });

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
