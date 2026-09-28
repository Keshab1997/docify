import 'package:flutter/material.dart';

import '../cv_form_state.dart';
import '../cv_section_meta.dart';
import '../widgets/cv_fields.dart';

/// Degrees, boards, years and marks. One line per qualification.
class CvEducationSection extends StatelessWidget {
  final CvFormState form;
  final VoidCallback onChanged;

  const CvEducationSection({
    super.key,
    required this.form,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final meta = kCvSections[2];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        CvSectionHeader(
          heading: meta.heading,
          subtitle: meta.subtitle,
          icon: meta.icon,
          color: meta.color,
          gradient: meta.gradient,
          done: form.isSectionDone(2),
        ),
        CvInputField(
          controller: form.education,
          label: 'Educational Background',
          hint: '• B.Tech CSE — MAKAUT (2020), 8.4 CGPA\n'
              '• HS (10+2) — WBCHSE (2016), 86%\n'
              '• Secondary — WBBSE (2014), 88%',
          icon: Icons.menu_book_rounded,
          maxLines: 6,
          onChanged: (_) => onChanged(),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                size: 16,
                color: Color(0xFF16A34A),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Start each line with • so it prints as a bullet. Put the '
                  'degree, then the board or university and year, then your '
                  'marks — that is the order Indian forms expect.',
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
