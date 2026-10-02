import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/doc_meta.dart';
import '../models/saved_doc.dart';
import 'doc_index.dart';
import 'doc_write_queue.dart';

class DocStore {
  static Future<Directory> _dir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, 'Docify'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<String?> pathFor(SavedDoc doc) async =>
      p.join((await _dir()).path, p.basename(doc.id));

  static Future<List<String>> _names(Directory dir) async {
    final names = <String>[];
    await for (final entry in dir.list(followLinks: false)) {
      if (entry is File) names.add(p.basename(entry.path));
    }
    return names;
  }

  static Future<SavedDoc> save({
    required Uint8List bytes,
    required String name,
    String? mime,
  }) => inDocWriteQueue(() async {
    final dir = await _dir();
    final fileName = uniqueDocumentName(p.basename(name), await _names(dir));
    final dest = File(p.join(dir.path, fileName));
    final pending = Directory(p.join(dir.path, '.pending'));
    await pending.create(recursive: true);
    final temp = File(p.join(pending.path, '${DateTime.now().microsecondsSinceEpoch}.tmp'));
    try {
      await temp.writeAsBytes(bytes, flush: true);
      // The destination only becomes visible once all bytes have been written.
      await temp.rename(dest.path);
    } finally {
      if (await temp.exists()) await temp.delete();
    }
    final stat = await dest.stat();
    return SavedDoc(id: fileName, name: fileName,
      mime: mime ?? mimeFromName(fileName), size: stat.size, modified: stat.modified);
  });

  static Future<List<SavedDoc>> list({bool includeTrash = false}) async {
    final dir = await _dir();
    final index = await DocIndex.load();
    final files = <SavedDoc>[];
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (!includeTrash && (index[name] ?? const DocMeta()).inTrash) continue;
      try {
        final stat = await entity.stat();
        files.add(SavedDoc(id: name, name: name, mime: mimeFromName(name),
          size: stat.size, modified: stat.modified));
      } on FileSystemException {
        // A concurrent permanent deletion is not a failed library load.
      }
    }
    files.sort((a, b) => b.modified.compareTo(a.modified));
    return files;
  }

  static Future<Uint8List> read(SavedDoc doc) async =>
      File((await pathFor(doc))!).readAsBytes();

  static Future<void> delete(SavedDoc doc) => inDocWriteQueue(() async {
    final file = File((await pathFor(doc))!);
    if (await file.exists()) await file.delete();
  });

  static Future<SavedDoc> rename(SavedDoc doc, String newName) => inDocWriteQueue(() async {
    final dir = await _dir();
    final safe = renameKeepingExtension(doc.name, p.basename(newName));
    final error = documentNameError(doc.name, safe, await _names(dir), except: doc.id);
    if (error != null) throw StateError(error);
    if (safe == doc.id) return doc;
    final dest = await File(p.join(dir.path, doc.id)).rename(p.join(dir.path, safe));
    final stat = await dest.stat();
    return SavedDoc(id: safe, name: safe, mime: doc.mime,
      size: stat.size, modified: stat.modified);
  });
}
