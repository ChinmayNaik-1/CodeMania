import 'package:flutter/material.dart';

class AppTheme {
  // Dark mode colors
  static const Color darkBackground = Color(0xFF1A1A2E);
  static const Color darkSurface = Color(0xFF262638);
  static const Color darkSurfaceLight = Color(0xFF2F2F47);
  static const Color darkAccent = Color(0xFFFFA116);
  static const Color darkAccentGreen = Color(0xFF00B8A3);
  static const Color darkAccentYellow = Color(0xFFFFC01E);
  static const Color darkAccentRed = Color(0xFFFF375F);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF8A8A9A);
  static const Color darkDivider = Color(0xFF3A3A52);

  // Light mode colors
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceLight = Color(0xFFEEEEEE);
  static const Color lightAccent = Color(0xFFFFA116);
  static const Color lightAccentGreen = Color(0xFF00B8A3);
  static const Color lightAccentYellow = Color(0xFFB89800);
  static const Color lightAccentRed = Color(0xFFE5264A);
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B6B80);
  static const Color lightDivider = Color(0xFFDDDDEE);

  // Additional colors
  static const Color activeTab = Color(0xFF2563EB);
  static const Color codeEditorBg = Color(0xFF0D0D0D);
  static const Color submitButton = Color(0xFF00B84C);

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.dark(
        primary: darkAccent,
        secondary: darkAccentGreen,
        surface: darkSurface,
        background: darkBackground,
        error: darkAccentRed,
        onPrimary: Colors.black,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
        onBackground: darkTextPrimary,
        outline: darkDivider,
      ),
      dividerColor: darkDivider,
      cardColor: darkSurface,
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: darkTextPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkBackground,
        selectedItemColor: darkTextPrimary,
        unselectedItemColor: darkTextSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        hintStyle: TextStyle(color: darkTextSecondary),
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
          borderSide: BorderSide(color: darkAccent, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkAccent,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: activeTab,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface,
        selectedColor: darkAccent,
        labelStyle: TextStyle(color: darkTextPrimary),
        secondaryLabelStyle: TextStyle(color: darkTextSecondary),
        shape: StadiumBorder(),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: darkTextPrimary, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: darkTextPrimary, fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: darkTextPrimary, fontSize: 24, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: darkTextPrimary, fontSize: 24, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: darkTextPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: darkTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: darkTextPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: darkTextPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: darkTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: darkTextPrimary, fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(color: darkTextPrimary, fontSize: 14, fontWeight: FontWeight.normal),
        bodySmall: TextStyle(color: darkTextSecondary, fontSize: 12, fontWeight: FontWeight.normal),
        labelLarge: TextStyle(color: darkTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(color: darkTextSecondary, fontSize: 12, fontWeight: FontWeight.normal),
        labelSmall: TextStyle(color: darkTextSecondary, fontSize: 11, fontWeight: FontWeight.normal),
      ),
    );
  }

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: ColorScheme.light(
        primary: lightAccent,
        secondary: lightAccentGreen,
        surface: lightSurface,
        background: lightBackground,
        error: lightAccentRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
        onBackground: lightTextPrimary,
        outline: lightDivider,
      ),
      dividerColor: lightDivider,
      cardColor: lightSurface,
      appBarTheme: AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: lightTextPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: lightTextPrimary,
        unselectedItemColor: lightTextSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        hintStyle: TextStyle(color: lightTextSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightAccent, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: activeTab,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightSurfaceLight,
        selectedColor: lightAccent,
        labelStyle: TextStyle(color: lightTextPrimary),
        secondaryLabelStyle: TextStyle(color: lightTextSecondary),
        shape: StadiumBorder(),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: lightTextPrimary, fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: lightTextPrimary, fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: lightTextPrimary, fontSize: 24, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: lightTextPrimary, fontSize: 24, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: lightTextPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: lightTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: lightTextPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: lightTextPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: lightTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: lightTextPrimary, fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(color: lightTextPrimary, fontSize: 14, fontWeight: FontWeight.normal),
        bodySmall: TextStyle(color: lightTextSecondary, fontSize: 12, fontWeight: FontWeight.normal),
        labelLarge: TextStyle(color: lightTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(color: lightTextSecondary, fontSize: 12, fontWeight: FontWeight.normal),
        labelSmall: TextStyle(color: lightTextSecondary, fontSize: 11, fontWeight: FontWeight.normal),
      ),
    );
  }

  // Helper methods to get colors based on theme
  static Color getDifficultyColor(String difficulty, bool isDark) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return isDark ? darkAccentGreen : lightAccentGreen;
      case 'medium':
        return isDark ? darkAccentYellow : lightAccentYellow;
      case 'hard':
        return isDark ? darkAccentRed : lightAccentRed;
      default:
        return isDark ? darkTextSecondary : lightTextSecondary;
    }
  }

  static Color getVerdictColor(String verdict, bool isDark) {
    final v = verdict.toLowerCase();
    if (v.contains('accept')) return isDark ? darkAccentGreen : lightAccentGreen;
    if (v.contains('wrong')) return isDark ? darkAccentRed : lightAccentRed;
    if (v.contains('time')) return isDark ? darkAccentYellow : lightAccentYellow;
    if (v.contains('error')) return isDark ? darkAccentRed : lightAccentRed;
    return isDark ? darkTextSecondary : lightTextSecondary;
  }

  static Color getSurfaceLight(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurfaceLight
        : lightSurfaceLight;
  }

  static Color getActiveTabColor(BuildContext context) {
    return activeTab;
  }
}
