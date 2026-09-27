import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// My Documents - app's own folder, no broad storage permission
class StorageService {
  static Future<Directory> getAppDocsDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final jobDocDir = Directory(p.join(dir.path, 'JobDoc'));
    if (!await jobDocDir.exists()) await jobDocDir.create(recursive: true);
    return jobDocDir;
  }

  static Future<File> saveToMyDocuments(File file) async {
    final docsDir = await getAppDocsDir();
    final newPath = p.join(docsDir.path, p.basename(file.path));
    return await file.copy(newPath);
  }

  static Future<List<FileSystemEntity>> listMyDocuments() async {
    final dir = await getAppDocsDir();
    final files = dir.listSync();
    files.sort(
      (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
    );
    return files;
  }
}
