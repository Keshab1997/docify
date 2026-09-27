import 'dart:typed_data';

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
  }) async {
    final pdf = pw.Document();
    pw.Widget section(String title, String body) {
      if (body.trim().isEmpty) return pw.SizedBox();
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              body,
              style: const pw.TextStyle(fontSize: 11, height: 1.35),
            ),
          ],
        ),
      );
    }

    pw.ImageProvider? photoImg;
    if (photo != null) photoImg = pw.MemoryImage(photo);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 28),
        build: (ctx) {
          final header = template == 1
              ? pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (photoImg != null) ...[
                      pw.ClipRRect(
                        horizontalRadius: 6,
                        verticalRadius: 6,
                        child: pw.Image(
                          photoImg,
                          width: 78,
                          height: 96,
                          fit: pw.BoxFit.cover,
                        ),
                      ),
                      pw.SizedBox(width: 14),
                    ],
                    pw.Expanded(
                      child: _cvIdentity(
                        name,
                        email,
                        phone,
                        address,
                        dob,
                        father,
                      ),
                    ),
                  ],
                )
              : pw.Column(
                  children: [
                    if (photoImg != null)
                      pw.Align(
                        alignment: pw.Alignment.centerRight,
                        child: pw.ClipRRect(
                          horizontalRadius: 6,
                          verticalRadius: 6,
                          child: pw.Image(
                            photoImg,
                            width: 72,
                            height: 88,
                            fit: pw.BoxFit.cover,
                          ),
                        ),
                      ),
                    _cvIdentity(name, email, phone, address, dob, father),
                  ],
                );

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              header,
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.blue800, thickness: 1.2),
              pw.SizedBox(height: 10),
              section('Objective', objective),
              section('Education', education),
              section('Experience', experience),
              section('Skills', skills),
              section('Languages', languages),
              if (declaration.trim().isNotEmpty) ...[
                pw.Spacer(),
                section('Declaration', declaration),
                pw.Text(
                  'Date: ____________          Signature: ____________',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ] else
                pw.Spacer(),
              pw.SizedBox(height: 8),
              pw.Text(
                'Created with JobDoc — on this device',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
              ),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  static pw.Widget _cvIdentity(
    String name,
    String email,
    String phone,
    String address,
    String dob,
    String father,
  ) {
    final bits = <String>[
      if (email.trim().isNotEmpty) email.trim(),
      if (phone.trim().isNotEmpty) phone.trim(),
    ];
    final extra = <String>[
      if (address.trim().isNotEmpty) address.trim(),
      if (dob.trim().isNotEmpty) 'DOB: ${dob.trim()}',
      if (father.trim().isNotEmpty) "Father's name: ${father.trim()}",
    ];
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          name.trim().isEmpty ? 'Name' : name.trim(),
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        if (bits.isNotEmpty)
          pw.Text(bits.join('  ·  '), style: const pw.TextStyle(fontSize: 10)),
        if (extra.isNotEmpty) ...[
          pw.SizedBox(height: 3),
          pw.Text(extra.join('\n'), style: const pw.TextStyle(fontSize: 10)),
        ],
      ],
    );
  }
}
