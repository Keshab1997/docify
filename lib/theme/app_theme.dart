import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'motion.dart';

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

  /// Destructive actions (delete, revoke).
  static const danger = Color(0xFFDC2626);

  /// Hairline border for chips and outlined controls.
  static const chipBorder = Color(0xFFE2E8F0);

  /// Pastel background for anything PDF-flavoured (file rows, group tint).
  static const pdfTint = Color(0xFFFFF1F2);

  /// Tool-group inks not covered by a name above.
  static const signatureInk = Color(0xFFE11D48);
  static const assistantInk = Color(0xFF7C3AED);
}

/// The type scale. New and edited screens should reach for these instead of
/// inventing another font size; a full sweep of the old literals is pending.
class AppText {
  const AppText._();

  static const display = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.3,
    color: AppColors.bodyText,
  );

  static const title = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.2,
    color: AppColors.bodyText,
  );

  static const body = TextStyle(
    fontSize: 14,
    height: 1.4,
    color: AppColors.bodyText,
  );

  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.bodyText,
  );

  static const caption = TextStyle(fontSize: 12, color: AppColors.mutedText);
}

/// Corner radii. The app used to carry sixteen different values; these are the
/// ones worth keeping, named for where they belong.
class Radii {
  const Radii._();

  static const double sm = 8;
  static const double chip = 14;
  static const double field = 16;
  static const double card = 18;
  static const double nav = 22;
  static const double sheet = 24;
  static const double shell = 28;
  static const double pill = 999;
}

/// Spacing steps, so gaps stop being magic numbers.
class Space {
  const Space._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
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
      // Android only: iOS and macOS already slide pages in natively, so the
      // fade-and-lift builder is only wired where the default zoom felt heavy.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
        },
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryButton,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.sheet),
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
          borderRadius: BorderRadius.circular(Radii.field),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.field),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.field),
          borderSide: const BorderSide(
            color: AppColors.primaryButton,
            width: 1.4,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.chip),
        ),
      ),
      // One chip look for every ChoiceChip/FilterChip in the app: preset
      // sizes, category filters, document filters, aspect locks.
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.lightBlue,
        disabledColor: AppColors.background,
        side: const BorderSide(color: AppColors.chipBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.chip),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.mutedText,
        ),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryButton,
        ),
      ),
    );
  }
}

/// Fades every pushed page in with a small lift instead of sliding it up from
/// the bottom, so opening a tool feels like the page was already there.
class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Motion.enter,
      reverseCurve: Motion.exit,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(curved),
        child: child,
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
