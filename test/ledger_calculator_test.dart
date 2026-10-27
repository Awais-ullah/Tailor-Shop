import 'package:flutter_test/flutter_test.dart';
import 'package:tailor_app/features/orders/data/order_status.dart';
import 'package:tailor_app/features/payments/data/ledger_calculator.dart';

import 'support/builders.dart';

void main() {
  final orders = [
    order(id: 'o1', customerId: 'a', total: 5000, paid: 2000),
    order(id: 'o2', customerId: 'a', total: 3000, paid: 3000),
    order(id: 'o3', customerId: 'b', total: 8000, paid: 0),
    // Cancelled work is never owed.
    order(
      id: 'o4',
      customerId: 'b',
      total: 9000,
      status: OrderStatus.cancelled,
    ),
    order(id: 'o5', customerId: 'c', total: 1000, paid: 1000),
  ];

  group('LedgerCalculator.forCustomer', () {
    test('adds up billed and paid, and counts orders still owing', () {
      final balance = LedgerCalculator.forCustomer('a', orders);
      expect(balance.totalBilled, 8000);
      expect(balance.totalPaid, 5000);
      expect(balance.outstanding, 3000);
      expect(balance.openOrders, 1);
    });

    test('leaves out cancelled orders', () {
      final balance = LedgerCalculator.forCustomer('b', orders);
      expect(balance.totalBilled, 8000);
      expect(balance.outstanding, 8000);
    });

    test('is zero for a customer with no orders', () {
      final balance = LedgerCalculator.forCustomer('nobody', orders);
      expect(balance.totalBilled, 0);
      expect(balance.openOrders, 0);
    });
  });

  group('LedgerCalculator.outstandingBalances', () {
    test('lists only customers who owe money, largest first', () {
      final balances = LedgerCalculator.outstandingBalances(orders);
      expect(balances.map((b) => b.customerId), ['b', 'a']);
      expect(balances.map((b) => b.outstanding), [8000, 3000]);
    });
  });

  group('LedgerCalculator.totalOutstanding', () {
    test('sums what is owed across the shop, cancelled excluded', () {
      expect(LedgerCalculator.totalOutstanding(orders), 11000);
    });
  });
}
