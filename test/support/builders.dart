import 'package:tailor_app/features/customers/data/models/customer.dart';
import 'package:tailor_app/features/orders/data/models/order.dart';
import 'package:tailor_app/features/orders/data/models/order_item.dart';
import 'package:tailor_app/features/orders/data/order_money.dart';
import 'package:tailor_app/features/orders/data/order_status.dart';
import 'package:tailor_app/features/payments/data/models/payment.dart';
import 'package:tailor_app/features/payments/data/payment_method.dart';

/// Small helpers so tests only spell out the fields they care about.

Customer customer(String id, {bool archived = false}) =>
    Customer(id: id, name: 'Customer $id', isArchived: archived);

Order order({
  required String id,
  String customerId = 'c1',
  int number = 1,
  int total = 1000,
  int paid = 0,
  OrderStatus status = OrderStatus.booked,
  DateTime? orderDate,
  DateTime? deliveryDate,
}) {
  final booked = orderDate ?? DateTime(2026, 10, 1);
  return Order(
    id: id,
    customerId: customerId,
    orderNumber: number,
    items: [OrderItem(name: 'Kurta', quantity: 1, unitPrice: total)],
    totalAmount: total,
    totalPaid: paid,
    remainingAmount: OrderMoney.remaining(total: total, paid: paid),
    paymentStatus: OrderMoney.paymentStatus(total: total, paid: paid),
    status: status,
    orderDate: booked,
    deliveryDate: deliveryDate ?? booked,
  );
}

Payment payment({
  required String id,
  String orderId = 'o1',
  String customerId = 'c1',
  int amount = 500,
  PaymentMethod method = PaymentMethod.cash,
  required DateTime paidAt,
  bool voided = false,
}) => Payment(
  id: id,
  orderId: orderId,
  customerId: customerId,
  amount: amount,
  method: method,
  paidAt: paidAt,
  isVoided: voided,
);
