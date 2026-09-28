// GENERATED FROM lib/services/cv_pdf_templates.dart by a mechanical split.
// Template bodies are unchanged from the original implementation.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../cv_data.dart';
import '../cv_pdf_kit.dart';

/// Royal Burgundy — deep maroon executive styling for academic and senior roles.
void buildRoyalBurgundy(pw.Document pdf, CvData d) {
  pw.ImageProvider? photo;
  if (d.photo != null) photo = pw.MemoryImage(d.photo!);

  const burgundy = PdfColor.fromInt(0xFF701A24);
  const softRose = PdfColor.fromInt(0xFFFFF1F2);
  final skillsList = CvPdfKit.splitItems(d.skills);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(30, 26, 30, 24),
      build: (ctx) {
        return pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Burgundy Left Stripe
            pw.Container(width: 5, color: burgundy),
            pw.SizedBox(width: 16),

            // Main content
            pw.Expanded(
              child: pw.Column(
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
                                color: burgundy,
                              ),
                            ),
                            if (d.title.trim().isNotEmpty) ...[
                              pw.SizedBox(height: 2),
                              pw.Text(
                                d.title.trim(),
                                style: const pw.TextStyle(
                                  fontSize: 11,
                                  color: PdfColors.grey700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                            pw.SizedBox(height: 6),
                            pw.Text(
                              [
                                if (d.email.isNotEmpty) d.email.trim(),
                                if (d.phone.isNotEmpty) d.phone.trim(),
                                if (d.address.isNotEmpty) d.address.trim(),
                              ].join('   ·   '),
                              style: const pw.TextStyle(fontSize: 8.5),
                            ),
                          ],
                        ),
                      ),
                      if (photo != null) ...[
                        pw.SizedBox(width: 12),
                        pw.Container(
                          width: 68,
                          height: 82,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: burgundy,
                              width: 1.5,
                            ),
                            borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(4),
                            ),
                          ),
                          child: pw.ClipRRect(
                            horizontalRadius: 3,
                            verticalRadius: 3,
                            child: pw.Image(photo, fit: pw.BoxFit.cover),
                          ),
                        ),
                      ],
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(color: burgundy, thickness: 1.2),
                  pw.SizedBox(height: 10),

                  if (d.objective.trim().isNotEmpty) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: const pw.BoxDecoration(
                        color: softRose,
                        borderRadius: pw.BorderRadius.all(
                          pw.Radius.circular(4),
                        ),
                      ),
                      child: pw.Text(
                        d.objective.trim(),
                        style: const pw.TextStyle(
                          fontSize: 9.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 12),
                  ],

                  if (d.experience.trim().isNotEmpty) ...[
                    _burgundyHeader('PROFESSIONAL EXPERIENCE', burgundy),
                    pw.SizedBox(height: 5),
                    CvPdfKit.bulletLines(d.experience, bulletColor: burgundy),
                    pw.SizedBox(height: 12),
                  ],

                  if (d.education.trim().isNotEmpty) ...[
                    _burgundyHeader('EDUCATION & ACADEMICS', burgundy),
                    pw.SizedBox(height: 5),
                    CvPdfKit.bulletLines(d.education, bulletColor: burgundy),
                    pw.SizedBox(height: 12),
                  ],

                  if (skillsList.isNotEmpty) ...[
                    _burgundyHeader('KEY SKILLS', burgundy),
                    pw.SizedBox(height: 6),
                    CvPdfKit.chips(skillsList,
                        bg: burgundy, text: PdfColors.white),
                    pw.SizedBox(height: 12),
                  ],

                  if (d.languages.isNotEmpty ||
                      d.dob.isNotEmpty ||
                      d.father.isNotEmpty) ...[
                    _burgundyHeader('PERSONAL DOSSIER', burgundy),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      [
                        if (d.dob.isNotEmpty) 'DOB: ${d.dob.trim()}',
                        if (d.father.isNotEmpty)
                          "Father's Name: ${d.father.trim()}",
                        if (d.languages.isNotEmpty)
                          'Languages: ${d.languages.trim()}',
                      ].join('   |   '),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.SizedBox(height: 10),
                  ],

                  if (d.declaration.trim().isNotEmpty) ...[
                    _burgundyHeader('DECLARATION', burgundy),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      d.declaration.trim(),
                      style: const pw.TextStyle(fontSize: 8.5),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Date: ____________',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.Text(
                          'Signature: ____________',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

pw.Widget _burgundyHeader(String title, PdfColor color) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 10.5,
          fontWeight: pw.FontWeight.bold,
          color: color,
          letterSpacing: 1,
        ),
      ),
      pw.SizedBox(height: 2),
      pw.Container(width: 32, height: 1.5, color: color),
    ],
  );
}
