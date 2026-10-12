import 'package:cloud_firestore/cloud_firestore.dart';

/// Watches Firestore's own "is this from the server?" and "is anything
/// still waiting to upload?" flags for the four shop collections.
class SyncRepository {
  SyncRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// These queries are deliberately IDENTICAL to the ones the app already
  /// uses (customers are ordered by nameLower), so Firestore shares one
  /// connection per query and no extra documents are read or billed.
  List<Stream<SnapshotMetadata>> watchMetadata(String shopId) {
    final shop = _firestore.collection('shops').doc(shopId);

    return [
      shop
          .collection('customers')
          .orderBy('nameLower')
          .snapshots(includeMetadataChanges: true)
          .map((snapshot) => snapshot.metadata),
      shop
          .collection('measurements')
          .snapshots(includeMetadataChanges: true)
          .map((snapshot) => snapshot.metadata),
      shop
          .collection('orders')
          .snapshots(includeMetadataChanges: true)
          .map((snapshot) => snapshot.metadata),
      shop
          .collection('payments')
          .snapshots(includeMetadataChanges: true)
          .map((snapshot) => snapshot.metadata),
    ];
  }
}