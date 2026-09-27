import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

class GallerySave {
  static Future<void> saveJpeg(Uint8List bytes, String name) async {
    final blob = Blob(
      [bytes.toJS].toJS,
      BlobPropertyBag(type: 'image/jpeg'),
    );
    final url = URL.createObjectURL(blob);
    final anchor = HTMLAnchorElement()
      ..href = url
      ..download = name;
    anchor.click();
    URL.revokeObjectURL(url);
  }
}
