import 'package:tailor_app/core/l10n/app_strings.dart';

/// Date helpers. Order and delivery dates are whole days, stored as
/// midnight in the device's time zone.
///
/// Dates are formatted with our own month / weekday names so they follow the
/// app language (Latin digits are used in every language).
class AppDates {
  AppDates._();

  static const Map<String, List<String>> _months = {
    'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
    'ur': ['جنوری', 'فروری', 'مارچ', 'اپریل', 'مئی', 'جون', 'جولائی', 'اگست', 'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر'],
    'ru': ['Janwari', 'Farwari', 'March', 'April', 'May', 'June', 'July', 'Agast', 'Sitambar', 'Aktoobar', 'Navambar', 'Disambar'],
    'ar': ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'],
    'hi': ['जन॰', 'फ़र॰', 'मार्च', 'अप्रैल', 'मई', 'जून', 'जुल॰', 'अग॰', 'सित॰', 'अक्टू॰', 'नव॰', 'दिस॰'],
    'zh': ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'],

  };

  /// Index 0 = Monday (matches DateTime.weekday - 1).
  static const Map<String, List<String>> _weekdays = {
    'en': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    'ur': ['پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ', 'اتوار'],
    'ru': ['Peer', 'Mangal', 'Budh', 'Jumerat', 'Jumma', 'Hafta', 'Itwaar'],
    'ar': ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'],
    'hi': ['सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि', 'रवि'],
    'zh': ['周一', '周二', '周三', '周四', '周五', '周六', '周日'],
  };

  static String get _code => S.current.code;

  /// Short month name for 1..12 (used by report charts).
  static String monthShort(int month) =>
      (_months[_code] ?? _months['en']!)[month - 1];

  static String _weekday(DateTime d) =>
      (_weekdays[_code] ?? _weekdays['en']!)[d.weekday - 1];

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime today() => dateOnly(DateTime.now());

  /// Calendar-safe (not "+ 24 hours", which breaks across clock changes).
  static DateTime addDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);

  /// e.g. "Sat, 24 Oct 2026"
  static String long(DateTime date) {
    if (_code == 'zh') return '${_weekday(date)} ${medium(date)}';
    return '${_weekday(date)}, ${medium(date)}';
  }

  /// e.g. "24 Oct 2026"
  static String medium(DateTime date) {
    if (_code == 'zh') return '${date.year}年${date.month}月${date.day}日';
    return '${date.day} ${monthShort(date.month)} ${date.year}';
  }

  /// e.g. "24 Oct"
  static String short(DateTime date) {
    if (_code == 'zh') return '${date.month}月${date.day}日';
    return '${date.day} ${monthShort(date.month)}';
  }

  static bool isBeforeToday(DateTime date) => dateOnly(date).isBefore(today());
}
