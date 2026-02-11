import 'package:flutter/material.dart';
import 'package:med_reminder_fixed/core/constant.dart';

class AppTheme {
  static ThemeData theme() {
    const primary = Color(AppConstants.primaryBlue);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primary),
      scaffoldBackgroundColor: const Color(0xFFF6F9FF),
      textTheme: const TextTheme().apply(
        fontSizeFactor: 1.15, // larger by default for older users
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE6EEFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE6EEFF)),
        ),
      ),
    );
  }
}
