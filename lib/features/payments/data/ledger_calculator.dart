import 'package:equatable/equatable.dart';
import 'package:tailor_app/features/orders/data/models/order.dart';
import 'package:tailor_app/features/orders/data/order_money.dart';
import 'package:tailor_app/features/orders/data/order_status.dart';

class CustomerBalance extends Equatable {
  const CustomerBalance({
    required this.customerId,
    required this.totalBilled,
    required this.totalPaid,
    required this.openOrders,
  });

  final String customerId;
  final int totalBilled;
  final int totalPaid;

  /// Orders that still have money owing.
  final int openOrders;

  int get outstanding =>
      OrderMoney.remaining(total: totalBilled, paid: totalPaid);

  @override
  List<Object?> get props => [customerId, totalBilled, totalPaid, openOrders];
}

class LedgerCalculator {
  LedgerCalculator._();

  /// Cancelled orders don't count: the customer owes nothing for work
  /// that was cancelled.
  static bool _counts(Order order) => order.status != OrderStatus.cancelled;

  static CustomerBalance forCustomer(String customerId, Iterable<Order> orders) {
    var billed = 0;
    var paid = 0;
    var open = 0;

    for (final order in orders) {
      if (order.customerId != customerId || !_counts(order)) continue;
      billed += order.totalAmount;
      paid += order.totalPaid;
      if (OrderMoney.remaining(total: order.totalAmount, paid: order.totalPaid) >
          0) {
        open++;
      }
    }

    return CustomerBalance(
      customerId: customerId,
      totalBilled: billed,
      totalPaid: paid,
      openOrders: open,
    );
  }

  /// Customers who owe money, largest balance first. One pass over all
  /// orders, so it stays fast as the shop grows.
  static List<CustomerBalance> outstandingBalances(Iterable<Order> orders) {
    final billed = <String, int>{};
    final paid = <String, int>{};
    final open = <String, int>{};

    for (final order in orders) {
      if (!_counts(order)) continue;
      final id = order.customerId;
      billed[id] = (billed[id] ?? 0) + order.totalAmount;
      paid[id] = (paid[id] ?? 0) + order.totalPaid;
      if (OrderMoney.remaining(total: order.totalAmount, paid: order.totalPaid) >
          0) {
        open[id] = (open[id] ?? 0) + 1;
      }
    }

    final result = [
      for (final id in billed.keys)
        CustomerBalance(
          customerId: id,
          totalBilled: billed[id]!,
          totalPaid: paid[id] ?? 0,
          openOrders: open[id] ?? 0,
        ),
    ].where((balance) => balance.outstanding > 0).toList();

    result.sort((a, b) => b.outstanding.compareTo(a.outstanding));
    return result;
  }

  static int totalOutstanding(Iterable<Order> orders) {
    var sum = 0;
    for (final order in orders) {
      if (!_counts(order)) continue;
      sum += OrderMoney.remaining(
        total: order.totalAmount,
        paid: order.totalPaid,
      );
    }
    return sum;
  }
}