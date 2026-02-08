import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF0f0f1a);
  static const Color surface = Color(0xFF1a1a2e);
  static const Color surfaceLight = Color(0xFF252542);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFc4c4d4);
  static const Color textMuted = Color(0xFF6e6e88);
  static const Color accentBlue = Color(0xFF667eea);
  static const Color accentPurple = Color(0xFF764ba2);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentRed = Color(0xFFe53935);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentTeal = Color(0xFF26C6DA);
  static const Color cardDark = Color(0xFF16162a);
  static const Color navBar = Color(0xFF0d0d1a);
  static const Color glowBorder = Color(0xFF667eea);

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient statCardGradient1 = LinearGradient(
    colors: [Color(0xFF1a1a35), Color(0xFF152040)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient statCardGradient2 = LinearGradient(
    colors: [Color(0xFF1a1a35), Color(0xFF153035)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueButtonGradient = LinearGradient(
    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient greenButtonGradient = LinearGradient(
    colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient auroraGradient = LinearGradient(
    colors: [
      Color(0x00667eea),
      Color(0x33667eea),
      Color(0x22764ba2),
      Color(0x00764ba2),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.accentBlue,
      textTheme: textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentBlue,
        secondary: AppColors.accentPurple,
        surface: AppColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navBar,
        selectedItemColor: AppColors.accentBlue,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
