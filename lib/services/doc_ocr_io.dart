import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../models/ocr_result.dart';
import '../models/saved_doc.dart';
import 'doc_platform.dart';
import 'doc_store.dart';

/// Explicitly requested OCR. Android uses a bundled, offline Latin-script model;
/// neither the original nor rendered PDF pages go to a remote OCR service.
class DocOcr {
  DocOcr._();
  static bool get available => DocPlatform.supported;
  static const maxPages = 20;

  static Future<OcrResult> recognise(SavedDoc doc, {
    required void Function(int page, String label) onProgress,
  }) async {
    if (!available) { throw UnsupportedError('On-device OCR requires the Android app.'); }
    if (doc.size > 30 * 1024 * 1024) { throw const FormatException('Use a file below 30 MB for text recognition.'); }
    if (doc.isImage) {
      final path = await DocStore.pathFor(doc);
      if (path == null) { throw StateError('This document is unavailable'); }
      onProgress(1, 'Recognising text on this device');
      return OcrResult(text: await DocPlatform.recognisePath(path), pages: 1);
    }
    if (!doc.isPdf) { throw const FormatException('Choose a PDF or image.'); }
    final count = await DocPlatform.pageCount(doc);
    final bytes = await DocStore.read(doc);
    final temp = await getTemporaryDirectory();
    final text = <String>[];
    var processed = 0;
    await for (final page in Printing.raster(bytes, dpi: 150).take(maxPages)) {
      processed++;
      onProgress(processed, 'Recognising PDF page $processed (up to $maxPages)');
      final file = File('${temp.path}/docify_ocr_${DateTime.now().microsecondsSinceEpoch}.png');
      try {
        await file.writeAsBytes(await page.toPng(), flush: true);
        text.add(await DocPlatform.recognisePath(file.path));
      } finally {
        if (await file.exists()) { await file.delete(); }
      }
    }
    return OcrResult(text: text.join('\n\n'), pages: processed,
      truncated: count == null ? processed == maxPages : count > processed);
  }
}
