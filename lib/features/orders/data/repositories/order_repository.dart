import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:tailor_app/core/data/shop_collections.dart';
import 'package:tailor_app/features/orders/data/models/order.dart';
import 'package:tailor_app/features/orders/data/order_status.dart';

/// Reads orders and writes everything about them except money.
/// Changes to totalPaid always go through PaymentRepository, together
/// with the payment that causes them.
/// Path: shops/{shopId}/orders/{orderId}
class OrderRepository {
  OrderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String shopId) =>
      ShopCollections.orders(_firestore, shopId);

  String newId(String shopId) => _collection(shopId).doc().id;

  /// Live list of every order in the shop.
  Stream<List<Order>> watchOrders(String shopId) {
    return ShopCollections.watchedOrders(_firestore, shopId).snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => Order.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  Future<void> createOrder(String shopId, Order order) {
    return _collection(shopId).doc(order.id).set(order.toMap());
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