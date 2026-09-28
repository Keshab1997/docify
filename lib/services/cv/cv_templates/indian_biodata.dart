// GENERATED FROM lib/services/cv_pdf_templates.dart by a mechanical split.
// Template bodies are unchanged from the original implementation.

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../cv_data.dart';
import '../cv_pdf_kit.dart';

/// Indian Bio-Data — the standard label/value format used for Govt, bank, SSC
/// and PSC applications.
void buildIndianBioData(pw.Document pdf, CvData d) {
  pw.ImageProvider? photo;
  if (d.photo != null) photo = pw.MemoryImage(d.photo!);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 28),
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Centered Header
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'CURRICULUM VITAE',
                    style: const pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      decoration: pw.TextDecoration.underline,
                      letterSpacing: 1.5,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                ],
              ),
            ),

            // Header Details & Photo
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        d.name.trim().toUpperCase(),
                        style: const pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      if (d.title.trim().isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          d.title.trim(),
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Email: ${d.email.trim()}',
                        style: const pw.TextStyle(fontSize: 9.5),
                      ),
                      pw.Text(
                        'Mobile: ${d.phone.trim()}',
                        style: const pw.TextStyle(fontSize: 9.5),
                      ),
                      if (d.address.isNotEmpty)
                        pw.Text(
                          'Address: ${d.address.trim()}',
                          style: const pw.TextStyle(fontSize: 9.5),
                        ),
                    ],
                  ),
                ),
                pw.Container(
                  width: 75,
                  height: 90,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 1.2),
                  ),
                  child: photo != null
                      ? pw.Image(photo, fit: pw.BoxFit.cover)
                      : pw.Center(
                          child: pw.Text(
                            'Affix\nPassport\nPhoto',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 1, color: PdfColors.black),
            pw.SizedBox(height: 6),

            // Personal Information Table
            _bioHeader('PERSONAL DETAILS'),
            pw.SizedBox(height: 4),
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey400,
                width: 0.5,
              ),
              columnWidths: const {
                0: pw.FixedColumnWidth(130),
                1: pw.FlexColumnWidth(),
              },
              children: [
                if (d.father.isNotEmpty)
                  _bioTableRow("Father's Name", d.father.trim()),
                if (d.dob.isNotEmpty)
                  _bioTableRow('Date of Birth', d.dob.trim()),
                _bioTableRow('Contact No.', d.phone.trim()),
                _bioTableRow('Email ID', d.email.trim()),
                if (d.address.isNotEmpty)
                  _bioTableRow('Permanent Address', d.address.trim()),
                if (d.languages.isNotEmpty)
                  _bioTableRow('Languages Known', d.languages.trim()),
              ],
            ),
            pw.SizedBox(height: 10),

            if (d.objective.trim().isNotEmpty) ...[
              _bioHeader('CAREER OBJECTIVE'),
              pw.SizedBox(height: 3),
              pw.Text(
                d.objective.trim(),
                style: const pw.TextStyle(fontSize: 9.5, height: 1.3),
              ),
              pw.SizedBox(height: 10),
            ],

            if (d.education.trim().isNotEmpty) ...[
              _bioHeader('ACADEMIC QUALIFICATIONS'),
              pw.SizedBox(height: 3),
              CvPdfKit.bulletLines(d.education, bulletColor: PdfColors.black),
              pw.SizedBox(height: 10),
            ],

            if (d.experience.trim().isNotEmpty) ...[
              _bioHeader('WORK EXPERIENCE'),
              pw.SizedBox(height: 3),
              CvPdfKit.bulletLines(d.experience, bulletColor: PdfColors.black),
              pw.SizedBox(height: 10),
            ],

            if (d.skills.trim().isNotEmpty) ...[
              _bioHeader('KEY SKILLS & COMPUTER PROFICIENCY'),
              pw.SizedBox(height: 3),
              pw.Text(
                d.skills.trim(),
                style: const pw.TextStyle(fontSize: 9.5, height: 1.3),
              ),
              pw.SizedBox(height: 10),
            ],
            // Declaration
            _bioHeader('DECLARATION'),
            pw.SizedBox(height: 3),
            pw.Text(
              d.declaration.trim().isNotEmpty
                  ? d.declaration.trim()
                  : 'I hereby declare that all the information provided above is true and correct to the best of my knowledge and belief.',
              style: const pw.TextStyle(fontSize: 9, height: 1.3),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Place: ____________',
                      style: const pw.TextStyle(fontSize: 9.5),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Date:  ____________',
                      style: const pw.TextStyle(fontSize: 9.5),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      '_______________________',
                      style: const pw.TextStyle(fontSize: 9.5),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '(Signature of Candidate)',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

pw.Widget _bioHeader(String title) {
  return pw.Text(
    title,
    style: const pw.TextStyle(
      fontSize: 10.5,
      fontWeight: pw.FontWeight.bold,
      decoration: pw.TextDecoration.underline,
    ),
  );
}

pw.TableRow _bioTableRow(String label, String value) {
  return pw.TableRow(
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(
          label,
          style:
              const pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
      ),
    ],
  );
}
