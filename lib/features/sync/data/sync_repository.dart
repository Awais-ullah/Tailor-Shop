import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tailor_app/core/data/shop_collections.dart';

/// Watches Firestore's own "is this from the server?" and "is anything
/// still waiting to upload?" flags for the four shop collections.
class SyncRepository {
  SyncRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Uses exactly the queries the data repositories watch (from
  /// ShopCollections), so Firestore shares one listener per query and no
  /// extra documents are read or billed.
  List<Stream<SnapshotMetadata>> watchMetadata(String shopId) {
    return [
      for (final query in ShopCollections.allWatched(_firestore, shopId))
        query
            .snapshots(includeMetadataChanges: true)
            .map((snapshot) => snapshot.metadata),
    ];
  }
}
