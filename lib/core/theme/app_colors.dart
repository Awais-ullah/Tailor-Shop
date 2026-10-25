import 'package:flutter/material.dart';

/// Tailor Shop colors, taken from the app icon (teal, gold, cream).
/// Screens never hard-code colors; they always read from here.
///
/// NOTE: the old "slate" names are kept so nothing else breaks. They are now
/// teal-tinted neutrals (slate50 is the cream screen background).
class AppColors {
  AppColors._();

  // Brand: deep teal
  static const Color primary = Color(0xFF0B4A57);
  static const Color primaryDark = Color(0xFF07343E);
  static const Color primaryLight = Color(0xFF0E5A69);
  static const Color primarySoft = Color(0xFFE4F0F1);

  // Brand: gold accent (use for icons / highlights, not small text)
  static const Color gold = Color(0xFFD4A94F);
  static const Color goldSoft = Color(0xFFFBF3E0);
  static const Color goldDeep = Color(0xFF8A6A1F); // gold that is readable as text

  // Neutrals
  static const Color slate50 = Color(0xFFF8F4EA); // screen background (cream)
  static const Color slate100 = Color(0xFFEEF1EE);
  static const Color slate200 = Color(0xFFE3E8E4);
  static const Color slate300 = Color(0xFFCBD5D1);
  static const Color slate500 = Color(0xFF556B70);
  static const Color slate700 = Color(0xFF2F4A50);
  static const Color slate900 = Color(0xFF10262C);

  // Semantic
  static const Color success = Color(0xFF157A3B);
  static const Color warning = Color(0xFF9A6700);
  static const Color danger = Color(0xFFB42318);
  static const Color info = Color(0xFF0A5A8C);
}