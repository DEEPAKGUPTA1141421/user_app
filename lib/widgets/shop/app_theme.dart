import 'package:flutter/material.dart';

const Color kPrimary = Color(0xFFFC8019);
const Color kPrimaryLight = Color(0xFFFFF5ED);
const Color kBackground = Color(0xFFF8F8F8);
const Color kSurface = Colors.white;
const Color kTextPrimary = Color(0xFF1A1A1A);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kTextMuted = Color(0xFF9CA3AF);
const Color kGreen = Color(0xFF16A34A);
const Color kBorder = Color(0xFFE5E7EB);

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimary,
      primary: kPrimary,
      surface: kSurface,
      background: kBackground,
    ),
    scaffoldBackgroundColor: kBackground,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      iconTheme: IconThemeData(color: kTextPrimary),
      titleTextStyle: TextStyle(
        color: kTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF3F4F6),
      labelStyle: const TextStyle(fontSize: 13, color: kTextSecondary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    ),
  );
}