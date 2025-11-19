import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData dark() {
    const background = Color(0xFF050815); // deep navy
    const surface = Color(0xFF101427);
    const surfaceAlt = Color(0xFF181C35);
    const primary = Color(0xFF4F46E5); // indigo
    const secondary = Color(0xFF06B6D4); // cyan
    const accentPink = Color(0xFFE11D48); // pink for likes

    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background, // ok even if deprecated – base still uses it
        outline: Colors.white.withOpacity(0.08),
      ),
      scaffoldBackgroundColor: background,
      cardColor: surface,
      dividerColor: Colors.white.withOpacity(0.06),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: primary,
            width: 1.5,
          ),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          elevation: 0,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: Colors.black,
      ),
      iconTheme: const IconThemeData(color: Colors.white70),
    );
  }
}
