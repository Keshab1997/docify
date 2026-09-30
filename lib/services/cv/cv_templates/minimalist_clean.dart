// GENERATED FROM lib/services/cv_pdf_templates.dart by a mechanical split.
// Template bodies are unchanged from the original implementation.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../cv_data.dart';
import '../cv_fit.dart';
import '../cv_pdf_kit.dart';

/// Minimalist Clean — pure monochrome, high legibility, ATS friendly.
void buildMinimalistClean(pw.Document pdf, CvData d) {
  pw.ImageProvider? photo;
  if (d.photo != null) photo = pw.MemoryImage(d.photo!);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 32),
      build: (ctx) => CvFit.page(() {
        final contacts = [
          if (d.email.isNotEmpty) d.email.trim(),
          if (d.phone.isNotEmpty) d.phone.trim(),
          if (d.address.isNotEmpty) d.address.trim(),
          if (d.dob.isNotEmpty) 'DOB: ${d.dob.trim()}',
        ];

        return CvFit.column(
          body: [
            // Header
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        d.name.trim().toUpperCase(),
                        style: const pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      if (d.title.trim().isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          d.title.trim().toUpperCase(),
                          style: const pw.TextStyle(
                            fontSize: 10.5,
                            color: PdfColors.grey700,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                      pw.SizedBox(height: 6),
                      pw.Text(
                        contacts.join('   |   '),
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (photo != null) ...[
                  pw.SizedBox(width: 14),
                  pw.Container(
                    width: 65,
                    height: 80,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        color: PdfColors.grey600,
                        width: 1,
                      ),
                    ),
                    child: pw.Image(photo, fit: pw.BoxFit.cover),
                  ),
                ],
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: PdfColors.black, thickness: 1),
            pw.SizedBox(height: 12),

            if (d.objective.trim().isNotEmpty) ...[
              _atsHeader('PROFESSIONAL SUMMARY'),
              pw.SizedBox(height: 4),
              pw.Text(
                d.objective.trim(),
                style: const pw.TextStyle(fontSize: 9.5, height: 1.35),
              ),
              CvFit.gap(12),
            ],

            if (d.experience.trim().isNotEmpty) ...[
              _atsHeader('WORK EXPERIENCE'),
              pw.SizedBox(height: 5),
              CvPdfKit.bulletLines(d.experience, bulletColor: PdfColors.black),
              CvFit.gap(12),
            ],

            if (d.education.trim().isNotEmpty) ...[
              _atsHeader('EDUCATION'),
              pw.SizedBox(height: 5),
              CvPdfKit.bulletLines(d.education, bulletColor: PdfColors.black),
              CvFit.gap(12),
            ],

            if (d.skills.trim().isNotEmpty) ...[
              _atsHeader('SKILLS & EXPERTISE'),
              pw.SizedBox(height: 4),
              pw.Text(
                d.skills.trim(),
                style: const pw.TextStyle(fontSize: 9.5, height: 1.35),
              ),
              CvFit.gap(12),
            ],

            if (d.languages.isNotEmpty || d.father.isNotEmpty) ...[
              _atsHeader('ADDITIONAL INFORMATION'),
              pw.SizedBox(height: 4),
              pw.Text(
                [
                  if (d.languages.isNotEmpty)
                    'Languages: ${d.languages.trim()}',
                  if (d.father.isNotEmpty) "Father's Name: ${d.father.trim()}",
                ].join('   |   '),
                style: const pw.TextStyle(fontSize: 9),
              ),
              CvFit.gap(10),
            ],
          ],
          footer: [
            if (d.declaration.trim().isNotEmpty) ...[
              _atsHeader('DECLARATION'),
              pw.SizedBox(height: 4),
              pw.Text(
                d.declaration.trim(),
                style: const pw.TextStyle(fontSize: 8.5),
              ),
              CvPdfKit.signatureFooter(
                candidateName: d.name,
                ink: PdfColors.black,
              ),
            ],
          ],
        );
      }),
    ),
  );
}

pw.Widget _atsHeader(String title) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        title,
        style: const pw.TextStyle(
          fontSize: 10.5,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      pw.SizedBox(height: 2),
      pw.Container(height: 0.5, color: PdfColors.grey600),
    ],
  );
}
