import 'package:flutter/material.dart';

/// Theme-aware colors. Read them with `context.pal.<name>`.
///
/// Light and dark versions live here, in one place. [AppColors] keeps the
/// fixed brand colors (teal gradient, gold) that look the same in both modes.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.brand,
    required this.primary,
    required this.primarySoft,
    required this.goldDeep,
    required this.slate50,
    required this.slate100,
    required this.slate200,
    required this.slate300,
    required this.slate500,
    required this.slate700,
    required this.slate900,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
  });

  final bool isDark;

  /// Screen background.
  final Color background;

  /// Cards, sheets, dialogs, the bottom bar.
  final Color surface;

  /// Teal used as a FILL (buttons, avatars, the selected tab pill).
  final Color brand;

  /// Teal used as text or icon color.
  final Color primary;

  /// Soft teal tint behind icons and avatars.
  final Color primarySoft;

  /// Gold that is readable as text.
  final Color goldDeep;

  // Neutrals (names kept from the original palette).
  final Color slate50; // sunken boxes inside a card
  final Color slate100; // chip backgrounds, progress tracks
  final Color slate200; // borders, dividers
  final Color slate300; // input borders
  final Color slate500; // muted text
  final Color slate700; // secondary text
  final Color slate900; // main text

  // Status colors.
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  static const AppPalette light = AppPalette(
    isDark: false,
    background: Color(0xFFF8F4EA),
    surface: Color(0xFFFFFFFF),
    brand: Color(0xFF0B4A57),
    primary: Color(0xFF0B4A57),
    primarySoft: Color(0xFFE4F0F1),
    goldDeep: Color(0xFF8A6A1F),
    slate50: Color(0xFFF8F4EA),
    slate100: Color(0xFFEEF1EE),
    slate200: Color(0xFFE3E8E4),
    slate300: Color(0xFFCBD5D1),
    slate500: Color(0xFF556B70),
    slate700: Color(0xFF2F4A50),
    slate900: Color(0xFF10262C),
    success: Color(0xFF157A3B),
    warning: Color(0xFF9A6700),
    danger: Color(0xFFB42318),
    info: Color(0xFF0A5A8C),
  );

  static const AppPalette dark = AppPalette(
    isDark: true,
    background: Color(0xFF0A1A1F),
    surface: Color(0xFF12272E),
    brand: Color(0xFF0F6678),
    primary: Color(0xFF5BB9C9),
    primarySoft: Color(0xFF17363F),
    goldDeep: Color(0xFFE3BF6E),
    slate50: Color(0xFF0D1F25),
    slate100: Color(0xFF1A343D),
    slate200: Color(0xFF24414B),
    slate300: Color(0xFF34545F),
    slate500: Color(0xFF9DB2B6),
    slate700: Color(0xFFC5D3D5),
    slate900: Color(0xFFE8EFEF),
    success: Color(0xFF4CC27A),
    warning: Color(0xFFE0A83A),
    danger: Color(0xFFFF8A80),
    info: Color(0xFF6CB8E8),
  );

  /// Makes a fixed (light-mode) color readable on a dark surface.
  /// In light mode the color is returned unchanged.
  Color adapt(Color color) {
    if (!isDark) return color;
    final hsl = HSLColor.fromColor(color);
    final lighter = (hsl.lightness + 0.28).clamp(0.0, 0.72);
    return hsl.withLightness(lighter).toColor();
  }

  @override
  AppPalette copyWith({
    bool? isDark,
    Color? background,
    Color? surface,
    Color? brand,
    Color? primary,
    Color? primarySoft,
    Color? goldDeep,
    Color? slate50,
    Color? slate100,
    Color? slate200,
    Color? slate300,
    Color? slate500,
    Color? slate700,
    Color? slate900,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
  }) {
    return AppPalette(
      isDark: isDark ?? this.isDark,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      brand: brand ?? this.brand,
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      goldDeep: goldDeep ?? this.goldDeep,
      slate50: slate50 ?? this.slate50,
      slate100: slate100 ?? this.slate100,
      slate200: slate200 ?? this.slate200,
      slate300: slate300 ?? this.slate300,
      slate500: slate500 ?? this.slate500,
      slate700: slate700 ?? this.slate700,
      slate900: slate900 ?? this.slate900,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return AppPalette(
      isDark: t < 0.5 ? isDark : other.isDark,
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      brand: mix(brand, other.brand),
      primary: mix(primary, other.primary),
      primarySoft: mix(primarySoft, other.primarySoft),
      goldDeep: mix(goldDeep, other.goldDeep),
      slate50: mix(slate50, other.slate50),
      slate100: mix(slate100, other.slate100),
      slate200: mix(slate200, other.slate200),
      slate300: mix(slate300, other.slate300),
      slate500: mix(slate500, other.slate500),
      slate700: mix(slate700, other.slate700),
      slate900: mix(slate900, other.slate900),
      success: mix(success, other.success),
      warning: mix(warning, other.warning),
      danger: mix(danger, other.danger),
      info: mix(info, other.info),
    );
  }
}

extension AppPaletteContext on BuildContext {
  /// The colors for the current theme (light or dark).
  AppPalette get pal => Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
