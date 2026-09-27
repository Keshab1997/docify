import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'cv_pdf_templates.dart';
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
  }) async {
    final pdf = pw.Document();
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

  static Future<Uint8List> compressPdf(Uint8List pdf, {double dpi = 110}) {
    return mergeViaRaster([pdf], dpi: dpi);
  }

  static Future<Uint8List> createCv({
    required String name,
    String title = '',
    required String email,
    required String phone,
    String address = '',
    String dob = '',
    String father = '',
    String objective = '',
    required String education,
    required String experience,
    required String skills,
    String languages = '',
    String declaration = '',
    Uint8List? photo,
    int template = 0,
  }) {
    return CvPdfTemplates.generate(
      CvData(
        name: name,
        title: title,
        email: email,
        phone: phone,
        address: address,
        dob: dob,
        father: father,
        objective: objective,
        education: education,
        experience: experience,
        skills: skills,
        languages: languages,
        declaration: declaration,
        photo: photo,
        template: template,
      ),
    );
  }
}
