import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ---- Brand colors (as provided) ----
  // Primary — deep forest green (#113023)
  static const primary = Color(0xFF113023);
  static const primaryLight = Color(0xFF1E4D38);
  static const primaryBg = Color(0xFFE7EFEA);

  // Secondary — slate blue (#35466B)
  // Kept the field name `secondary` (was `purple`) so its role in the
  // codebase — accents, secondary stats, badges — stays the same.
  static const secondary = Color(0xFF35466B);
  static const secondaryLight = Color(0xFF4E6390);
  static const secondaryBg = Color(0xFFE9ECF3);

  // Accent — muted rosewood, mixed from the brand green + blue so it reads
  // as part of the same family while staying distinguishable in stat grids
  // that need 5-6 simultaneous colors (was `pink`).
  static const accent = Color(0xFF8C5B73);
  static const accentLight = Color(0xFFAD7E92);
  static const accentBg = Color(0xFFF2E8EC);

  // White (#FFFFFF) — as provided
  static const white = Color(0xFFFFFFFF);

  // ---- Neutrals derived from the brand green for a cohesive feel ----
  static const background = Color(0xFFF5F8F6);
  static const cardBg = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF13241B);
  static const textMid = Color(0xFF5C6B64);
  static const textLight = Color(0xFF93A29B);
  static const border = Color(0xFFE1E8E4);
  static const neutralGrey = Color(0xFFAAB6AF);
  static const neutralGreyLight = Color(0xFFD7DEDA);

  // ---- Status colors, tinted to sit naturally inside the palette ----
  static const success = Color(0xFF2F8F5B);
  static const successLight = Color(0xFF49B47A);
  static const successBg = Color(0xFFE5F3EC);

  static const warning = Color(0xFFC98A2C);
  static const warningLight = Color(0xFFE0A857);
  static const warningBg = Color(0xFFFBF1E2);

  static const error = Color(0xFFC1453B);
  static const errorLight = Color(0xFFDC6B5C);
  static const errorBg = Color(0xFFF8E6E4);

  // Back-compat aliases
  static const gradientStart = primary;
  static const gradientEnd = secondary;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, successLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [warning, warningLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [error, errorLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neutralGradient = LinearGradient(
    colors: [neutralGreyLight, neutralGrey],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [textDark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static const Color primaryColor = AppColors.primary;
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        textTheme: GoogleFonts.poppinsTextTheme().copyWith(
          displayLarge: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
          titleLarge: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
          bodyMedium: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textMid,
          ),
          bodySmall: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textLight,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
          iconTheme: const IconThemeData(color: AppColors.textDark),
        ),
      );
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double cardRadius = 24;
  static const double buttonRadius = 16;
  static const double chipRadius = 12;
}

class AppShadow {
  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get strong => [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.25),
          blurRadius: 32,
          offset: const Offset(0, 12),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get subtle => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ];
}
