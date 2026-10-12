import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:tailor_app/features/measurements/data/measurement_templates.dart';

class Measurement extends Equatable {
  const Measurement({
    required this.id,
    required this.customerId,
    required this.garmentType,
    this.label = '',
    this.values = const {},
    this.styles = const {},
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String customerId;
  final GarmentType garmentType;
  final String label;

  /// Measurement key -> inches. Only fields that were filled in.
  final Map<String, double> values;

  /// Style group key -> chosen option ids.
  final Map<String, List<String>> styles;
  final String notes;

  /// Null while a freshly written server timestamp is not confirmed yet.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Measurement.fromMap(String id, Map<String, dynamic> map) {
    final values = <String, double>{};
    final rawValues = map['values'];
    if (rawValues is Map) {
      rawValues.forEach((key, value) {
        if (value is num) values['$key'] = value.toDouble();
      });
    }

    final styles = <String, List<String>>{};
    final rawStyles = map['styles'];
    if (rawStyles is Map) {
      rawStyles.forEach((key, value) {
        if (value is List) {
          styles['$key'] = value.whereType<String>().toList();
        } else if (value is String) {
          styles['$key'] = [value];
        }
      });
    }

    return Measurement(
      id: id,
      customerId: (map['customerId'] as String?) ?? '',
      garmentType: GarmentType.fromId(map['garmentType'] as String?) ??
          GarmentType.shirtKurta,
      label: (map['label'] as String?) ?? '',
      values: values,
      styles: styles,
      notes: (map['notes'] as String?) ?? '',
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
    );
  }

  /// Full document, used when CREATING.
  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'garmentType': garmentType.id,
      'label': label,
      'values': values,
      'styles': styles,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Fields an edit may change. `values` and `styles` are REPLACED as a
  /// whole, so clearing a field really removes it.
  Map<String, dynamic> toUpdateMap() {
    return {
      'garmentType': garmentType.id,
      'label': label,
      'values': values,
      'styles': styles,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _toDate(Object? value) =>
      value is Timestamp ? value.toDate() : null;

  @override
  List<Object?> get props => [
    id,
    customerId,
    garmentType,
    label,
    values,
    styles,
    notes,
    createdAt,
    updatedAt,
  ];
}