class PhoneUtils {
  PhoneUtils._();

  /// Keeps digits only and converts Pakistani international formats
  /// (+92 300 ..., 0092 300 ...) to the local 03xx format, so the same
  /// number written differently compares as equal.
  static String normalize(String input) {
    var digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0092')) {
      digits = '0${digits.substring(4)}';
    } else if (digits.startsWith('92') && digits.length >= 12) {
      digits = '0${digits.substring(2)}';
    }
    return digits;
  }

  /// Phone is optional; if entered it must look like a real number.
  static String? validateOptional(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;

    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7 || digits.length > 15) {
      return 'Enter a valid phone number';
    }
    return null;
  }
}