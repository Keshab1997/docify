import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/saved_doc.dart';
import 'doc_store.dart';

/// Android supplies local PDF metadata and (when explicitly requested) OCR.
/// The browser preview has no phone file paths and falls back gracefully.
class DocPlatform {
  DocPlatform._();
  static const _channel = MethodChannel('com.keshabstudios.docify/documents');

  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<int?> pageCount(SavedDoc doc) async {
    if (!supported || !doc.isPdf) return null;
    try {
      final path = await DocStore.pathFor(doc);
      if (path == null) return null;
      return await _channel.invokeMethod<int>('pdfPageCount', {'path': path});
    } catch (_) {
      return null; // Encrypted/damaged PDFs still have a usable file row.
    }
  }

  static Future<String> recognisePath(String path) async {
    if (!supported) {
      throw UnsupportedError(
          'On-device text recognition is available in the Android app.');
    }
    return await _channel
            .invokeMethod<String>('recogniseText', {'path': path}) ??
        '';
  }
}
