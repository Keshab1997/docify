// GENERATED FROM lib/services/cv_pdf_templates.dart by a mechanical split.
// Template bodies are unchanged from the original implementation.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../cv_data.dart';
import '../cv_pdf_kit.dart';

/// Modern Split — 35/65 dual-tone split card with a light background sidebar.
void buildModernSplit(pw.Document pdf, CvData d) {
  pw.ImageProvider? photo;
  if (d.photo != null) photo = pw.MemoryImage(d.photo!);

  const slateBg = PdfColor.fromInt(0xFFF1F5F9);
  const darkPrimary = PdfColor.fromInt(0xFF334155);
  const accent = PdfColor.fromInt(0xFF0284C7);
  final skillsList = CvPdfKit.splitItems(d.skills);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) {
        return pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Left Shaded Pane (35%)
            pw.Container(
              width: 185,
              color: slateBg,
              padding: const pw.EdgeInsets.fromLTRB(16, 28, 16, 24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (photo != null) ...[
                    pw.Center(
                      child: pw.Container(
                        width: 80,
                        height: 95,
                        decoration: pw.BoxDecoration(
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(6),
                          ),
                          border: pw.Border.all(color: accent, width: 2),
                        ),
                        child: pw.ClipRRect(
                          horizontalRadius: 4,
                          verticalRadius: 4,
                          child: pw.Image(photo, fit: pw.BoxFit.cover),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 16),
                  ],
                  pw.Text(
                    'CONTACT',
                    style: const pw.TextStyle(
                      fontSize: 10.5,
                      fontWeight: pw.FontWeight.bold,
                      color: darkPrimary,
                      letterSpacing: 1,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  _splitContactItem('Phone', d.phone),
                  _splitContactItem('Email', d.email),
                  if (d.address.isNotEmpty)
                    _splitContactItem('Address', d.address),
                  if (d.dob.isNotEmpty)
                    _splitContactItem('Date of Birth', d.dob),
                  if (d.father.isNotEmpty)
                    _splitContactItem("Father's Name", d.father),
                  if (skillsList.isNotEmpty) ...[
                    pw.SizedBox(height: 16),
                    pw.Text(
                      'SKILLS',
                      style: const pw.TextStyle(
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                        color: darkPrimary,
                        letterSpacing: 1,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    CvPdfKit.chips(
                      skillsList,
                      bg: darkPrimary,
                      text: PdfColors.white,
                    ),
                  ],
                  if (d.languages.isNotEmpty) ...[
                    pw.SizedBox(height: 16),
                    pw.Text(
                      'LANGUAGES',
                      style: const pw.TextStyle(
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                        color: darkPrimary,
                        letterSpacing: 1,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      d.languages.trim(),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                  pw.Spacer(),
                  pw.Text(
                    'Created with Docify',
                    style: const pw.TextStyle(
                      fontSize: 7.5,
                      color: PdfColors.grey500,
                    ),
                  ),
                ],
              ),
            ),

            // Right White Pane (65%)
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(22, 28, 22, 24),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      d.name.trim(),
                      style: const pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: darkPrimary,
                      ),
                    ),
                    if (d.title.trim().isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        d.title.trim(),
                        style: const pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ],
                    pw.SizedBox(height: 10),
                    pw.Divider(color: accent, thickness: 1.5),
                    pw.SizedBox(height: 10),
                    if (d.objective.trim().isNotEmpty) ...[
                      _splitMainHeader('PROFESSIONAL PROFILE', accent),
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
                      _splitMainHeader('WORK EXPERIENCE', accent),
                      pw.SizedBox(height: 5),
                      CvPdfKit.bulletLines(d.experience, bulletColor: accent),
                      pw.SizedBox(height: 12),
                    ],
                    if (d.education.trim().isNotEmpty) ...[
                      _splitMainHeader('EDUCATION', accent),
                      pw.SizedBox(height: 5),
                      CvPdfKit.bulletLines(d.education, bulletColor: accent),
                      pw.SizedBox(height: 12),
                    ],
                    if (d.declaration.trim().isNotEmpty) ...[
                      _splitMainHeader('DECLARATION', accent),
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
            ),
          ],
        );
      },
    ),
  );
}

pw.Widget _splitContactItem(String label, String value) {
  if (value.trim().isEmpty) return pw.SizedBox();
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 1),
        pw.Text(
          value.trim(),
          style: const pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _splitMainHeader(String title, PdfColor accent) {
  return pw.Row(
    children: [
      pw.Container(width: 3.5, height: 12, color: accent),
      pw.SizedBox(width: 6),
      pw.Text(
        title,
        style: const pw.TextStyle(
          fontSize: 10.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey800,
          letterSpacing: 0.8,
        ),
      ),
    ],
  );
}
