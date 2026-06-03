import 'package:flutter/material.dart';

/// LeetCode-inspired dark theme constants
class LeetCodeTheme {
  // Core colors
  static const Color background = Color(0xFF1A1A2E);
  static const Color surface = Color(0xFF262638);
  static const Color surfaceLight = Color(0xFF2F2F47);
  static const Color accent = Color(0xFFFFA116);
  static const Color accentGreen = Color(0xFF00B8A3);
  static const Color accentYellow = Color(0xFFFFC01E);
  static const Color accentRed = Color(0xFFFF375F);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8A8A9A);
  static const Color divider = Color(0xFF3A3A52);
  
  // Additional colors
  static const Color activeTab = Color(0xFF2563EB);
  static const Color codeEditorBg = Color(0xFF0D0D0D);
  static const Color submitButton = Color(0xFF00B84C);
  
  // Difficulty colors
  static Color getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return accentGreen;
      case 'medium':
        return accentYellow;
      case 'hard':
        return accentRed;
      default:
        return textSecondary;
    }
  }
  
  // Verdict colors
  static Color getVerdictColor(String verdict) {
    final v = verdict.toLowerCase();
    if (v.contains('accept')) return accentGreen;
    if (v.contains('wrong')) return accentRed;
    if (v.contains('time')) return accentYellow;
    if (v.contains('error')) return accentRed;
    return textSecondary;
  }
}
