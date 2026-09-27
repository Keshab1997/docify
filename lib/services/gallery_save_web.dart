import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

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
    final blob = Blob([bytes.toJS].toJS, BlobPropertyBag(type: mime));
    final url = URL.createObjectURL(blob);
    final anchor = HTMLAnchorElement()
      ..href = url
      ..download = name;
    anchor.click();
    URL.revokeObjectURL(url);
  }
}
