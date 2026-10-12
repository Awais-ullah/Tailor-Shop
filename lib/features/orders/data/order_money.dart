import 'package:tailor_app/features/orders/data/models/order_item.dart';
import 'package:tailor_app/features/orders/data/order_status.dart';

class OrderMoney {
  OrderMoney._();

  static int lineTotal(OrderItem item) => item.quantity * item.unitPrice;

  static int total(Iterable<OrderItem> items) =>
      items.fold(0, (sum, item) => sum + lineTotal(item));

  /// Remaining = Total - Total paid.
  static int remaining({required int total, required int paid}) =>
      total - paid;

  static PaymentStatus paymentStatus({required int total, required int paid}) {
    if (paid <= 0) return PaymentStatus.unpaid;
    if (paid >= total) return PaymentStatus.paid;
    return PaymentStatus.partial;
  }
}