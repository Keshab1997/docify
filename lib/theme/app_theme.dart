import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background = Color(0xFFF6F8FC);
  static const card = Color(0xFFFFFFFF);
  static const titleBlue = Color(0xFF1D4ED8);
  static const bodyText = Color(0xFF0F172A);
  static const mutedText = Color(0xFF64748B);
  static const primaryButton = Color(0xFF2563EB);
  static const photoResizeCard = Color(0xFFEEF4FF);
  static const signatureCard = Color(0xFFFFF1F4);
  static const imageToPdfCard = Color(0xFFE9FBF3);
  static const mergePdfCard = Color(0xFFF4F0FF);
  static const jobFormStart = Color(0xFFFFF6F1);
  static const jobFormEnd = Color(0xFFFFF0F6);
  static const pdfBadge = Color(0xFFEF4444);
  static const successChip = Color(0xFF16A34A);
  static const lightBlue = Color(0xFFDBEAFE);
}

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryButton,
        background: AppColors.background,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.bodyText),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.bodyText),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14, color: AppColors.bodyText),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12, color: AppColors.mutedText),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
