import 'package:flutter/material.dart';

import '../cv_form_state.dart';
import '../cv_local_suggestions.dart';
import '../cv_section_meta.dart';
import '../widgets/cv_fields.dart';

/// Jobs and internships, newest first, then projects.
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
          hint: '• [Role] @ [Company] ([Dates])\n'
              '  - [Main responsibility]\n'
              '  - [Result or achievement]',
          icon: Icons.history_edu_rounded,
          maxLines: 6,
          onChanged: (_) => onChanged(),
        ),
        Text(
          'Tap a starter, check the role, then replace bracketed prompts with your facts.',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            CvHelperChip(
              label: 'Job entry',
              text: CvLocalSuggestions.workExperienceEntry(
                role: form.title.text,
              ),
              target: form.experience,
              onChanged: onChanged,
              append: true,
            ),
            CvHelperChip(
              label: 'Internship',
              text: CvLocalSuggestions.internshipEntry,
              target: form.experience,
              onChanged: onChanged,
              append: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        CvInputField(
          controller: form.projects,
          label: 'Projects',
          hint: '• [Project] — [What it does] ([Tools used])\n'
              '  - [Your contribution]',
          icon: Icons.rocket_launch_outlined,
          maxLines: 4,
          onChanged: (_) => onChanged(),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: CvHelperChip(
            label: 'Project entry',
            text: CvLocalSuggestions.projectEntry,
            target: form.projects,
            onChanged: onChanged,
            append: true,
          ),
        ),
      ],
    );
  }
}
