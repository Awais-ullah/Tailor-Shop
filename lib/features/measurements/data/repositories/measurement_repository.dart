import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tailor_app/features/measurements/data/models/measurement.dart';

/// The ONLY class that reads or writes measurement documents.
/// Path: shops/{shopId}/measurements/{measurementId}
class MeasurementRepository {
  MeasurementRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String shopId) =>
      _firestore.collection('shops').doc(shopId).collection('measurements');

  String newId(String shopId) => _collection(shopId).doc().id;

  /// Live list of every measurement set in the shop.
  Stream<List<Measurement>> watchMeasurements(String shopId) {
    return _collection(shopId).snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => Measurement.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  Future<void> createMeasurement(String shopId, Measurement measurement) {
    return _collection(shopId).doc(measurement.id).set(measurement.toMap());
  }

  Future<void> updateMeasurement(String shopId, Measurement measurement) {
    return _collection(shopId)
        .doc(measurement.id)
        .update(measurement.toUpdateMap());
  }

  Future<void> deleteMeasurement(String shopId, String measurementId) {
    return _collection(shopId).doc(measurementId).delete();
  }
}