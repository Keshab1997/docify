import 'dart:io';
import 'dart:typed_data';

Future<Uint8List?> readFilePath(String? path) async {
  if (path == null || path.isEmpty) return null;
  final file = File(path);
  if (!await file.exists()) return null;
  return file.readAsBytes();
}
