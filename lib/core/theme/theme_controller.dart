import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the chosen theme (Light / Dark / System) and saves it on the device.
/// Use [ThemeController.instance] anywhere; listen to it to rebuild.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._() : super(ThemeMode.light);

  static final ThemeController instance = ThemeController._();

  static const String _key = 'theme_mode';

  /// Call once in main() before runApp.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      value = ThemeMode.values.firstWhere(
            (mode) => mode.name == saved,
        orElse: () => ThemeMode.light,
      );
    } catch (_) {
      value = ThemeMode.light;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {
      // Not being able to save is fine; the choice still applies now.
    }
  }
}
