import 'package:flutter/material.dart';
import 'dart:ui';

class GameTextStyles {
  // Font weights as static constants
  static const double thin = 100.0;
  static const double extraLight = 200.0;
  static const double light = 300.0;
  static const double regular = 400.0;
  static const double medium = 500.0;
  static const double semiBold = 600.0;
  static const double bold = 700.0;
  static const double heavy = 800.0;

  static TextStyle _withWeight(double weight) {
    return TextStyle(
      fontFamily: 'CraftworkGrotesk',
      fontVariations: [FontVariation('wght', weight)],
    );
  }

  static const TextStyle heading = TextStyle(
    fontFamily: 'CraftworkGrotesk',
    fontSize: 28,
    fontVariations: [FontVariation('wght', bold)],
    color: Color(0xFF1C1C1E),
  );

  static const TextStyle subheading = TextStyle(
    fontFamily: 'CraftworkGrotesk',
    fontSize: 18,
    fontVariations: [FontVariation('wght', medium)],
    color: Color(0xFF1C1C1E),
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'CraftworkGrotesk',
    fontSize: 16,
    fontVariations: [FontVariation('wght', regular)],
    color: Color(0xFF1C1C1E),
  );

  static const TextStyle score = TextStyle(
    fontFamily: 'CraftworkGrotesk',
    fontSize: 20,
    fontVariations: [FontVariation('wght', bold)],
    color: Color(0xFF1C1C1E),
  );
}
