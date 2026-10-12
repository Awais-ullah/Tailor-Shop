import 'package:intl/intl.dart';

class Money {
  Money._();

  // en_IN grouping gives 1,00,000 (lakh/crore), the convention used in Pakistan.
  static final NumberFormat _format = NumberFormat.decimalPattern('en_IN');

  /// Whole rupees, e.g. 5000 -> "Rs. 5,000".
  static String pkr(int amount) => 'Rs. ${_format.format(amount)}';
}