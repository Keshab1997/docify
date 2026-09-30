import 'package:docify/models/saved_doc.dart';
import 'package:docify/services/doc_folders.dart';
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

  group('DocFolders', () {
    test('built-in folders come first, then the rest A to Z', () async {
      await DocFolders.create('WBSSC 2026');
      await DocFolders.create('Railway Form');
      final library = await DocFolders.load();
      final names = [for (final f in library.folders) f.name];
      expect(names, [
        'Job Forms',
        'Certificates',
        'ID Proof',
        'Photo & Signature',
        'Others',
        'Railway Form',
        'WBSSC 2026',
      ]);
    });

    test('a filed document stays in its folder', () async {
      final wbssc = await DocFolders.create('WBSSC 2026');
      await DocFolders.file(['admit.pdf'], wbssc);
      await DocFolders.file(['aadhaar.jpg'], BuiltInFolder.idProof.folder);
      final library = await DocFolders.load();
      expect(library.folderOf(_doc('admit.pdf')).name, 'WBSSC 2026');
      expect(library.folderOf(_doc('aadhaar.jpg')).name, 'ID Proof');
    });

    test('files filed as categories before folders stay put', () async {
      SharedPreferences.setMockInitialValues({
        'doc_categories': '{"pan.pdf": "idProof"}',
      });
      final library = await DocFolders.load();
      expect(library.folderOf(_doc('pan.pdf')), BuiltInFolder.idProof.folder);
    });

    test('unfiled photos go to Photo & Signature, the rest to Others', () {
      const library = DocLibrary();
      expect(library.folderOf(_doc('photo.jpg')).name, 'Photo & Signature');
      expect(library.folderOf(_doc('form.pdf')).name, 'Others');
    });

    test('a file whose folder is gone goes by type', () {
      const library = DocLibrary(filed: {'photo.jpg': 'f123'});
      expect(library.folderOf(_doc('photo.jpg')).name, 'Photo & Signature');
    });

    test('a renamed folder keeps its files', () async {
      final folder = await DocFolders.create('WBSSC');
      await DocFolders.file(['admit.pdf'], folder);
      await DocFolders.rename(folder.id, 'WBSSC 2026');
      final library = await DocFolders.load();
      expect(library.folderOf(_doc('admit.pdf')).name, 'WBSSC 2026');
    });

    test('deleting a folder moves its files to Others', () async {
      final folder = await DocFolders.create('Old exam');
      await DocFolders.file(['photo.jpg'], folder);
      await DocFolders.remove(folder.id);
      final library = await DocFolders.load();
      expect(library.custom, isEmpty);
      // Others, even for a photo that would otherwise go by type.
      expect(library.folderOf(_doc('photo.jpg')).name, 'Others');
    });

    test('renaming a file keeps its folder', () async {
      await DocFolders.file(
        ['IMG-0003.jpg'],
        BuiltInFolder.certificates.folder,
      );
      await DocFolders.move('IMG-0003.jpg', 'Marksheet.jpg');
      final library = await DocFolders.load();
      expect(library.filed, {'Marksheet.jpg': 'certificates'});
    });

    test('deleting a file forgets its folder', () async {
      await DocFolders.file(['a.pdf', 'b.pdf'], BuiltInFolder.jobForms.folder);
      await DocFolders.forget('a.pdf');
      expect((await DocFolders.load()).filed, {'b.pdf': 'jobForms'});
    });

    test('a damaged store counts as empty', () async {
      SharedPreferences.setMockInitialValues({
        'doc_folders': 'not json',
        'doc_categories': '[1, 2]',
      });
      final library = await DocFolders.load();
      expect(library.custom, isEmpty);
      expect(library.filed, isEmpty);
    });
  });

  group('folder names', () {
    final folders = [
      for (final b in BuiltInFolder.values) b.folder,
      const DocFolder(id: 'f1', name: 'WBSSC 2026'),
    ];

    test('need some text', () {
      expect(folderNameError('   ', folders), 'Enter a folder name');
    });

    test('are used once, whatever the case', () {
      expect(
        folderNameError('id proof', folders),
        'There is already a folder called ID Proof',
      );
      expect(folderNameError(' wbssc 2026 ', folders), isNotNull);
      expect(folderNameError('Railway Form', folders), isNull);
    });

    test('have a length limit', () {
      expect(folderNameError('x' * 41, folders), isNotNull);
      expect(folderNameError('x' * 40, folders), isNull);
    });

    test('a renamed folder may keep its own name', () {
      expect(folderNameError('WBSSC 2026', folders, except: 'f1'), isNull);
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
