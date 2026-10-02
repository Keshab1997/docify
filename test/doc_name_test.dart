import 'dart:typed_data';

import 'package:docify/models/saved_doc.dart';
import 'package:docify/services/doc_store_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  group('document names', () {
    test('rejects blank, unsafe, overlong and duplicate names', () {
      const names = ['photo.jpg', 'ID.pdf'];
      expect(documentNameError('photo.jpg', '', names, except: 'photo.jpg'),
          isNotNull);
      expect(documentNameError('photo.jpg', '../photo', names), isNotNull);
      expect(documentNameError('photo.jpg', 'x' * 241, names), isNotNull);
      expect(documentNameError('new.pdf', 'id', names), isNotNull);
      expect(
          documentNameError('photo.jpg', 'Photo', names, except: 'photo.jpg'),
          isNull);
    });

    test('extension and readable size labels are preserved', () {
      expect(renameKeepingExtension('certificate.pdf', 'Degree'), 'Degree.pdf');
      expect(fileSizeLabel(12), '12 B');
      expect(fileSizeLabel(2048), '2.0 KB');
      expect(fileSizeLabel(2 * 1024 * 1024), '2.0 MB');
    });
  });

  test('store rename keeps bytes and refuses to replace a sibling', () async {
    final a =
        await DocStore.save(bytes: Uint8List.fromList([1]), name: 'name-a.pdf');
    final b =
        await DocStore.save(bytes: Uint8List.fromList([2]), name: 'name-b.pdf');
    try {
      await expectLater(DocStore.rename(a, 'name-b'), throwsStateError);
      expect(await DocStore.read(b), [2]);
      final renamed = await DocStore.rename(a, 'name-c');
      expect(renamed.name, 'name-c.pdf');
      expect(renamed.mime, 'application/pdf');
      expect(await DocStore.read(renamed), [1]);
      await DocStore.delete(renamed);
    } finally {
      await DocStore.delete(a);
      await DocStore.delete(b);
    }
  });
}
