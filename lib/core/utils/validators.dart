import 'package:tailor_app/core/l10n/app_strings.dart';
class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? requiredField(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return S.current.fieldRequired(fieldName ?? S.current.thisField);
    }
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return S.current.emailRequired;
    if (!_emailRegex.hasMatch(v)) return S.current.emailInvalid;
    return null;
  }

  /// Used when CREATING a password.
  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return S.current.passwordRequired;
    if (v.length < 8) return S.current.passwordTooShort;
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return S.current.passwordConfirmRequired;
    if (value != original) return S.current.passwordsDontMatch;
    return null;
  }
}