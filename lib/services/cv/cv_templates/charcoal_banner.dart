// GENERATED FROM lib/services/cv_pdf_templates.dart by a mechanical split.
// Template bodies are unchanged from the original implementation.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../cv_data.dart';
import '../cv_pdf_kit.dart';

/// Charcoal Banner — full-width dark charcoal header with a two-column body.
void buildCharcoalBanner(pw.Document pdf, CvData d) {
  pw.ImageProvider? photo;
  if (d.photo != null) photo = pw.MemoryImage(d.photo!);

  const charcoal = PdfColor.fromInt(0xFF18181B);
  const amber = PdfColor.fromInt(0xFFF59E0B);
  final skillsList = CvPdfKit.splitItems(d.skills);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) {
        return pw.Column(
          children: [
            // Charcoal Header
            pw.Container(
              color: charcoal,
              padding: const pw.EdgeInsets.fromLTRB(28, 24, 28, 18),
              child: pw.Row(
                children: [
                  if (photo != null) ...[
                    pw.Container(
                      width: 70,
                      height: 70,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(color: amber, width: 2),
                      ),
                      child: pw.ClipOval(
                        child: pw.Image(photo, fit: pw.BoxFit.cover),
                      ),
                    ),
                    pw.SizedBox(width: 16),
                  ],
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          d.name.trim().isEmpty ? 'Candidate' : d.name.trim(),
                          style: const pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        if (d.title.trim().isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            d.title.trim(),
                            style: const pw.TextStyle(
                              fontSize: 11,
                              color: amber,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                        pw.SizedBox(height: 6),
                        pw.Text(
                          [
                            if (d.phone.isNotEmpty) d.phone.trim(),
                            if (d.email.isNotEmpty) d.email.trim(),
                            if (d.address.isNotEmpty) d.address.trim(),
                          ].join('   |   '),
                          style: const pw.TextStyle(
                            fontSize: 8.5,
                            color: PdfColors.grey300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Amber Stripe
            pw.Container(height: 3, color: amber),

            // Body: 2 Columns
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left Sub-column (38%)
                    pw.SizedBox(
                      width: 190,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (skillsList.isNotEmpty) ...[
                            _charcoalHeader('SKILLS', amber),
                            pw.SizedBox(height: 6),
                            CvPdfKit.chips(
                              skillsList,
                              bg: charcoal,
                              text: PdfColors.white,
                            ),
                            pw.SizedBox(height: 14),
                          ],
                          if (d.education.trim().isNotEmpty) ...[
                            _charcoalHeader('EDUCATION', amber),
                            pw.SizedBox(height: 5),
                            CvPdfKit.bulletLines(d.education,
                                bulletColor: amber),
                            pw.SizedBox(height: 14),
                          ],
                          if (d.languages.isNotEmpty ||
                              d.dob.isNotEmpty ||
                              d.father.isNotEmpty) ...[
                            _charcoalHeader('DETAILS', amber),
                            pw.SizedBox(height: 4),
                            if (d.languages.isNotEmpty)
                              pw.Text(
                                'Languages: ${d.languages.trim()}',
                                style: const pw.TextStyle(fontSize: 8.5),
                              ),
                            if (d.dob.isNotEmpty)
                              pw.Text(
                                'DOB: ${d.dob.trim()}',
                                style: const pw.TextStyle(fontSize: 8.5),
                              ),
                            if (d.father.isNotEmpty)
                              pw.Text(
                                "Father: ${d.father.trim()}",
                                style: const pw.TextStyle(fontSize: 8.5),
                              ),
                          ],
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 18),

                    // Right Sub-column (62%)
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (d.objective.trim().isNotEmpty) ...[
                            _charcoalHeader('OBJECTIVE', amber),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              d.objective.trim(),
                              style: const pw.TextStyle(
                                fontSize: 9.5,
                                height: 1.35,
                              ),
                            ),
                            pw.SizedBox(height: 14),
                          ],
                          if (d.experience.trim().isNotEmpty) ...[
                            _charcoalHeader('WORK EXPERIENCE', amber),
                            pw.SizedBox(height: 5),
                            CvPdfKit.bulletLines(d.experience,
                                bulletColor: charcoal),
                            pw.SizedBox(height: 14),
                          ],
                          if (d.declaration.trim().isNotEmpty) ...[
                            pw.Spacer(),
                            _charcoalHeader('DECLARATION', amber),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              d.declaration.trim(),
                              style: const pw.TextStyle(fontSize: 8.5),
                            ),
                            pw.SizedBox(height: 12),
                            pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'Date: ____________',
                                  style: const pw.TextStyle(fontSize: 8.5),
                                ),
                                pw.Text(
                                  'Signature: ____________',
                                  style: const pw.TextStyle(fontSize: 8.5),
                                ),
                              ],
                            ),
                          ] else ...[
                            pw.Spacer(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

pw.Widget _charcoalHeader(String title, PdfColor accent) {
  return pw.Row(
    children: [
      pw.Container(width: 4, height: 12, color: accent),
      pw.SizedBox(width: 5),
      pw.Text(
        title,
        style: const pw.TextStyle(
          fontSize: 10.5,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    ],
  );
}
