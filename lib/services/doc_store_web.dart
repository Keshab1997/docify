import 'dart:typed_data';

import '../models/doc_meta.dart';
import '../models/saved_doc.dart';
import 'doc_index.dart';
import 'doc_write_queue.dart';

class _Mem {
  _Mem(this.doc, this.bytes);
  SavedDoc doc;
  Uint8List bytes;
}

/// Browser preview adapter. Bytes are intentionally in memory, not advertised
/// as durable browser storage; the Android adapter is the persistent store.
class DocStore {
  static final _items = <_Mem>[];

  static Future<String?> pathFor(SavedDoc doc) async => null;

  static Future<SavedDoc> save({
    required Uint8List bytes,
    required String name,
    String? mime,
  }) => inDocWriteQueue(() async {
    final fileName = uniqueDocumentName(name.split('/').last.split('\\').last,
      _items.map((e) => e.doc.name));
    final doc = SavedDoc(id: fileName, name: fileName,
      mime: mime ?? mimeFromName(fileName), size: bytes.length, modified: DateTime.now());
    _items.insert(0, _Mem(doc, bytes));
    return doc;
  });

  static Future<List<SavedDoc>> list({bool includeTrash = false}) async {
    final index = await DocIndex.load();
    return [for (final item in _items)
      if (includeTrash || !(index[item.doc.id] ?? const DocMeta()).inTrash) item.doc];
  }

  static Future<Uint8List> read(SavedDoc doc) async =>
      _items.firstWhere((item) => item.doc.id == doc.id).bytes;

  static Future<void> delete(SavedDoc doc) => inDocWriteQueue(() async {
    _items.removeWhere((item) => item.doc.id == doc.id);
  });

  static Future<SavedDoc> rename(SavedDoc doc, String newName) => inDocWriteQueue(() async {
    final item = _items.firstWhere((item) => item.doc.id == doc.id);
    final safe = renameKeepingExtension(doc.name, newName.split('/').last.split('\\').last);
    final error = documentNameError(doc.name, safe,
      _items.map((item) => item.doc.name), except: doc.id);
    if (error != null) throw StateError(error);
    if (safe == doc.id) return doc;
    final next = SavedDoc(id: safe, name: safe, mime: doc.mime,
      size: item.doc.size, modified: DateTime.now());
    item.doc = next;
    return next;
  });
}
