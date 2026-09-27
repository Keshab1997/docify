import 'package:flutter/material.dart';

class CvTemplateInfo {
  final int id;
  final String name;
  final String subtitle;
  final String badge;
  final Color primaryColor;
  final Color accentColor;
  final IconData icon;

  const CvTemplateInfo({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.badge,
    required this.primaryColor,
    required this.accentColor,
    required this.icon,
  });
}

const List<CvTemplateInfo> kCvTemplates = [
  CvTemplateInfo(
    id: 0,
    name: 'Modern Sidebar',
    subtitle: 'Dark slate sidebar with teal accents and photo frame',
    badge: 'Popular',
    primaryColor: Color(0xFF1E293B),
    accentColor: Color(0xFF0D9488),
    icon: Icons.view_sidebar_rounded,
  ),
  CvTemplateInfo(
    id: 1,
    name: 'Executive Navy',
    subtitle: 'Classic corporate layout with navy banner and gold details',
    badge: 'Corporate',
    primaryColor: Color(0xFF0F2B48),
    accentColor: Color(0xFFD4AF37),
    icon: Icons.business_center_rounded,
  ),
  CvTemplateInfo(
    id: 2,
    name: 'Tech Indigo',
    subtitle: 'Developer focused design with pill skills and clean lines',
    badge: 'IT & Tech',
    primaryColor: Color(0xFF4338CA),
    accentColor: Color(0xFF6366F1),
    icon: Icons.terminal_rounded,
  ),
  CvTemplateInfo(
    id: 3,
    name: 'Creative Emerald',
    subtitle: 'Vibrant emerald header with rounded sections and mint tags',
    badge: 'Creative',
    primaryColor: Color(0xFF065F46),
    accentColor: Color(0xFF10B981),
    icon: Icons.palette_rounded,
  ),
  CvTemplateInfo(
    id: 4,
    name: 'Indian Bio-Data',
    subtitle: 'Standard format for Govt, Bank, SSC, PSC & Private jobs',
    badge: 'Govt & Exam',
    primaryColor: Color(0xFF1F2937),
    accentColor: Color(0xFF2563EB),
    icon: Icons.description_rounded,
  ),
  CvTemplateInfo(
    id: 5,
    name: 'Minimalist Clean',
    subtitle: 'Pure monochrome layout, high legibility & ATS friendly',
    badge: 'ATS Clean',
    primaryColor: Color(0xFF111827),
    accentColor: Color(0xFF6B7280),
    icon: Icons.article_rounded,
  ),
  CvTemplateInfo(
    id: 6,
    name: 'Charcoal Banner',
    subtitle: 'Full-width dark charcoal header with 2-column body',
    badge: 'Executive',
    primaryColor: Color(0xFF18181B),
    accentColor: Color(0xFFF59E0B),
    icon: Icons.view_day_rounded,
  ),
  CvTemplateInfo(
    id: 7,
    name: 'Royal Burgundy',
    subtitle: 'Deep maroon executive styling for academic & senior roles',
    badge: 'Academic',
    primaryColor: Color(0xFF701A24),
    accentColor: Color(0xFFBE123C),
    icon: Icons.school_rounded,
  ),
  CvTemplateInfo(
    id: 8,
    name: 'Split Slate',
    subtitle: '35/65 dual-tone split card with light background sidebar',
    badge: 'Modern',
    primaryColor: Color(0xFF334155),
    accentColor: Color(0xFF0284C7),
    icon: Icons.dashboard_customize_rounded,
  ),
  CvTemplateInfo(
    id: 9,
    name: 'Nordic Frost',
    subtitle: 'Cyan and deep ocean blue compact layout for freshers',
    badge: 'Freshers',
    primaryColor: Color(0xFF0369A1),
    accentColor: Color(0xFF0EA5E9),
    icon: Icons.auto_awesome_rounded,
  ),
];
