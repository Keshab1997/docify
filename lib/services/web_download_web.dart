import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

class WebDownload {
  static Future<void> save(Uint8List bytes, String name, String mime) async {
    final blob = Blob(
      [bytes.toJS].toJS,
      BlobPropertyBag(type: mime),
    );
    final url = URL.createObjectURL(blob);
    final anchor = HTMLAnchorElement()
      ..href = url
      ..download = name;
    anchor.click();
    URL.revokeObjectURL(url);
  }
}
