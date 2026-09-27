import 'dart:typed_data';

import 'package:gal/gal.dart';

import '../models/saved_doc.dart';
import 'doc_store.dart';

class GallerySave {
  static Future<void> saveJpeg(Uint8List bytes, String name) =>
      saveImage(bytes, name, mime: 'image/jpeg');

  static Future<void> savePng(Uint8List bytes, String name) =>
      saveImage(bytes, name, mime: 'image/png');

  static Future<void> saveImage(
    Uint8List bytes,
    String name, {
    String mime = 'image/jpeg',
  }) async {
    await DocStore.save(bytes: bytes, name: name, mime: mime);
    try {
      final allowed = await Gal.requestAccess();
      if (allowed) {
        await Gal.putImageBytes(bytes, name: name);
      }
    } catch (_) {
      // My Documents still has the file.
    }
  }
}
