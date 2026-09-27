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
  // Navigation: 0 = Form Editor, 1 = Live Preview
  int _currentTab = 0;
  Key _previewKey = UniqueKey();

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
    text: 'I hereby declare that the above information is true to the best of my knowledge and belief.',
  );

  Uint8List? _photo;
  Uint8List? _cv;
  String? _cvName;
  bool _busy = false;
  int _template = 0;
  String _selectedCategory = 'All';

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
    setState(() => _busy = true);
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
    } finally {
      if (mounted) setState(() => _busy = false);
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
      _objective.text = 'Passionate software engineer with 3+ years of experience building scalable, high-performance cross-platform mobile and web applications with Flutter and modern cloud services.';
      _education.text = '• B.Tech in Computer Science & Engineering — MAKAUT (2016 - 2020), DGPA: 8.4\n• Higher Secondary (10+2) Science — WBCHSE (2016), 86%\n• Secondary Examination (10th) — WBBSE (2014), 88%';
      _experience.text = '• Senior Mobile App Developer at TechNova Solutions (2022 - Present)\n  - Architected 4 production apps with 100k+ active users.\n  - Reduced app startup latency by 35% using lazy loading and clean state management.\n• Junior Software Developer at CloudByte Labs (2020 - 2022)\n  - Built responsive UI components, REST API integration, and offline-first SQLite sync.';
      _skills.text = 'Flutter, Dart, Firebase, REST APIs, Git & GitHub, State Management (Riverpod, Bloc), SQLite, UI/UX Design, Problem Solving';
      _languages.text = 'English, Bengali, Hindi';
      _declaration.text = 'I hereby declare that all the information provided above is true and correct to the best of my knowledge and belief.';
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

  @override
  Widget build(BuildContext context) {
    final activeTemplate =
        kCvTemplates[_template.clamp(0, kCvTemplates.length - 1)];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'CV Builder Studio',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Load Sample CV',
            icon: const Icon(
              Icons.auto_fix_high_rounded,
              color: AppColors.titleBlue,
            ),
            onPressed: _loadSampleData,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
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
        ],
      ),
      body: Column(
        children: [
          // Segmented Navigation: Form Editor vs Instant Preview
          _buildSegmentedTab(),

          // Template Selector Bar (ALWAYS VISIBLE in both Edit and Preview!)
          _buildTemplateSelector(activeTemplate),

          // Main View (Tab 0: Form Editor, Tab 1: Instant Preview)
          Expanded(
            child: _currentTab == 0
                ? _buildFormEditor(activeTemplate)
                : _buildInstantPreview(activeTemplate),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Segmented Control (Edit Form vs Instant Preview)
  // ---------------------------------------------------------------------------
  Widget _buildSegmentedTab() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _currentTab = 0),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _currentTab == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _currentTab == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 18,
                      color: _currentTab == 0
                          ? AppColors.titleBlue
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Form Editor',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _currentTab == 0
                            ? AppColors.titleBlue
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                _persist();
                setState(() {
                  _currentTab = 1;
                  _previewKey = UniqueKey();
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _currentTab == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _currentTab == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.visibility_rounded,
                      size: 18,
                      color: _currentTab == 1
                          ? AppColors.titleBlue
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Instant Preview',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _currentTab == 1
                            ? AppColors.titleBlue
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.titleBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.titleBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Template Carousel with Wireframe Visuals
  // ---------------------------------------------------------------------------
  Widget _buildTemplateSelector(CvTemplateInfo activeTemplate) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Choose Template',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.bodyText,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_template + 1}/10',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.titleBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  activeTemplate.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: activeTemplate.accentColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Horizontal Carousel of 10 Templates with Wireframe Thumbnails
          SizedBox(
            height: 98,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: kCvTemplates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final t = kCvTemplates[i];
                final selected = _template == t.id;

                return InkWell(
                  onTap: () {
                    _persist();
                    setState(() {
                      _template = t.id;
                      _previewKey = UniqueKey();
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 110,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: selected
                          ? t.primaryColor.withOpacity(0.06)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? t.accentColor : Colors.grey.shade200,
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: t.accentColor.withOpacity(0.18),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CvTemplateThumbnail(
                              template: t,
                              isSelected: selected,
                            ),
                            const SizedBox(width: 6),
                            if (selected)
                              Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: t.accentColor,
                              )
                            else
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: t.accentColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.name,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: selected ? t.primaryColor : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          t.badge,
                          style: TextStyle(
                            fontSize: 8.5,
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

  // ---------------------------------------------------------------------------
  // TAB 0: Form Editor (Modern Categorized Cards)
  // ---------------------------------------------------------------------------
  Widget _buildFormEditor(CvTemplateInfo activeTemplate) {
    final completeness = _calculateCompleteness();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // Profile Completeness Progress
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        size: 18,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Profile Completeness: ${(completeness * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.auto_fix_high_rounded, size: 14),
                    label: const Text(
                      'Sample CV',
                      style: TextStyle(fontSize: 11),
                    ),
                    onPressed: _loadSampleData,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: completeness,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    completeness > 0.7
                        ? AppColors.successChip
                        : (completeness > 0.4 ? Colors.orange : Colors.blue),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Section 1: Personal Information
        _buildSectionCard(
          title: 'Personal Information',
          subtitle: 'Name, professional role, contact and photo',
          icon: Icons.person_rounded,
          iconColor: Colors.blue.shade700,
          children: [
            // Photo Picker Row
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.blue.shade50,
                    backgroundImage: _photo == null
                        ? null
                        : MemoryImage(_photo!),
                    child: _photo == null
                        ? Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.blue.shade700,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Candidate Photograph',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _photo == null
                              ? 'Optional, passport size'
                              : 'Photo attached',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_photo != null)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _photo = null),
                    ),
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.photo_library_rounded, size: 14),
                    label: Text(_photo == null ? 'Upload' : 'Change'),
                    onPressed: () async {
                      final b = await pickPhoto(context);
                      if (b != null) setState(() => _photo = b);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _inputField(
              controller: _name,
              label: 'Full Name *',
              hint: 'e.g. Rahul Sarkar',
              icon: Icons.badge_outlined,
            ),
            _inputField(
              controller: _title,
              label: 'Job Title / Designation',
              hint: 'e.g. Software Engineer / Assistant Manager',
              icon: Icons.work_outline_rounded,
            ),
            _inputField(
              controller: _email,
              label: 'Email Address *',
              hint: 'e.g. rahul.sarkar@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            _inputField(
              controller: _phone,
              label: 'Mobile Number *',
              hint: 'e.g. +91 98765 43210',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            _inputField(
              controller: _address,
              label: 'Address / Location',
              hint: 'e.g. Salt Lake, Sector V, Kolkata, WB - 700091',
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),
            Row(
              children: [
                Expanded(
                  child: _inputField(
                    controller: _dob,
                    label: 'Date of Birth',
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
        const SizedBox(height: 14),

        // Section 2: Career Objective / Summary
        _buildSectionCard(
          title: 'Career Objective / Summary',
          subtitle: 'A brief summary of your professional goals and strengths',
          icon: Icons.flag_rounded,
          iconColor: Colors.deepOrange,
          children: [
            _inputField(
              controller: _objective,
              label: 'Professional Summary / Objective',
              hint:
                  'Describe your expertise, experience, and value you bring...',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _templateHelperChip(
                  label: '+ Fresher Objective',
                  onTap: () {
                    _objective.text = 'Enthusiastic and motivated graduate seeking an entry-level opportunity to apply academic learning and problem-solving skills in a dynamic environment.';
                    setState(() {});
                  },
                ),
                _templateHelperChip(
                  label: '+ Experienced Summary',
                  onTap: () {
                    _objective.text = 'Results-driven professional with proven expertise in project delivery, operational excellence, and cross-functional team collaboration.';
                    setState(() {});
                  },
                ),
                _templateHelperChip(
                  label: '+ Tech / Developer',
                  onTap: () {
                    _objective.text = 'Passionate software engineer focused on building robust, scalable applications with clean architecture and modern development practices.';
                    setState(() {});
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Section 3: Academic Qualifications
        _buildSectionCard(
          title: 'Education & Qualifications',
          subtitle: 'Degrees, Universities/Boards, passing years and marks',
          icon: Icons.school_rounded,
          iconColor: Colors.green.shade700,
          children: [
            _inputField(
              controller: _education,
              label: 'Educational Background (Degrees / Boards / Marks)',
              hint: '• B.Tech in CSE — MAKAUT (2020), 8.4 CGPA\n• Higher Secondary (10+2) — WBCHSE (2016), 86%\n• Secondary (10th) — WBBSE (2014), 88%',
              icon: Icons.menu_book_rounded,
              maxLines: 4,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Section 4: Work Experience & Projects
        _buildSectionCard(
          title: 'Experience & Projects',
          subtitle:
              'Past employment, internships, responsibilities, or key projects',
          icon: Icons.business_center_rounded,
          iconColor: Colors.indigo.shade700,
          children: [
            _inputField(
              controller: _experience,
              label: 'Work Experience / Internships',
              hint: '• Software Engineer at ABC Tech (2022 - Present)\n  - Led core feature development and reduced latency by 30%.\n• Junior Developer at XYZ Corp (2020 - 2022)',
              icon: Icons.history_edu_rounded,
              maxLines: 4,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Section 5: Key Skills & Languages
        _buildSectionCard(
          title: 'Skills & Languages',
          subtitle: 'Technical skills, tools, and spoken languages',
          icon: Icons.psychology_rounded,
          iconColor: Colors.purple.shade700,
          children: [
            _inputField(
              controller: _skills,
              label: 'Key Skills (comma or newline separated)',
              hint: 'Flutter, Dart, Firebase, Git, Python, Problem Solving',
              icon: Icons.code_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 4),
            const Text(
              'Quick Add Skill:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children:
                  [
                    'Flutter',
                    'Dart',
                    'Firebase',
                    'Python',
                    'SQL',
                    'Git',
                    'REST APIs',
                    'MS Excel',
                    'Communication',
                  ].map((s) {
                    return ActionChip(
                      label: Text(
                        '+ $s',
                        style: const TextStyle(fontSize: 10.5),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        final curr = _skills.text.trim();
                        if (!curr.toLowerCase().contains(s.toLowerCase())) {
                          _skills.text = curr.isEmpty ? s : '$curr, $s';
                          setState(() {});
                        }
                      },
                    );
                  }).toList(),
            ),
            const SizedBox(height: 12),
            _inputField(
              controller: _languages,
              label: 'Languages Known',
              hint: 'e.g. English, Bengali, Hindi',
              icon: Icons.translate_rounded,
            ),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: ['English', 'Bengali', 'Hindi'].map((l) {
                return ActionChip(
                  label: Text('+ $l', style: const TextStyle(fontSize: 10.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    final curr = _languages.text.trim();
                    if (!curr.toLowerCase().contains(l.toLowerCase())) {
                      _languages.text = curr.isEmpty ? l : '$curr, $l';
                      setState(() {});
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Section 6: Declaration
        _buildSectionCard(
          title: 'Declaration & Signature',
          subtitle: 'Formal declaration statement printed at the bottom',
          icon: Icons.verified_user_rounded,
          iconColor: Colors.teal.shade700,
          children: [
            _inputField(
              controller: _declaration,
              label: 'Declaration Statement',
              hint: 'I hereby declare that...',
              icon: Icons.draw_rounded,
              maxLines: 3,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Action Buttons Row
        Row(
          children: [
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.titleBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.visibility_rounded, size: 20),
                label: const Text(
                  'Instant Live Preview',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(
                    color: AppColors.titleBlue,
                    width: 1.5,
                  ),
                ),
                icon: const Icon(
                  Icons.download_rounded,
                  color: AppColors.titleBlue,
                  size: 20,
                ),
                label: const Text(
                  'Save PDF',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.titleBlue,
                  ),
                ),
                onPressed: _saveCvPdf,
              ),
            ),
          ],
        ),

        if (_cv != null) ...[
          const SizedBox(height: 14),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            leading: const Icon(
              Icons.picture_as_pdf_rounded,
              color: AppColors.pdfBadge,
            ),
            title: Text(
              _cvName ?? 'cv.pdf',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Saved to your device'),
            trailing: IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: () => ShareBytes.share(
                bytes: _cv!,
                name: _cvName ?? 'cv.pdf',
                mime: 'application/pdf',
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: Instant Live Preview with In-Place Switching & Zoom
  // ---------------------------------------------------------------------------
  Widget _buildInstantPreview(CvTemplateInfo activeTemplate) {
    return Column(
      children: [
        // Live Preview Top Info Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: activeTemplate.primaryColor.withOpacity(0.06),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    activeTemplate.icon,
                    size: 16,
                    color: activeTemplate.accentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Previewing: ${activeTemplate.name}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: activeTemplate.primaryColor,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Refresh', style: TextStyle(fontSize: 11)),
                onPressed: () {
                  _persist();
                  setState(() => _previewKey = UniqueKey());
                },
              ),
            ],
          ),
        ),

        // Live PDF Rendering Engine
        Expanded(
          child: PdfPreview(
            key: _previewKey,
            build: (format) => _generateCurrentPdf(),
            canChangePageFormat: false,
            canChangeOrientation: false,
            allowPrinting: true,
            allowSharing: true,
            maxPageWidth: 540,
            pdfFileName:
                'CV_${_name.text.trim().isEmpty ? "Resume" : _name.text.trim().replaceAll(" ", "_")}.pdf',
            loadingWidget: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: activeTemplate.accentColor),
                  const SizedBox(height: 12),
                  Text(
                    'Rendering ${activeTemplate.name} preview...',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom Action Bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Edit Form'),
                onPressed: () => setState(() => _currentTab = 0),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryButton,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.save_alt_rounded, size: 18),
                  label: Text('Save PDF (${activeTemplate.name})'),
                  onPressed: _saveCvPdf,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helper UI Widgets
  // ---------------------------------------------------------------------------
  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.bodyText,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
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
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade600),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          labelStyle: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          hintStyle: TextStyle(fontSize: 11.5, color: Colors.grey.shade400),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.titleBlue,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _templateHelperChip({
    required String label,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
      ),
      backgroundColor: Colors.grey.shade100,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onPressed: onTap,
    );
  }
}

// -----------------------------------------------------------------------------
// Miniature Wireframe Thumbnail for each Template
// -----------------------------------------------------------------------------
class CvTemplateThumbnail extends StatelessWidget {
  final CvTemplateInfo template;
  final bool isSelected;

  const CvTemplateThumbnail({
    super.key,
    required this.template,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isSelected ? template.accentColor : Colors.grey.shade300,
          width: isSelected ? 1.5 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
      case 0: // Sidebar
        return Row(
          children: [
            Container(width: 13, color: template.primaryColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(2.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 3,
                      width: 18,
                      color: template.primaryColor,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: 1.5,
                      width: 22,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: 1.5,
                      width: 16,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 3),
                    Container(
                      height: 2,
                      width: 12,
                      color: template.accentColor,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: 1.5,
                      width: 20,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 1: // Executive Navy
        return Column(
          children: [
            Container(
              height: 13,
              color: template.primaryColor,
              padding: const EdgeInsets.all(2),
              alignment: Alignment.centerLeft,
              child: Container(
                height: 2,
                width: 16,
                color: template.accentColor,
              ),
            ),
            Container(height: 1.5, color: template.accentColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(2.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 2,
                      width: 14,
                      color: template.primaryColor,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: 1.5,
                      width: 28,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 3),
                    Container(
                      height: 2,
                      width: 16,
                      color: template.primaryColor,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: 1.5,
                      width: 24,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 2: // Tech Indigo
        return Padding(
          padding: const EdgeInsets.all(2.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 5, height: 5, color: template.primaryColor),
                  const SizedBox(width: 2),
                  Container(
                    height: 2.5,
                    width: 16,
                    color: template.primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    height: 2,
                    width: 6,
                    color: template.accentColor.withOpacity(0.5),
                  ),
                  const SizedBox(width: 2),
                  Container(
                    height: 2,
                    width: 8,
                    color: template.accentColor.withOpacity(0.5),
                  ),
                  const SizedBox(width: 2),
                  Container(
                    height: 2,
                    width: 6,
                    color: template.accentColor.withOpacity(0.5),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Container(height: 1.5, width: 28, color: Colors.grey.shade300),
              const SizedBox(height: 2),
              Container(height: 1.5, width: 22, color: Colors.grey.shade300),
              const SizedBox(height: 3),
              Container(height: 2, width: 12, color: template.primaryColor),
              const SizedBox(height: 2),
              Container(height: 1.5, width: 26, color: Colors.grey.shade300),
            ],
          ),
        );
      case 3: // Creative Emerald
        return Column(
          children: [
            Container(
              height: 14,
              color: template.primaryColor,
              padding: const EdgeInsets.all(2),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Container(height: 2, width: 14, color: Colors.white),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(2.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 2,
                      width: 12,
                      color: template.accentColor,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: 1.5,
                      width: 26,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 3),
                    Container(
                      height: 2,
                      width: 14,
                      color: template.accentColor,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: 1.5,
                      width: 22,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 4: // Indian Bio-Data
        return Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            children: [
              Center(
                child: Container(height: 2, width: 18, color: Colors.black),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 1.5, width: 12, color: Colors.black),
                      const SizedBox(height: 1),
                      Container(
                        height: 1,
                        width: 16,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                  Container(
                    width: 7,
                    height: 9,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Container(height: 0.5, color: Colors.black),
              const SizedBox(height: 2),
              Container(
                height: 12,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400, width: 0.5),
                ),
                child: Column(
                  children: [
                    Container(height: 2.5, color: Colors.grey.shade200),
                    const Spacer(),
                    Container(height: 0.5, color: Colors.grey.shade300),
                    const Spacer(),
                  ],
                ),
              ),
            ],
          ),
        );
      case 5: // Minimalist Clean
        return Padding(
          padding: const EdgeInsets.all(3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 3, width: 18, color: Colors.black),
              const SizedBox(height: 2),
              Container(height: 0.8, width: 26, color: Colors.grey.shade600),
              const SizedBox(height: 2),
              Container(height: 0.8, color: Colors.black),
              const SizedBox(height: 2),
              Container(height: 1.5, width: 14, color: Colors.black),
              const SizedBox(height: 1.5),
              Container(height: 1, width: 24, color: Colors.grey.shade400),
              const SizedBox(height: 2),
              Container(height: 1.5, width: 16, color: Colors.black),
              const SizedBox(height: 1.5),
              Container(height: 1, width: 22, color: Colors.grey.shade400),
            ],
          ),
        );
      case 6: // Charcoal Banner
        return Column(
          children: [
            Container(height: 14, color: template.primaryColor),
            Container(height: 1.5, color: template.accentColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(2.5),
                child: Row(
                  children: [
                    Container(width: 10, color: Colors.grey.shade100),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 2,
                            width: 12,
                            color: template.primaryColor,
                          ),
                          const SizedBox(height: 1.5),
                          Container(
                            height: 1.2,
                            width: 16,
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
      case 7: // Royal Burgundy
        return Row(
          children: [
            Container(width: 3, color: template.primaryColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(2.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 2.5,
                      width: 16,
                      color: template.primaryColor,
                    ),
                    const SizedBox(height: 1.5),
                    Container(height: 0.8, color: template.primaryColor),
                    const SizedBox(height: 2),
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: template.accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: 1.2,
                      width: 22,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 8: // Split Slate
        return Row(
          children: [
            Container(width: 13, color: const Color(0xFFF1F5F9)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(2.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 2.5,
                      width: 16,
                      color: template.primaryColor,
                    ),
                    const SizedBox(height: 1.5),
                    Container(
                      height: 1,
                      width: 18,
                      color: template.accentColor,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: 1.2,
                      width: 16,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 1.5),
                    Container(
                      height: 1.2,
                      width: 14,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 9: // Nordic Frost
      default:
        return Padding(
          padding: const EdgeInsets.all(2.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: template.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Container(
                    height: 2.5,
                    width: 16,
                    color: Colors.grey.shade800,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Container(height: 1, color: template.accentColor),
              const SizedBox(height: 2),
              Container(height: 1.5, width: 14, color: template.primaryColor),
              const SizedBox(height: 1.5),
              Container(height: 1.2, width: 24, color: Colors.grey.shade300),
              const SizedBox(height: 2),
              Container(height: 1.5, width: 12, color: template.primaryColor),
              const SizedBox(height: 1.5),
              Container(height: 1.2, width: 20, color: Colors.grey.shade300),
            ],
          ),
        );
    }
  }
}
