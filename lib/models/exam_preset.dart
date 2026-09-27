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

  static const custom = ExamPreset(
    id: 'custom',
    name: 'Custom',
    subtitle: 'Set your own KB and pixels',
    photoMinKb: 10,
    photoMaxKb: 100,
    sigMinKb: 5,
    sigMaxKb: 50,
  );

  static const all = <ExamPreset>[
    ExamPreset(
      id: 'ssc',
      name: 'SSC',
      subtitle: 'Photo 20–50 KB · Sign 10–20 KB',
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
