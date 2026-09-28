import 'package:flutter/material.dart';

import '../cv_form_state.dart';
import '../cv_section_meta.dart';
import '../widgets/cv_fields.dart';

/// Short summary of who the applicant is and what they are after.
class CvObjectiveSection extends StatelessWidget {
  final CvFormState form;
  final VoidCallback onChanged;

  const CvObjectiveSection({
    super.key,
    required this.form,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final meta = kCvSections[1];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        CvSectionHeader(
          heading: meta.heading,
          subtitle: meta.subtitle,
          icon: meta.icon,
          color: meta.color,
          gradient: meta.gradient,
          done: form.isSectionDone(1),
        ),
        CvInputField(
          controller: form.objective,
          label: 'Objective / Summary',
          hint: 'Describe your strengths and goals…',
          icon: Icons.notes_rounded,
          maxLines: 4,
          onChanged: (_) => onChanged(),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              CvHelperChip(
                label: 'Fresher',
                text:
                    'Enthusiastic graduate seeking entry-level opportunity to '
                    'apply academic learning and problem-solving skills.',
                target: form.objective,
                onChanged: onChanged,
              ),
              CvHelperChip(
                label: 'Experienced',
                text: 'Results-driven professional with proven expertise in '
                    'delivery and team collaboration.',
                target: form.objective,
                onChanged: onChanged,
              ),
              CvHelperChip(
                label: 'Developer',
                text:
                    'Passionate software engineer focused on robust, scalable '
                    'apps with clean architecture.',
                target: form.objective,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
