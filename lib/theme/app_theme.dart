import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF1e1e2f);
  static const Color surface = Color(0xFF2a2a3d);
  static const Color surfaceLight = Color(0xFF32324a);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFc4c4d4);
  static const Color textMuted = Color(0xFF8888a0);
  static const Color accentBlue = Color(0xFF667eea);
  static const Color accentPurple = Color(0xFF764ba2);
  static const Color accentGreen = Color(0xFF4CAF50);
  static const Color accentRed = Color(0xFFe53935);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentTeal = Color(0xFF26C6DA);
  static const Color cardDark = Color(0xFF252540);
  static const Color navBar = Color(0xFF1a1a2e);

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient statCardGradient1 = LinearGradient(
    colors: [Color(0xFF2a2a4a), Color(0xFF1e3a5f)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient statCardGradient2 = LinearGradient(
    colors: [Color(0xFF2a2a4a), Color(0xFF1e4a4a)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueButtonGradient = LinearGradient(
    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.accentBlue,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentBlue,
        secondary: AppColors.accentPurple,
        surface: AppColors.surface,
      ),
      fontFamily: 'Inter',
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
        hintStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
