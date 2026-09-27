import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/cv_template_info.dart';
import '../../models/saved_doc.dart';
import '../../services/pdf_service.dart';
import '../../services/save_out.dart';
import '../../services/share_bytes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tool_ui.dart';

class CvBuilderScreen extends StatefulWidget {
  const CvBuilderScreen({super.key});

  @override
  State<CvBuilderScreen> createState() => _CvBuilderScreenState();
}

class _CvBuilderScreenState extends State<CvBuilderScreen> {
  int _currentTab = 0;
  Key _previewKey = UniqueKey();
  final ScrollController _scrollController = ScrollController();
  final Set<int> _expanded = {0, 1, 2, 3, 4, 5};

  final _name = TextEditingController();
  final _title = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _dob = TextEditingController();
  final _father = TextEditingController();
  final _objective = TextEditingController();
  final _education = TextEditingController();
  final _experience = TextEditingController();
  final _skills = TextEditingController();
  final _languages = TextEditingController();
  final _declaration = TextEditingController(
    text:
        'I hereby declare that the above information is true to the best of my knowledge and belief.',
  );

  Uint8List? _photo;
  Uint8List? _cv;
  String? _cvName;
  int _template = 0;

  final List<GlobalKey> _sectionKeys = List.generate(6, (_) => GlobalKey());

  static const _keys = {
    'name': 'cv_name',
    'title': 'cv_title',
    'email': 'cv_email',
    'phone': 'cv_phone',
    'address': 'cv_address',
    'dob': 'cv_dob',
    'father': 'cv_father',
    'objective': 'cv_objective',
    'education': 'cv_education',
    'experience': 'cv_experience',
    'skills': 'cv_skills',
    'languages': 'cv_languages',
    'template': 'cv_template',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _name.text = p.getString(_keys['name']!) ?? '';
    _title.text = p.getString(_keys['title']!) ?? '';
    _email.text = p.getString(_keys['email']!) ?? '';
    _phone.text = p.getString(_keys['phone']!) ?? '';
    _address.text = p.getString(_keys['address']!) ?? '';
    _dob.text = p.getString(_keys['dob']!) ?? '';
    _father.text = p.getString(_keys['father']!) ?? '';
    _objective.text = p.getString(_keys['objective']!) ?? '';
    _education.text = p.getString(_keys['education']!) ?? '';
    _experience.text = p.getString(_keys['experience']!) ?? '';
    _skills.text = p.getString(_keys['skills']!) ?? '';
    _languages.text = p.getString(_keys['languages']!) ?? '';
    final savedTemplate = p.getInt(_keys['template']!) ?? 0;
    _template = (savedTemplate >= 0 && savedTemplate < kCvTemplates.length)
        ? savedTemplate
        : 0;
    if (mounted) setState(() {});
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keys['name']!, _name.text);
    await p.setString(_keys['title']!, _title.text);
    await p.setString(_keys['email']!, _email.text);
    await p.setString(_keys['phone']!, _phone.text);
    await p.setString(_keys['address']!, _address.text);
    await p.setString(_keys['dob']!, _dob.text);
    await p.setString(_keys['father']!, _father.text);
    await p.setString(_keys['objective']!, _objective.text);
    await p.setString(_keys['education']!, _education.text);
    await p.setString(_keys['experience']!, _experience.text);
    await p.setString(_keys['skills']!, _skills.text);
    await p.setString(_keys['languages']!, _languages.text);
    await p.setInt(_keys['template']!, _template);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _name.dispose();
    _title.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _dob.dispose();
    _father.dispose();
    _objective.dispose();
    _education.dispose();
    _experience.dispose();
    _skills.dispose();
    _languages.dispose();
    _declaration.dispose();
    super.dispose();
  }

  Future<Uint8List> _generateCurrentPdf() {
    return PdfService.createCv(
      name: _name.text,
      title: _title.text,
      email: _email.text,
      phone: _phone.text,
      address: _address.text,
      dob: _dob.text,
      father: _father.text,
      objective: _objective.text,
      education: _education.text,
      experience: _experience.text,
      skills: _skills.text,
      languages: _languages.text,
      declaration: _declaration.text,
      photo: _photo,
      template: _template,
    );
  }

  Future<void> _saveCvPdf() async {
    try {
      await _persist();
      final bytes = await _generateCurrentPdf();
      final safe = _name.text.trim().isEmpty
          ? 'CV'
          : _name.text.trim().replaceAll(' ', '_');
      final name = 'CV_${safe}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await SaveOut.pdf(bytes, name);
      if (!mounted) return;
      setState(() {
        _cv = bytes;
        _cvName = name;
      });
      showJobSnack(
        context,
        '✅ CV saved successfully · ${kbLabel(bytes.length)}',
      );
    } catch (e) {
      if (!mounted) return;
      showJobSnack(context, 'Could not create CV: $e');
    }
  }

  void _loadSampleData() {
    setState(() {
      _name.text = 'Rahul Sarkar';
      _title.text = 'Software Engineer & Flutter Developer';
      _email.text = 'rahul.sarkar@example.com';
      _phone.text = '+91 98765 43210';
      _address.text = 'Salt Lake, Sector V, Kolkata, WB - 700091';
      _dob.text = '15 Aug 1998';
      _father.text = 'Bimal Sarkar';
      _objective.text =
          'Passionate software engineer with 3+ years of experience building scalable, high-performance cross-platform mobile and web applications with Flutter and modern cloud services.';
      _education.text =
          '• B.Tech in Computer Science & Engineering — MAKAUT (2016 - 2020), DGPA: 8.4\n• Higher Secondary (10+2) Science — WBCHSE (2016), 86%\n• Secondary Examination (10th) — WBBSE (2014), 88%';
      _experience.text =
          '• Senior Mobile App Developer at TechNova Solutions (2022 - Present)\n  - Architected 4 production apps with 100k+ active users.\n  - Reduced app startup latency by 35% using lazy loading and clean state management.\n• Junior Software Developer at CloudByte Labs (2020 - 2022)\n  - Built responsive UI components, REST API integration, and offline-first SQLite sync.';
      _skills.text =
          'Flutter, Dart, Firebase, REST APIs, Git & GitHub, State Management (Riverpod, Bloc), SQLite, UI/UX Design, Problem Solving';
      _languages.text = 'English, Bengali, Hindi';
      _declaration.text =
          'I hereby declare that all the information provided above is true and correct to the best of my knowledge and belief.';
      _previewKey = UniqueKey();
    });
    _persist();
    showJobSnack(
      context,
      '✨ Sample CV data loaded! Tap "Instant Preview" to check.',
    );
  }

  void _clearData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all fields?'),
        content: const Text(
          'Are you sure you want to clear all entered CV information? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _name.clear();
                _title.clear();
                _email.clear();
                _phone.clear();
                _address.clear();
                _dob.clear();
                _father.clear();
                _objective.clear();
                _education.clear();
                _experience.clear();
                _skills.clear();
                _languages.clear();
                _photo = null;
                _previewKey = UniqueKey();
              });
              _persist();
              showJobSnack(context, 'Form cleared');
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  double _calculateCompleteness() {
    const total = 9;
    var filled = 0;
    if (_name.text.trim().isNotEmpty) filled++;
    if (_title.text.trim().isNotEmpty) filled++;
    if (_email.text.trim().isNotEmpty) filled++;
    if (_phone.text.trim().isNotEmpty) filled++;
    if (_address.text.trim().isNotEmpty) filled++;
    if (_objective.text.trim().isNotEmpty) filled++;
    if (_education.text.trim().isNotEmpty) filled++;
    if (_experience.text.trim().isNotEmpty) filled++;
    if (_skills.text.trim().isNotEmpty) filled++;
    return filled / total;
  }

  bool _isSectionDone(int index) {
    switch (index) {
      case 0:
        return _name.text.trim().isNotEmpty &&
            _email.text.trim().isNotEmpty &&
            _phone.text.trim().isNotEmpty;
      case 1:
        return _objective.text.trim().isNotEmpty;
      case 2:
        return _education.text.trim().isNotEmpty;
      case 3:
        return _experience.text.trim().isNotEmpty;
      case 4:
        return _skills.text.trim().isNotEmpty;
      case 5:
        return _declaration.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  void _scrollToSection(int index) {
    final key = _sectionKeys[index];
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
    }
    setState(() => _expanded.add(index));
  }

  void _showTemplateGallery() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'All Templates',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${kCvTemplates.length} designs',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.titleBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Pick a design that fits your role — all are ATS-friendly and print-ready.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.78,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: kCvTemplates.length,
                itemBuilder: (c, i) {
                  final t = kCvTemplates[i];
                  final selected = _template == t.id;
                  return _buildGalleryCard(t, selected);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryCard(CvTemplateInfo t, bool selected) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _template = t.id;
          _previewKey = UniqueKey();
        });
        _persist();
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? t.accentColor : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: t.accentColor.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Center(
                  child: SizedBox(
                    width: 72,
                    height: 92,
                    child: CvTemplateThumbnail(
                      template: t,
                      isSelected: selected,
                      enlarged: true,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Text(
                t.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: selected ? t.primaryColor : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 2),
              child: Text(
                t.subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? t.primaryColor.withValues(alpha: 0.08)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: t.accentColor,
                    )
                  else
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 12,
                      color: Colors.grey.shade500,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    t.badge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: selected ? t.primaryColor : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeTemplate =
        kCvTemplates[_template.clamp(0, kCvTemplates.length - 1)];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CV Builder Studio',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            Text(
              'Professional • ATS ready • 10 templates',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        toolbarHeight: 62,
        actions: [
          IconButton(
            tooltip: 'Load Sample',
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_fix_high_rounded,
                color: AppColors.titleBlue,
                size: 18,
              ),
            ),
            onPressed: _loadSampleData,
          ),
          const SizedBox(width: 2),
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(Icons.more_horiz_rounded, size: 18),
            ),
            onSelected: (val) {
              if (val == 'sample') _loadSampleData();
              if (val == 'clear') _clearData();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'sample',
                child: Row(
                  children: [
                    Icon(Icons.auto_fix_high_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Fill Sample Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Colors.red,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Clear All Fields',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildSegmentedTab(),
          _buildTemplateStrip(activeTemplate),
          Expanded(
            child: _currentTab == 0
                ? _buildFormEditor(activeTemplate)
                : _buildInstantPreview(activeTemplate),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTab() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _segmentButton(
              label: 'Edit CV',
              icon: Icons.edit_note_rounded,
              selected: _currentTab == 0,
              onTap: () => setState(() => _currentTab = 0),
            ),
          ),
          Expanded(
            child: _segmentButton(
              label: 'Preview',
              icon: Icons.visibility_rounded,
              selected: _currentTab == 1,
              badge: 'LIVE',
              onTap: () {
                _persist();
                setState(() {
                  _currentTab = 1;
                  _previewKey = UniqueKey();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentButton({
    required String label,
    required IconData icon,
    required bool selected,
    String? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.titleBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.titleBlue.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : Colors.grey.shade700,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white
                      : AppColors.titleBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: selected ? AppColors.titleBlue : AppColors.titleBlue,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateStrip(CvTemplateInfo active) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Template',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: active.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    active.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _showTemplateGallery,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'View all ${kCvTemplates.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.grid_view_rounded,
                          size: 14,
                          color: Colors.grey.shade700,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: kCvTemplates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final t = kCvTemplates[i];
                final selected = _template == t.id;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _template = t.id;
                      _previewKey = UniqueKey();
                    });
                    _persist();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 96,
                    decoration: BoxDecoration(
                      color: selected
                          ? t.primaryColor.withValues(alpha: 0.06)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? t.accentColor : Colors.grey.shade200,
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: t.accentColor.withValues(alpha: 0.16),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            CvTemplateThumbnail(
                              template: t,
                              isSelected: selected,
                            ),
                            if (selected)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: t.accentColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.name,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: selected ? t.primaryColor : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          t.badge,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormEditor(CvTemplateInfo active) {
    final completeness = _calculateCompleteness();
    final pct = (completeness * 100).toInt();
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            children: [
              _buildProgressHeader(completeness, pct, active),
              const SizedBox(height: 14),
              _buildCategoryNav(),
              const SizedBox(height: 14),
              _buildExpandableSection(
                key: _sectionKeys[0],
                index: 0,
                title: 'Personal Details',
                subtitle: 'Name, role, contact & photo',
                icon: Icons.person_rounded,
                iconColor: const Color(0xFF2563EB),
                gradient: const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                child: Column(
                  children: [
                    _buildPhotoPicker(),
                    const SizedBox(height: 12),
                    _inputField(
                      controller: _name,
                      label: 'Full Name *',
                      hint: 'e.g. Rahul Sarkar',
                      icon: Icons.badge_outlined,
                    ),
                    _inputField(
                      controller: _title,
                      label: 'Professional Title',
                      hint: 'e.g. Software Engineer',
                      icon: Icons.work_outline_rounded,
                    ),
                    _inputField(
                      controller: _email,
                      label: 'Email *',
                      hint: 'rahul.sarkar@example.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _inputField(
                      controller: _phone,
                      label: 'Mobile *',
                      hint: '+91 98765 43210',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    _inputField(
                      controller: _address,
                      label: 'Address',
                      hint: 'Salt Lake, Sector V, Kolkata - 700091',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _inputField(
                            controller: _dob,
                            label: 'DOB',
                            hint: '15 Aug 1998',
                            icon: Icons.cake_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _inputField(
                            controller: _father,
                            label: "Father's Name",
                            hint: 'Bimal Sarkar',
                            icon: Icons.family_restroom_outlined,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildExpandableSection(
                key: _sectionKeys[1],
                index: 1,
                title: 'Career Objective',
                subtitle: 'Your summary in 2-3 lines',
                icon: Icons.flag_rounded,
                iconColor: const Color(0xFFEA580C),
                gradient: const [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                child: Column(
                  children: [
                    _inputField(
                      controller: _objective,
                      label: 'Objective / Summary',
                      hint: 'Describe your strengths and goals...',
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _helperChip(
                            'Fresher',
                            'Enthusiastic graduate seeking entry-level opportunity to apply academic learning and problem-solving skills.',
                            _objective,
                          ),
                          _helperChip(
                            'Experienced',
                            'Results-driven professional with proven expertise in delivery and team collaboration.',
                            _objective,
                          ),
                          _helperChip(
                            'Developer',
                            'Passionate software engineer focused on robust, scalable apps with clean architecture.',
                            _objective,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildExpandableSection(
                key: _sectionKeys[2],
                index: 2,
                title: 'Education',
                subtitle: 'Degrees, boards, years & marks',
                icon: Icons.school_rounded,
                iconColor: const Color(0xFF16A34A),
                gradient: const [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                child: _inputField(
                  controller: _education,
                  label: 'Educational Background',
                  hint:
                      '• B.Tech CSE — MAKAUT (2020), 8.4 CGPA\n• HS (10+2) — WBCHSE (2016), 86%\n• Secondary — WBBSE (2014), 88%',
                  icon: Icons.menu_book_rounded,
                  maxLines: 4,
                ),
              ),
              _buildExpandableSection(
                key: _sectionKeys[3],
                index: 3,
                title: 'Experience',
                subtitle: 'Jobs, internships & projects',
                icon: Icons.business_center_rounded,
                iconColor: const Color(0xFF4F46E5),
                gradient: const [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
                child: _inputField(
                  controller: _experience,
                  label: 'Work Experience',
                  hint:
                      '• Senior Developer @ TechNova (2022 — Present)\n  - Built 4 apps with 100k+ users\n• Junior Developer @ CloudByte (2020 — 2022)',
                  icon: Icons.history_edu_rounded,
                  maxLines: 4,
                ),
              ),
              _buildExpandableSection(
                key: _sectionKeys[4],
                index: 4,
                title: 'Skills & Languages',
                subtitle: 'Tools, tech & spoken languages',
                icon: Icons.psychology_rounded,
                iconColor: const Color(0xFF9333EA),
                gradient: const [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
                child: Column(
                  children: [
                    _inputField(
                      controller: _skills,
                      label: 'Key Skills',
                      hint: 'Flutter, Dart, Firebase, Git, Python...',
                      icon: Icons.code_rounded,
                      maxLines: 2,
                    ),
                    _quickChips(
                      title: 'Quick add:',
                      items: const [
                        'Flutter',
                        'Dart',
                        'Firebase',
                        'Python',
                        'SQL',
                        'Git',
                        'REST APIs',
                        'MS Excel',
                        'Communication',
                      ],
                      controller: _skills,
                    ),
                    const SizedBox(height: 12),
                    _inputField(
                      controller: _languages,
                      label: 'Languages',
                      hint: 'English, Bengali, Hindi',
                      icon: Icons.translate_rounded,
                    ),
                    _quickChips(
                      title: '',
                      items: const ['English', 'Bengali', 'Hindi'],
                      controller: _languages,
                    ),
                  ],
                ),
              ),
              _buildExpandableSection(
                key: _sectionKeys[5],
                index: 5,
                title: 'Declaration',
                subtitle: 'Closing statement for your CV',
                icon: Icons.verified_user_rounded,
                iconColor: const Color(0xFF0D9488),
                gradient: const [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                child: _inputField(
                  controller: _declaration,
                  label: 'Declaration Text',
                  hint: 'I hereby declare that...',
                  icon: Icons.draw_rounded,
                  maxLines: 3,
                ),
              ),
              if (_cv != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: AppColors.pdfBadge,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _cvName ?? 'cv.pdf',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Ready to share • ${kbLabel(_cv!.length)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.titleBlue,
                        ),
                        icon: const Icon(Icons.share_rounded, size: 18),
                        onPressed: () => ShareBytes.share(
                          bytes: _cv!,
                          name: _cvName ?? 'cv.pdf',
                          mime: 'application/pdf',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
        _buildStickyActionBar(active),
      ],
    );
  }

  Widget _buildProgressHeader(
    double completeness,
    int pct,
    CvTemplateInfo active,
  ) {
    final color = pct > 70
        ? const Color(0xFF16A34A)
        : pct > 40
            ? const Color(0xFFF59E0B)
            : const Color(0xFF2563EB);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, active.primaryColor.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  value: completeness,
                  strokeWidth: 5,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile Completeness',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  pct == 100
                      ? '✨ Amazing! Your CV is ready to preview.'
                      : pct > 70
                          ? 'Great progress — just a bit more!'
                          : 'Fill the sections below to improve your CV',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: completeness,
                    minHeight: 5,
                    backgroundColor: Colors.grey.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            icon: const Icon(Icons.auto_fix_high_rounded, size: 14),
            label: const Text('Sample', style: TextStyle(fontSize: 11)),
            onPressed: _loadSampleData,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryNav() {
    const cats = [
      ('Personal', Icons.person_rounded),
      ('Objective', Icons.flag_rounded),
      ('Education', Icons.school_rounded),
      ('Experience', Icons.work_rounded),
      ('Skills', Icons.psychology_rounded),
      ('Declare', Icons.verified_rounded),
    ];
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final done = _isSectionDone(i);
          final expanded = _expanded.contains(i);
          return InkWell(
            onTap: () => _scrollToSection(i),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: expanded ? AppColors.titleBlue : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: expanded ? AppColors.titleBlue : Colors.grey.shade300,
                ),
                boxShadow: done
                    ? [
                        BoxShadow(
                          color:
                              const Color(0xFF16A34A).withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    cats[i].$2,
                    size: 14,
                    color: expanded ? Colors.white : Colors.grey.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cats[i].$1,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: expanded ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                  if (done) ...[
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: Color(0xFF16A34A),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExpandableSection({
    required GlobalKey key,
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<Color> gradient,
    required Widget child,
  }) {
    final expanded = _expanded.contains(index);
    final done = _isSectionDone(index);
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: expanded
              ? iconColor.withValues(alpha: 0.18)
              : Colors.grey.shade200,
          width: expanded ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: expanded ? 0.06 : 0.03),
            blurRadius: expanded ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() {
              if (expanded) {
                _expanded.remove(index);
              } else {
                _expanded.add(index);
              }
            }),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(18),
              bottom: Radius.circular(expanded ? 0 : 18),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(18),
                  bottom: Radius.circular(expanded ? 0 : 18),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (done)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16A34A),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.check_rounded,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      'Done',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: child,
            ),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                  image: _photo == null
                      ? null
                      : DecorationImage(
                          image: MemoryImage(_photo!),
                          fit: BoxFit.cover,
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _photo == null
                    ? Icon(
                        Icons.person_rounded,
                        size: 30,
                        color: Colors.grey.shade400,
                      )
                    : null,
              ),
              if (_photo != null)
                InkWell(
                  onTap: () => setState(() => _photo = null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile Photo',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  _photo == null
                      ? 'Passport size, white background recommended'
                      : 'Tap Change to pick another photo',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.titleBlue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: Icon(
                        _photo == null
                            ? Icons.photo_library_rounded
                            : Icons.swap_horiz_rounded,
                        size: 16,
                      ),
                      label: Text(
                        _photo == null ? 'Upload' : 'Change',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () async {
                        final b = await pickPhoto(context);
                        if (b != null) setState(() => _photo = b);
                      },
                    ),
                    if (_photo == null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Optional',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyActionBar(CvTemplateInfo active) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                  foregroundColor: Colors.grey.shade800,
                ),
                icon: const Icon(Icons.visibility_rounded, size: 18),
                label: const Text(
                  'Preview',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                onPressed: () {
                  _persist();
                  setState(() {
                    _currentTab = 1;
                    _previewKey = UniqueKey();
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: active.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: Text(
                  'Create PDF • ${active.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                onPressed: _saveCvPdf,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstantPreview(CvTemplateInfo active) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: active.primaryColor.withValues(alpha: 0.06),
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Icon(active.icon, size: 16, color: active.accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Preview — ${active.name}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: active.primaryColor,
                      ),
                    ),
                    Text(
                      active.subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  _persist();
                  setState(() => _previewKey = UniqueKey());
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.grey.shade100,
            child: PdfPreview(
              key: _previewKey,
              build: (format) => _generateCurrentPdf(),
              canChangePageFormat: false,
              canChangeOrientation: false,
              allowPrinting: true,
              allowSharing: true,
              maxPageWidth: 560,
              pdfFileName:
                  'CV_${_name.text.trim().isEmpty ? "Resume" : _name.text.trim().replaceAll(" ", "_")}.pdf',
              loadingWidget: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: active.accentColor),
                    const SizedBox(height: 12),
                    Text(
                      'Rendering ${active.name}…',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Edit CV'),
                  onPressed: () => setState(() => _currentTab = 0),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: active.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: const Icon(Icons.save_alt_rounded, size: 18),
                    label: const Text('Save to Device'),
                    onPressed: _saveCvPdf,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 13.5),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.grey.shade700),
          ),
          isDense: true,
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 13,
          ),
          labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.titleBlue,
              width: 1.6,
            ),
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _helperChip(String label, String text, TextEditingController target) {
    return ActionChip(
      label: Text(
        '+ $label',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      onPressed: () {
        target.text = text;
        setState(() {});
      },
    );
  }

  Widget _quickChips({
    required String title,
    required List<String> items,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 2),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: items.map((s) {
            final already = controller.text.toLowerCase().contains(
                  s.toLowerCase(),
                );
            return FilterChip(
              label: Text(
                already ? '✓ $s' : '+ $s',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: already ? Colors.white : Colors.grey.shade800,
                ),
              ),
              selected: already,
              showCheckmark: false,
              backgroundColor: Colors.white,
              selectedColor: AppColors.titleBlue,
              side: BorderSide(
                color: already ? AppColors.titleBlue : Colors.grey.shade300,
              ),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              onSelected: (_) {
                final curr = controller.text.trim();
                if (!already) {
                  controller.text = curr.isEmpty ? s : '$curr, $s';
                } else {
                  // remove
                  final parts = curr
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.toLowerCase() != s.toLowerCase())
                      .toList();
                  controller.text = parts.join(', ');
                }
                setState(() {});
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class CvTemplateThumbnail extends StatelessWidget {
  final CvTemplateInfo template;
  final bool isSelected;
  final bool enlarged;

  const CvTemplateThumbnail({
    super.key,
    required this.template,
    required this.isSelected,
    this.enlarged = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = enlarged ? 72.0 : 42.0;
    final h = enlarged ? 92.0 : 54.0;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(enlarged ? 8 : 4),
        border: Border.all(
          color: isSelected ? template.accentColor : Colors.grey.shade300,
          width: isSelected ? 1.5 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 3,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildLayout(),
    );
  }

  Widget _buildLayout() {
    switch (template.id) {
      case 0:
        return Row(
          children: [
            Container(width: enlarged ? 22 : 13, color: template.primaryColor),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(enlarged ? 4 : 2.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: enlarged ? 5 : 3,
                      width: enlarged ? 30 : 18,
                      color: template.primaryColor,
                    ),
                    SizedBox(height: enlarged ? 3 : 2),
                    Container(
                      height: 1.5,
                      width: enlarged ? 36 : 22,
                      color: Colors.grey.shade300,
                    ),
                    SizedBox(height: enlarged ? 3 : 2),
                    Container(
                      height: 1.5,
                      width: enlarged ? 26 : 16,
                      color: Colors.grey.shade300,
                    ),
                    SizedBox(height: enlarged ? 4 : 3),
                    Container(
                      height: enlarged ? 3 : 2,
                      width: enlarged ? 20 : 12,
                      color: template.accentColor,
                    ),
                    SizedBox(height: enlarged ? 3 : 2),
                    Container(
                      height: 1.5,
                      width: enlarged ? 34 : 20,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 1:
        return Column(
          children: [
            Container(
              height: enlarged ? 22 : 13,
              color: template.primaryColor,
              padding: EdgeInsets.all(enlarged ? 4 : 2),
              alignment: Alignment.centerLeft,
              child: Container(
                height: enlarged ? 3 : 2,
                width: enlarged ? 26 : 16,
                color: template.accentColor,
              ),
            ),
            Container(height: 1.5, color: template.accentColor),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(enlarged ? 4 : 2.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: enlarged ? 3 : 2,
                      width: enlarged ? 24 : 14,
                      color: template.primaryColor,
                    ),
                    SizedBox(height: enlarged ? 3 : 2),
                    Container(
                      height: 1.5,
                      width: enlarged ? 48 : 28,
                      color: Colors.grey.shade300,
                    ),
                    SizedBox(height: enlarged ? 4 : 3),
                    Container(
                      height: enlarged ? 3 : 2,
                      width: enlarged ? 26 : 16,
                      color: template.primaryColor,
                    ),
                    SizedBox(height: enlarged ? 3 : 2),
                    Container(
                      height: 1.5,
                      width: enlarged ? 40 : 24,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 2:
        return Padding(
          padding: EdgeInsets.all(enlarged ? 4 : 2.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: enlarged ? 8 : 5,
                    height: enlarged ? 8 : 5,
                    color: template.primaryColor,
                  ),
                  SizedBox(width: enlarged ? 3 : 2),
                  Container(
                    height: enlarged ? 4 : 2.5,
                    width: enlarged ? 26 : 16,
                    color: template.primaryColor,
                  ),
                ],
              ),
              SizedBox(height: enlarged ? 3 : 2),
              Row(
                children: [
                  Container(
                    height: enlarged ? 3 : 2,
                    width: enlarged ? 10 : 6,
                    color: template.accentColor.withValues(alpha: 0.5),
                  ),
                  SizedBox(width: enlarged ? 3 : 2),
                  Container(
                    height: enlarged ? 3 : 2,
                    width: enlarged ? 14 : 8,
                    color: template.accentColor.withValues(alpha: 0.5),
                  ),
                  SizedBox(width: enlarged ? 3 : 2),
                  Container(
                    height: enlarged ? 3 : 2,
                    width: enlarged ? 10 : 6,
                    color: template.accentColor.withValues(alpha: 0.5),
                  ),
                ],
              ),
              SizedBox(height: enlarged ? 4 : 3),
              Container(
                height: 1.5,
                width: enlarged ? 46 : 28,
                color: Colors.grey.shade300,
              ),
              SizedBox(height: enlarged ? 3 : 2),
              Container(
                height: 1.5,
                width: enlarged ? 36 : 22,
                color: Colors.grey.shade300,
              ),
              SizedBox(height: enlarged ? 4 : 3),
              Container(
                height: enlarged ? 3 : 2,
                width: enlarged ? 20 : 12,
                color: template.primaryColor,
              ),
              SizedBox(height: enlarged ? 3 : 2),
              Container(
                height: 1.5,
                width: enlarged ? 44 : 26,
                color: Colors.grey.shade300,
              ),
            ],
          ),
        );
      case 3:
        return Column(
          children: [
            Container(
              height: enlarged ? 24 : 14,
              color: template.primaryColor,
              padding: EdgeInsets.all(enlarged ? 4 : 2),
              child: Row(
                children: [
                  Container(
                    width: enlarged ? 12 : 7,
                    height: enlarged ? 12 : 7,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: enlarged ? 3 : 2),
                  Container(
                    height: enlarged ? 3 : 2,
                    width: enlarged ? 24 : 14,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(enlarged ? 4 : 2.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: enlarged ? 3 : 2,
                      width: enlarged ? 20 : 12,
                      color: template.accentColor,
                    ),
                    SizedBox(height: enlarged ? 3 : 2),
                    Container(
                      height: 1.5,
                      width: enlarged ? 44 : 26,
                      color: Colors.grey.shade300,
                    ),
                    SizedBox(height: enlarged ? 4 : 3),
                    Container(
                      height: enlarged ? 3 : 2,
                      width: enlarged ? 24 : 14,
                      color: template.accentColor,
                    ),
                    SizedBox(height: enlarged ? 3 : 2),
                    Container(
                      height: 1.5,
                      width: enlarged ? 36 : 22,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 4:
        return Padding(
          padding: EdgeInsets.all(enlarged ? 4 : 2),
          child: Column(
            children: [
              Center(
                child: Container(
                  height: enlarged ? 3 : 2,
                  width: enlarged ? 30 : 18,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: enlarged ? 3 : 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 1.5,
                        width: enlarged ? 20 : 12,
                        color: Colors.black,
                      ),
                      SizedBox(height: enlarged ? 2 : 1),
                      Container(
                        height: 1,
                        width: enlarged ? 26 : 16,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                  Container(
                    width: enlarged ? 12 : 7,
                    height: enlarged ? 16 : 9,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 0.5),
                    ),
                  ),
                ],
              ),
              SizedBox(height: enlarged ? 3 : 2),
              Container(height: 0.5, color: Colors.black),
              SizedBox(height: enlarged ? 3 : 2),
              Container(
                height: enlarged ? 20 : 12,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400, width: 0.5),
                ),
                child: Column(
                  children: [
                    Container(
                      height: enlarged ? 4 : 2.5,
                      color: Colors.grey.shade200,
                    ),
                    const Spacer(),
                    Container(height: 0.5, color: Colors.grey.shade300),
                    const Spacer(),
                  ],
                ),
              ),
            ],
          ),
        );
      case 5:
        return Padding(
          padding: EdgeInsets.all(enlarged ? 5 : 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: enlarged ? 5 : 3,
                width: enlarged ? 30 : 18,
                color: Colors.black,
              ),
              SizedBox(height: enlarged ? 3 : 2),
              Container(
                height: 0.8,
                width: enlarged ? 44 : 26,
                color: Colors.grey.shade600,
              ),
              SizedBox(height: enlarged ? 3 : 2),
              Container(height: 0.8, color: Colors.black),
              SizedBox(height: enlarged ? 3 : 2),
              Container(
                height: 1.5,
                width: enlarged ? 24 : 14,
                color: Colors.black,
              ),
              SizedBox(height: enlarged ? 2 : 1.5),
              Container(
                height: 1,
                width: enlarged ? 40 : 24,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: enlarged ? 3 : 2),
              Container(
                height: 1.5,
                width: enlarged ? 26 : 16,
                color: Colors.black,
              ),
              SizedBox(height: enlarged ? 2 : 1.5),
              Container(
                height: 1,
                width: enlarged ? 36 : 22,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        );
      case 6:
        return Column(
          children: [
            Container(height: enlarged ? 24 : 14, color: template.primaryColor),
            Container(height: 1.5, color: template.accentColor),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(enlarged ? 4 : 2.5),
                child: Row(
                  children: [
                    Container(
                      width: enlarged ? 18 : 10,
                      color: Colors.grey.shade100,
                    ),
                    SizedBox(width: enlarged ? 4 : 3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: enlarged ? 3 : 2,
                            width: enlarged ? 20 : 12,
                            color: template.primaryColor,
                          ),
                          SizedBox(height: enlarged ? 2 : 1.5),
                          Container(
                            height: 1.2,
                            width: enlarged ? 26 : 16,
                            color: Colors.grey.shade300,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 7:
        return Row(
          children: [
            Container(width: enlarged ? 5 : 3, color: template.primaryColor),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(enlarged ? 4 : 2.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: enlarged ? 4 : 2.5,
                      width: enlarged ? 26 : 16,
                      color: template.primaryColor,
                    ),
                    SizedBox(height: enlarged ? 2 : 1.5),
                    Container(height: 0.8, color: template.primaryColor),
                    SizedBox(height: enlarged ? 3 : 2),
                    Container(
                      height: enlarged ? 10 : 6,
                      decoration: BoxDecoration(
                        color: template.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    SizedBox(height: enlarged ? 3 : 2),
                    Container(
                      height: 1.2,
                      width: enlarged ? 36 : 22,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 8:
        return Row(
          children: [
            Container(
              width: enlarged ? 22 : 13,
              color: const Color(0xFFF1F5F9),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(enlarged ? 4 : 2.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: enlarged ? 4 : 2.5,
                      width: enlarged ? 26 : 16,
                      color: template.primaryColor,
                    ),
                    SizedBox(height: enlarged ? 2 : 1.5),
                    Container(
                      height: 1,
                      width: enlarged ? 30 : 18,
                      color: template.accentColor,
                    ),
                    SizedBox(height: enlarged ? 3 : 2),
                    Container(
                      height: 1.2,
                      width: enlarged ? 26 : 16,
                      color: Colors.grey.shade300,
                    ),
                    SizedBox(height: enlarged ? 2 : 1.5),
                    Container(
                      height: 1.2,
                      width: enlarged ? 24 : 14,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 9:
      default:
        return Padding(
          padding: EdgeInsets.all(enlarged ? 4 : 2.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: enlarged ? 8 : 5,
                    height: enlarged ? 8 : 5,
                    decoration: BoxDecoration(
                      color: template.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: enlarged ? 3 : 2),
                  Container(
                    height: enlarged ? 4 : 2.5,
                    width: enlarged ? 26 : 16,
                    color: Colors.grey.shade800,
                  ),
                ],
              ),
              SizedBox(height: enlarged ? 3 : 2),
              Container(height: 1, color: template.accentColor),
              SizedBox(height: enlarged ? 3 : 2),
              Container(
                height: 1.5,
                width: enlarged ? 24 : 14,
                color: template.primaryColor,
              ),
              SizedBox(height: enlarged ? 2 : 1.5),
              Container(
                height: 1.2,
                width: enlarged ? 40 : 24,
                color: Colors.grey.shade300,
              ),
              SizedBox(height: enlarged ? 3 : 2),
              Container(
                height: 1.5,
                width: enlarged ? 20 : 12,
                color: template.primaryColor,
              ),
              SizedBox(height: enlarged ? 2 : 1.5),
              Container(
                height: 1.2,
                width: enlarged ? 34 : 20,
                color: Colors.grey.shade300,
              ),
            ],
          ),
        );
    }
  }
}
