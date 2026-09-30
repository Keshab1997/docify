import 'package:docify/services/doc_categories.dart';
import 'package:docify/widgets/doc_upload_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens the category sheet the way My documents does and reports what it
/// returned through [done].
Future<void> _open(
  WidgetTester tester,
  void Function(DocFiling?) done, {
  String? name,
  DocCategory? initial,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => done(
            await showDocCategorySheet(
              context,
              title: 'Save file',
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

FilledButton _save(WidgetTester tester) =>
    tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'));

void main() {
  testWidgets('Save waits until a category is picked', (tester) async {
    DocFiling? result;
    await _open(tester, (r) => result = r, name: 'IMG-0003');
    expect(_save(tester).onPressed, isNull);

    await tester.ensureVisible(find.text('ID Proof'));
    await tester.tap(find.text('ID Proof'));
    await tester.pump();
    expect(_save(tester).onPressed, isNotNull);

    await tester.enterText(find.byType(TextField), 'Aadhaar Card');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(result?.category, DocCategory.idProof);
    expect(result?.name, 'Aadhaar Card');
  });

  testWidgets('several files at once get no name field', (tester) async {
    await _open(tester, (_) {});
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('the category being viewed is picked already', (tester) async {
    await _open(tester, (_) {}, initial: DocCategory.jobForms);
    expect(_save(tester).onPressed, isNotNull);
  });
}
