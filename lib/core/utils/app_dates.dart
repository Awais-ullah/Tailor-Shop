import 'package:intl/intl.dart';

/// Date helpers. Order and delivery dates are whole days, stored as
/// midnight in the device's time zone.
class AppDates {
  AppDates._();

  static final DateFormat _long = DateFormat('EEE, d MMM y');
  static final DateFormat _medium = DateFormat('d MMM y');
  static final DateFormat _short = DateFormat('d MMM');

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime today() => dateOnly(DateTime.now());

  /// Calendar-safe (not "+ 24 hours", which breaks across clock changes).
  static DateTime addDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);

  static String long(DateTime date) => _long.format(date);
  static String medium(DateTime date) => _medium.format(date);
  static String short(DateTime date) => _short.format(date);

  static bool isBeforeToday(DateTime date) => dateOnly(date).isBefore(today());
}