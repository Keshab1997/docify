import 'package:pdf/widgets.dart' as pw;

import 'cv_data.dart';
import 'cv_templates/modern_sidebar.dart';
import 'cv_templates/executive_navy.dart';
import 'cv_templates/tech_indigo.dart';
import 'cv_templates/creative_emerald.dart';
import 'cv_templates/indian_biodata.dart';
import 'cv_templates/minimalist_clean.dart';
import 'cv_templates/charcoal_banner.dart';
import 'cv_templates/royal_burgundy.dart';
import 'cv_templates/modern_split.dart';
import 'cv_templates/nordic_frost.dart';

/// Signature every CV template implements.
typedef CvTemplateBuilder = void Function(pw.Document pdf, CvData data);

/// Template id (see `CvTemplateInfo.id`) to its renderer.
///
/// The ids match `kCvTemplates` in `lib/models/cv_template_info.dart`; an
/// unknown id falls back to template 0 rather than throwing, so a stale
/// saved preference can never break PDF generation.
final Map<int, CvTemplateBuilder> kCvTemplateBuilders = {
  0: buildModernSidebar,
  1: buildExecutiveNavy,
  2: buildTechIndigo,
  3: buildCreativeEmerald,
  4: buildIndianBioData,
  5: buildMinimalistClean,
  6: buildCharcoalBanner,
  7: buildRoyalBurgundy,
  8: buildModernSplit,
  9: buildNordicFrost,
};
