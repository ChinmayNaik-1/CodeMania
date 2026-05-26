import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Dark mode color palette
  static const Color bgPage = Color(0xFF0F0F0F);
  static const Color bgSurface = Color(0xFF1A1A2E);
  static const Color bgCard = Color(0xFF16213E);
  static const Color bgElevated = Color(0xFF1F2B47);
  static const Color primaryAccent = Color(0xFF7C3AED);
  static const Color primaryHover = Color(0xFF6D28D9);
  static const Color secondaryAccent = Color(0xFF06B6D4);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF475569);
  static const Color borderDefault = Color(0xFF2D3748);

  // Verdicts (for backward compatibility)
  static const Color verdictAccepted = successColor;
  static const Color verdictWrongAnswer = errorColor;
  static const Color verdictRuntimeError = errorColor;
  static const Color verdictTimeLimit = warningColor;
  static const Color verdictPending = textMuted;
  static const Color verdictEasy = successColor;
  static const Color verdictMedium = warningColor;
  static const Color verdictHard = errorColor;

  // Legacy colors (for backward compatibility with old code)
  static const Color primaryColor = primaryAccent;
  static const Color primaryDark = primaryHover;
  static const Color accentColor = secondaryAccent;
  static const Color backgroundColor = bgPage;
  static const Color surfaceColor = bgSurface;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F3FB),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF5E2ED5),
        secondary: Color(0xFF2195D8),
        error: Color(0xFFE06060),
        surface: Color(0xFFFDFDFF),
      ),
      textTheme:
          GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        headlineLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF242453),
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF242453),
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF242453),
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF242453),
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF242453),
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF4F5B73),
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF4F5B73),
          height: 1.6,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF7A839E),
        ),
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: const Color(0xFFFDFDFF),
        foregroundColor: const Color(0xFF242453),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF242453),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF4F1FB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5E2ED5), width: 1.5),
        ),
        hintStyle: const TextStyle(color: Color(0xFF919CB2)),
        labelStyle: const TextStyle(color: Color(0xFF4F5B73)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle:
              GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF5E2ED5),
          side: const BorderSide(color: Color(0xFFD8CFEE)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle:
              GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: Color(0xFFECEAF7),
        selectedColor: Color(0xFF5E2ED5),
        labelStyle: TextStyle(color: Color(0xFF5E2ED5)),
        shape: StadiumBorder(),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE6E0F3)),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFFFDFDFF),
        selectedItemColor: Color(0xFF5E2ED5),
        unselectedItemColor: Color(0xFF7A839E),
      ),
    );
  }

  static Color getVerdictColor(String verdict) {
    switch (verdict.toLowerCase()) {
      case 'accepted':
        return verdictAccepted;
      case 'wrong_answer':
        return verdictWrongAnswer;
      case 'runtime_error':
        return verdictRuntimeError;
      case 'time_limit_exceeded':
        return verdictTimeLimit;
      default:
        return verdictPending;
    }
  }

  static Color getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return verdictEasy;
      case 'medium':
        return verdictMedium;
      case 'hard':
        return verdictHard;
      default:
        return textMuted;
    }
  }

  static String getVerdictLabel(String verdict) {
    return verdict
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  // Helper: Get contrasting text color for backgrounds
  static Color getContrastText(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
