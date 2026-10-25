import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';

/// Holds the chosen app language and saves it on the device.
///
/// [value] is the saved choice: a language code ('en', 'ur', ...) or `null`
/// for "System default". Listen to it to rebuild when the language changes.
class LocaleController extends ValueNotifier<String?> {
  LocaleController._() : super(null);

  static final LocaleController instance = LocaleController._();

  static const String _key = 'app_language';

  /// The language actually in use right now ('en' if the phone's language
  /// is not one we support).
  String get activeCode => _resolve(value);

  static String _resolve(String? saved) {
    if (AppLanguage.byCode(saved) != null) return saved!;
    final device = ui.PlatformDispatcher.instance.locale.languageCode;
    return AppLanguage.byCode(device) != null ? device : 'en';
  }

  /// Call once in main() before runApp.
  Future<void> load() async {
    String? saved;
    try {
      final prefs = await SharedPreferences.getInstance();
      saved = prefs.getString(_key);
    } catch (_) {
      saved = null;
    }
    // Set directly: nobody is listening yet.
    value = AppLanguage.byCode(saved) != null ? saved : null;
    S.setLanguage(_resolve(value));
  }

  /// Pass `null` for "System default".
  Future<void> setLanguage(String? code) async {
    final next = AppLanguage.byCode(code) != null ? code : null;
    S.setLanguage(_resolve(next));
    value = next; // notifies listeners (the app rebuilds)
    try {
      final prefs = await SharedPreferences.getInstance();
      if (next == null) {
        await prefs.remove(_key);
      } else {
        await prefs.setString(_key, next);
      }
    } catch (_) {
      // Not being able to save is fine; the choice still applies now.
    }
  }
}
