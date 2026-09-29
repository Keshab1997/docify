/// Numbers taken from an exam board's application instructions.
///
/// Boards change these between cycles, so every entry carries [sourceNote] and
/// [asOf]: re-check the current notification before a release and update the
/// date. Nothing here is a substitute for reading the form.
class ExamPreset {
  const ExamPreset({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.photoMinKb,
    required this.photoMaxKb,
    this.photoW,
    this.photoH,
    required this.sigMinKb,
    required this.sigMaxKb,
    this.sigW,
    this.sigH,
    this.sourceNote = '',
    this.asOf = '',
  });

  final String id;
  final String name;
  final String subtitle;
  final int photoMinKb;
  final int photoMaxKb;
  final int? photoW;
  final int? photoH;
  final int sigMinKb;
  final int sigMaxKb;
  final int? sigW;
  final int? sigH;

  /// Which instruction sheet these numbers came from.
  final String sourceNote;

  /// When they were last checked, as `YYYY-MM`.
  final String asOf;

  static const custom = ExamPreset(
    id: 'custom',
    name: 'Custom',
    subtitle: 'Set your own KB and pixels',
    photoMinKb: 10,
    photoMaxKb: 100,
    sigMinKb: 5,
    sigMaxKb: 50,
    sourceNote: 'Your own numbers',
  );

  static const all = <ExamPreset>[
    ExamPreset(
      id: 'ssc',
      name: 'SSC',
      subtitle: 'Photo 20–50 KB · Sign 10–20 KB',
      sourceNote: 'SSC online application photo & signature instructions',
      asOf: '2026-09',
      photoMinKb: 20,
      photoMaxKb: 50,
      photoW: 413,
      photoH: 531,
      sigMinKb: 10,
      sigMaxKb: 20,
      sigW: 472,
      sigH: 236,
    ),
    ExamPreset(
      id: 'ibps',
      name: 'IBPS',
      subtitle: 'Photo 20–50 KB · Sign 10–20 KB',
      sourceNote: 'IBPS online application photo & signature instructions',
      asOf: '2026-09',
      photoMinKb: 20,
      photoMaxKb: 50,
      photoW: 413,
      photoH: 531,
      sigMinKb: 10,
      sigMaxKb: 20,
      sigW: 472,
      sigH: 236,
    ),
    ExamPreset(
      id: 'rail',
      name: 'Rail / RRB',
      subtitle: 'Photo 20–50 KB · Sign 10–20 KB',
      sourceNote: 'RRB online application photo & signature instructions',
      asOf: '2026-09',
      photoMinKb: 20,
      photoMaxKb: 50,
      photoW: 413,
      photoH: 531,
      sigMinKb: 10,
      sigMaxKb: 20,
      sigW: 400,
      sigH: 200,
    ),
    ExamPreset(
      id: 'upsc',
      name: 'UPSC',
      subtitle: 'Photo 20–300 KB · Sign 10–40 KB',
      sourceNote: 'UPSC online application photo & signature instructions',
      asOf: '2026-09',
      photoMinKb: 20,
      photoMaxKb: 300,
      photoW: 413,
      photoH: 531,
      sigMinKb: 10,
      sigMaxKb: 40,
    ),
    ExamPreset(
      id: 'passport',
      name: 'Passport',
      subtitle: '35×45 mm or 2×2 in, white bg',
      sourceNote: 'Passport Seva photo specification',
      asOf: '2026-09',
      photoMinKb: 10,
      photoMaxKb: 50,
      photoW: 413,
      photoH: 531,
      sigMinKb: 10,
      sigMaxKb: 50,
    ),
    custom,
  ];

  static ExamPreset byId(String id) =>
      all.firstWhere((e) => e.id == id, orElse: () => custom);
}
