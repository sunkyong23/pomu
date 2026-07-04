import 'package:flutter/material.dart';

import 'pomu_colors.dart';

class PomuTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,

      scaffoldBackgroundColor: PomuColors.background,

      colorScheme: ColorScheme.fromSeed(
        seedColor: PomuColors.primary,
        brightness: Brightness.light,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: PomuColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),

      dividerColor: PomuColors.divider,

      cardColor: PomuColors.surface,

      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: PomuColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: PomuColors.divider),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: PomuColors.primary, width: 1.5),
        ),

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: PomuColors.textPrimary,
          letterSpacing: -1,
        ),

        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: PomuColors.textPrimary,
        ),

        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: PomuColors.textPrimary,
        ),

        bodyLarge: TextStyle(fontSize: 16, color: PomuColors.textPrimary),

        bodyMedium: TextStyle(fontSize: 15, color: PomuColors.textSecondary),
      ),
    );
  }
}
