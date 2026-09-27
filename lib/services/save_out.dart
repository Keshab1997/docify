import 'dart:typed_data';

import '../models/saved_doc.dart';
import 'doc_store.dart';
import 'web_download.dart';

class SaveOut {
  static Future<SavedDoc> pdf(Uint8List bytes, String name) async {
    final doc = await DocStore.save(
      bytes: bytes,
      name: name,
      mime: 'application/pdf',
    );
    await WebDownload.save(bytes, name, 'application/pdf');
    return doc;
  }
}
