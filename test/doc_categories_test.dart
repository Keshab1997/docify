import 'package:docify/models/saved_doc.dart';
import 'package:docify/services/doc_categories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

SavedDoc _doc(String name) => SavedDoc(
      id: name,
      name: name,
      mime: mimeFromName(name),
      size: 1,
      modified: DateTime(2026),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('DocCategories', () {
    test('a filed document keeps its category', () async {
      await DocCategories.file(['aadhaar.pdf', 'pan.jpg'], DocCategory.idProof);
      expect(await DocCategories.load(), {
        'aadhaar.pdf': DocCategory.idProof,
        'pan.jpg': DocCategory.idProof,
      });
    });

    test('unfiled photos go to Photo & Signature, the rest to Others', () {
      expect(DocCategories.of(_doc('photo.jpg'), {}), DocCategory.photoSign);
      expect(DocCategories.of(_doc('form.pdf'), {}), DocCategory.others);
      expect(
        DocCategories.of(_doc('form.pdf'), {'form.pdf': DocCategory.jobForms}),
        DocCategory.jobForms,
      );
    });

    test('renaming keeps the category', () async {
      await DocCategories.file(['IMG-0003.jpg'], DocCategory.certificates);
      await DocCategories.move('IMG-0003.jpg', 'Marksheet.jpg');
      expect(await DocCategories.load(), {
        'Marksheet.jpg': DocCategory.certificates,
      });
    });

    test('deleting forgets the category', () async {
      await DocCategories.file(['a.pdf', 'b.pdf'], DocCategory.jobForms);
      await DocCategories.forget('a.pdf');
      expect(await DocCategories.load(), {'b.pdf': DocCategory.jobForms});
    });

    test('a damaged store counts as empty', () async {
      SharedPreferences.setMockInitialValues({'doc_categories': 'not json'});
      expect(await DocCategories.load(), isEmpty);
    });

    test('unknown category names are skipped', () async {
      SharedPreferences.setMockInitialValues({
        'doc_categories': '{"a.pdf": "spaceship", "b.pdf": "idProof"}',
      });
      expect(await DocCategories.load(), {'b.pdf': DocCategory.idProof});
    });
  });

  group('file names', () {
    test('a new name keeps the extension of the file', () {
      expect(
        renameKeepingExtension('IMG-0003.jpg', 'Aadhaar Card'),
        'Aadhaar Card.jpg',
      );
    });

    test('a blank name keeps the original', () {
      expect(renameKeepingExtension('form.pdf', '  '), 'form.pdf');
    });

    test('an extension the user typed is not doubled', () {
      expect(
        renameKeepingExtension('form.PDF', 'Admit card.pdf'),
        'Admit card.pdf',
      );
    });

    test('a slash cannot turn into a folder', () {
      expect(renameKeepingExtension('a.pdf', 'WBSSC/2026'), 'WBSSC-2026.pdf');
    });

    test('nameStem drops only the extension', () {
      expect(nameStem('IMG-0003.jpg'), 'IMG-0003');
      expect(nameStem('Admit.card.pdf'), 'Admit.card');
      expect(nameStem('README'), 'README');
    });
  });
}
