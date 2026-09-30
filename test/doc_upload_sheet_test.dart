import 'package:docify/services/doc_folders.dart';
import 'package:docify/widgets/doc_upload_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _folders = [for (final b in BuiltInFolder.values) b.folder];

/// Opens the folder sheet the way My documents does and reports what it
/// returned through [done].
Future<void> _open(
  WidgetTester tester,
  void Function(DocFiling?) done, {
  String? name,
  DocFolder? initial,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => done(
            await showDocFolderSheet(
              context,
              title: 'Save file',
              folders: _folders,
              initial: initial,
              name: name,
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

FilledButton _button(WidgetTester tester, String label) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, label));

Future<void> _tapNewFolder(WidgetTester tester) async {
  await tester.ensureVisible(find.text('New folder'));
  await tester.tap(find.text('New folder'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Save waits until a folder is picked', (tester) async {
    DocFiling? result;
    await _open(tester, (r) => result = r, name: 'IMG-0003');
    expect(_button(tester, 'Save').onPressed, isNull);

    await tester.ensureVisible(find.text('ID Proof'));
    await tester.tap(find.text('ID Proof'));
    await tester.pump();
    expect(_button(tester, 'Save').onPressed, isNotNull);

    await tester.enterText(find.byType(TextField), 'Aadhaar Card');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(result?.folder, BuiltInFolder.idProof.folder);
    expect(result?.name, 'Aadhaar Card');
  });

  testWidgets('several files at once get no name field', (tester) async {
    await _open(tester, (_) {});
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('the folder being viewed is picked already', (tester) async {
    await _open(tester, (_) {}, initial: BuiltInFolder.jobForms.folder);
    expect(_button(tester, 'Save').onPressed, isNotNull);
  });

  testWidgets('a new folder can be made from the sheet', (tester) async {
    DocFiling? result;
    await _open(tester, (r) => result = r);

    await _tapNewFolder(tester);
    await tester.enterText(find.byType(TextField), 'WBSSC 2026');
    // enterText doesn't pump, and Create stays off until a frame shows
    // the name.
    await tester.pump();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // Made and picked, so Save works straight away.
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(result?.folder.name, 'WBSSC 2026');
    final saved = await DocFolders.load();
    expect(saved.custom.single.name, 'WBSSC 2026');
  });

  testWidgets('a folder name can only be used once', (tester) async {
    await _open(tester, (_) {});
    await _tapNewFolder(tester);
    await tester.enterText(find.byType(TextField), 'id proof');
    await tester.pump();
    expect(
      find.text('There is already a folder called ID Proof'),
      findsOneWidget,
    );
    expect(_button(tester, 'Create').onPressed, isNull);
  });
}
