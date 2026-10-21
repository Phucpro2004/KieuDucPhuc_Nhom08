import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Palette - Executive Corporate Dark Theme
  static const Color bgDark = Color(0xFF0B0F19);
  static const Color bgCard = Color(0xFF151C2C);
  static const Color bgCardLight = Color(0xFF1E293B);
  
  static const Color primary = Color(0xFF6366F1); // Electric Indigo
  static const Color primaryGlow = Color(0xFF818CF8);
  static const Color secondary = Color(0xFF06B6D4); // Neon Cyan
  static const Color accentGold = Color(0xFFF59E0B); // Amber Gold
  
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFF43F5E); // Crimson Red
  
  static const Color textWhite = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDark = Color(0xFF334155);
  
  static const Color borderGlass = Color(0x33FFFFFF);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    primaryColor: primary,
    fontFamily: GoogleFonts.beVietnamPro().fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: Colors.white,
      surface: bgCard,
      onSurface: textWhite,
      error: error,
      onError: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        textStyle: GoogleFonts.beVietnamPro(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: textMuted,
        textStyle: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    textTheme: GoogleFonts.beVietnamProTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.beVietnamPro(color: textWhite, fontWeight: FontWeight.bold, fontSize: 28, height: 1.3),
      titleLarge: GoogleFonts.beVietnamPro(color: textWhite, fontWeight: FontWeight.w700, fontSize: 20, height: 1.3),
      titleMedium: GoogleFonts.beVietnamPro(color: textWhite, fontWeight: FontWeight.w600, fontSize: 16, height: 1.3),
      bodyLarge: GoogleFonts.beVietnamPro(color: textWhite, fontSize: 15, height: 1.4),
      bodyMedium: GoogleFonts.beVietnamPro(color: textMuted, fontSize: 13, height: 1.4),
      labelLarge: GoogleFonts.beVietnamPro(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, height: 1.2),
    ),
    useMaterial3: true,
  );
}
