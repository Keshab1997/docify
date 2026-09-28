import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Helpers shared by more than one CV template.
///
/// Kept in one place so every template splits and styles list content the
/// same way; template-specific helpers live beside their template.
class CvPdfKit {
  const CvPdfKit._();

  /// Splits a comma/semicolon/newline separated field into clean items.
  static List<String> splitItems(String text) {
    if (text.trim().isEmpty) return [];
    return text
        .split(RegExp(r'[,;\n]'))
        .map((s) => s.trim().replaceAll(RegExp(r'^[-*•·\s]+'), ''))
        .where((s) => s.isNotEmpty)
        .toList();
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
