import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:tailor_app/core/utils/phone_utils.dart';

class Customer extends Equatable {
  const Customer({
    required this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.notes = '',
    this.isArchived = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String phone;
  final String address;
  final String notes;
  final bool isArchived;

  /// Null while a freshly written server timestamp is not confirmed yet.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Derived values. They are always recomputed from name/phone, so they
  /// can never disagree with the fields they come from.
  String get nameLower => name.toLowerCase();
  String get phoneNormalized => PhoneUtils.normalize(phone);

  String get initial =>
      name.isEmpty ? '?' : String.fromCharCode(name.runes.first).toUpperCase();

  factory Customer.fromMap(String id, Map<String, dynamic> map) {
    return Customer(
      id: id,
      name: (map['name'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      address: (map['address'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
      isArchived: (map['isArchived'] as bool?) ?? false,
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
    );
  }

  /// Full document, used when CREATING a customer.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nameLower': nameLower,
      'phone': phone,
      'phoneNormalized': phoneNormalized,
      'address': address,
      'notes': notes,
      'isArchived': isArchived,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Only the fields an edit may change (never createdAt or isArchived).
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'nameLower': nameLower,
      'phone': phone,
      'phoneNormalized': phoneNormalized,
      'address': address,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _toDate(Object? value) =>
      value is Timestamp ? value.toDate() : null;

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    address,
    notes,
    isArchived,
    createdAt,
    updatedAt,
  ];
}