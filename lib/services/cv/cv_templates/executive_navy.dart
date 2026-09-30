// GENERATED FROM lib/services/cv_pdf_templates.dart by a mechanical split.
// Template bodies are unchanged from the original implementation.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../cv_data.dart';
import '../cv_pdf_kit.dart';

/// Executive Navy — classic corporate layout with a navy banner and gold rules.
void buildExecutiveNavy(pw.Document pdf, CvData d) {
  pw.ImageProvider? photo;
  if (d.photo != null) photo = pw.MemoryImage(d.photo!);

  const navyPrimary = PdfColor.fromInt(0xFF0F2B48);
  const goldAccent = PdfColor.fromInt(0xFFD4AF37);
  const lightSlate = PdfColor.fromInt(0xFFF1F5F9);

  final skillsList = CvPdfKit.splitItems(d.skills);
  final contactParts = [
    if (d.phone.isNotEmpty) d.phone.trim(),
    if (d.email.isNotEmpty) d.email.trim(),
    if (d.address.isNotEmpty) d.address.trim(),
  ];

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Navy Banner
            pw.Container(
              color: navyPrimary,
              padding: const pw.EdgeInsets.fromLTRB(28, 24, 28, 20),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
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
                            color: PdfColors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        if (d.title.trim().isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Text(
                            d.title.trim().toUpperCase(),
                            style: const pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: goldAccent,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                        pw.SizedBox(height: 8),
                        if (contactParts.isNotEmpty)
                          pw.Text(
                            contactParts.join('   |   '),
                            style: const pw.TextStyle(
                              fontSize: 8.5,
                              color: PdfColors.grey300,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (photo != null) ...[
                    pw.SizedBox(width: 14),
                    pw.Container(
                      width: 70,
                      height: 85,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: goldAccent, width: 2),
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(6),
                        ),
                      ),
                      child: pw.ClipRRect(
                        horizontalRadius: 4,
                        verticalRadius: 4,
                        child: pw.Image(photo, fit: pw.BoxFit.cover),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Gold divider
            pw.Container(height: 3, color: goldAccent),

            // Body content
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(28, 20, 28, 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (d.objective.trim().isNotEmpty) ...[
                      _corporateHeader(
                        'EXECUTIVE SUMMARY',
                        navyPrimary,
                        goldAccent,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        d.objective.trim(),
                        style: const pw.TextStyle(
                          fontSize: 9.5,
                          height: 1.35,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                    ],
                    if (d.experience.trim().isNotEmpty) ...[
                      _corporateHeader(
                        'PROFESSIONAL EXPERIENCE',
                        navyPrimary,
                        goldAccent,
                      ),
                      pw.SizedBox(height: 5),
                      CvPdfKit.bulletLines(d.experience,
                          bulletColor: navyPrimary),
                      pw.SizedBox(height: 12),
                    ],
                    if (d.education.trim().isNotEmpty) ...[
                      _corporateHeader(
                        'EDUCATION & CREDENTIALS',
                        navyPrimary,
                        goldAccent,
                      ),
                      pw.SizedBox(height: 5),
                      CvPdfKit.bulletLines(d.education,
                          bulletColor: navyPrimary),
                      pw.SizedBox(height: 12),
                    ],
                    if (skillsList.isNotEmpty) ...[
                      _corporateHeader(
                        'CORE COMPETENCIES',
                        navyPrimary,
                        goldAccent,
                      ),
                      pw.SizedBox(height: 6),
                      CvPdfKit.chips(skillsList,
                          bg: lightSlate, text: navyPrimary),
                      pw.SizedBox(height: 12),
                    ],
                    if (d.dob.isNotEmpty ||
                        d.father.isNotEmpty ||
                        d.languages.isNotEmpty) ...[
                      _corporateHeader(
                        'ADDITIONAL DETAILS',
                        navyPrimary,
                        goldAccent,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        [
                          if (d.dob.isNotEmpty) 'DOB: ${d.dob.trim()}',
                          if (d.father.isNotEmpty)
                            "Father's Name: ${d.father.trim()}",
                          if (d.languages.isNotEmpty)
                            'Languages: ${d.languages.trim()}',
                        ].join('   ·   '),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.SizedBox(height: 10),
                    ],
                    if (d.declaration.trim().isNotEmpty) ...[
                      // Spacer anchors this block to the page bottom, so a
                      // short CV keeps the signature where it belongs
                      // instead of floating it up mid-page.
                      pw.Expanded(child: pw.SizedBox()),
                      _corporateHeader(
                        'DECLARATION',
                        navyPrimary,
                        goldAccent,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        d.declaration.trim(),
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColors.grey700,
                        ),
                      ),
                      CvPdfKit.signatureFooter(
                        candidateName: d.name,
                        ink: navyPrimary,
                      ),
                    ],
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

pw.Widget _corporateHeader(
  String title,
  PdfColor color,
  PdfColor accent,
) {
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
      pw.Container(width: 40, height: 2, color: accent),
    ],
  );
}
