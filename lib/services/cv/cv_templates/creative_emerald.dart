// GENERATED FROM lib/services/cv_pdf_templates.dart by a mechanical split.
// Template bodies are unchanged from the original implementation.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../cv_data.dart';
import '../cv_fit.dart';
import '../cv_pdf_kit.dart';

/// Creative Emerald — vibrant emerald header with rounded sections and mint tags.
void buildCreativeEmerald(pw.Document pdf, CvData d) {
  pw.ImageProvider? photo;
  if (d.photo != null) photo = pw.MemoryImage(d.photo!);

  const emeraldDark = PdfColor.fromInt(0xFF065F46);
  const mintLight = PdfColor.fromInt(0xFFD1FAE5);
  const mintChip = PdfColor.fromInt(0xFF059669);

  final skillsList = CvPdfKit.splitItems(d.skills);
  final details = CvPdfKit.detailLines(d);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => CvFit.page(() {
        return pw.Column(
          children: [
            // Emerald Top Bar
            pw.Container(
              color: emeraldDark,
              padding: const pw.EdgeInsets.fromLTRB(28, 24, 28, 20),
              child: CvFit.scaled(
                child: pw.Row(
                  children: [
                    if (photo != null) ...[
                      pw.Container(
                        width: 72,
                        height: 72,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(
                            color: PdfColors.white,
                            width: 2,
                          ),
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
                            d.name.trim(),
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
                                color: PdfColors.grey200,
                              ),
                            ),
                          ],
                          pw.SizedBox(height: 6),
                          pw.Text(
                            [
                              if (d.email.isNotEmpty) d.email.trim(),
                              if (d.phone.isNotEmpty) d.phone.trim(),
                              if (d.address.isNotEmpty) d.address.trim(),
                            ].join('  ·  '),
                            style: const pw.TextStyle(
                              fontSize: 8.5,
                              color: mintLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Body
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(28, 20, 28, 20),
                child: CvFit.column(
                  body: [
                    if (d.objective.trim().isNotEmpty) ...[
                      _emeraldHeader('OBJECTIVE', emeraldDark, mintLight),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        d.objective.trim(),
                        style: const pw.TextStyle(
                          fontSize: 9.5,
                          height: 1.35,
                        ),
                      ),
                      CvFit.gap(12),
                    ],
                    if (d.experience.trim().isNotEmpty) ...[
                      _emeraldHeader('EXPERIENCE', emeraldDark, mintLight),
                      pw.SizedBox(height: 5),
                      CvPdfKit.bulletLines(d.experience,
                          bulletColor: emeraldDark),
                      CvFit.gap(12),
                    ],
                    if (d.projects.trim().isNotEmpty) ...[
                      _emeraldHeader('PROJECTS', emeraldDark, mintLight),
                      pw.SizedBox(height: 5),
                      CvPdfKit.bulletLines(
                        d.projects,
                        bulletColor: emeraldDark,
                      ),
                      CvFit.gap(12),
                    ],
                    if (d.education.trim().isNotEmpty) ...[
                      _emeraldHeader('EDUCATION', emeraldDark, mintLight),
                      pw.SizedBox(height: 5),
                      CvPdfKit.bulletLines(d.education,
                          bulletColor: emeraldDark),
                      CvFit.gap(12),
                    ],
                    if (d.certifications.trim().isNotEmpty) ...[
                      _emeraldHeader('CERTIFICATIONS', emeraldDark, mintLight),
                      pw.SizedBox(height: 5),
                      CvPdfKit.bulletLines(
                        d.certifications,
                        bulletColor: emeraldDark,
                      ),
                      CvFit.gap(12),
                    ],
                    if (skillsList.isNotEmpty) ...[
                      _emeraldHeader(
                        'SKILLS & PROFICIENCIES',
                        emeraldDark,
                        mintLight,
                      ),
                      pw.SizedBox(height: 6),
                      CvPdfKit.chips(skillsList,
                          bg: mintChip, text: PdfColors.white),
                      CvFit.gap(12),
                    ],
                    if (details.isNotEmpty) ...[
                      _emeraldHeader(
                        'PERSONAL DETAILS',
                        emeraldDark,
                        mintLight,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        details.join('   ·   '),
                        style: const pw.TextStyle(fontSize: 9, height: 1.35),
                      ),
                      CvFit.gap(10),
                    ],
                  ],
                  footer: [
                    if (d.declaration.trim().isNotEmpty) ...[
                      _emeraldHeader('DECLARATION', emeraldDark, mintLight),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        d.declaration.trim(),
                        style: const pw.TextStyle(fontSize: 8.5),
                      ),
                      CvPdfKit.signatureFooter(
                        candidateName: d.name,
                        ink: emeraldDark,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    ),
  );
}

pw.Widget _emeraldHeader(String title, PdfColor text, PdfColor bg) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: pw.BoxDecoration(
      color: bg,
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
    ),
    child: pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: text,
        letterSpacing: 0.8,
      ),
    ),
  );
}
