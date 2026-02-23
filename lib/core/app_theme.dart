import 'package:flutter/material.dart';
import 'package:med_reminder_fixed/core/constant.dart';

class AppTheme {
  static ThemeData theme() {
    const primary = Color(AppConstants.primaryGreen);

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
    );

    final cs = base.colorScheme;

    return base.copyWith(
      // soft medicinal background
      scaffoldBackgroundColor: const Color(0xFFF4F8F4),

      // consistent text color
      textTheme: base.textTheme.apply(
        bodyColor: Colors.black,
        displayColor: Colors.black,
      ),

      // ✅ AppBar in medical green
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // ✅ Cards (clean + rounded)
      cardTheme: CardThemeData(
        elevation: 1,
        color: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),

      // ✅ Input styles
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        labelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        hintStyle: const TextStyle(fontSize: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFDDEBDE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFDDEBDE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),

      // ✅ Elevated button in green
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),

      // ✅ Outlined buttons green border
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          foregroundColor: primary,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          side: const BorderSide(color: primary, width: 1.4),
        ),
      ),

      // ✅ FAB green
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),

      // ✅ Bottom nav bar styling
      navigationBarTheme: NavigationBarThemeData(
        height: 78,
        backgroundColor: Colors.white,
        indicatorColor: cs.primary.withOpacity(0.12),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),

      // ✅ Divider tint
      dividerTheme: DividerThemeData(
        color: cs.primary.withOpacity(0.12),
        thickness: 1,
      ),
    );
  }
}