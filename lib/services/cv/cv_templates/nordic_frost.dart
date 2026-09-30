// GENERATED FROM lib/services/cv_pdf_templates.dart by a mechanical split.
// Template bodies are unchanged from the original implementation.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../cv_data.dart';
import '../cv_pdf_kit.dart';

/// Nordic Frost — compact cyan and deep-ocean-blue layout for freshers.
void buildNordicFrost(pw.Document pdf, CvData d) {
  pw.ImageProvider? photo;
  if (d.photo != null) photo = pw.MemoryImage(d.photo!);

  const oceanBlue = PdfColor.fromInt(0xFF0284C7);
  const iceBorder = PdfColor.fromInt(0xFFBAE6FD);
  final skillsList = CvPdfKit.splitItems(d.skills);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 20),
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (photo != null) ...[
                  pw.Container(
                    width: 65,
                    height: 75,
                    decoration: pw.BoxDecoration(
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(6),
                      ),
                      border: pw.Border.all(color: oceanBlue, width: 1.5),
                    ),
                    child: pw.ClipRRect(
                      horizontalRadius: 5,
                      verticalRadius: 5,
                      child: pw.Image(photo, fit: pw.BoxFit.cover),
                    ),
                  ),
                  pw.SizedBox(width: 14),
                ],
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        d.name.trim(),
                        style: const pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey900,
                        ),
                      ),
                      if (d.title.trim().isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          d.title.trim(),
                          style: const pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: oceanBlue,
                          ),
                        ),
                      ],
                      pw.SizedBox(height: 5),
                      pw.Text(
                        [
                          if (d.email.isNotEmpty) d.email.trim(),
                          if (d.phone.isNotEmpty) d.phone.trim(),
                          if (d.address.isNotEmpty) d.address.trim(),
                        ].join('   ·   '),
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: oceanBlue, thickness: 1.5),
            pw.SizedBox(height: 10),

            if (d.objective.trim().isNotEmpty) ...[
              _nordicHeader('PROFILE SUMMARY', oceanBlue),
              pw.SizedBox(height: 4),
              pw.Text(
                d.objective.trim(),
                style: const pw.TextStyle(fontSize: 9.5, height: 1.35),
              ),
              pw.SizedBox(height: 12),
            ],

            if (skillsList.isNotEmpty) ...[
              _nordicHeader('KEY SKILLS & TOOLS', oceanBlue),
              pw.SizedBox(height: 6),
              CvPdfKit.chips(skillsList, bg: iceBorder, text: oceanBlue),
              pw.SizedBox(height: 12),
            ],

            if (d.education.trim().isNotEmpty) ...[
              _nordicHeader('EDUCATION', oceanBlue),
              pw.SizedBox(height: 5),
              CvPdfKit.bulletLines(d.education, bulletColor: oceanBlue),
              pw.SizedBox(height: 12),
            ],

            if (d.experience.trim().isNotEmpty) ...[
              _nordicHeader('EXPERIENCE & INTERNSHIPS', oceanBlue),
              pw.SizedBox(height: 5),
              CvPdfKit.bulletLines(d.experience, bulletColor: oceanBlue),
              pw.SizedBox(height: 12),
            ],

            if (d.languages.isNotEmpty ||
                d.dob.isNotEmpty ||
                d.father.isNotEmpty) ...[
              _nordicHeader('ADDITIONAL INFORMATION', oceanBlue),
              pw.SizedBox(height: 4),
              pw.Text(
                [
                  if (d.dob.isNotEmpty) 'DOB: ${d.dob.trim()}',
                  if (d.father.isNotEmpty) "Father's Name: ${d.father.trim()}",
                  if (d.languages.isNotEmpty)
                    'Languages: ${d.languages.trim()}',
                ].join('   |   '),
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 10),
            ],

            if (d.declaration.trim().isNotEmpty) ...[
              // Spacer anchors this block to the page bottom, so a short CV
              // keeps the signature where it belongs instead of floating it
              // up mid-page.
              pw.Expanded(child: pw.SizedBox()),
              _nordicHeader('DECLARATION', oceanBlue),
              pw.SizedBox(height: 4),
              pw.Text(
                d.declaration.trim(),
                style: const pw.TextStyle(fontSize: 8.5),
              ),
              CvPdfKit.signatureFooter(
                candidateName: d.name,
                ink: oceanBlue,
              ),
            ],
          ],
        );
      },
    ),
  );
}

pw.Widget _nordicHeader(String title, PdfColor color) {
  return pw.Row(
    children: [
      pw.Container(
        width: 6,
        height: 6,
        decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
      ),
      pw.SizedBox(width: 6),
      pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 10.5,
          fontWeight: pw.FontWeight.bold,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    ],
  );
}
