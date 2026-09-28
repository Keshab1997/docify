import 'package:flutter/material.dart';

import '../cv_form_state.dart';
import '../cv_section_meta.dart';
import '../widgets/cv_fields.dart';

/// Jobs, internships and projects, newest first.
class CvExperienceSection extends StatelessWidget {
  final CvFormState form;
  final VoidCallback onChanged;

  const CvExperienceSection({
    super.key,
    required this.form,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final meta = kCvSections[3];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        CvSectionHeader(
          heading: meta.heading,
          subtitle: meta.subtitle,
          icon: meta.icon,
          color: meta.color,
          gradient: meta.gradient,
          done: form.isSectionDone(3),
        ),
        CvInputField(
          controller: form.experience,
          label: 'Work Experience',
          hint: '• Senior Developer @ TechNova (2022 — Present)\n'
              '  - Built 4 apps with 100k+ users\n'
              '• Junior Developer @ CloudByte (2020 — 2022)',
          icon: Icons.history_edu_rounded,
          maxLines: 6,
          onChanged: (_) => onChanged(),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC7D2FE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                size: 16,
                color: Color(0xFF4F46E5),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Use • for each role and indent achievements under it with '
                  'two spaces and a dash. Freshers can list internships, '
                  'college projects or freelance work here.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
