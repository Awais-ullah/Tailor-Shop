import 'package:flutter_test/flutter_test.dart';
import 'package:tailor_app/features/dashboard/data/dashboard_summary.dart';
import 'package:tailor_app/features/orders/data/order_status.dart';

import 'support/builders.dart';

void main() {
  final today = DateTime(2026, 10, 15);
  DateTime day(int d) => DateTime(2026, 10, d);

  final orders = [
    // Overdue: still active, due yesterday.
    order(id: 'late', number: 1, orderDate: day(1), deliveryDate: day(14)),
    // Due today.
    order(id: 'today', number: 2, orderDate: day(2), deliveryDate: day(15)),
    // Ready, due in 7 days (the last day of the window).
    order(
      id: 'ready',
      number: 3,
      status: OrderStatus.ready,
      orderDate: day(3),
      deliveryDate: day(22),
    ),
    // Due in 8 days: outside the upcoming window.
    order(id: 'later', number: 4, orderDate: day(4), deliveryDate: day(23)),
    // Booked today.
    order(id: 'new', number: 5, orderDate: day(15), deliveryDate: day(20)),
    // Delivered orders are never overdue.
    order(
      id: 'done',
      number: 6,
      status: OrderStatus.delivered,
      orderDate: day(1),
      deliveryDate: day(2),
    ),
    // Cancelled orders don't count anywhere.
    order(
      id: 'gone',
      number: 7,
      status: OrderStatus.cancelled,
      orderDate: day(15),
      deliveryDate: day(1),
    ),
  ];

  final payments = [
    payment(id: 'p3', amount: 700, paidAt: day(15)),
    payment(id: 'p2', amount: 999, paidAt: day(15), voided: true),
    payment(id: 'p1', amount: 300, paidAt: day(14)),
  ];

  final summary = DashboardSummary.compute(
    customers: [customer('c1'), customer('c2', archived: true)],
    orders: orders,
    payments: payments,
    today: today,
  );

  test('counts orders by status, cancelled excluded', () {
    expect(summary.totalOrders, 6);
    expect(summary.pendingOrders, 4);
    expect(summary.readyOrders, 1);
    expect(summary.deliveredOrders, 1);
  });

  test('finds overdue, due-today and booked-today orders', () {
    expect(summary.overdueOrders, 1);
    expect(summary.dueToday, 1);
    expect(summary.todaysOrders, 1);
  });

  test('upcoming deliveries: active, due within a week, overdue first', () {
    expect(
      summary.upcomingDeliveries.map((o) => o.id),
      ['late', 'today', 'new', 'ready'],
    );
  });

  test('collected today ignores voided payments and other days', () {
    expect(summary.collectedToday, 700);
  });

  test('counts only active customers', () {
    expect(summary.totalCustomers, 1);
  });

  test('recent orders are newest number first, at most 5', () {
    expect(summary.recentOrders.map((o) => o.orderNumber), [7, 6, 5, 4, 3]);
  });
}
