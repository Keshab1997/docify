import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'pdf_merge.dart';

class PdfService {
  static Future<Uint8List> imagesToPdf(
    List<Uint8List> images, {
    String page = 'a4',
    bool landscape = false,
    double margin = 18,
  }) async {
    final pdf = pw.Document();
    var format = page == 'letter' ? PdfPageFormat.letter : PdfPageFormat.a4;
    if (landscape) format = format.landscape;
    for (final bytes in images) {
      final image = pw.MemoryImage(bytes);
      pdf.addPage(
        pw.Page(
          pageFormat: format,
          margin: pw.EdgeInsets.all(margin),
          build: (_) =>
              pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
        ),
      );
    }
    return pdf.save();
  }

  static Future<({Uint8List bytes, bool rasterized})> mergePdfs(
    List<Uint8List> pdfs,
  ) async {
    try {
      final bytes = await compute(mergeClassicPdfs, pdfs);
      return (bytes: bytes, rasterized: false);
    } catch (_) {
      final bytes = await mergeViaRaster(pdfs);
      return (bytes: bytes, rasterized: true);
    }
  }

  static Future<Uint8List> mergeViaRaster(
    List<Uint8List> pdfs, {
    double dpi = 140,
    void Function(int pages)? onProgress,
  }) async {
    final pdf = pw.Document();
    var done = 0;
    for (final src in pdfs) {
      await for (final page in Printing.raster(src, dpi: dpi)) {
        final png = await page.toPng();
        final image = pw.MemoryImage(png);
        final format = PdfPageFormat(
          page.width * PdfPageFormat.inch / dpi,
          page.height * PdfPageFormat.inch / dpi,
        );
        pdf.addPage(
          pw.Page(
            pageFormat: format,
            margin: pw.EdgeInsets.zero,
            build: (_) => pw.Image(image, fit: pw.BoxFit.fill),
          ),
        );
        done++;
        onProgress?.call(done);
      }
    }
    return pdf.save();
  }

  static Future<List<Uint8List>> pdfToImages(
    Uint8List pdf, {
    double dpi = 140,
  }) async {
    final out = <Uint8List>[];
    await for (final page in Printing.raster(pdf, dpi: dpi)) {
      out.add(await page.toPng());
    }
    return out;
  }

  /// Re-renders every page at a lower resolution. For a scan or a photo PDF
  /// that shrinks the file; for a text PDF it can grow it, so the caller gets
  /// [CompressResult] and we keep whichever file is smaller.
  static Future<CompressResult> compressPdf(
    Uint8List pdf, {
    double dpi = 110,
    void Function(int pages)? onProgress,
  }) async {
    var pages = 0;
    final raster = await mergeViaRaster(
      [pdf],
      dpi: dpi,
      onProgress: (done) {
        pages = done;
        onProgress?.call(done);
      },
    );
    final keptOriginal = raster.length >= pdf.length;
    return CompressResult(
      bytes: keptOriginal ? pdf : raster,
      originalBytes: pdf.length,
      keptOriginal: keptOriginal,
      pages: pages,
    );
  }
}

/// Outcome of a compress run. `keptOriginal` is true when re-rendering made
/// the file bigger, in which case [bytes] is the untouched input.
class CompressResult {
  const CompressResult({
    required this.bytes,
    required this.originalBytes,
    required this.keptOriginal,
    required this.pages,
  });

  final Uint8List bytes;
  final int originalBytes;
  final bool keptOriginal;
  final int pages;
}
