import 'package:flutter_test/flutter_test.dart';
import 'package:tailor_app/features/orders/data/order_status.dart';
import 'package:tailor_app/features/payments/data/payment_method.dart';
import 'package:tailor_app/features/reports/data/report_summary.dart';

import 'support/builders.dart';

void main() {
  group('ReportPeriod.range', () {
    test('a week runs Monday to Sunday', () {
      // Wednesday 28 Oct 2026.
      final range = ReportPeriod.thisWeek.range(DateTime(2026, 10, 28, 15));
      expect(range.start, DateTime(2026, 10, 26));
      expect(range.end, DateTime(2026, 11, 1));
    });

    test('this month ends on its last day, including February', () {
      final range = ReportPeriod.thisMonth.range(DateTime(2026, 2, 10));
      expect(range.start, DateTime(2026, 2, 1));
      expect(range.end, DateTime(2026, 2, 28));
    });

    test('last month crosses the year boundary in January', () {
      final range = ReportPeriod.lastMonth.range(DateTime(2026, 1, 15));
      expect(range.start, DateTime(2025, 12, 1));
      expect(range.end, DateTime(2025, 12, 31));
    });

    test('ranges include both their first and last day', () {
      final range = ReportPeriod.today.range(DateTime(2026, 10, 5, 9));
      expect(range.contains(DateTime(2026, 10, 5, 23, 59)), isTrue);
      expect(range.contains(DateTime(2026, 10, 6)), isFalse);
    });
  });

  group('ReportSummary.compute', () {
    final now = DateTime(2026, 10, 3, 18);

    final payments = [
      payment(id: 'p1', amount: 1000, paidAt: DateTime(2026, 10, 1)),
      payment(
        id: 'p2',
        amount: 500,
        method: PaymentMethod.bank,
        paidAt: DateTime(2026, 10, 3),
      ),
      payment(
        id: 'p3',
        amount: 9999,
        paidAt: DateTime(2026, 10, 2),
        voided: true,
      ),
      // Last month: outside the period.
      payment(id: 'p4', amount: 7000, paidAt: DateTime(2026, 9, 30)),
    ];

    final orders = [
      order(id: 'o1', customerId: 'a', total: 3000,
          orderDate: DateTime(2026, 10, 1)),
      order(id: 'o2', customerId: 'b', total: 5000,
          orderDate: DateTime(2026, 10, 2)),
      order(id: 'o3', customerId: 'a', total: 4000,
          orderDate: DateTime(2026, 10, 3)),
      order(
        id: 'o4',
        customerId: 'c',
        total: 8000,
        status: OrderStatus.cancelled,
        orderDate: DateTime(2026, 10, 2),
      ),
    ];

    final summary = ReportSummary.compute(
      orders: orders,
      payments: payments,
      period: ReportPeriod.thisMonth,
      now: now,
    );

    test('income counts only non-voided payments inside the period', () {
      expect(summary.income, 1500);
      expect(summary.incomeByMethod[PaymentMethod.cash], 1000);
      expect(summary.incomeByMethod[PaymentMethod.bank], 500);
    });

    test('new orders and booked value leave out cancelled orders', () {
      expect(summary.newOrders, 3);
      expect(summary.bookedValue, 12000);
    });

    test('orders by status still show cancelled orders', () {
      expect(summary.ordersByStatus[OrderStatus.booked], 3);
      expect(summary.ordersByStatus[OrderStatus.cancelled], 1);
    });

    test('top customers are ranked by value booked', () {
      expect(summary.topCustomers.map((c) => c.customerId), ['a', 'b']);
      expect(summary.topCustomers.first.orderCount, 2);
      expect(summary.topCustomers.first.billed, 7000);
    });

    test('daily buckets stop at today', () {
      expect(summary.buckets.map((b) => b.amount), [1000, 0, 500]);
    });

    test('a year is bucketed by month, up to the current month', () {
      final yearly = ReportSummary.compute(
        orders: orders,
        payments: payments,
        period: ReportPeriod.thisYear,
        now: now,
      );
      expect(yearly.buckets, hasLength(10));
      expect(yearly.buckets[8].amount, 7000); // September
      expect(yearly.buckets[9].amount, 1500); // October
    });

    test('"today" has no chart buckets', () {
      final today = ReportSummary.compute(
        orders: orders,
        payments: payments,
        period: ReportPeriod.today,
        now: now,
      );
      expect(today.buckets, isEmpty);
      expect(today.income, 500);
    });
  });
}
