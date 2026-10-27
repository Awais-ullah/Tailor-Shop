import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tailor_app/core/data/shop_collections.dart';
import 'package:tailor_app/features/customers/data/models/customer.dart';

/// The ONLY class that reads or writes customer documents.
/// Path: shops/{shopId}/customers/{customerId}
class CustomerRepository {
  CustomerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String shopId) =>
      ShopCollections.customers(_firestore, shopId);

  /// Generated on the device, so it works offline and retries can never
  /// create duplicates.
  String newId(String shopId) => _collection(shopId).doc().id;

  /// Live list of every customer, sorted by name. Updates instantly when
  /// data changes locally or on the server.
  Stream<List<Customer>> watchCustomers(String shopId) {
    return ShopCollections.watchedCustomers(_firestore, shopId).snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => Customer.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  Future<void> createCustomer(String shopId, Customer customer) {
    return _collection(shopId).doc(customer.id).set(customer.toMap());
  }

  Future<void> updateCustomer(String shopId, Customer customer) {
    return _collection(shopId).doc(customer.id).update(customer.toUpdateMap());
  }

  Future<void> setArchived(String shopId, String customerId, bool archived) {
    return _collection(shopId).doc(customerId).update({
      'isArchived': archived,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}