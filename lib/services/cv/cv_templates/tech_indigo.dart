// GENERATED FROM lib/services/cv_pdf_templates.dart by a mechanical split.
// Template bodies are unchanged from the original implementation.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../cv_data.dart';
import '../cv_pdf_kit.dart';

/// Tech Indigo — developer-focused design with pill skills and clean lines.
void buildTechIndigo(pw.Document pdf, CvData d) {
  pw.ImageProvider? photo;
  if (d.photo != null) photo = pw.MemoryImage(d.photo!);

  const indigo = PdfColor.fromInt(0xFF4338CA);
  const chipBg = PdfColor.fromInt(0xFFEEF2FF);
  const darkSlate = PdfColor.fromInt(0xFF1E293B);

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
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        d.name.trim(),
                        style: const pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: darkSlate,
                        ),
                      ),
                      if (d.title.trim().isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          d.title.trim(),
                          style: const pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: indigo,
                          ),
                        ),
                      ],
                      pw.SizedBox(height: 6),
                      pw.Wrap(
                        spacing: 8,
                        children: [
                          if (d.email.isNotEmpty)
                            pw.Text(
                              '» ${d.email.trim()}',
                              style: const pw.TextStyle(fontSize: 8.5),
                            ),
                          if (d.phone.isNotEmpty)
                            pw.Text(
                              '» ${d.phone.trim()}',
                              style: const pw.TextStyle(fontSize: 8.5),
                            ),
                          if (d.address.isNotEmpty)
                            pw.Text(
                              '» ${d.address.trim()}',
                              style: const pw.TextStyle(fontSize: 8.5),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (photo != null) ...[
                  pw.SizedBox(width: 12),
                  pw.Container(
                    width: 68,
                    height: 80,
                    decoration: pw.BoxDecoration(
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(6),
                      ),
                      border: pw.Border.all(color: indigo, width: 1.5),
                    ),
                    child: pw.ClipRRect(
                      horizontalRadius: 5,
                      verticalRadius: 5,
                      child: pw.Image(photo, fit: pw.BoxFit.cover),
                    ),
                  ),
                ],
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: indigo, thickness: 1.5),
            pw.SizedBox(height: 10),

            if (skillsList.isNotEmpty) ...[
              _techHeader('TECH STACK & SKILLS', indigo),
              pw.SizedBox(height: 6),
              CvPdfKit.chips(skillsList, bg: chipBg, text: indigo, fontSize: 9),
              pw.SizedBox(height: 12),
            ],

            if (d.objective.trim().isNotEmpty) ...[
              _techHeader('SUMMARY', indigo),
              pw.SizedBox(height: 4),
              pw.Text(
                d.objective.trim(),
                style: const pw.TextStyle(fontSize: 9.5, height: 1.35),
              ),
              pw.SizedBox(height: 12),
            ],

            if (d.experience.trim().isNotEmpty) ...[
              _techHeader('EXPERIENCE & PROJECTS', indigo),
              pw.SizedBox(height: 5),
              CvPdfKit.bulletLines(d.experience, bulletColor: indigo),
              pw.SizedBox(height: 12),
            ],

            if (d.education.trim().isNotEmpty) ...[
              _techHeader('EDUCATION', indigo),
              pw.SizedBox(height: 5),
              CvPdfKit.bulletLines(d.education, bulletColor: indigo),
              pw.SizedBox(height: 12),
            ],

            if (d.languages.isNotEmpty || d.dob.isNotEmpty) ...[
              _techHeader('BIO & LANGUAGES', indigo),
              pw.SizedBox(height: 4),
              pw.Text(
                [
                  if (d.languages.isNotEmpty)
                    'Languages: ${d.languages.trim()}',
                  if (d.dob.isNotEmpty) 'DOB: ${d.dob.trim()}',
                  if (d.father.isNotEmpty) "Father's Name: ${d.father.trim()}",
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
              _techHeader('DECLARATION', indigo),
              pw.SizedBox(height: 3),
              pw.Text(
                d.declaration.trim(),
                style: const pw.TextStyle(fontSize: 8.5),
              ),
              CvPdfKit.signatureFooter(
                candidateName: d.name,
                ink: indigo,
              ),
            ],
          ],
        );
      },
    ),
  );
}

pw.Widget _techHeader(String title, PdfColor color) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: pw.BoxDecoration(
      border: pw.Border(left: pw.BorderSide(color: color, width: 3)),
    ),
    child: pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 10.5,
        fontWeight: pw.FontWeight.bold,
        color: color,
        letterSpacing: 0.8,
      ),
    ),
  );
}
