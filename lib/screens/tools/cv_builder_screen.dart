import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    text: 'I hereby declare that the above information is true to the best of my knowledge.',
  );
  Uint8List? _photo;
  Uint8List? _cv;
  String? _cvName;
  bool _busy = false;
  int _template = 0;

  static const _keys = {
    'name': 'cv_name',
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
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _name.text = p.getString(_keys['name']!) ?? '';
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
    if (mounted) setState(() {});
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keys['name']!, _name.text);
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
  }

  @override
  void dispose() {
    _name.dispose();
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
    return Scaffold(
      appBar: AppBar(title: const Text('CV Builder')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const HintBanner(
            'A simple local PDF. Text stays on this phone. No account.',
            color: AppColors.imageToPdfCard,
          ),
          const SizedBox(height: 12),
          const SectionLabel('Template'),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Classic'),
                selected: _template == 0,
                onSelected: (_) => setState(() => _template = 0),
              ),
              ChoiceChip(
                label: const Text('Photo + header'),
                selected: _template == 1,
                onSelected: (_) => setState(() => _template = 1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 28,
              backgroundImage: _photo == null ? null : MemoryImage(_photo!),
              child: _photo == null ? const Icon(Icons.person) : null,
            ),
            title: const Text('Photo (optional)'),
            trailing: TextButton(
              onPressed: () async {
                final b = await pickPhoto(context);
                if (b != null) setState(() => _photo = b);
              },
              child: const Text('Pick'),
            ),
          ),
          _field(_name, 'Full name'),
          _field(_email, 'Email'),
          _field(_phone, 'Phone'),
          _field(_address, 'Address', maxLines: 2),
          _field(_dob, 'Date of birth'),
          _field(_father, "Father's name"),
          _field(_objective, 'Objective', maxLines: 3),
          _field(_education, 'Education', maxLines: 4),
          _field(_experience, 'Experience', maxLines: 4),
          _field(_skills, 'Skills', maxLines: 2),
          _field(_languages, 'Languages'),
          _field(_declaration, 'Declaration', maxLines: 3),
          const SizedBox(height: 8),
          PrimaryJobButton(
            label: 'Create CV PDF',
            onPressed: _create,
            busy: _busy,
          ),
          if (_cv != null)
            ListTile(
              leading: const Icon(
                Icons.picture_as_pdf,
                color: AppColors.pdfBadge,
              ),
              title: Text(_cvName ?? 'cv.pdf'),
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
