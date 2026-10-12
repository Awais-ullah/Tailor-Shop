import 'package:flutter/material.dart';

/// Professional Slate color system.
/// Screens never hard-code colors; they always read from here.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF1D4ED8);
  static const Color primarySoft = Color(0xFFEFF4FF);

  // Slate neutrals
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate900 = Color(0xFF0F172A);

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF0284C7);
}