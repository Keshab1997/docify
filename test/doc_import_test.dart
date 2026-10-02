import 'dart:convert';
import 'dart:typed_data';

import 'package:docify/models/import_file.dart';
import 'package:docify/models/saved_doc.dart';
import 'package:docify/services/doc_folders.dart';
import 'package:docify/services/doc_import.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Store extends DocumentImportStore {
  final items = <String, Uint8List>{};
  SavedDoc doc(String name) => SavedDoc(id: name, name: name,
    mime: mimeFromName(name), size: items[name]!.length, modified: DateTime(2026));
  @override
  Future<List<SavedDoc>> list() async => [for (final name in items.keys) doc(name)];
  @override
  Future<Uint8List> read(SavedDoc doc) async => items[doc.id]!;
  @override
  Future<SavedDoc> save(Uint8List bytes, String name) async {
    final unique = uniqueDocumentName(name, items.keys);
    items[unique] = bytes;
    return doc(unique);
  }
}

ImportFile _source(String name, String content) => ImportFile(
  name: name, read: () async => Uint8List.fromList(utf8.encode(content)),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('one failed file does not abort later saves and reports progress', () async {
    final store = _Store();
    final progress = <int>[];
    final result = await DocImport.run(
      files: [_source('a.pdf', '%PDF-a'), _source('bad.pdf', ''), _source('b.pdf', '%PDF-b')],
      folder: BuiltInFolder.certificates.folder, store: store,
      onDuplicate: (_, __) async => DuplicateChoice.skip,
      onProgress: (done, _, __) => progress.add(done),
    );
    expect(result.saved.map((doc) => doc.name), ['a.pdf', 'b.pdf']);
    expect(result.failed, hasLength(1));
    expect(progress.last, 3);
    expect((await DocFolders.load()).filed, {'a.pdf': 'certificates', 'b.pdf': 'certificates'});
  });

  test('duplicate content offers skip or keep both without replacing bytes', () async {
    final store = _Store();
    var choices = 0;
    Future<ImportOutcome> run(DuplicateChoice choice) => DocImport.run(
      files: [_source('same.pdf', '%PDF-same')], folder: BuiltInFolder.others.folder,
      store: store, onProgress: (_, __, ___) {},
      onDuplicate: (_, __) async { choices++; return choice; },
    );
    expect((await run(DuplicateChoice.skip)).saved, hasLength(1));
    expect((await run(DuplicateChoice.skip)).skipped, 1);
    expect((await run(DuplicateChoice.keepBoth)).saved.single.name, 'same (2).pdf');
    expect(choices, 2);
    expect(store.items.keys, ['same.pdf', 'same (2).pdf']);
  });

  test('known oversized sources are rejected without reading them', () async {
    var read = false;
    final result = await DocImport.run(
      files: [ImportFile(name: 'huge.pdf', size: DocImport.maxBytes + 1,
        read: () async { read = true; return Uint8List(0); })],
      folder: BuiltInFolder.others.folder, store: _Store(),
      onDuplicate: (_, __) async => DuplicateChoice.keepBoth,
      onProgress: (_, __, ___) {},
    );
    expect(read, isFalse);
    expect(result.failed.single.reason, contains('30 MB'));
  });
}
