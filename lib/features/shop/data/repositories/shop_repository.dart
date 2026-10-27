import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tailor_app/core/data/shop_collections.dart';
import 'package:flutter/foundation.dart';
import 'package:tailor_app/features/shop/data/models/shop.dart';

/// The ONLY class that reads or writes the shop document.
class ShopRepository {
  ShopRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _shopRef(String shopId) =>
      ShopCollections.shop(_firestore, shopId);

  /// Creates the owner's shop document if it does not exist yet.
  /// Safe to call on every login. Failures (for example offline on the
  /// very first launch) are logged and retried on the next launch,
  /// because the rest of the app does not depend on this document.
  Future<void> ensureShopExists({
    required String ownerUid,
    required String shopName,
  }) async {
    try {
      final ref = _shopRef(ownerUid);
      final snapshot = await ref.get();
      if (snapshot.exists) return;

      final shop = Shop(id: ownerUid, name: shopName, ownerUid: ownerUid);
      await ref.set(shop.toMap());
    } catch (e) {
      debugPrint('[ShopRepository] ensureShopExists failed: $e');
    }
  }

  /// Live updates, including metadata changes, so the UI can tell
  /// "from cache" vs "from server" and "pending write" vs "synced".
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchShopSnapshot(
      String shopId,
      ) {
    return _shopRef(shopId).snapshots(includeMetadataChanges: true);
  }

  Future<void> updateShopName(String shopId, String name) {
    return _shopRef(shopId).update({
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}