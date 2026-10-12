/// Reads and displays measurements in inches, the way tailors write them.
class InchFormat {
  InchFormat._();

  static const double maxInches = 150;

  static const Map<String, double> _glyphValues = {
    '⅛': 0.125,
    '¼': 0.25,
    '⅜': 0.375,
    '½': 0.5,
    '⅝': 0.625,
    '¾': 0.75,
    '⅞': 0.875,
  };

  // Index = number of eighths.
  static const List<String> _glyphs = ['', '⅛', '¼', '⅜', '½', '⅝', '¾', '⅞'];

  /// Accepts "15", "15.5", "15,5", "15 1/2", "1/2" and "15½".
  /// Returns null when the text is empty or not a valid number.
  static double? parse(String input) {
    final text = input.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;

    double? result;
    final glyphValue = _glyphValues[text.substring(text.length - 1)];

    if (glyphValue != null) {
      // Ends with a fraction symbol, e.g. "15½".
      final wholeText = text.substring(0, text.length - 1).trim();
      final whole = wholeText.isEmpty ? 0.0 : double.tryParse(wholeText);
      if (whole == null) return null;
      result = whole + glyphValue;
    } else {
      // "15 1/2" or "1/2".
      final match =
      RegExp(r'^(?:(\d+)\s+)?(\d+)\s*/\s*(\d+)$').firstMatch(text);
      if (match != null) {
        final whole = int.parse(match.group(1) ?? '0');
        final numerator = int.parse(match.group(2)!);
        final denominator = int.parse(match.group(3)!);
        if (denominator == 0) return null;
        result = whole + numerator / denominator;
      } else {
        result = double.tryParse(text);
      }
    }

    if (result == null || !result.isFinite) return null;
    return double.parse(result.toStringAsFixed(3));
  }

  /// Form validator. The field is optional, so empty is fine.
  static String? validateOptional(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;

    final parsed = parse(text);
    if (parsed == null) return 'Use a number like 15, 15.5 or 15 1/2';
    if (parsed <= 0) return 'Must be greater than 0';
    if (parsed > maxInches) return 'Must be ${maxInches.toInt()} or less';
    return null;
  }

  /// Shows exact eighths as fractions (15½) and anything else as a
  /// decimal, so 15.3 is never silently displayed as something it isn't.
  static String format(double value) {
    final whole = value.floor();
    final eighths = (value - whole) * 8;
    final rounded = eighths.round();

    if ((eighths - rounded).abs() < 1e-9) {
      if (rounded == 0) return '$whole';
      if (rounded == 8) return '${whole + 1}';
      final glyph = _glyphs[rounded];
      return whole == 0 ? glyph : '$whole$glyph';
    }

    var text = value.toStringAsFixed(2);
    text = text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    return text;
  }
}