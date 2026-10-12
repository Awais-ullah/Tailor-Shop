import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:tailor_app/features/orders/data/models/order.dart';
import 'package:tailor_app/features/orders/data/order_status.dart';
import 'package:tailor_app/features/payments/data/models/payment.dart';

/// The ONLY class that reads or writes order documents.
/// Path: shops/{shopId}/orders/{orderId}
class OrderRepository {
  OrderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String shopId) =>
      _firestore.collection('shops').doc(shopId).collection('orders');

  CollectionReference<Map<String, dynamic>> _payments(String shopId) =>
      _firestore.collection('shops').doc(shopId).collection('payments');

  String newId(String shopId) => _collection(shopId).doc().id;

  String newPaymentId(String shopId) => _payments(shopId).doc().id;

  /// Live list of every order in the shop.
  Stream<List<Order>> watchOrders(String shopId) {
    return _collection(shopId).snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => Order.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  Future<void> createOrder(String shopId, Order order) {
    return _collection(shopId).doc(order.id).set(order.toMap());
  }

  /// Creates the order AND its advance payment in one atomic batch.
  Future<void> createOrderWithAdvance(
      String shopId,
      Order order,
      Payment payment,
      ) {
    final batch = _firestore.batch();
    batch.set(_collection(shopId).doc(order.id), order.toMap());
    batch.set(_payments(shopId).doc(payment.id), payment.toMap());
    return batch.commit();
  }

  Future<void> updateOrder(String shopId, Order order) {
    return _collection(shopId).doc(order.id).update(order.toUpdateMap());
  }

  Future<void> setStatus(String shopId, String orderId, OrderStatus status) {
    return _collection(shopId).doc(orderId).update({
      'status': status.id,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}