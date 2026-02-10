import 'package:flutter/material.dart';

class AppColors {
  // Hex codes from the provided palette
  static const Color darkest = Color(0xFF06141B);
  static const Color dark = Color(0xFF11212D);
  static const Color medium = Color(0xFF253745);
  static const Color lightMedium = Color(0xFF4A5C6A);
  static const Color light = Color(0xFF9BA8AB);
  static const Color lightest = Color(0xFFCCD0CF);

  // Light Theme Palette
  static const Color lightPrimary = Color(0xFF1E3A8A); // Scholastic Blue
  static const Color lightSecondary = Color(0xFFF59E0B); // Amber/Yellow
  static const Color lightBackground = Color(0xFFF3F4F6); // Off-white/Cream
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure White
  static const Color lightText = Color(0xFF111827); // Dark Grey/Black for text
  static const Color lightTextSecondary = Color(0xFF6B7280); // Grey text

  // Gender Colors (User Requested)
  static const Color derColor = Color(0xFF1E88E5); // Medium Blue
  static const Color dieColor = Color(0xFFE91E63); // Pink
  static const Color dasColor = Color(0xFFFFC107); // Yellow

  static Color getArticleColor(String? article) {
    if (article == null) return lightMedium;
    switch (article.toLowerCase()) {
      case 'der':
        return derColor;
      case 'die':
        return dieColor;
      case 'das':
        return dasColor;
      default:
        return lightMedium;
    }
  }
}
