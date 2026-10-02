import '../models/ocr_result.dart';
import '../models/saved_doc.dart';

class DocOcr {
  DocOcr._();
  static bool get available => false;
  static const maxPages = 20;
  static Future<OcrResult> recognise(SavedDoc doc, {
    required void Function(int page, String label) onProgress,
  }) async {
    throw UnsupportedError('On-device text recognition is available in the Android app.');
  }
}
