import 'dart:typed_data';

import 'package:docify/models/doc_meta.dart';
import 'package:docify/models/saved_doc.dart';
import 'package:docify/services/doc_actions.dart';
import 'package:docify/services/doc_index.dart';
import 'package:docify/services/doc_store_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('soft trash keeps bytes and metadata but hides active listings',
      () async {
    final doc = await DocStore.save(
        bytes: Uint8List.fromList([1, 2]), name: 'recoverable.pdf');
    try {
      await DocIndex.starred(doc.id, true);
      await DocIndex.tags(doc.id, ['certificate']);
      await DocIndex.update(doc.id, (meta) => meta.copyWith(trashedAt: 123));
      expect((await DocStore.list()).map((d) => d.id), isNot(contains(doc.id)));
      expect((await DocStore.list(includeTrash: true)).map((d) => d.id),
          contains(doc.id));
      expect(await DocStore.read(doc), [1, 2]);
      await DocIndex.update(doc.id, (meta) => meta.copyWith(restore: true));
      expect((await DocStore.list()).map((d) => d.id), contains(doc.id));
      expect((await DocIndex.load())[doc.id]!.starred, isTrue);
      expect((await DocIndex.load())[doc.id]!.tags, ['certificate']);
    } finally {
      await DocStore.delete(doc);
    }
  });

  test('retention is 30 days and an active document cannot expire', () {
    final deleted = DateTime(2026, 1, 1);
    final meta = DocMeta(trashedAt: deleted.millisecondsSinceEpoch);
    expect(DocActions.expired(meta, deleted.add(const Duration(days: 29))),
        isFalse);
    expect(DocActions.expired(meta, deleted.add(const Duration(days: 30))),
        isTrue);
    expect(DocActions.expired(const DocMeta(), deleted), isFalse);
  });

  test('readable conflict names are case insensitive', () {
    expect(
        uniqueDocumentName('ID.pdf', ['id.pdf', 'id (2).pdf']), 'ID (3).pdf');
    expect(uniqueDocumentName('photo.jpg', []), 'photo.jpg');
  });
}
