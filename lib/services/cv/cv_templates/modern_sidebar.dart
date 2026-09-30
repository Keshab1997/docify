// GENERATED FROM lib/services/cv_pdf_templates.dart by a mechanical split.
// Template bodies are unchanged from the original implementation.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../cv_data.dart';
import '../cv_pdf_kit.dart';

/// Modern Sidebar — dark slate sidebar with teal accents and a photo frame.
void buildModernSidebar(pw.Document pdf, CvData d) {
  pw.ImageProvider? photo;
  if (d.photo != null) photo = pw.MemoryImage(d.photo!);

  const sidebarBg = PdfColor.fromInt(0xFF1E293B);
  const tealAccent = PdfColor.fromInt(0xFF0D9488);
  const tealChipBg = PdfColor.fromInt(0xFF0F766E);
  const textDark = PdfColor.fromInt(0xFF0F172A);

  final skillsList = CvPdfKit.splitItems(d.skills);
  final langList = CvPdfKit.splitItems(d.languages);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) {
        return pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Left Sidebar
            pw.Container(
              width: 185,
              color: sidebarBg,
              padding: const pw.EdgeInsets.fromLTRB(16, 28, 16, 24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (photo != null) ...[
                    pw.Center(
                      child: pw.Container(
                        width: 82,
                        height: 98,
                        decoration: pw.BoxDecoration(
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(8),
                          ),
                          border: pw.Border.all(color: tealAccent, width: 2),
                        ),
                        child: pw.ClipRRect(
                          horizontalRadius: 6,
                          verticalRadius: 6,
                          child: pw.Image(photo, fit: pw.BoxFit.cover),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 16),
                  ],

                  // Contact Header
                  pw.Text(
                    'CONTACT',
                    style: const pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: tealAccent,
                      letterSpacing: 1.2,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  _sideContactItem('Phone', d.phone),
                  _sideContactItem('Email', d.email),
                  if (d.address.isNotEmpty)
                    _sideContactItem('Address', d.address),
                  if (d.dob.isNotEmpty)
                    _sideContactItem('Date of Birth', d.dob),
                  if (d.father.isNotEmpty)
                    _sideContactItem("Father's Name", d.father),

                  if (skillsList.isNotEmpty) ...[
                    pw.SizedBox(height: 16),
                    pw.Text(
                      'SKILLS',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: tealAccent,
                        letterSpacing: 1.2,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    CvPdfKit.chips(skillsList,
                        bg: tealChipBg, text: PdfColors.white),
                  ],

                  if (langList.isNotEmpty) ...[
                    pw.SizedBox(height: 16),
                    pw.Text(
                      'LANGUAGES',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: tealAccent,
                        letterSpacing: 1.2,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    ...langList.map(
                      (l) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 3),
                        child: pw.Text(
                          '· $l',
                          style: const pw.TextStyle(
                            fontSize: 9.5,
                            color: PdfColors.grey300,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Right Main Content
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header Name & Title
                    pw.Text(
                      d.name.trim(),
                      style: const pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    if (d.title.trim().isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        d.title.trim(),
                        style: const pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: tealAccent,
                        ),
                      ),
                    ],
                    pw.SizedBox(height: 12),
                    pw.Container(height: 1.5, color: tealAccent),
                    pw.SizedBox(height: 12),

                    if (d.objective.trim().isNotEmpty) ...[
                      _sectionTitle('ABOUT / OBJECTIVE', tealAccent),
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
                      _sectionTitle('WORK EXPERIENCE', tealAccent),
                      pw.SizedBox(height: 5),
                      CvPdfKit.bulletLines(d.experience,
                          bulletColor: tealAccent),
                      pw.SizedBox(height: 12),
                    ],

                    if (d.education.trim().isNotEmpty) ...[
                      _sectionTitle('EDUCATION', tealAccent),
                      pw.SizedBox(height: 5),
                      CvPdfKit.bulletLines(d.education,
                          bulletColor: tealAccent),
                      pw.SizedBox(height: 12),
                    ],

                    if (d.declaration.trim().isNotEmpty) ...[
                      _sectionTitle('DECLARATION', tealAccent),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        d.declaration.trim(),
                        style: const pw.TextStyle(
                          fontSize: 8.5,
                          height: 1.3,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.SizedBox(height: 14),
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

pw.Widget _sideContactItem(String label, String value) {
  if (value.trim().isEmpty) return pw.SizedBox();
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey400),
        ),
        pw.SizedBox(height: 1),
        pw.Text(
          value.trim(),
          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.white),
        ),
      ],
    ),
  );
}

pw.Widget _sectionTitle(String title, PdfColor color) {
  return pw.Row(
    children: [
      pw.Container(width: 3, height: 12, color: color),
      pw.SizedBox(width: 5),
      pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    ],
  );
}
