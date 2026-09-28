import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import 'cv/cv_data.dart';
import 'cv/cv_template_registry.dart';
import 'cv/cv_text_sanitizer.dart';

export 'cv/cv_data.dart';

/// Renders a CV to PDF bytes using the template selected in [CvData.template].
///
/// The ten template implementations live in `cv/cv_templates/`, one file each;
/// this class is the single public entry point used by `PdfService`.
class CvPdfTemplates {
  const CvPdfTemplates._();

  static Future<Uint8List> generate(CvData data) async {
    final pdf = pw.Document();
    // The built-in font only draws Latin-1, so pasted em dashes, curly quotes
    // and rupee signs used to reach the page as empty boxes. Cleaning here
    // covers all ten templates at once.
    final clean = CvTextSanitizer.cleanData(data);
    // Unknown ids fall back to the first template rather than throwing, so a
    // stale saved preference can never break PDF generation.
    final builder =
        kCvTemplateBuilders[clean.template] ?? kCvTemplateBuilders[0]!;
    builder(pdf, clean);
    return pdf.save();
  }
}
