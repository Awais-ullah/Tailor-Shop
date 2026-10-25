import 'package:intl/intl.dart';
import 'package:tailor_app/core/currency/currency_controller.dart';

/// Formats amounts in the currency chosen in Settings.
/// Amounts are always whole numbers; the currency only changes how they look.
class Money {
  Money._();

  // en_IN grouping gives 1,00,000 (lakh/crore), the convention used in
  // Pakistan, India and Bangladesh. Other currencies use 100,000.
  static final NumberFormat _indian = NumberFormat.decimalPattern('en_IN');
  static final NumberFormat _western = NumberFormat.decimalPattern('en_US');

  /// Whole units in the chosen currency, e.g. 5000 -> "Rs. 5,000" or "$5,000".
  /// (The name `pkr` is kept so existing code keeps working.)
  static String pkr(int amount) {
    final currency = CurrencyController.instance.value;
    final number =
    (currency.indianGrouping ? _indian : _western).format(amount);
    return '${currency.prefix}$number';
  }

  /// The text in front of an amount, for input fields: "Rs. ", "$", ...
  static String get prefix => CurrencyController.instance.value.prefix;
}
