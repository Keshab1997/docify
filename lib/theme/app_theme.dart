import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background = Color(0xFFF4F7FC);
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
        surface: AppColors.background,
      ),
    );
    final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: text.copyWith(
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.bodyText,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.bodyText,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: AppColors.bodyText,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: AppColors.mutedText,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.bodyText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.bodyText,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryButton,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.mutedText,
          fontSize: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primaryButton,
            width: 1.4,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class Soft {
  static List<BoxShadow> get card => [
    BoxShadow(
      color: const Color(0xFF0F172A).withValues(alpha: 0.05),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
}
