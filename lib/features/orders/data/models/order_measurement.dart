import 'package:equatable/equatable.dart';
import 'package:tailor_app/features/measurements/data/measurement_templates.dart';
import 'package:tailor_app/features/measurements/data/models/measurement.dart';

/// A COPY of a measurement set, saved inside an order. Changing the
/// customer's measurements later never changes old orders.
class OrderMeasurement extends Equatable {
  const OrderMeasurement({
    required this.sourceId,
    required this.garmentType,
    this.label = '',
    this.values = const {},
    this.styles = const {},
    this.notes = '',
  });

  /// The measurement set this was copied from (for reference only).
  final String sourceId;
  final GarmentType garmentType;
  final String label;
  final Map<String, double> values;
  final Map<String, List<String>> styles;
  final String notes;

  factory OrderMeasurement.fromMeasurement(Measurement measurement) {
    return OrderMeasurement(
      sourceId: measurement.id,
      garmentType: measurement.garmentType,
      label: measurement.label,
      values: Map.of(measurement.values),
      styles: {
        for (final entry in measurement.styles.entries)
          entry.key: List.of(entry.value),
      },
      notes: measurement.notes,
    );
  }

  factory OrderMeasurement.fromMap(Map<String, dynamic> map) {
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
        }
      });
    }

    return OrderMeasurement(
      sourceId: (map['sourceId'] as String?) ?? '',
      garmentType: GarmentType.fromId(map['garmentType'] as String?) ??
          GarmentType.shirtKurta,
      label: (map['label'] as String?) ?? '',
      values: values,
      styles: styles,
      notes: (map['notes'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sourceId': sourceId,
      'garmentType': garmentType.id,
      'label': label,
      'values': values,
      'styles': styles,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props =>
      [sourceId, garmentType, label, values, styles, notes];
}