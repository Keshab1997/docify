import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class CvData {
  final String name;
  final String title;
  final String email;
  final String phone;
  final String address;
  final String dob;
  final String father;
  final String objective;
  final String education;
  final String experience;
  final String skills;
  final String languages;
  final String declaration;
  final Uint8List? photo;
  final int template;

  const CvData({
    required this.name,
    this.title = '',
    required this.email,
    required this.phone,
    this.address = '',
    this.dob = '',
    this.father = '',
    this.objective = '',
    required this.education,
    required this.experience,
    required this.skills,
    this.languages = '',
    this.declaration = '',
    this.photo,
    this.template = 0,
  });
}

class CvPdfTemplates {
  static Future<Uint8List> generate(CvData data) async {
    final pdf = pw.Document();

    switch (data.template) {
      case 1:
        _buildExecutiveNavy(pdf, data);
        break;
      case 2:
        _buildTechIndigo(pdf, data);
        break;
      case 3:
        _buildCreativeEmerald(pdf, data);
        break;
      case 4:
        _buildIndianBioData(pdf, data);
        break;
      case 5:
        _buildMinimalistClean(pdf, data);
        break;
      case 6:
        _buildCharcoalBanner(pdf, data);
        break;
      case 7:
        _buildRoyalBurgundy(pdf, data);
        break;
      case 8:
        _buildModernSplit(pdf, data);
        break;
      case 9:
        _buildNordicFrost(pdf, data);
        break;
      case 0:
      default:
        _buildModernSidebar(pdf, data);
        break;
    }

    return pdf.save();
  }

  // Helper methods
  static List<String> _splitItems(String text) {
    if (text.trim().isEmpty) return [];
    return text
        .split(RegExp(r'[,;\n]'))
        .map((s) => s.trim().replaceAll(RegExp(r'^[-*•\s]+'), ''))
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static pw.Widget _chips(
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

  static pw.Widget _bulletLines(
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
        final clean = line.replaceAll(RegExp(r'^[-*•\s]+'), '');
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

  // -------------------------------------------------------------------------
  // Template 0: Modern Sidebar (Dark Slate + Teal)
  // -------------------------------------------------------------------------
  static void _buildModernSidebar(pw.Document pdf, CvData d) {
    pw.ImageProvider? photo;
    if (d.photo != null) photo = pw.MemoryImage(d.photo!);

    const sidebarBg = PdfColor.fromInt(0xFF1E293B);
    const tealAccent = PdfColor.fromInt(0xFF0D9488);
    const tealChipBg = PdfColor.fromInt(0xFF0F766E);
    const textDark = PdfColor.fromInt(0xFF0F172A);

    final skillsList = _splitItems(d.skills);
    final langList = _splitItems(d.languages);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (ctx) {
          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Left Sidebar
              pw.Container(
                width: 185,
                color: sidebarBg,
                padding: const pw.EdgeInsets.fromLTRB(16, 28, 16, 24),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (photo != null) ...[
                      pw.Center(
                        child: pw.Container(
                          width: 82,
                          height: 98,
                          decoration: pw.BoxDecoration(
                            borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(8),
                            ),
                            border: pw.Border.all(color: tealAccent, width: 2),
                          ),
                          child: pw.ClipRRect(
                            horizontalRadius: 6,
                            verticalRadius: 6,
                            child: pw.Image(photo, fit: pw.BoxFit.cover),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 16),
                    ],

                    // Contact Header
                    pw.Text(
                      'CONTACT',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: tealAccent,
                        letterSpacing: 1.2,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    _sideContactItem('Phone', d.phone),
                    _sideContactItem('Email', d.email),
                    if (d.address.isNotEmpty)
                      _sideContactItem('Address', d.address),
                    if (d.dob.isNotEmpty)
                      _sideContactItem('Date of Birth', d.dob),
                    if (d.father.isNotEmpty)
                      _sideContactItem("Father's Name", d.father),

                    if (skillsList.isNotEmpty) ...[
                      pw.SizedBox(height: 16),
                      pw.Text(
                        'SKILLS',
                        style: const pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: tealAccent,
                          letterSpacing: 1.2,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      _chips(skillsList, bg: tealChipBg, text: PdfColors.white),
                    ],

                    if (langList.isNotEmpty) ...[
                      pw.SizedBox(height: 16),
                      pw.Text(
                        'LANGUAGES',
                        style: const pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: tealAccent,
                          letterSpacing: 1.2,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      ...langList.map(
                        (l) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 3),
                          child: pw.Text(
                            '• $l',
                            style: const pw.TextStyle(
                              fontSize: 9.5,
                              color: PdfColors.grey300,
                            ),
                          ),
                        ),
                      ),
                    ],

                    pw.Spacer(),
                    pw.Text(
                      'JobDoc CV Builder',
                      style: const pw.TextStyle(
                        fontSize: 7.5,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),

              // Right Main Content
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Header Name & Title
                      pw.Text(
                        d.name.trim().isEmpty ? 'Full Name' : d.name.trim(),
                        style: const pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      if (d.title.trim().isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          d.title.trim(),
                          style: const pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: tealAccent,
                          ),
                        ),
                      ],
                      pw.SizedBox(height: 12),
                      pw.Container(height: 1.5, color: tealAccent),
                      pw.SizedBox(height: 12),

                      if (d.objective.trim().isNotEmpty) ...[
                        _sectionTitle('ABOUT / OBJECTIVE', tealAccent),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          d.objective.trim(),
                          style: const pw.TextStyle(
                            fontSize: 9.5,
                            height: 1.35,
                          ),
                        ),
                        pw.SizedBox(height: 12),
                      ],

                      if (d.experience.trim().isNotEmpty) ...[
                        _sectionTitle('WORK EXPERIENCE', tealAccent),
                        pw.SizedBox(height: 5),
                        _bulletLines(d.experience, bulletColor: tealAccent),
                        pw.SizedBox(height: 12),
                      ],

                      if (d.education.trim().isNotEmpty) ...[
                        _sectionTitle('EDUCATION', tealAccent),
                        pw.SizedBox(height: 5),
                        _bulletLines(d.education, bulletColor: tealAccent),
                        pw.SizedBox(height: 12),
                      ],

                      if (d.declaration.trim().isNotEmpty) ...[
                        pw.Spacer(),
                        _sectionTitle('DECLARATION', tealAccent),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          d.declaration.trim(),
                          style: const pw.TextStyle(
                            fontSize: 8.5,
                            height: 1.3,
                            color: PdfColors.grey800,
                          ),
                        ),
                        pw.SizedBox(height: 14),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Date: ____________',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            pw.Text(
                              'Signature: ____________',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ],
                        ),
                      ] else ...[
                        pw.Spacer(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static pw.Widget _sideContactItem(String label, String value) {
    if (value.trim().isEmpty) return pw.SizedBox();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey400),
          ),
          pw.SizedBox(height: 1),
          pw.Text(
            value.trim(),
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.white),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title, PdfColor color) {
    return pw.Row(
      children: [
        pw.Container(width: 3, height: 12, color: color),
        pw.SizedBox(width: 5),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: color,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Template 1: Executive Corporate (Navy & Gold Accent)
  // -------------------------------------------------------------------------
  static void _buildExecutiveNavy(pw.Document pdf, CvData d) {
    pw.ImageProvider? photo;
    if (d.photo != null) photo = pw.MemoryImage(d.photo!);

    const navyPrimary = PdfColor.fromInt(0xFF0F2B48);
    const goldAccent = PdfColor.fromInt(0xFFD4AF37);
    const lightSlate = PdfColor.fromInt(0xFFF1F5F9);

    final skillsList = _splitItems(d.skills);
    final contactParts = [
      if (d.phone.isNotEmpty) d.phone.trim(),
      if (d.email.isNotEmpty) d.email.trim(),
      if (d.address.isNotEmpty) d.address.trim(),
    ];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Navy Banner
              pw.Container(
                color: navyPrimary,
                padding: const pw.EdgeInsets.fromLTRB(28, 24, 28, 20),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            d.name.trim().isEmpty
                                ? 'EXECUTIVE CANDIDATE'
                                : d.name.trim().toUpperCase(),
                            style: const pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (d.title.trim().isNotEmpty) ...[
                            pw.SizedBox(height: 3),
                            pw.Text(
                              d.title.trim().toUpperCase(),
                              style: const pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: goldAccent,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                          pw.SizedBox(height: 8),
                          if (contactParts.isNotEmpty)
                            pw.Text(
                              contactParts.join('   |   '),
                              style: const pw.TextStyle(
                                fontSize: 8.5,
                                color: PdfColors.grey300,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (photo != null) ...[
                      pw.SizedBox(width: 14),
                      pw.Container(
                        width: 70,
                        height: 85,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: goldAccent, width: 2),
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(6),
                          ),
                        ),
                        child: pw.ClipRRect(
                          horizontalRadius: 4,
                          verticalRadius: 4,
                          child: pw.Image(photo, fit: pw.BoxFit.cover),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Gold divider
              pw.Container(height: 3, color: goldAccent),

              // Body content
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.fromLTRB(28, 20, 28, 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (d.objective.trim().isNotEmpty) ...[
                        _corporateHeader(
                          'EXECUTIVE SUMMARY',
                          navyPrimary,
                          goldAccent,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          d.objective.trim(),
                          style: const pw.TextStyle(
                            fontSize: 9.5,
                            height: 1.35,
                          ),
                        ),
                        pw.SizedBox(height: 12),
                      ],
                      if (d.experience.trim().isNotEmpty) ...[
                        _corporateHeader(
                          'PROFESSIONAL EXPERIENCE',
                          navyPrimary,
                          goldAccent,
                        ),
                        pw.SizedBox(height: 5),
                        _bulletLines(d.experience, bulletColor: navyPrimary),
                        pw.SizedBox(height: 12),
                      ],
                      if (d.education.trim().isNotEmpty) ...[
                        _corporateHeader(
                          'EDUCATION & CREDENTIALS',
                          navyPrimary,
                          goldAccent,
                        ),
                        pw.SizedBox(height: 5),
                        _bulletLines(d.education, bulletColor: navyPrimary),
                        pw.SizedBox(height: 12),
                      ],
                      if (skillsList.isNotEmpty) ...[
                        _corporateHeader(
                          'CORE COMPETENCIES',
                          navyPrimary,
                          goldAccent,
                        ),
                        pw.SizedBox(height: 6),
                        _chips(skillsList, bg: lightSlate, text: navyPrimary),
                        pw.SizedBox(height: 12),
                      ],
                      if (d.dob.isNotEmpty ||
                          d.father.isNotEmpty ||
                          d.languages.isNotEmpty) ...[
                        _corporateHeader(
                          'ADDITIONAL DETAILS',
                          navyPrimary,
                          goldAccent,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          [
                            if (d.dob.isNotEmpty) 'DOB: ${d.dob.trim()}',
                            if (d.father.isNotEmpty)
                              "Father's Name: ${d.father.trim()}",
                            if (d.languages.isNotEmpty)
                              'Languages: ${d.languages.trim()}',
                          ].join('   •   '),
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.SizedBox(height: 10),
                      ],
                      if (d.declaration.trim().isNotEmpty) ...[
                        pw.Spacer(),
                        _corporateHeader(
                          'DECLARATION',
                          navyPrimary,
                          goldAccent,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          d.declaration.trim(),
                          style: const pw.TextStyle(
                            fontSize: 8.5,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 14),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Date: ____________',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            pw.Text(
                              'Signature: ____________',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ],
                        ),
                      ] else ...[
                        pw.Spacer(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static pw.Widget _corporateHeader(
    String title,
    PdfColor color,
    PdfColor accent,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
            color: color,
            letterSpacing: 1,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Container(width: 40, height: 2, color: accent),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Template 2: Tech Indigo (Developer & IT Pro)
  // -------------------------------------------------------------------------
  static void _buildTechIndigo(pw.Document pdf, CvData d) {
    pw.ImageProvider? photo;
    if (d.photo != null) photo = pw.MemoryImage(d.photo!);

    const indigo = PdfColor.fromInt(0xFF4338CA);
    const chipBg = PdfColor.fromInt(0xFFEEF2FF);
    const darkSlate = PdfColor.fromInt(0xFF1E293B);

    final skillsList = _splitItems(d.skills);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 20),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          d.name.trim().isEmpty
                              ? 'Software Developer'
                              : d.name.trim(),
                          style: const pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: darkSlate,
                          ),
                        ),
                        if (d.title.trim().isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            d.title.trim(),
                            style: const pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: indigo,
                            ),
                          ),
                        ],
                        pw.SizedBox(height: 6),
                        pw.Wrap(
                          spacing: 8,
                          children: [
                            if (d.email.isNotEmpty)
                              pw.Text(
                                '✉ ${d.email.trim()}',
                                style: const pw.TextStyle(fontSize: 8.5),
                              ),
                            if (d.phone.isNotEmpty)
                              pw.Text(
                                '☎ ${d.phone.trim()}',
                                style: const pw.TextStyle(fontSize: 8.5),
                              ),
                            if (d.address.isNotEmpty)
                              pw.Text(
                                '⚲ ${d.address.trim()}',
                                style: const pw.TextStyle(fontSize: 8.5),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (photo != null) ...[
                    pw.SizedBox(width: 12),
                    pw.Container(
                      width: 68,
                      height: 80,
                      decoration: pw.BoxDecoration(
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(6),
                        ),
                        border: pw.Border.all(color: indigo, width: 1.5),
                      ),
                      child: pw.ClipRRect(
                        horizontalRadius: 5,
                        verticalRadius: 5,
                        child: pw.Image(photo, fit: pw.BoxFit.cover),
                      ),
                    ),
                  ],
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: indigo, thickness: 1.5),
              pw.SizedBox(height: 10),

              if (skillsList.isNotEmpty) ...[
                _techHeader('TECH STACK & SKILLS', indigo),
                pw.SizedBox(height: 6),
                _chips(skillsList, bg: chipBg, text: indigo, fontSize: 9),
                pw.SizedBox(height: 12),
              ],

              if (d.objective.trim().isNotEmpty) ...[
                _techHeader('SUMMARY', indigo),
                pw.SizedBox(height: 4),
                pw.Text(
                  d.objective.trim(),
                  style: const pw.TextStyle(fontSize: 9.5, height: 1.35),
                ),
                pw.SizedBox(height: 12),
              ],

              if (d.experience.trim().isNotEmpty) ...[
                _techHeader('EXPERIENCE & PROJECTS', indigo),
                pw.SizedBox(height: 5),
                _bulletLines(d.experience, bulletColor: indigo),
                pw.SizedBox(height: 12),
              ],

              if (d.education.trim().isNotEmpty) ...[
                _techHeader('EDUCATION', indigo),
                pw.SizedBox(height: 5),
                _bulletLines(d.education, bulletColor: indigo),
                pw.SizedBox(height: 12),
              ],

              if (d.languages.isNotEmpty || d.dob.isNotEmpty) ...[
                _techHeader('BIO & LANGUAGES', indigo),
                pw.SizedBox(height: 4),
                pw.Text(
                  [
                    if (d.languages.isNotEmpty)
                      'Languages: ${d.languages.trim()}',
                    if (d.dob.isNotEmpty) 'DOB: ${d.dob.trim()}',
                    if (d.father.isNotEmpty)
                      "Father's Name: ${d.father.trim()}",
                  ].join('   |   '),
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 10),
              ],

              if (d.declaration.trim().isNotEmpty) ...[
                pw.Spacer(),
                _techHeader('DECLARATION', indigo),
                pw.SizedBox(height: 3),
                pw.Text(
                  d.declaration.trim(),
                  style: const pw.TextStyle(fontSize: 8.5),
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Date: ____________',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Signature: ____________',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ] else ...[
                pw.Spacer(),
              ],
            ],
          );
        },
      ),
    );
  }

  static pw.Widget _techHeader(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(
        border: pw.Border(left: pw.BorderSide(color: color, width: 3)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 10.5,
          fontWeight: pw.FontWeight.bold,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Template 3: Creative Emerald (Fresh Mint & Dark Emerald)
  // -------------------------------------------------------------------------
  static void _buildCreativeEmerald(pw.Document pdf, CvData d) {
    pw.ImageProvider? photo;
    if (d.photo != null) photo = pw.MemoryImage(d.photo!);

    const emeraldDark = PdfColor.fromInt(0xFF065F46);
    const mintLight = PdfColor.fromInt(0xFFD1FAE5);
    const mintChip = PdfColor.fromInt(0xFF059669);

    final skillsList = _splitItems(d.skills);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (ctx) {
          return pw.Column(
            children: [
              // Emerald Top Bar
              pw.Container(
                color: emeraldDark,
                padding: const pw.EdgeInsets.fromLTRB(28, 24, 28, 20),
                child: pw.Row(
                  children: [
                    if (photo != null) ...[
                      pw.Container(
                        width: 72,
                        height: 72,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(
                            color: PdfColors.white,
                            width: 2,
                          ),
                        ),
                        child: pw.ClipOval(
                          child: pw.Image(photo, fit: pw.BoxFit.cover),
                        ),
                      ),
                      pw.SizedBox(width: 16),
                    ],
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            d.name.trim().isEmpty ? 'Your Name' : d.name.trim(),
                            style: const pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                          if (d.title.trim().isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              d.title.trim(),
                              style: const pw.TextStyle(
                                fontSize: 11,
                                color: PdfColors.grey200,
                              ),
                            ),
                          ],
                          pw.SizedBox(height: 6),
                          pw.Text(
                            [
                              if (d.email.isNotEmpty) d.email.trim(),
                              if (d.phone.isNotEmpty) d.phone.trim(),
                              if (d.address.isNotEmpty) d.address.trim(),
                            ].join('  ·  '),
                            style: const pw.TextStyle(
                              fontSize: 8.5,
                              color: mintLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.fromLTRB(28, 20, 28, 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (d.objective.trim().isNotEmpty) ...[
                        _emeraldHeader('OBJECTIVE', emeraldDark, mintLight),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          d.objective.trim(),
                          style: const pw.TextStyle(
                            fontSize: 9.5,
                            height: 1.35,
                          ),
                        ),
                        pw.SizedBox(height: 12),
                      ],
                      if (d.experience.trim().isNotEmpty) ...[
                        _emeraldHeader('EXPERIENCE', emeraldDark, mintLight),
                        pw.SizedBox(height: 5),
                        _bulletLines(d.experience, bulletColor: emeraldDark),
                        pw.SizedBox(height: 12),
                      ],
                      if (d.education.trim().isNotEmpty) ...[
                        _emeraldHeader('EDUCATION', emeraldDark, mintLight),
                        pw.SizedBox(height: 5),
                        _bulletLines(d.education, bulletColor: emeraldDark),
                        pw.SizedBox(height: 12),
                      ],
                      if (skillsList.isNotEmpty) ...[
                        _emeraldHeader(
                          'SKILLS & PROFICIENCIES',
                          emeraldDark,
                          mintLight,
                        ),
                        pw.SizedBox(height: 6),
                        _chips(skillsList, bg: mintChip, text: PdfColors.white),
                        pw.SizedBox(height: 12),
                      ],
                      if (d.languages.isNotEmpty || d.dob.isNotEmpty) ...[
                        _emeraldHeader(
                          'PERSONAL DETAILS',
                          emeraldDark,
                          mintLight,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          [
                            if (d.languages.isNotEmpty)
                              'Languages: ${d.languages.trim()}',
                            if (d.dob.isNotEmpty) 'DOB: ${d.dob.trim()}',
                            if (d.father.isNotEmpty)
                              "Father's Name: ${d.father.trim()}",
                          ].join('   •   '),
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        pw.SizedBox(height: 10),
                      ],
                      if (d.declaration.trim().isNotEmpty) ...[
                        pw.Spacer(),
                        _emeraldHeader('DECLARATION', emeraldDark, mintLight),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          d.declaration.trim(),
                          style: const pw.TextStyle(fontSize: 8.5),
                        ),
                        pw.SizedBox(height: 12),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Date: ____________',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            pw.Text(
                              'Signature: ____________',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ],
                        ),
                      ] else ...[
                        pw.Spacer(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static pw.Widget _emeraldHeader(String title, PdfColor text, PdfColor bg) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: text,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Template 4: Indian Job Bio-Data (Govt & Exam standard format)
  // -------------------------------------------------------------------------
  static void _buildIndianBioData(pw.Document pdf, CvData d) {
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
                          d.name.trim().isEmpty
                              ? 'NAME'
                              : d.name.trim().toUpperCase(),
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
                _bulletLines(d.education, bulletColor: PdfColors.black),
                pw.SizedBox(height: 10),
              ],

              if (d.experience.trim().isNotEmpty) ...[
                _bioHeader('WORK EXPERIENCE'),
                pw.SizedBox(height: 3),
                _bulletLines(d.experience, bulletColor: PdfColors.black),
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
              pw.Spacer(),
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

  static pw.Widget _bioHeader(String title) {
    return pw.Text(
      title,
      style: const pw.TextStyle(
        fontSize: 10.5,
        fontWeight: pw.FontWeight.bold,
        decoration: pw.TextDecoration.underline,
      ),
    );
  }

  static pw.TableRow _bioTableRow(String label, String value) {
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

  // -------------------------------------------------------------------------
  // Template 5: Minimalist Clean (ATS-Optimized Monochrome)
  // -------------------------------------------------------------------------
  static void _buildMinimalistClean(pw.Document pdf, CvData d) {
    pw.ImageProvider? photo;
    if (d.photo != null) photo = pw.MemoryImage(d.photo!);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 32),
        build: (ctx) {
          final contacts = [
            if (d.email.isNotEmpty) d.email.trim(),
            if (d.phone.isNotEmpty) d.phone.trim(),
            if (d.address.isNotEmpty) d.address.trim(),
            if (d.dob.isNotEmpty) 'DOB: ${d.dob.trim()}',
          ];

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          d.name.trim().isEmpty
                              ? 'NAME'
                              : d.name.trim().toUpperCase(),
                          style: const pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        if (d.title.trim().isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            d.title.trim().toUpperCase(),
                            style: const pw.TextStyle(
                              fontSize: 10.5,
                              color: PdfColors.grey700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                        pw.SizedBox(height: 6),
                        pw.Text(
                          contacts.join('   |   '),
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (photo != null) ...[
                    pw.SizedBox(width: 14),
                    pw.Container(
                      width: 65,
                      height: 80,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColors.grey600,
                          width: 1,
                        ),
                      ),
                      child: pw.Image(photo, fit: pw.BoxFit.cover),
                    ),
                  ],
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColors.black, thickness: 1),
              pw.SizedBox(height: 12),

              if (d.objective.trim().isNotEmpty) ...[
                _atsHeader('PROFESSIONAL SUMMARY'),
                pw.SizedBox(height: 4),
                pw.Text(
                  d.objective.trim(),
                  style: const pw.TextStyle(fontSize: 9.5, height: 1.35),
                ),
                pw.SizedBox(height: 12),
              ],

              if (d.experience.trim().isNotEmpty) ...[
                _atsHeader('WORK EXPERIENCE'),
                pw.SizedBox(height: 5),
                _bulletLines(d.experience, bulletColor: PdfColors.black),
                pw.SizedBox(height: 12),
              ],

              if (d.education.trim().isNotEmpty) ...[
                _atsHeader('EDUCATION'),
                pw.SizedBox(height: 5),
                _bulletLines(d.education, bulletColor: PdfColors.black),
                pw.SizedBox(height: 12),
              ],

              if (d.skills.trim().isNotEmpty) ...[
                _atsHeader('SKILLS & EXPERTISE'),
                pw.SizedBox(height: 4),
                pw.Text(
                  d.skills.trim(),
                  style: const pw.TextStyle(fontSize: 9.5, height: 1.35),
                ),
                pw.SizedBox(height: 12),
              ],

              if (d.languages.isNotEmpty || d.father.isNotEmpty) ...[
                _atsHeader('ADDITIONAL INFORMATION'),
                pw.SizedBox(height: 4),
                pw.Text(
                  [
                    if (d.languages.isNotEmpty)
                      'Languages: ${d.languages.trim()}',
                    if (d.father.isNotEmpty)
                      "Father's Name: ${d.father.trim()}",
                  ].join('   |   '),
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 10),
              ],

              if (d.declaration.trim().isNotEmpty) ...[
                pw.Spacer(),
                _atsHeader('DECLARATION'),
                pw.SizedBox(height: 4),
                pw.Text(
                  d.declaration.trim(),
                  style: const pw.TextStyle(fontSize: 8.5),
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Date: ____________',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Signature: ____________',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ] else ...[
                pw.Spacer(),
              ],
            ],
          );
        },
      ),
    );
  }

  static pw.Widget _atsHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: const pw.TextStyle(
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Container(height: 0.5, color: PdfColors.grey600),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Template 6: Charcoal Banner (Full width Dark Header + 2 Column)
  // -------------------------------------------------------------------------
  static void _buildCharcoalBanner(pw.Document pdf, CvData d) {
    pw.ImageProvider? photo;
    if (d.photo != null) photo = pw.MemoryImage(d.photo!);

    const charcoal = PdfColor.fromInt(0xFF18181B);
    const amber = PdfColor.fromInt(0xFFF59E0B);
    final skillsList = _splitItems(d.skills);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (ctx) {
          return pw.Column(
            children: [
              // Charcoal Header
              pw.Container(
                color: charcoal,
                padding: const pw.EdgeInsets.fromLTRB(28, 24, 28, 18),
                child: pw.Row(
                  children: [
                    if (photo != null) ...[
                      pw.Container(
                        width: 70,
                        height: 70,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: amber, width: 2),
                        ),
                        child: pw.ClipOval(
                          child: pw.Image(photo, fit: pw.BoxFit.cover),
                        ),
                      ),
                      pw.SizedBox(width: 16),
                    ],
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            d.name.trim().isEmpty ? 'Candidate' : d.name.trim(),
                            style: const pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                          if (d.title.trim().isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              d.title.trim(),
                              style: const pw.TextStyle(
                                fontSize: 11,
                                color: amber,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                          pw.SizedBox(height: 6),
                          pw.Text(
                            [
                              if (d.phone.isNotEmpty) d.phone.trim(),
                              if (d.email.isNotEmpty) d.email.trim(),
                              if (d.address.isNotEmpty) d.address.trim(),
                            ].join('   |   '),
                            style: const pw.TextStyle(
                              fontSize: 8.5,
                              color: PdfColors.grey300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Amber Stripe
              pw.Container(height: 3, color: amber),

              // Body: 2 Columns
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.fromLTRB(24, 20, 24, 20),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Left Sub-column (38%)
                      pw.SizedBox(
                        width: 190,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            if (skillsList.isNotEmpty) ...[
                              _charcoalHeader('SKILLS', amber),
                              pw.SizedBox(height: 6),
                              _chips(
                                skillsList,
                                bg: charcoal,
                                text: PdfColors.white,
                              ),
                              pw.SizedBox(height: 14),
                            ],
                            if (d.education.trim().isNotEmpty) ...[
                              _charcoalHeader('EDUCATION', amber),
                              pw.SizedBox(height: 5),
                              _bulletLines(d.education, bulletColor: amber),
                              pw.SizedBox(height: 14),
                            ],
                            if (d.languages.isNotEmpty ||
                                d.dob.isNotEmpty ||
                                d.father.isNotEmpty) ...[
                              _charcoalHeader('DETAILS', amber),
                              pw.SizedBox(height: 4),
                              if (d.languages.isNotEmpty)
                                pw.Text(
                                  'Languages: ${d.languages.trim()}',
                                  style: const pw.TextStyle(fontSize: 8.5),
                                ),
                              if (d.dob.isNotEmpty)
                                pw.Text(
                                  'DOB: ${d.dob.trim()}',
                                  style: const pw.TextStyle(fontSize: 8.5),
                                ),
                              if (d.father.isNotEmpty)
                                pw.Text(
                                  "Father: ${d.father.trim()}",
                                  style: const pw.TextStyle(fontSize: 8.5),
                                ),
                            ],
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 18),

                      // Right Sub-column (62%)
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            if (d.objective.trim().isNotEmpty) ...[
                              _charcoalHeader('OBJECTIVE', amber),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                d.objective.trim(),
                                style: const pw.TextStyle(
                                  fontSize: 9.5,
                                  height: 1.35,
                                ),
                              ),
                              pw.SizedBox(height: 14),
                            ],
                            if (d.experience.trim().isNotEmpty) ...[
                              _charcoalHeader('WORK EXPERIENCE', amber),
                              pw.SizedBox(height: 5),
                              _bulletLines(d.experience, bulletColor: charcoal),
                              pw.SizedBox(height: 14),
                            ],
                            if (d.declaration.trim().isNotEmpty) ...[
                              pw.Spacer(),
                              _charcoalHeader('DECLARATION', amber),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                d.declaration.trim(),
                                style: const pw.TextStyle(fontSize: 8.5),
                              ),
                              pw.SizedBox(height: 12),
                              pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'Date: ____________',
                                    style: const pw.TextStyle(fontSize: 8.5),
                                  ),
                                  pw.Text(
                                    'Signature: ____________',
                                    style: const pw.TextStyle(fontSize: 8.5),
                                  ),
                                ],
                              ),
                            ] else ...[
                              pw.Spacer(),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static pw.Widget _charcoalHeader(String title, PdfColor accent) {
    return pw.Row(
      children: [
        pw.Container(width: 4, height: 12, color: accent),
        pw.SizedBox(width: 5),
        pw.Text(
          title,
          style: const pw.TextStyle(
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Template 7: Royal Burgundy (Executive & Academic)
  // -------------------------------------------------------------------------
  static void _buildRoyalBurgundy(pw.Document pdf, CvData d) {
    pw.ImageProvider? photo;
    if (d.photo != null) photo = pw.MemoryImage(d.photo!);

    const burgundy = PdfColor.fromInt(0xFF701A24);
    const softRose = PdfColor.fromInt(0xFFFFF1F2);
    final skillsList = _splitItems(d.skills);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(30, 26, 30, 24),
        build: (ctx) {
          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Burgundy Left Stripe
              pw.Container(width: 5, color: burgundy),
              pw.SizedBox(width: 16),

              // Main content
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                d.name.trim().isEmpty
                                    ? 'Curriculum Vitae'
                                    : d.name.trim(),
                                style: const pw.TextStyle(
                                  fontSize: 22,
                                  fontWeight: pw.FontWeight.bold,
                                  color: burgundy,
                                ),
                              ),
                              if (d.title.trim().isNotEmpty) ...[
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  d.title.trim(),
                                  style: const pw.TextStyle(
                                    fontSize: 11,
                                    color: PdfColors.grey700,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                              pw.SizedBox(height: 6),
                              pw.Text(
                                [
                                  if (d.email.isNotEmpty) d.email.trim(),
                                  if (d.phone.isNotEmpty) d.phone.trim(),
                                  if (d.address.isNotEmpty) d.address.trim(),
                                ].join('   •   '),
                                style: const pw.TextStyle(fontSize: 8.5),
                              ),
                            ],
                          ),
                        ),
                        if (photo != null) ...[
                          pw.SizedBox(width: 12),
                          pw.Container(
                            width: 68,
                            height: 82,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(
                                color: burgundy,
                                width: 1.5,
                              ),
                              borderRadius: const pw.BorderRadius.all(
                                pw.Radius.circular(4),
                              ),
                            ),
                            child: pw.ClipRRect(
                              horizontalRadius: 3,
                              verticalRadius: 3,
                              child: pw.Image(photo, fit: pw.BoxFit.cover),
                            ),
                          ),
                        ],
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Divider(color: burgundy, thickness: 1.2),
                    pw.SizedBox(height: 10),

                    if (d.objective.trim().isNotEmpty) ...[
                      pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        decoration: const pw.BoxDecoration(
                          color: softRose,
                          borderRadius: pw.BorderRadius.all(
                            pw.Radius.circular(4),
                          ),
                        ),
                        child: pw.Text(
                          d.objective.trim(),
                          style: const pw.TextStyle(
                            fontSize: 9.5,
                            height: 1.35,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 12),
                    ],

                    if (d.experience.trim().isNotEmpty) ...[
                      _burgundyHeader('PROFESSIONAL EXPERIENCE', burgundy),
                      pw.SizedBox(height: 5),
                      _bulletLines(d.experience, bulletColor: burgundy),
                      pw.SizedBox(height: 12),
                    ],

                    if (d.education.trim().isNotEmpty) ...[
                      _burgundyHeader('EDUCATION & ACADEMICS', burgundy),
                      pw.SizedBox(height: 5),
                      _bulletLines(d.education, bulletColor: burgundy),
                      pw.SizedBox(height: 12),
                    ],

                    if (skillsList.isNotEmpty) ...[
                      _burgundyHeader('KEY SKILLS', burgundy),
                      pw.SizedBox(height: 6),
                      _chips(skillsList, bg: burgundy, text: PdfColors.white),
                      pw.SizedBox(height: 12),
                    ],

                    if (d.languages.isNotEmpty ||
                        d.dob.isNotEmpty ||
                        d.father.isNotEmpty) ...[
                      _burgundyHeader('PERSONAL DOSSIER', burgundy),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        [
                          if (d.dob.isNotEmpty) 'DOB: ${d.dob.trim()}',
                          if (d.father.isNotEmpty)
                            "Father's Name: ${d.father.trim()}",
                          if (d.languages.isNotEmpty)
                            'Languages: ${d.languages.trim()}',
                        ].join('   |   '),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.SizedBox(height: 10),
                    ],

                    if (d.declaration.trim().isNotEmpty) ...[
                      pw.Spacer(),
                      _burgundyHeader('DECLARATION', burgundy),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        d.declaration.trim(),
                        style: const pw.TextStyle(fontSize: 8.5),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Date: ____________',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                          pw.Text(
                            'Signature: ____________',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                    ] else ...[
                      pw.Spacer(),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static pw.Widget _burgundyHeader(String title, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
            color: color,
            letterSpacing: 1,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Container(width: 32, height: 1.5, color: color),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Template 8: Modern Split Card (Dual Tone Ice Slate)
  // -------------------------------------------------------------------------
  static void _buildModernSplit(pw.Document pdf, CvData d) {
    pw.ImageProvider? photo;
    if (d.photo != null) photo = pw.MemoryImage(d.photo!);

    const slateBg = PdfColor.fromInt(0xFFF1F5F9);
    const darkPrimary = PdfColor.fromInt(0xFF334155);
    const accent = PdfColor.fromInt(0xFF0284C7);
    final skillsList = _splitItems(d.skills);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (ctx) {
          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Left Shaded Pane (35%)
              pw.Container(
                width: 185,
                color: slateBg,
                padding: const pw.EdgeInsets.fromLTRB(16, 28, 16, 24),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (photo != null) ...[
                      pw.Center(
                        child: pw.Container(
                          width: 80,
                          height: 95,
                          decoration: pw.BoxDecoration(
                            borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(6),
                            ),
                            border: pw.Border.all(color: accent, width: 2),
                          ),
                          child: pw.ClipRRect(
                            horizontalRadius: 4,
                            verticalRadius: 4,
                            child: pw.Image(photo, fit: pw.BoxFit.cover),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 16),
                    ],
                    pw.Text(
                      'CONTACT',
                      style: const pw.TextStyle(
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                        color: darkPrimary,
                        letterSpacing: 1,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    _splitContactItem('Phone', d.phone),
                    _splitContactItem('Email', d.email),
                    if (d.address.isNotEmpty)
                      _splitContactItem('Address', d.address),
                    if (d.dob.isNotEmpty)
                      _splitContactItem('Date of Birth', d.dob),
                    if (d.father.isNotEmpty)
                      _splitContactItem("Father's Name", d.father),
                    if (skillsList.isNotEmpty) ...[
                      pw.SizedBox(height: 16),
                      pw.Text(
                        'SKILLS',
                        style: const pw.TextStyle(
                          fontSize: 10.5,
                          fontWeight: pw.FontWeight.bold,
                          color: darkPrimary,
                          letterSpacing: 1,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      _chips(
                        skillsList,
                        bg: darkPrimary,
                        text: PdfColors.white,
                      ),
                    ],
                    if (d.languages.isNotEmpty) ...[
                      pw.SizedBox(height: 16),
                      pw.Text(
                        'LANGUAGES',
                        style: const pw.TextStyle(
                          fontSize: 10.5,
                          fontWeight: pw.FontWeight.bold,
                          color: darkPrimary,
                          letterSpacing: 1,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        d.languages.trim(),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                    pw.Spacer(),
                    pw.Text(
                      'Created with JobDoc',
                      style: const pw.TextStyle(
                        fontSize: 7.5,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),

              // Right White Pane (65%)
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.fromLTRB(22, 28, 22, 24),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        d.name.trim().isEmpty
                            ? 'Candidate Name'
                            : d.name.trim(),
                        style: const pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: darkPrimary,
                        ),
                      ),
                      if (d.title.trim().isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          d.title.trim(),
                          style: const pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: accent,
                          ),
                        ),
                      ],
                      pw.SizedBox(height: 10),
                      pw.Divider(color: accent, thickness: 1.5),
                      pw.SizedBox(height: 10),
                      if (d.objective.trim().isNotEmpty) ...[
                        _splitMainHeader('PROFESSIONAL PROFILE', accent),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          d.objective.trim(),
                          style: const pw.TextStyle(
                            fontSize: 9.5,
                            height: 1.35,
                          ),
                        ),
                        pw.SizedBox(height: 12),
                      ],
                      if (d.experience.trim().isNotEmpty) ...[
                        _splitMainHeader('WORK EXPERIENCE', accent),
                        pw.SizedBox(height: 5),
                        _bulletLines(d.experience, bulletColor: accent),
                        pw.SizedBox(height: 12),
                      ],
                      if (d.education.trim().isNotEmpty) ...[
                        _splitMainHeader('EDUCATION', accent),
                        pw.SizedBox(height: 5),
                        _bulletLines(d.education, bulletColor: accent),
                        pw.SizedBox(height: 12),
                      ],
                      if (d.declaration.trim().isNotEmpty) ...[
                        pw.Spacer(),
                        _splitMainHeader('DECLARATION', accent),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          d.declaration.trim(),
                          style: const pw.TextStyle(fontSize: 8.5),
                        ),
                        pw.SizedBox(height: 12),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Date: ____________',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            pw.Text(
                              'Signature: ____________',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ],
                        ),
                      ] else ...[
                        pw.Spacer(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static pw.Widget _splitContactItem(String label, String value) {
    if (value.trim().isEmpty) return pw.SizedBox();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 1),
          pw.Text(
            value.trim(),
            style: const pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _splitMainHeader(String title, PdfColor accent) {
    return pw.Row(
      children: [
        pw.Container(width: 3.5, height: 12, color: accent),
        pw.SizedBox(width: 6),
        pw.Text(
          title,
          style: const pw.TextStyle(
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Template 9: Nordic Frost (Ocean Blue & Modern Freshers)
  // -------------------------------------------------------------------------
  static void _buildNordicFrost(pw.Document pdf, CvData d) {
    pw.ImageProvider? photo;
    if (d.photo != null) photo = pw.MemoryImage(d.photo!);

    const oceanBlue = PdfColor.fromInt(0xFF0284C7);
    const iceBorder = PdfColor.fromInt(0xFFBAE6FD);
    final skillsList = _splitItems(d.skills);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 20),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (photo != null) ...[
                    pw.Container(
                      width: 65,
                      height: 75,
                      decoration: pw.BoxDecoration(
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(6),
                        ),
                        border: pw.Border.all(color: oceanBlue, width: 1.5),
                      ),
                      child: pw.ClipRRect(
                        horizontalRadius: 5,
                        verticalRadius: 5,
                        child: pw.Image(photo, fit: pw.BoxFit.cover),
                      ),
                    ),
                    pw.SizedBox(width: 14),
                  ],
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          d.name.trim().isEmpty ? 'Name' : d.name.trim(),
                          style: const pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey900,
                          ),
                        ),
                        if (d.title.trim().isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            d.title.trim(),
                            style: const pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: oceanBlue,
                            ),
                          ),
                        ],
                        pw.SizedBox(height: 5),
                        pw.Text(
                          [
                            if (d.email.isNotEmpty) d.email.trim(),
                            if (d.phone.isNotEmpty) d.phone.trim(),
                            if (d.address.isNotEmpty) d.address.trim(),
                          ].join('   •   '),
                          style: const pw.TextStyle(
                            fontSize: 8.5,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: oceanBlue, thickness: 1.5),
              pw.SizedBox(height: 10),

              if (d.objective.trim().isNotEmpty) ...[
                _nordicHeader('PROFILE SUMMARY', oceanBlue),
                pw.SizedBox(height: 4),
                pw.Text(
                  d.objective.trim(),
                  style: const pw.TextStyle(fontSize: 9.5, height: 1.35),
                ),
                pw.SizedBox(height: 12),
              ],

              if (skillsList.isNotEmpty) ...[
                _nordicHeader('KEY SKILLS & TOOLS', oceanBlue),
                pw.SizedBox(height: 6),
                _chips(skillsList, bg: iceBorder, text: oceanBlue),
                pw.SizedBox(height: 12),
              ],

              if (d.education.trim().isNotEmpty) ...[
                _nordicHeader('EDUCATION', oceanBlue),
                pw.SizedBox(height: 5),
                _bulletLines(d.education, bulletColor: oceanBlue),
                pw.SizedBox(height: 12),
              ],

              if (d.experience.trim().isNotEmpty) ...[
                _nordicHeader('EXPERIENCE & INTERNSHIPS', oceanBlue),
                pw.SizedBox(height: 5),
                _bulletLines(d.experience, bulletColor: oceanBlue),
                pw.SizedBox(height: 12),
              ],

              if (d.languages.isNotEmpty ||
                  d.dob.isNotEmpty ||
                  d.father.isNotEmpty) ...[
                _nordicHeader('ADDITIONAL INFORMATION', oceanBlue),
                pw.SizedBox(height: 4),
                pw.Text(
                  [
                    if (d.dob.isNotEmpty) 'DOB: ${d.dob.trim()}',
                    if (d.father.isNotEmpty)
                      "Father's Name: ${d.father.trim()}",
                    if (d.languages.isNotEmpty)
                      'Languages: ${d.languages.trim()}',
                  ].join('   |   '),
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 10),
              ],

              if (d.declaration.trim().isNotEmpty) ...[
                pw.Spacer(),
                _nordicHeader('DECLARATION', oceanBlue),
                pw.SizedBox(height: 4),
                pw.Text(
                  d.declaration.trim(),
                  style: const pw.TextStyle(fontSize: 8.5),
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Date: ____________',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      'Signature: ____________',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ] else ...[
                pw.Spacer(),
              ],
            ],
          );
        },
      ),
    );
  }

  static pw.Widget _nordicHeader(String title, PdfColor color) {
    return pw.Row(
      children: [
        pw.Container(
          width: 6,
          height: 6,
          decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
        ),
        pw.SizedBox(width: 6),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
            color: color,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
