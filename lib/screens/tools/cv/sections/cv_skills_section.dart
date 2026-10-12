import 'package:flutter/material.dart';

import '../cv_form_state.dart';
import '../cv_local_suggestions.dart';
import '../cv_section_meta.dart';
import '../widgets/cv_fields.dart';

/// Technical skills, spoken languages and hobbies.
class CvSkillsSection extends StatelessWidget {
  final CvFormState form;
  final VoidCallback onChanged;

  const CvSkillsSection({
    super.key,
    required this.form,
    required this.onChanged,
  });

  static const _languageChips = ['English', 'Bengali', 'Hindi'];

  static const _hobbyChips = [
    'Reading',
    'Cricket',
    'Music',
    'Travelling',
    'Photography',
    'Drawing',
  ];

  @override
  Widget build(BuildContext context) {
    final meta = kCvSections[4];
    final role = form.title.text.trim();
    final suggestedSkills = CvLocalSuggestions.skillsForProfile(
      role: role,
      education: form.education.text,
      experience: form.experience.text,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        CvSectionHeader(
          heading: meta.heading,
          subtitle: meta.subtitle,
          icon: meta.icon,
          color: meta.color,
          gradient: meta.gradient,
          done: form.isSectionDone(4),
        ),
        CvInputField(
          controller: form.skills,
          label: 'Key Skills',
          hint: 'Flutter, Dart, Firebase, Git, Python…',
          icon: Icons.code_rounded,
          maxLines: 3,
          onChanged: (_) => onChanged(),
        ),
        CvQuickChips(
          title: role.isEmpty
              ? 'Common skill suggestions:'
              : 'Suggested for $role:',
          items: suggestedSkills,
          controller: form.skills,
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
        CvInputField(
          controller: form.languages,
          label: 'Languages',
          hint: 'English, Bengali, Hindi',
          icon: Icons.translate_rounded,
          onChanged: (_) => onChanged(),
        ),
        CvQuickChips(
          title: '',
          items: _languageChips,
          controller: form.languages,
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
        CvInputField(
          controller: form.hobbies,
          label: 'Hobbies & Interests',
          hint: 'Reading, Cricket, Photography',
          icon: Icons.interests_outlined,
          onChanged: (_) => onChanged(),
        ),
        CvQuickChips(
          title: '',
          items: _hobbyChips,
          controller: form.hobbies,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
