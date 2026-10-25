import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A currency the shop can display. Display only: nothing is converted.
class AppCurrency {
  const AppCurrency(
    this.code,
    this.name,
    this.symbol, {
    this.spaced = false,
    this.indianGrouping = false,
  });

  /// ISO code, e.g. 'PKR'. This is what we save on the device.
  final String code;

  /// English name shown in the list.
  final String name;

  /// What appears before the amount, e.g. 'Rs.' or '$'.
  final String symbol;

  /// true  -> "Rs. 5,000" / "SAR 5,000"
  /// false -> "$5,000"
  final bool spaced;

  /// true  -> 1,00,000 (lakh / crore, used in Pakistan, India, Bangladesh)
  /// false -> 100,000
  final bool indianGrouping;

  /// Text placed in front of an amount, e.g. "Rs. " or "$".
  String get prefix => spaced ? '$symbol ' : symbol;

  /// e.g. "Pakistani Rupee (Rs.)"
  String get display => '$name ($symbol)';

  static const AppCurrency pkr = AppCurrency(
    'PKR',
    'Pakistani Rupee',
    'Rs.',
    spaced: true,
    indianGrouping: true,
  );

  static const List<AppCurrency> all = [
    pkr,
    AppCurrency('USD', 'US Dollar', r'$'),
    AppCurrency('EUR', 'Euro', '€'),
    AppCurrency('GBP', 'British Pound', '£'),
    AppCurrency('SAR', 'Saudi Riyal', 'SAR', spaced: true),
    AppCurrency('AED', 'UAE Dirham', 'AED', spaced: true),
    AppCurrency('INR', 'Indian Rupee', '₹', indianGrouping: true),
    AppCurrency('CNY', 'Chinese Yuan', 'CN¥'),
    AppCurrency('TRY', 'Turkish Lira', '₺'),
    AppCurrency(
      'BDT',
      'Bangladeshi Taka',
      'Tk',
      spaced: true,
      indianGrouping: true,
    ),
  ];

  static AppCurrency byCode(String? code) {
    for (final c in all) {
      if (c.code == code) return c;
    }
    return pkr;
  }
}

/// Holds the chosen currency and saves it on the device.
/// Use [CurrencyController.instance] anywhere; listen to it to rebuild.
class CurrencyController extends ValueNotifier<AppCurrency> {
  CurrencyController._() : super(AppCurrency.pkr);

  static final CurrencyController instance = CurrencyController._();

  static const String _key = 'currency_code';

  /// Call once in main() before runApp.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      value = AppCurrency.byCode(prefs.getString(_key));
    } catch (_) {
      value = AppCurrency.pkr;
    }
  }

  Future<void> setCurrency(AppCurrency currency) async {
    value = currency;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, currency.code);
    } catch (_) {
      // Not being able to save is fine; the choice still applies now.
    }
  }
}
