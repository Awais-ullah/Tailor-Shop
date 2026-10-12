import 'package:tailor_app/core/utils/app_dates.dart';
import 'package:tailor_app/features/customers/data/models/customer.dart';
import 'package:tailor_app/features/orders/data/models/order.dart';
import 'package:tailor_app/features/orders/data/order_status.dart';
import 'package:tailor_app/features/payments/data/ledger_calculator.dart';
import 'package:tailor_app/features/payments/data/models/payment.dart';

/// Every number on the dashboard, calculated in one place from the data
/// already loaded in memory. Pure Dart, so it is easy to test.
class DashboardSummary {
  const DashboardSummary({
    required this.totalCustomers,
    required this.totalOrders,
    required this.pendingOrders,
    required this.readyOrders,
    required this.deliveredOrders,
    required this.todaysOrders,
    required this.dueToday,
    required this.overdueOrders,
    required this.collectedToday,
    required this.totalOutstanding,
    required this.upcomingDeliveries,
    required this.recentOrders,
    required this.recentPayments,
    required this.topBalances,
  });

  final int totalCustomers;

  /// Everything except cancelled orders.
  final int totalOrders;

  /// Booked + Cutting + Stitching.
  final int pendingOrders;
  final int readyOrders;
  final int deliveredOrders;

  /// Orders booked today.
  final int todaysOrders;
  final int dueToday;
  final int overdueOrders;

  final int collectedToday;
  final int totalOutstanding;

  /// Active orders due within a week (overdue ones first), at most 5.
  final List<Order> upcomingDeliveries;
  final List<Order> recentOrders;
  final List<Payment> recentPayments;
  final List<CustomerBalance> topBalances;

  /// [payments] must be newest first (PaymentsCubit already does this).
  factory DashboardSummary.compute({
    required Iterable<Customer> customers,
    required List<Order> orders,
    required List<Payment> payments,
    required DateTime today,
  }) {
    final day = AppDates.dateOnly(today);
    final weekAhead = AppDates.addDays(day, 7);

    var total = 0;
    var pending = 0;
    var ready = 0;
    var delivered = 0;
    var todays = 0;
    var dueToday = 0;
    var overdue = 0;
    final upcoming = <Order>[];

    for (final order in orders) {
      if (order.status == OrderStatus.cancelled) continue;
      total++;

      switch (order.status) {
        case OrderStatus.booked:
        case OrderStatus.cutting:
        case OrderStatus.stitching:
          pending++;
        case OrderStatus.ready:
          ready++;
        case OrderStatus.delivered:
          delivered++;
        case OrderStatus.cancelled:
          break;
      }

      if (AppDates.dateOnly(order.orderDate) == day) todays++;

      if (order.status.isActive) {
        final due = AppDates.dateOnly(order.deliveryDate);
        if (due == day) dueToday++;
        if (due.isBefore(day)) overdue++;
        if (!due.isAfter(weekAhead)) upcoming.add(order);
      }
    }

    upcoming.sort((a, b) {
      final byDate = a.deliveryDate.compareTo(b.deliveryDate);
      return byDate != 0 ? byDate : a.orderNumber.compareTo(b.orderNumber);
    });

    final recent = [...orders]
      ..sort((a, b) => b.orderNumber.compareTo(a.orderNumber));

    var collected = 0;
    for (final payment in payments) {
      if (!payment.isVoided && AppDates.dateOnly(payment.paidAt) == day) {
        collected += payment.amount;
      }
    }

    return DashboardSummary(
      totalCustomers: customers.where((c) => !c.isArchived).length,
      totalOrders: total,
      pendingOrders: pending,
      readyOrders: ready,
      deliveredOrders: delivered,
      todaysOrders: todays,
      dueToday: dueToday,
      overdueOrders: overdue,
      collectedToday: collected,
      totalOutstanding: LedgerCalculator.totalOutstanding(orders),
      upcomingDeliveries: upcoming.take(5).toList(),
      recentOrders: recent.take(5).toList(),
      recentPayments: payments.take(5).toList(),
      topBalances: LedgerCalculator.outstandingBalances(orders).take(5).toList(),
    );
  }
}