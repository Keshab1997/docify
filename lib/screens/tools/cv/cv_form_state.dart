import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/cv_template_info.dart';
import '../../../services/cv/cv_text_sanitizer.dart';
import '../../../services/cv_pdf_templates.dart';

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
  final TextEditingController mother = TextEditingController();
  final TextEditingController nationality = TextEditingController();
  final TextEditingController gender = TextEditingController();
  final TextEditingController maritalStatus = TextEditingController();
  final TextEditingController objective = TextEditingController();
  final TextEditingController education = TextEditingController();
  final TextEditingController certifications = TextEditingController();
  final TextEditingController experience = TextEditingController();
  final TextEditingController projects = TextEditingController();
  final TextEditingController skills = TextEditingController();
  final TextEditingController languages = TextEditingController();
  final TextEditingController hobbies = TextEditingController();
  final TextEditingController declaration = TextEditingController(
    text:
        'I hereby declare that the above information is true to the best of my '
        'knowledge and belief.',
  );

  /// The passport photo, already cropped and shrunk by `CvPhotoPicker`.
  Uint8List? get photo => _photo;
  set photo(Uint8List? bytes) {
    _photo = bytes;
    _photoChanged = true;
    scheduleSave();
  }

  Uint8List? _photo;

  /// Whether [photo] changed since it was last saved. At up to ~120 KB it is
  /// by far the largest thing saved, so it is only written when it changes
  /// instead of on every autosave.
  bool _photoChanged = false;

  /// Index into `kCvTemplates`.
  int template = 0;

  static const _kName = 'cv_name';
  static const _kTitle = 'cv_title';
  static const _kEmail = 'cv_email';
  static const _kPhone = 'cv_phone';
  static const _kAddress = 'cv_address';
  static const _kDob = 'cv_dob';
  static const _kFather = 'cv_father';
  static const _kMother = 'cv_mother';
  static const _kNationality = 'cv_nationality';
  static const _kGender = 'cv_gender';
  static const _kMaritalStatus = 'cv_marital_status';
  static const _kObjective = 'cv_objective';
  static const _kEducation = 'cv_education';
  static const _kCertifications = 'cv_certifications';
  static const _kExperience = 'cv_experience';
  static const _kProjects = 'cv_projects';
  static const _kSkills = 'cv_skills';
  static const _kLanguages = 'cv_languages';
  static const _kHobbies = 'cv_hobbies';
  static const _kDeclaration = 'cv_declaration';
  static const _kTemplate = 'cv_template';
  static const _kPhoto = 'cv_photo';

  /// Every text field, keyed by the preference it is saved under.
  late final Map<String, TextEditingController> _fields = {
    _kName: name,
    _kTitle: title,
    _kEmail: email,
    _kPhone: phone,
    _kAddress: address,
    _kDob: dob,
    _kFather: father,
    _kMother: mother,
    _kNationality: nationality,
    _kGender: gender,
    _kMaritalStatus: maritalStatus,
    _kObjective: objective,
    _kEducation: education,
    _kCertifications: certifications,
    _kExperience: experience,
    _kProjects: projects,
    _kSkills: skills,
    _kLanguages: languages,
    _kHobbies: hobbies,
    _kDeclaration: declaration,
  };

  /// Pending autosave, restarted by every edit.
  Timer? _autosave;

  /// The save in flight. Saves run one after another, so an older snapshot
  /// of the form can never land on top of a newer one.
  Future<void> _saving = Future<void>.value();

  bool _listening = false;
  bool _disposed = false;

  /// Restores a previously saved draft. An out-of-range template id from an
  /// older build falls back to the first template instead of corrupting state.
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    // The builder may already be closed by the time the store answers.
    if (_disposed) return;
    for (final field in _fields.entries) {
      final saved = p.getString(field.key);
      // A field that was never saved keeps its initial text, which is how a
      // new draft gets the default declaration.
      if (saved != null) field.value.text = saved;
    }
    final savedTemplate = p.getInt(_kTemplate) ?? 0;
    template = (savedTemplate >= 0 && savedTemplate < kCvTemplates.length)
        ? savedTemplate
        : 0;
    final savedPhoto = p.getString(_kPhoto);
    if (savedPhoto != null) {
      try {
        _photo = base64Decode(savedPhoto);
      } on FormatException {
        // A damaged photo must not keep the builder from opening.
        _photo = null;
      }
    }
    _listen();
  }

  /// Saves the draft after every edit from here on. Only started once the
  /// saved draft is back in the fields, so the empty form shown while it
  /// loads can never overwrite it.
  void _listen() {
    if (_listening) return;
    _listening = true;
    for (final field in _fields.values) {
      field.addListener(scheduleSave);
    }
  }

  /// Saves the draft shortly after the last edit.
  ///
  /// The form used to be saved only on Preview, Save PDF and a few other
  /// taps, so closing the app after typing, or Android killing it in the
  /// background, threw the typing away. The delay folds a burst of
  /// keystrokes into a single write.
  void scheduleSave() {
    _autosave?.cancel();
    _autosave = Timer(const Duration(milliseconds: 800), persist);
  }

  /// Writes a pending autosave right away: the app is going into the
  /// background, where Android may kill it without warning, or the builder
  /// is closing.
  void flush() {
    if (_autosave?.isActive ?? false) persist();
  }

  /// Writes the whole draft now.
  Future<void> persist() {
    _autosave?.cancel();
    // Everything is read before the first await: dispose() saves as its last
    // act, and the controllers are gone by the time the store answers.
    final text = {
      for (final field in _fields.entries) field.key: field.value.text,
    };
    final template = this.template;
    final photoChanged = _photoChanged;
    final photo = _photo;
    _photoChanged = false;
    final save = _saving.then((_) async {
      final p = await SharedPreferences.getInstance();
      for (final entry in text.entries) {
        await p.setString(entry.key, entry.value);
      }
      await p.setInt(_kTemplate, template);
      if (!photoChanged) return;
      if (photo == null) {
        await p.remove(_kPhoto);
      } else {
        await p.setString(_kPhoto, base64Encode(photo));
      }
    });
    // One failed write must not stop every later save.
    _saving = save.catchError((Object _) {});
    return save;
  }

  void loadSample() {
    name.text = 'Keshab Sarkar';
    title.text = 'Software Engineer & Flutter Developer';
    email.text = 'keshabsarkar2018@gmail.com';
    phone.text = '+91 9382284190';
    address.text =
        'Simla, Mertala, Tita, Purbasthali-2 Block, Purba Bardhaman, WB - 713513';
    dob.text = '25/07/1997';
    father.text = 'Krishna Sarkar';
    nationality.text = 'Indian';
    gender.text = 'Male';
    // Left blank rather than made up: family details and marital status are
    // facts only the user can fill in.
    mother.clear();
    maritalStatus.clear();
    objective.text =
        'Passionate software engineer with 3+ years of experience building '
        'scalable, high-performance cross-platform mobile and web applications '
        'with Flutter and modern cloud services.';
    education.text =
        '• B.Tech in Computer Science & Engineering — MAKAUT (2016 - 2020), '
        'DGPA: 8.4\n'
        '• Higher Secondary (10+2) Science — WBCHSE (2016), 86%\n'
        '• Secondary Examination (10th) — WBBSE (2014), 88%';
    certifications.text =
        '• Flutter & Dart App Development — online certification (2021)\n'
        '• Firebase for Mobile Developers — workshop (2022)';
    experience.text =
        '• Senior Mobile App Developer at TechNova Solutions (2022 - Present)\n'
        '  - Architected 4 production apps with 100k+ active users.\n'
        '  - Reduced app startup latency by 35% using lazy loading and clean '
        'state management.\n'
        '• Junior Software Developer at CloudByte Labs (2020 - 2022)\n'
        '  - Built responsive UI components, REST API integration, and '
        'offline-first SQLite sync.';
    projects.text =
        '• Docify — photo, signature, PDF and CV tools for job and exam forms '
        '(Flutter, Firebase)\n'
        '• Expense tracker with offline-first sync and monthly charts '
        '(Flutter, SQLite)';
    skills.text =
        'Flutter, Dart, Firebase, REST APIs, Git & GitHub, State Management '
        '(Riverpod, Bloc), SQLite, UI/UX Design, Problem Solving';
    languages.text = 'English, Bengali, Hindi';
    hobbies.text = 'Reading, Cricket, Photography, Travelling';
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
    mother.clear();
    nationality.clear();
    gender.clear();
    maritalStatus.clear();
    objective.clear();
    education.clear();
    certifications.clear();
    experience.clear();
    projects.clear();
    skills.clear();
    languages.clear();
    hobbies.clear();
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

  /// The form as a template sees it, before anything has been cleaned.
  CvData toData({int? template}) => CvData(
        name: name.text,
        title: title.text,
        email: email.text,
        phone: phone.text,
        address: address.text,
        dob: dob.text,
        gender: gender.text,
        maritalStatus: maritalStatus.text,
        nationality: nationality.text,
        father: father.text,
        mother: mother.text,
        objective: objective.text,
        education: education.text,
        certifications: certifications.text,
        experience: experience.text,
        projects: projects.text,
        skills: skills.text,
        languages: languages.text,
        hobbies: hobbies.text,
        declaration: declaration.text,
        photo: photo,
        template: template ?? this.template,
      );

  /// Labels of the filled fields whose text the PDF font cannot print, so the
  /// user can be told before they save a CV with a blank name on it.
  List<String> get undrawableFields =>
      CvTextSanitizer.undrawableFields(toData());

  /// What the PDF would leave out or cut off, as short lines for the user.
  /// Empty when nothing is at risk. [cutOff] comes from [render]: the page
  /// shrinks a long CV to fit, so text is only lost when even the smallest
  /// size is not enough.
  List<String> printWarnings({required bool cutOff}) => [
        if (undrawableFields.isNotEmpty)
          'These fields will be left out of the PDF, because the CV font can '
              'only print English letters, digits and punctuation: '
              '${undrawableFields.join(', ')}.',
        if (cutOff)
          'Your CV is longer than this design can hold, even with the text at '
              'its smallest size, so the bottom of the page will be cut off. '
              'Shorten a section or try another design.',
      ];

  /// A filesystem-safe name for the generated PDF.
  String get fileNameStem {
    final n = name.text.trim();
    return n.isEmpty ? 'CV' : n.replaceAll(' ', '_');
  }

  /// Renders the current form the way it will be saved, and reports whether
  /// the page had to cut any of it off. Pass [template] to render a design
  /// other than the selected one.
  Future<CvRender> render({int? template}) =>
      CvPdfTemplates.render(toData(template: template));

  /// Renders the current form. Pass [template] to render a design other than
  /// the selected one, which is what the full screen preview browses with.
  ///
  /// Goes through [toData] like [render] does. It used to copy every field
  /// into a second parameter list, where a new field could silently go
  /// missing from the preview.
  Future<Uint8List> buildPdf({int? template}) {
    return CvPdfTemplates.generate(toData(template: template));
  }

  void dispose() {
    // Whatever was typed in the last moment before leaving is still pending.
    flush();
    _disposed = true;
    for (final field in _fields.values) {
      field.dispose();
    }
  }
}
