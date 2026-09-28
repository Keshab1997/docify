/// How much CV text each design can actually hold on one page.
///
/// Every template draws a single page and the `pdf` package clips whatever does
/// not fit, silently — a long CV used to lose its last sections with no warning
/// and nothing on screen to explain it. The package exposes no way to measure a
/// laid-out widget, so instead of trying to detect the overflow at run time the
/// capacities below were measured once, offline, and are used to warn the user
/// before the PDF is made.
///
/// How they were measured: a realistic CV (objective, three qualifications,
/// skills, declaration, and N experience bullets) was rendered in all ten
/// designs at increasing sizes, and the largest size where the last bullet *and*
/// the declaration both survived was recorded. The numbers agree with the
/// leftover space measured independently from the produced PDFs — Charcoal
/// Banner was the roomiest, Indian Bio-Data the tightest.
///
/// Raise a value only after re-measuring it.
class CvFit {
  const CvFit._();

  /// Characters in the flowing body of the CV (objective + education +
  /// experience + skills + declaration) that each design holds on one page.
  ///
  /// Keyed by `CvTemplateInfo.id`. Deliberately conservative: the measured
  /// figure rounded down to the nearest size that was proven to render whole.
  static const Map<int, int> capacity = {
    0: 2400, // Modern Sidebar
    1: 1960, // Executive Navy
    2: 1960, // Tech Indigo
    3: 1960, // Creative Emerald
    4: 1530, // Indian Bio-Data  - the tightest design
    5: 1960, // Minimalist Clean
    6: 2620, // Charcoal Banner - the roomiest design
    7: 1960, // Royal Burgundy
    8: 2400, // Modern Split
    9: 1960, // Nordic Frost
  };

  /// Warn once the CV uses this much of a design's capacity, so there is still
  /// room for the estimate to be a little off before anything is lost.
  static const double warnAt = 0.9;

  /// Capacity of the design with the most room, for the "switch design"
  /// suggestion in the warning.
  static const int roomiest = 2620;
  static const int roomiestId = 6;

  /// Body characters in a CV of this size.
  static int bodyChars({
    required String objective,
    required String education,
    required String experience,
    required String skills,
    required String declaration,
  }) =>
      objective.trim().length +
      education.trim().length +
      experience.trim().length +
      skills.trim().length +
      declaration.trim().length;

  /// Whether [templateId] is at risk of cutting the bottom of a CV this long.
  static bool atRisk(int templateId, int bodyChars) {
    final cap = capacity[templateId];
    if (cap == null) return false;
    return bodyChars > cap * warnAt;
  }
}
