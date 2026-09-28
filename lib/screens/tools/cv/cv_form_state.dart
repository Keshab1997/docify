import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/cv_template_info.dart';
import '../../../services/pdf_service.dart';

/// Every editable field of the CV, plus the little state that has to survive a
/// tab switch.
///
/// The controllers live here rather than in the screen's state so that moving
/// between the section tabs can never drop what the user typed, and so the
/// form can be loaded, cleared and persisted without the widgets knowing how.
class CvFormState {
  final TextEditingController name = TextEditingController();
  final TextEditingController title = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController dob = TextEditingController();
  final TextEditingController father = TextEditingController();
  final TextEditingController objective = TextEditingController();
  final TextEditingController education = TextEditingController();
  final TextEditingController experience = TextEditingController();
  final TextEditingController skills = TextEditingController();
  final TextEditingController languages = TextEditingController();
  final TextEditingController declaration = TextEditingController(
    text:
        'I hereby declare that the above information is true to the best of my '
        'knowledge and belief.',
  );

  Uint8List? photo;

  /// Index into `kCvTemplates`.
  int template = 0;

  static const _kName = 'cv_name';
  static const _kTitle = 'cv_title';
  static const _kEmail = 'cv_email';
  static const _kPhone = 'cv_phone';
  static const _kAddress = 'cv_address';
  static const _kDob = 'cv_dob';
  static const _kFather = 'cv_father';
  static const _kObjective = 'cv_objective';
  static const _kEducation = 'cv_education';
  static const _kExperience = 'cv_experience';
  static const _kSkills = 'cv_skills';
  static const _kLanguages = 'cv_languages';
  static const _kDeclaration = 'cv_declaration';
  static const _kTemplate = 'cv_template';

  /// Restores a previously saved draft. An out-of-range template id from an
  /// older build falls back to the first template instead of corrupting state.
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    name.text = p.getString(_kName) ?? '';
    title.text = p.getString(_kTitle) ?? '';
    email.text = p.getString(_kEmail) ?? '';
    phone.text = p.getString(_kPhone) ?? '';
    address.text = p.getString(_kAddress) ?? '';
    dob.text = p.getString(_kDob) ?? '';
    father.text = p.getString(_kFather) ?? '';
    objective.text = p.getString(_kObjective) ?? '';
    education.text = p.getString(_kEducation) ?? '';
    experience.text = p.getString(_kExperience) ?? '';
    skills.text = p.getString(_kSkills) ?? '';
    languages.text = p.getString(_kLanguages) ?? '';
    final saved = p.getString(_kDeclaration);
    if (saved != null) declaration.text = saved;
    final savedTemplate = p.getInt(_kTemplate) ?? 0;
    template = (savedTemplate >= 0 && savedTemplate < kCvTemplates.length)
        ? savedTemplate
        : 0;
  }

  Future<void> persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kName, name.text);
    await p.setString(_kTitle, title.text);
    await p.setString(_kEmail, email.text);
    await p.setString(_kPhone, phone.text);
    await p.setString(_kAddress, address.text);
    await p.setString(_kDob, dob.text);
    await p.setString(_kFather, father.text);
    await p.setString(_kObjective, objective.text);
    await p.setString(_kEducation, education.text);
    await p.setString(_kExperience, experience.text);
    await p.setString(_kSkills, skills.text);
    await p.setString(_kLanguages, languages.text);
    await p.setString(_kDeclaration, declaration.text);
    await p.setInt(_kTemplate, template);
  }

  void loadSample() {
    name.text = 'Rahul Sarkar';
    title.text = 'Software Engineer & Flutter Developer';
    email.text = 'rahul.sarkar@example.com';
    phone.text = '+91 98765 43210';
    address.text = 'Salt Lake, Sector V, Kolkata, WB - 700091';
    dob.text = '15 Aug 1998';
    father.text = 'Bimal Sarkar';
    objective.text =
        'Passionate software engineer with 3+ years of experience building '
        'scalable, high-performance cross-platform mobile and web applications '
        'with Flutter and modern cloud services.';
    education.text =
        '• B.Tech in Computer Science & Engineering — MAKAUT (2016 - 2020), '
        'DGPA: 8.4\n'
        '• Higher Secondary (10+2) Science — WBCHSE (2016), 86%\n'
        '• Secondary Examination (10th) — WBBSE (2014), 88%';
    experience.text =
        '• Senior Mobile App Developer at TechNova Solutions (2022 - Present)\n'
        '  - Architected 4 production apps with 100k+ active users.\n'
        '  - Reduced app startup latency by 35% using lazy loading and clean '
        'state management.\n'
        '• Junior Software Developer at CloudByte Labs (2020 - 2022)\n'
        '  - Built responsive UI components, REST API integration, and '
        'offline-first SQLite sync.';
    skills.text =
        'Flutter, Dart, Firebase, REST APIs, Git & GitHub, State Management '
        '(Riverpod, Bloc), SQLite, UI/UX Design, Problem Solving';
    languages.text = 'English, Bengali, Hindi';
    declaration.text =
        'I hereby declare that all the information provided above is true and '
        'correct to the best of my knowledge and belief.';
  }

  /// Empties the form back to a blank draft. The declaration keeps its default
  /// wording because a CV is expected to carry one.
  void clear() {
    name.clear();
    title.clear();
    email.clear();
    phone.clear();
    address.clear();
    dob.clear();
    father.clear();
    objective.clear();
    education.clear();
    experience.clear();
    skills.clear();
    languages.clear();
    declaration.clear();
    photo = null;
  }

  /// Fraction of the fields an employer actually needs that are filled in.
  double get completeness {
    const total = 9;
    var filled = 0;
    if (name.text.trim().isNotEmpty) filled++;
    if (title.text.trim().isNotEmpty) filled++;
    if (email.text.trim().isNotEmpty) filled++;
    if (phone.text.trim().isNotEmpty) filled++;
    if (address.text.trim().isNotEmpty) filled++;
    if (objective.text.trim().isNotEmpty) filled++;
    if (education.text.trim().isNotEmpty) filled++;
    if (experience.text.trim().isNotEmpty) filled++;
    if (skills.text.trim().isNotEmpty) filled++;
    return filled / total;
  }

  /// Whether the section at [index] has enough content to be considered done.
  bool isSectionDone(int index) {
    switch (index) {
      case 0:
        return name.text.trim().isNotEmpty &&
            email.text.trim().isNotEmpty &&
            phone.text.trim().isNotEmpty;
      case 1:
        return objective.text.trim().isNotEmpty;
      case 2:
        return education.text.trim().isNotEmpty;
      case 3:
        return experience.text.trim().isNotEmpty;
      case 4:
        return skills.text.trim().isNotEmpty;
      case 5:
        return declaration.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  /// A filesystem-safe name for the generated PDF.
  String get fileNameStem {
    final n = name.text.trim();
    return n.isEmpty ? 'CV' : n.replaceAll(' ', '_');
  }

  /// Renders the current form. Pass [template] to render a design other than
  /// the selected one, which is what the full screen preview browses with.
  Future<Uint8List> buildPdf({int? template}) {
    return PdfService.createCv(
      name: name.text,
      title: title.text,
      email: email.text,
      phone: phone.text,
      address: address.text,
      dob: dob.text,
      father: father.text,
      objective: objective.text,
      education: education.text,
      experience: experience.text,
      skills: skills.text,
      languages: languages.text,
      declaration: declaration.text,
      photo: photo,
      template: template ?? this.template,
    );
  }

  void dispose() {
    name.dispose();
    title.dispose();
    email.dispose();
    phone.dispose();
    address.dispose();
    dob.dispose();
    father.dispose();
    objective.dispose();
    education.dispose();
    experience.dispose();
    skills.dispose();
    languages.dispose();
    declaration.dispose();
  }
}
