import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/saved_doc.dart';

class DocStore {
  static Future<Directory> _dir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, 'Docify'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<SavedDoc> save({
    required Uint8List bytes,
    required String name,
    String? mime,
  }) async {
    final dir = await _dir();
    var fileName = p.basename(name);
    var dest = File(p.join(dir.path, fileName));
    if (await dest.exists()) {
      final stem = p.basenameWithoutExtension(fileName);
      final ext = p.extension(fileName);
      fileName = '${stem}_${DateTime.now().millisecondsSinceEpoch}$ext';
      dest = File(p.join(dir.path, fileName));
    }
    await dest.writeAsBytes(bytes, flush: true);
    final stat = await dest.stat();
    return SavedDoc(
      id: fileName,
      name: fileName,
      mime: mime ?? mimeFromName(fileName),
      size: bytes.length,
      modified: stat.modified,
    );
  }

  static Future<List<SavedDoc>> list() async {
    final dir = await _dir();
    final files = dir.listSync().whereType<File>().toList()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return [
      for (final f in files)
        SavedDoc(
          id: p.basename(f.path),
          name: p.basename(f.path),
          mime: mimeFromName(f.path),
          size: f.lengthSync(),
          modified: f.statSync().modified,
        ),
    ];
  }

  static Future<Uint8List> read(SavedDoc doc) async {
    final dir = await _dir();
    return File(p.join(dir.path, doc.id)).readAsBytes();
  }

  static Future<void> delete(SavedDoc doc) async {
    final dir = await _dir();
    final f = File(p.join(dir.path, doc.id));
    if (await f.exists()) await f.delete();
  }

  static Future<SavedDoc> rename(SavedDoc doc, String newName) async {
    final dir = await _dir();
    final safe = renameKeepingExtension(doc.name, p.basename(newName));
    final names = await dir
        .list()
        .where((entry) => entry is File)
        .map(
          (entry) => p.basename(entry.path),
        )
        .toList();
    final error = documentNameError(doc.name, safe, names, except: doc.id);
    if (error != null) throw StateError(error);
    if (safe == doc.id) return doc;
    final src = File(p.join(dir.path, doc.id));
    final dest = File(p.join(dir.path, safe));
    await src.rename(dest.path);
    final stat = await dest.stat();
    return SavedDoc(
      id: safe,
      name: safe,
      mime: doc.mime,
      size: stat.size,
      modified: stat.modified,
    );
  }
}
