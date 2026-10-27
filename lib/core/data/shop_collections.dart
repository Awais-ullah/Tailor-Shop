import 'package:cloud_firestore/cloud_firestore.dart';

/// The one place that knows where a shop's data lives in Firestore, and
/// the query each collection is watched with.
///
/// The data repositories and SyncRepository watch the SAME queries, so
/// Firestore shares one listener per query and the sync indicator reads
/// nothing extra. If a collection ever needs to load only recent history,
/// this is the place to add it.
class ShopCollections {
  ShopCollections._();

  static DocumentReference<Map<String, dynamic>> shop(
    FirebaseFirestore firestore,
    String shopId,
  ) =>
      firestore.collection('shops').doc(shopId);

  static CollectionReference<Map<String, dynamic>> customers(
    FirebaseFirestore firestore,
    String shopId,
  ) =>
      shop(firestore, shopId).collection('customers');

  static CollectionReference<Map<String, dynamic>> measurements(
    FirebaseFirestore firestore,
    String shopId,
  ) =>
      shop(firestore, shopId).collection('measurements');

  static CollectionReference<Map<String, dynamic>> orders(
    FirebaseFirestore firestore,
    String shopId,
  ) =>
      shop(firestore, shopId).collection('orders');

  static CollectionReference<Map<String, dynamic>> payments(
    FirebaseFirestore firestore,
    String shopId,
  ) =>
      shop(firestore, shopId).collection('payments');

  /// Customers are listed by name.
  static Query<Map<String, dynamic>> watchedCustomers(
    FirebaseFirestore firestore,
    String shopId,
  ) =>
      customers(firestore, shopId).orderBy('nameLower');

  /// The others are sorted on the device, so they are watched unordered.
  static Query<Map<String, dynamic>> watchedMeasurements(
    FirebaseFirestore firestore,
    String shopId,
  ) =>
      measurements(firestore, shopId);

  static Query<Map<String, dynamic>> watchedOrders(
    FirebaseFirestore firestore,
    String shopId,
  ) =>
      orders(firestore, shopId);

  static Query<Map<String, dynamic>> watchedPayments(
    FirebaseFirestore firestore,
    String shopId,
  ) =>
      payments(firestore, shopId);

  /// Every watched query, for the sync indicator.
  static List<Query<Map<String, dynamic>>> allWatched(
    FirebaseFirestore firestore,
    String shopId,
  ) =>
      [
        watchedCustomers(firestore, shopId),
        watchedMeasurements(firestore, shopId),
        watchedOrders(firestore, shopId),
        watchedPayments(firestore, shopId),
      ];
}
