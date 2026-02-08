import 'package:dutschi/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,

      // Color Scheme
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.light,
        onPrimary: AppColors.darkest,
        secondary: AppColors.medium,
        onSecondary: AppColors.lightest,
        tertiary: AppColors.lightMedium,
        onTertiary: AppColors.lightest,
        error: Colors.redAccent,
        onError: Colors.white,
        surface: AppColors.dark,
        onSurface: AppColors.lightest,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: AppColors.dark,

      // Typography
      textTheme: GoogleFonts.outfitTextTheme().apply(bodyColor: AppColors.lightest, displayColor: AppColors.lightest),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.dark,
        foregroundColor: AppColors.lightest,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.lightest),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.light,
          foregroundColor: AppColors.darkest,
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(color: AppColors.dark, elevation: 4).copyWith(
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: AppColors.light),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkest,
        indicatorColor: AppColors.light,
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.lightest),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.darkest);
          }
          return const IconThemeData(color: AppColors.lightest);
        }),
      ),
    );
  }
}
