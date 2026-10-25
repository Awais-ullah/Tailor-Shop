import 'package:tailor_app/core/l10n/app_strings.dart';
import 'package:tailor_app/core/utils/app_dates.dart';
import 'package:tailor_app/features/orders/data/models/order.dart';
import 'package:tailor_app/features/orders/data/order_status.dart';
import 'package:tailor_app/features/payments/data/models/payment.dart';
import 'package:tailor_app/features/payments/data/payment_method.dart';

/// A span of whole days. [end] is the last day, inclusive.
class DateRange {
  const DateRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  bool contains(DateTime date) {
    final day = AppDates.dateOnly(date);
    return !day.isBefore(start) && !day.isAfter(end);
  }
}

enum ReportPeriod {
  today('range.today', 'Today'),
  thisWeek('range.week', 'This week'),
  thisMonth('range.month', 'This month'),
  lastMonth('range.lastMonth', 'Last month'),
  thisYear('range.year', 'This year');

  const ReportPeriod(this._id, this._fallback);

  final String _id;
  final String _fallback;

  String get label => S.current.dyn(_id, _fallback);

  DateRange range(DateTime now) {
    final today = AppDates.dateOnly(now);

    switch (this) {
      case ReportPeriod.today:
        return DateRange(today, today);
      case ReportPeriod.thisWeek:
      // Weeks run Monday to Sunday.
        final monday = AppDates.addDays(today, -(today.weekday - 1));
        return DateRange(monday, AppDates.addDays(monday, 6));
      case ReportPeriod.thisMonth:
        return DateRange(
          DateTime(today.year, today.month, 1),
          DateTime(today.year, today.month + 1, 0),
        );
      case ReportPeriod.lastMonth:
        return DateRange(
          DateTime(today.year, today.month - 1, 1),
          DateTime(today.year, today.month, 0),
        );
      case ReportPeriod.thisYear:
        return DateRange(
          DateTime(today.year, 1, 1),
          DateTime(today.year, 12, 31),
        );
    }
  }
}

class IncomeBucket {
  const IncomeBucket(this.label, this.amount);

  final String label;
  final int amount;
}

class TopCustomer {
  const TopCustomer({
    required this.customerId,
    required this.orderCount,
    required this.billed,
  });

  final String customerId;
  final int orderCount;
  final int billed;
}

class ReportSummary {
  const ReportSummary({
    required this.range,
    required this.income,
    required this.incomeByMethod,
    required this.newOrders,
    required this.bookedValue,
    required this.ordersByStatus,
    required this.topCustomers,
    required this.buckets,
  });

  final DateRange range;

  /// Money received in the period (voided payments excluded).
  final int income;
  final Map<PaymentMethod, int> incomeByMethod;

  /// Orders booked in the period (cancelled excluded) and their value.
  final int newOrders;
  final int bookedValue;

  /// Orders booked in the period, by their CURRENT status.
  final Map<OrderStatus, int> ordersByStatus;

  /// Customers with the highest order value in the period.
  final List<TopCustomer> topCustomers;

  /// Income per day (or per month for a year). Empty for "Today".
  final List<IncomeBucket> buckets;

  factory ReportSummary.compute({
    required List<Order> orders,
    required List<Payment> payments,
    required ReportPeriod period,
    required DateTime now,
  }) {
    final today = AppDates.dateOnly(now);
    final range = period.range(now);

    var income = 0;
    final byMethod = {for (final method in PaymentMethod.values) method: 0};
    final byDay = <DateTime, int>{};

    for (final payment in payments) {
      if (payment.isVoided || !range.contains(payment.paidAt)) continue;
      income += payment.amount;
      byMethod[payment.method] = (byMethod[payment.method] ?? 0) + payment.amount;

      final day = AppDates.dateOnly(payment.paidAt);
      byDay[day] = (byDay[day] ?? 0) + payment.amount;
    }

    var newOrders = 0;
    var booked = 0;
    final byStatus = {for (final status in OrderStatus.values) status: 0};
    final billedByCustomer = <String, int>{};
    final countByCustomer = <String, int>{};

    for (final order in orders) {
      if (!range.contains(order.orderDate)) continue;

      byStatus[order.status] = (byStatus[order.status] ?? 0) + 1;
      if (order.status == OrderStatus.cancelled) continue;

      newOrders++;
      booked += order.totalAmount;
      billedByCustomer[order.customerId] =
          (billedByCustomer[order.customerId] ?? 0) + order.totalAmount;
      countByCustomer[order.customerId] =
          (countByCustomer[order.customerId] ?? 0) + 1;
    }

    final top = [
      for (final entry in billedByCustomer.entries)
        TopCustomer(
          customerId: entry.key,
          orderCount: countByCustomer[entry.key] ?? 0,
          billed: entry.value,
        ),
    ]..sort((a, b) => b.billed.compareTo(a.billed));

    return ReportSummary(
      range: range,
      income: income,
      incomeByMethod: byMethod,
      newOrders: newOrders,
      bookedValue: booked,
      ordersByStatus: byStatus,
      topCustomers: top.take(5).toList(),
      buckets: _buckets(period, range, today, byDay),
    );
  }

  static List<IncomeBucket> _buckets(
      ReportPeriod period,
      DateRange range,
      DateTime today,
      Map<DateTime, int> byDay,
      ) {
    if (period == ReportPeriod.today) return const [];

    // Don't draw empty bars for days that haven't happened yet.
    final last = range.end.isAfter(today) ? today : range.end;

    if (period == ReportPeriod.thisYear) {
      final monthly = <int, int>{};
      byDay.forEach((day, amount) {
        monthly[day.month] = (monthly[day.month] ?? 0) + amount;
      });

      return [
        for (var month = 1; month <= last.month; month++)
          IncomeBucket(
            AppDates.monthShort(month),
            monthly[month] ?? 0,
          ),
      ];
    }

    final buckets = <IncomeBucket>[];
    for (var day = range.start;
    !day.isAfter(last);
    day = AppDates.addDays(day, 1)) {
      buckets.add(IncomeBucket(AppDates.short(day), byDay[day] ?? 0));
    }
    return buckets;
  }
}