import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ShadTheme {
  // Colors
  static const background = Color(0xFFFFFFFF);
  static const foreground = Color(0xFF09090B);
  static const muted = Color(0xFF71717A);
  static const mutedForeground = Color(0xFF71717A);
  static const card = Color(0xFFFFFFFF);
  static const cardForeground = Color(0xFF09090B);
  static const popover = Color(0xFFFFFFFF);
  static const popoverForeground = Color(0xFF09090B);
  static const border = Color(0xFFE4E4E7);
  static const input = Color(0xFFE4E4E7);
  static const primary = Color(0xFF18181B);
  static const primaryForeground = Color(0xFFFFFFFF);
  static const secondary = Color(0xFFF4F4F5);
  static const secondaryForeground = Color(0xFF18181B);
  static const accent = Color(0xFFF4F4F5);
  static const accentForeground = Color(0xFF18181B);
  static const destructive = Color(0xFFEF4444);
  static const destructiveForeground = Color(0xFFFFFFFF);
  static const ring = Color(0xFF18181B);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: primary,
          secondary: secondary,
          surface: card,
        ),
        textTheme: GoogleFonts.interTextTheme(),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: border),
          ),
        ),
      );

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        background: background,
      ),
      textTheme: const TextTheme(
        // Use Chelsea Market for headings and game text
        displayLarge: TextStyle(
          fontFamily: 'ChelseaMarket',
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          fontFamily: 'ChelseaMarket',
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          fontFamily: 'ChelseaMarket',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        // Use Inter for body text
        bodyLarge: TextStyle(fontFamily: 'Inter'),
        bodyMedium: TextStyle(fontFamily: 'Inter'),
        bodySmall: TextStyle(fontFamily: 'Inter'),
      ),
      // ... other theme configurations ...
    );
  }
}
