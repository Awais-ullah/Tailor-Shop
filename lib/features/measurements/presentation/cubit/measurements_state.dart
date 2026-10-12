import 'package:equatable/equatable.dart';
import 'package:tailor_app/features/measurements/data/measurement_templates.dart';
import 'package:tailor_app/features/measurements/data/models/measurement.dart';

enum MeasurementsStatus { loading, loaded, failure }

class MeasurementsState extends Equatable {
  const MeasurementsState({
    this.status = MeasurementsStatus.loading,
    this.measurements = const [],
    this.query = '',
    this.garmentFilter,
    this.errorMessage,
  });

  final MeasurementsStatus status;

  /// Newest first.
  final List<Measurement> measurements;
  final String query;
  final GarmentType? garmentFilter;
  final String? errorMessage;

  List<Measurement> forCustomer(String customerId) =>
      measurements.where((m) => m.customerId == customerId).toList();

  Measurement? byId(String id) {
    for (final measurement in measurements) {
      if (measurement.id == id) return measurement;
    }
    return null;
  }

  /// The most recently updated set of this garment type for a customer.
  Measurement? latestFor(
      String customerId,
      GarmentType type, {
        String? excludeId,
      }) {
    for (final measurement in measurements) {
      if (measurement.customerId == customerId &&
          measurement.garmentType == type &&
          measurement.id != excludeId) {
        return measurement;
      }
    }
    return null;
  }

  /// For the global list: garment filter plus search by customer name
  /// or label. [customerNameOf] is supplied by the screen, because
  /// customer names live in the customers cubit.
  List<Measurement> filtered(String Function(String customerId) customerNameOf) {
    final q = query.trim().toLowerCase();

    return measurements.where((measurement) {
      if (garmentFilter != null && measurement.garmentType != garmentFilter) {
        return false;
      }
      if (q.isEmpty) return true;

      return customerNameOf(measurement.customerId).toLowerCase().contains(q) ||
          measurement.label.toLowerCase().contains(q);
    }).toList();
  }

  MeasurementsState copyWith({
    MeasurementsStatus? status,
    List<Measurement>? measurements,
    String? query,
    GarmentType? garmentFilter,
    bool clearGarmentFilter = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MeasurementsState(
      status: status ?? this.status,
      measurements: measurements ?? this.measurements,
      query: query ?? this.query,
      garmentFilter:
      clearGarmentFilter ? null : (garmentFilter ?? this.garmentFilter),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, measurements, query, garmentFilter, errorMessage];
}