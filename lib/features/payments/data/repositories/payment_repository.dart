import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:tailor_app/core/data/shop_collections.dart';
import 'package:tailor_app/features/orders/data/models/order.dart';
import 'package:tailor_app/features/orders/data/order_money.dart';
import 'package:tailor_app/features/payments/data/models/payment.dart';

/// The only class that moves money: it writes payments and the money
/// fields of orders (totalPaid, remainingAmount, lastPaymentId). Every
/// change is ONE batch that writes both, so they can never disagree, and
/// the security rules check each batch.
class PaymentRepository {
  PaymentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _payments(String shopId) =>
      ShopCollections.payments(_firestore, shopId);

  CollectionReference<Map<String, dynamic>> _orders(String shopId) =>
      ShopCollections.orders(_firestore, shopId);

  String newId(String shopId) => _payments(shopId).doc().id;

  /// Live list of every payment in the shop.
  Stream<List<Payment>> watchPayments(String shopId) {
    return ShopCollections.watchedPayments(_firestore, shopId).snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => Payment.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  /// Creates a new order AND its advance payment in one atomic batch.
  /// The order must already carry `totalPaid == payment.amount` and
  /// `lastPaymentId == payment.id`.
  Future<void> createOrderWithAdvance(
      String shopId, {
        required Order order,
        required Payment payment,
      }) {
    final batch = _firestore.batch();
    batch.set(_orders(shopId).doc(order.id), order.toMap());
    batch.set(_payments(shopId).doc(payment.id), payment.toMap());
    return batch.commit();
  }

  /// Adds the payment AND moves the order's totals, atomically.
  /// Increments (not "set to") are used so that two devices recording
  /// payments while offline both still count when they sync.
  Future<void> recordPayment(
      String shopId, {
        required Order order,
        required Payment payment,
      }) {
    final newPaid = order.totalPaid + payment.amount;

    final batch = _firestore.batch();
    batch.set(_payments(shopId).doc(payment.id), payment.toMap());
    batch.update(_orders(shopId).doc(order.id), {
      'totalPaid': FieldValue.increment(payment.amount),
      'remainingAmount': FieldValue.increment(-payment.amount),
      'paymentStatus': OrderMoney.paymentStatus(
        total: order.totalAmount,
        paid: newPaid,
      ).id,
      'lastPaymentId': payment.id,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return batch.commit();
  }

  /// Marks the payment voided AND gives its amount back to the order's
  /// balance, atomically. The payment record is kept.
  Future<void> voidPayment(
      String shopId, {
        required Order order,
        required Payment payment,
      }) {
    final newPaid = order.totalPaid - payment.amount;

    final batch = _firestore.batch();
    batch.update(_payments(shopId).doc(payment.id), {
      'isVoided': true,
      'voidedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_orders(shopId).doc(order.id), {
      'totalPaid': FieldValue.increment(-payment.amount),
      'remainingAmount': FieldValue.increment(payment.amount),
      'paymentStatus': OrderMoney.paymentStatus(
        total: order.totalAmount,
        paid: newPaid,
      ).id,
      'lastPaymentId': payment.id,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return batch.commit();
  }
}