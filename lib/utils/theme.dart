import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Premium NCC Colors
  static const Color navyBlue = Color(0xFF0A192F); // Deep Navy
  static const Color gold = Color(0xFFFFD700); // Standard Gold
  static const Color accentBlue = Color(
    0xFF1D5CFF,
  ); // Brighter Blue for interactions
  static const Color white = Colors.white;
  static const Color lightGrey = Color(0xFFF5F7FA); // Reverted to original
  static const Color authBackground = Color(
    0xFFE2E8F0,
  ); // New specific color for Auth
  static const Color error = Color(0xFFD32F2F);
  static const Color orange = Color(0xFFFF9800); // Orange
  static const Color lightBlueBg = Color(0xFFE8F0FF);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: lightGrey,
      primaryColor: navyBlue,
      colorScheme: ColorScheme.light(
        primary: navyBlue,
        secondary: gold,
        surface: white,
        error: error,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: navyBlue,
        displayColor: navyBlue,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: navyBlue,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: navyBlue,
          foregroundColor: white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: navyBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
