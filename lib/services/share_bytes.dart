import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

class ShareBytes {
  static Future<void> share({
    required Uint8List bytes,
    required String name,
    required String mime,
  }) {
    return SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, name: name, mimeType: mime)],
      ),
    );
  }
}
