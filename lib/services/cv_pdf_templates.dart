import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import 'cv/cv_data.dart';
import 'cv/cv_fit.dart';
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
    return (await render(data)).bytes;
  }

  /// Like [generate], but also reports how the page was fitted, which the
  /// builder needs to warn about a CV too long for its design.
  static Future<CvRender> render(CvData data) async {
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
    final bytes = await pdf.save();
    // The page is only laid out, and so only fitted, during save().
    final fit = CvFit.resultOf(pdf.document);
    return CvRender(
      bytes: bytes,
      scale: fit?.scale ?? 1,
      cutOff: fit?.cutOff ?? false,
    );
  }
}

/// A rendered CV, plus what [CvFit] did to fit it onto one page.
class CvRender {
  const CvRender({
    required this.bytes,
    required this.scale,
    required this.cutOff,
  });

  final Uint8List bytes;

  /// Factor the page was drawn at: above 1 for a short CV, below 1 for a
  /// long one.
  final double scale;

  /// True when the CV did not fit even at the smallest scale, so the end of
  /// it is missing from the page.
  final bool cutOff;
}
