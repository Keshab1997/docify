import 'package:flutter/material.dart';

import '../cv_form_state.dart';
import '../cv_local_suggestions.dart';
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
        Text(
          'Suggestions use your title and skills when entered. Tap one to fill.',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final suggestion in CvLocalSuggestions.objectives(
              role: form.title.text,
              skills: form.skills.text,
            ))
              CvHelperChip(
                label: suggestion.label,
                text: suggestion.text,
                target: form.objective,
                onChanged: onChanged,
              ),
          ],
        ),
      ],
    );
  }
}
