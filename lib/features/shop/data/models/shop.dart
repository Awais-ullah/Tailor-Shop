import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Shop extends Equatable {
  const Shop({
    required this.id,
    required this.name,
    required this.ownerUid,
    this.currency = 'PKR',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String ownerUid;
  final String currency;

  /// Null while a freshly written server timestamp has not been
  /// confirmed by the server yet (for example when offline).
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Shop.fromMap(String id, Map<String, dynamic> map) {
    return Shop(
      id: id,
      name: (map['name'] as String?) ?? 'My Tailor Shop',
      ownerUid: (map['ownerUid'] as String?) ?? id,
      currency: (map['currency'] as String?) ?? 'PKR',
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
    );
  }

  /// Used when CREATING the shop document.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerUid': ownerUid,
      'currency': currency,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _toDate(Object? value) =>
      value is Timestamp ? value.toDate() : null;

  @override
  List<Object?> get props =>
      [id, name, ownerUid, currency, createdAt, updatedAt];
}