import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'cv_data.dart';

/// Helpers shared by more than one CV template.
///
/// Kept in one place so every template splits and styles list content the
/// same way; template-specific helpers live beside their template.
class CvPdfKit {
  const CvPdfKit._();

  /// A hairline used for fill-in blanks (date, place, signature). Real
  /// vector rules instead of `_` runs, so every font renders them identically.
  static pw.Widget fillLine(
    double width, {
    PdfColor? color,
    double thickness = 0.9,
  }) {
    return pw.Container(
      width: width,
      height: thickness,
      color: color ?? PdfColors.grey800,
    );
  }

  /// The closing block of a CV: fill-in rules for place/date on the left,
  /// and a signature rule with the candidate's name on the right.
  ///
  /// Callers put this LAST in the `footer` of a `CvFit.column`, which keeps
  /// the block at the BOTTOM of the page. Without that anchor, short CVs
  /// floated the signature up to the middle of the page, which read as
  /// unfinished.
  static pw.Widget signatureFooter({
    String candidateName = '',
    String signatureCaption = '(Signature)',
    bool includePlace = false,
    PdfColor? ink,
    PdfColor? captionColor,
    double fontSize = 9,
  }) {
    final lineColor = ink ?? PdfColors.grey800;
    final caption = pw.TextStyle(
      fontSize: fontSize - 0.5,
      color: captionColor ?? PdfColors.grey600,
    );

    pw.Widget field(double width, String label) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          fillLine(width, color: lineColor),
          pw.SizedBox(height: 3),
          pw.Text(label, style: caption),
        ],
      );
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 18),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (includePlace) ...[
                field(110, 'Place'),
                pw.SizedBox(height: 12),
              ],
              field(110, 'Date'),
            ],
          ),
          pw.Expanded(child: pw.SizedBox()),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              fillLine(150, color: lineColor),
              pw.SizedBox(height: 3),
              if (candidateName.trim().isNotEmpty) ...[
                pw.Text(
                  candidateName.trim(),
                  style: pw.TextStyle(
                    fontSize: fontSize,
                    fontWeight: pw.FontWeight.bold,
                    color: lineColor,
                  ),
                ),
                pw.SizedBox(height: 1),
              ],
              pw.Text(signatureCaption, style: caption),
            ],
          ),
        ],
      ),
    );
  }

  /// Splits a comma/semicolon/newline separated field into clean items.
  static List<String> splitItems(String text) {
    if (text.trim().isEmpty) return [];
    return text
        .split(RegExp(r'[,;\n]'))
        .map((s) => s.trim().replaceAll(RegExp(r'^[-*•·\s]+'), ''))
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Bio-data details: date of birth, gender, marital status, nationality
  /// and parents' names, as label/value pairs in that order, blanks left out.
  ///
  /// Shared so every design shows the same fields under the same names. Each
  /// design used to keep its own list, and two of them hid the whole block
  /// when only the father's name was filled in. [dob] is false for a design
  /// that already prints the date of birth with the contact details.
  static List<MapEntry<String, String>> personal(CvData d, {bool dob = true}) {
    return _filled({
      if (dob) 'Date of Birth': d.dob,
      'Gender': d.gender,
      'Marital Status': d.maritalStatus,
      'Nationality': d.nationality,
      "Father's Name": d.father,
      "Mother's Name": d.mother,
    });
  }

  /// [personal] plus languages and hobbies, as `Label: value` lines, for the
  /// designs that list all of them in one block.
  static List<String> detailLines(CvData d, {bool dob = true}) {
    final details = [
      ...personal(d, dob: dob),
      ..._filled({'Languages': d.languages, 'Hobbies': d.hobbies}),
    ];
    return [for (final detail in details) '${detail.key}: ${detail.value}'];
  }

  static List<MapEntry<String, String>> _filled(Map<String, String> fields) {
    return [
      for (final field in fields.entries)
        if (field.value.trim().isNotEmpty)
          MapEntry(field.key, field.value.trim()),
    ];
  }

  /// Renders a wrapped row of small filled pills.
  static pw.Widget chips(
    List<String> items, {
    required PdfColor bg,
    required PdfColor text,
    double fontSize = 8.5,
  }) {
    if (items.isEmpty) return pw.SizedBox();
    return pw.Wrap(
      spacing: 4,
      runSpacing: 4,
      children: items.map((item) {
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: pw.BoxDecoration(
            color: bg,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          child: pw.Text(
            item,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: pw.FontWeight.bold,
              color: text,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Renders newline separated text as a bulleted list.
  static pw.Widget bulletLines(
    String text, {
    PdfColor? bulletColor,
    PdfColor? textColor,
    double fontSize = 9.5,
  }) {
    final lines = text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (lines.isEmpty) return pw.SizedBox();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: lines.map((line) {
        final clean = line.replaceAll(RegExp(r'^[-*•·\s]+'), '');
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 3.5, right: 6),
                child: pw.Container(
                  width: 4,
                  height: 4,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    color: bulletColor ?? PdfColors.blue800,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  clean,
                  style: pw.TextStyle(
                    fontSize: fontSize,
                    color: textColor ?? PdfColors.grey900,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
