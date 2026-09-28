import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import 'cv/cv_data.dart';
import 'cv/cv_template_registry.dart';

export 'cv/cv_data.dart';

/// Renders a CV to PDF bytes using the template selected in [CvData.template].
///
/// The ten template implementations live in `cv/cv_templates/`, one file each;
/// this class is the single public entry point used by `PdfService`.
class CvPdfTemplates {
  const CvPdfTemplates._();

  static Future<Uint8List> generate(CvData data) async {
    final pdf = pw.Document();
    // Unknown ids fall back to the first template rather than throwing, so a
    // stale saved preference can never break PDF generation.
    final builder =
        kCvTemplateBuilders[data.template] ?? kCvTemplateBuilders[0]!;
    builder(pdf, data);
    return pdf.save();
  }
}
