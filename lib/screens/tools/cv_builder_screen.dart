import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/cv_template_info.dart';
import '../../models/saved_doc.dart';
import '../../services/pdf_service.dart';
import '../../services/save_out.dart';
import '../../services/share_bytes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pdf_preview_page.dart';
import '../../widgets/tool_ui.dart';

class CvBuilderScreen extends StatefulWidget {
  const CvBuilderScreen({super.key});

  @override
  State<CvBuilderScreen> createState() => _CvBuilderScreenState();
}

class _CvBuilderScreenState extends State<CvBuilderScreen> {
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
        'I hereby declare that the above information is true to the best of my knowledge.',
  );
  Uint8List? _photo;
  Uint8List? _cv;
  String? _cvName;
  bool _busy = false;
  int _template = 0;

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

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      await _persist();
      final bytes = await PdfService.createCv(
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
      showJobSnack(context, 'CV saved · ${kbLabel(bytes.length)}');
    } catch (e) {
      if (!mounted) return;
      showJobSnack(context, 'Could not create CV: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTemplate = kCvTemplates[_template.clamp(0, kCvTemplates.length - 1)];

    return Scaffold(
      appBar: AppBar(title: const Text('CV Builder')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HintBanner(
            '10 premium templates available. Text stays on this device. No account.',
            color: AppColors.imageToPdfCard,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionLabel('Choose Template (10 Styles)'),
              Text(
                '${_template + 1}/10',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kCvTemplates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final t = kCvTemplates[i];
                final selected = _template == t.id;
                return InkWell(
                  onTap: () => setState(() => _template = t.id),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 135,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selected
                          ? t.primaryColor.withOpacity(0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? t.accentColor : Colors.grey.shade300,
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: t.accentColor.withOpacity(0.18),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: t.primaryColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                t.badge,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (selected)
                              Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: t.accentColor,
                              )
                            else
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: t.accentColor,
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        Icon(t.icon, size: 22, color: t.primaryColor),
                        const SizedBox(height: 4),
                        Text(
                          t.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: selected ? t.primaryColor : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: activeTemplate.primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: activeTemplate.accentColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  activeTemplate.icon,
                  size: 16,
                  color: activeTemplate.accentColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${activeTemplate.name}: ${activeTemplate.subtitle}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 28,
              backgroundImage: _photo == null ? null : MemoryImage(_photo!),
              child: _photo == null ? const Icon(Icons.person) : null,
            ),
            title: const Text('Photo (optional)'),
            subtitle: Text(
              _photo == null ? 'No photo picked' : 'Photo attached',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_photo != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _photo = null),
                  ),
                TextButton(
                  onPressed: () async {
                    final b = await pickPhoto(context);
                    if (b != null) setState(() => _photo = b);
                  },
                  child: const Text('Pick'),
                ),
              ],
            ),
          ),
          _field(_name, 'Full name'),
          _field(_title, 'Job title / Designation (e.g. Software Engineer, Executive)'),
          _field(_email, 'Email'),
          _field(_phone, 'Phone'),
          _field(_address, 'Address', maxLines: 2),
          _field(_dob, 'Date of birth (e.g. 15 Aug 1998)'),
          _field(_father, "Father's name"),
          _field(_objective, 'Objective / Summary', maxLines: 3),
          _field(_education, 'Education (Degrees, Boards, Years, Marks)', maxLines: 4),
          _field(_experience, 'Experience & Projects', maxLines: 4),
          _field(_skills, 'Skills (comma or newline separated)', maxLines: 2),
          _field(_languages, 'Languages (e.g. English, Bengali, Hindi)'),
          _field(_declaration, 'Declaration', maxLines: 3),
          const SizedBox(height: 8),
          PrimaryJobButton(
            label: 'Create CV PDF (${activeTemplate.name})',
            onPressed: _create,
            busy: _busy,
          ),
          if (_cv != null) ...[
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(
                Icons.picture_as_pdf,
                color: AppColors.pdfBadge,
              ),
              title: Text(_cvName ?? 'cv.pdf'),
              subtitle: const Text('Tap to view or share'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_rounded),
                    onPressed: () => PdfPreviewPage.open(
                      context,
                      bytes: _cv!,
                      name: _cvName ?? 'cv.pdf',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
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
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
