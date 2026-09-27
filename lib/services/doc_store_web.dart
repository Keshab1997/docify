import 'dart:typed_data';

import '../models/saved_doc.dart';

class _Mem {
  _Mem(this.doc, this.bytes);
  SavedDoc doc;
  Uint8List bytes;
}

class DocStore {
  static final _items = <_Mem>[];

  static Future<SavedDoc> save({
    required Uint8List bytes,
    required String name,
    String? mime,
  }) async {
    var fileName = name.split('/').last.split('\\').last;
    if (_items.any((e) => e.doc.id == fileName)) {
      final dot = fileName.lastIndexOf('.');
      final stem = dot <= 0 ? fileName : fileName.substring(0, dot);
      final ext = dot <= 0 ? '' : fileName.substring(dot);
      fileName = '${stem}_${DateTime.now().millisecondsSinceEpoch}$ext';
    }
    final doc = SavedDoc(
      id: fileName,
      name: fileName,
      mime: mime ?? mimeFromName(fileName),
      size: bytes.length,
      modified: DateTime.now(),
    );
    _items.insert(0, _Mem(doc, bytes));
    return doc;
  }

  static Future<List<SavedDoc>> list() async =>
      [for (final e in _items) e.doc];

  static Future<Uint8List> read(SavedDoc doc) async {
    return _items.firstWhere((e) => e.doc.id == doc.id).bytes;
  }

  static Future<void> delete(SavedDoc doc) async {
    _items.removeWhere((e) => e.doc.id == doc.id);
  }

  static Future<SavedDoc> rename(SavedDoc doc, String newName) async {
    final item = _items.firstWhere((e) => e.doc.id == doc.id);
    final safe = newName.split('/').last.split('\\').last;
    final next = SavedDoc(
      id: safe,
      name: safe,
      mime: mimeFromName(safe),
      size: item.doc.size,
      modified: DateTime.now(),
    );
    item.doc = next;
    return next;
  }
}
