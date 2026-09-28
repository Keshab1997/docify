import 'package:flutter/material.dart';

import '../cv_form_state.dart';
import '../cv_section_meta.dart';
import '../widgets/cv_fields.dart';

/// Closing statement printed at the end of exam-format CVs.
class CvDeclarationSection extends StatelessWidget {
  final CvFormState form;
  final VoidCallback onChanged;

  const CvDeclarationSection({
    super.key,
    required this.form,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final meta = kCvSections[5];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        CvSectionHeader(
          heading: meta.heading,
          subtitle: meta.subtitle,
          icon: meta.icon,
          color: meta.color,
          gradient: meta.gradient,
          done: form.isSectionDone(5),
        ),
        CvInputField(
          controller: form.declaration,
          label: 'Declaration Text',
          hint: 'I hereby declare that…',
          icon: Icons.draw_rounded,
          maxLines: 5,
          onChanged: (_) => onChanged(),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 16,
                color: Color(0xFF0D9488),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Government and bank applications expect a declaration. '
                  'Date and place are usually written by hand on the printed '
                  'copy, so they are left out of the PDF.',
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
