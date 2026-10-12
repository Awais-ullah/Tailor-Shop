import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:tailor_app/features/orders/data/models/order.dart';
import 'package:tailor_app/features/orders/data/order_money.dart';
import 'package:tailor_app/features/payments/data/models/payment.dart';

/// The ONLY class that writes payments. Every payment change is ONE
/// batch that also updates the order, so they can never disagree.
class PaymentRepository {
  PaymentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _payments(String shopId) =>
      _firestore.collection('shops').doc(shopId).collection('payments');

  CollectionReference<Map<String, dynamic>> _orders(String shopId) =>
      _firestore.collection('shops').doc(shopId).collection('orders');

  String newId(String shopId) => _payments(shopId).doc().id;

  /// Live list of every payment in the shop.
  Stream<List<Payment>> watchPayments(String shopId) {
    return _payments(shopId).snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => Payment.fromMap(doc.id, doc.data()))
          .toList(),
    );
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