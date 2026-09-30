import 'package:flutter/material.dart';

/// One editable block of the CV.
///
/// The builder renders each of these as its own tab page, so the metadata for
/// a section lives here instead of being repeated at the call site. Adding a
/// section means adding one entry here plus one page widget.
class CvSectionMeta {
  /// Short label used on the tab itself.
  final String label;

  /// Full heading shown at the top of the page.
  final String heading;

  /// One-line explanation of what belongs in this section.
  final String subtitle;

  final IconData icon;
  final Color color;
  final List<Color> gradient;

  const CvSectionMeta({
    required this.label,
    required this.heading,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.gradient,
  });
}

/// The six form sections, in tab order. Index order is load-bearing: it is what
/// `CvFormState.isSectionDone` and the section widgets are keyed on.
const List<CvSectionMeta> kCvSections = [
  CvSectionMeta(
    label: 'Personal',
    heading: 'Personal Details',
    subtitle: 'Name, contact, photo and bio-data',
    icon: Icons.person_rounded,
    color: Color(0xFF2563EB),
    gradient: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
  ),
  CvSectionMeta(
    label: 'Objective',
    heading: 'Career Objective',
    subtitle: 'Your summary in two or three lines',
    icon: Icons.flag_rounded,
    color: Color(0xFFEA580C),
    gradient: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
  ),
  CvSectionMeta(
    label: 'Education',
    heading: 'Education & Certifications',
    subtitle: 'Degrees, marks and certificates',
    icon: Icons.school_rounded,
    color: Color(0xFF16A34A),
    gradient: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
  ),
  CvSectionMeta(
    label: 'Experience',
    heading: 'Experience & Projects',
    subtitle: 'Jobs, internships and projects',
    icon: Icons.business_center_rounded,
    color: Color(0xFF4F46E5),
    gradient: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
  ),
  CvSectionMeta(
    label: 'Skills',
    heading: 'Skills, Languages & Hobbies',
    subtitle: 'Tools, spoken languages and interests',
    icon: Icons.psychology_rounded,
    color: Color(0xFF9333EA),
    gradient: [Color(0xFFFAF5FF), Color(0xFFF3E8FF)],
  ),
  CvSectionMeta(
    label: 'Declaration',
    heading: 'Declaration',
    subtitle: 'Closing statement for your CV',
    icon: Icons.verified_user_rounded,
    color: Color(0xFF0D9488),
    gradient: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
  ),
];
