import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tailor_app/core/errors/firestore_error_mapper.dart';
import 'package:tailor_app/core/utils/offline_write.dart';
import 'package:tailor_app/features/measurements/data/measurement_templates.dart';
import 'package:tailor_app/features/measurements/data/models/measurement.dart';
import 'package:tailor_app/features/measurements/data/repositories/measurement_repository.dart';
import 'package:tailor_app/features/measurements/presentation/cubit/measurements_state.dart';

class MeasurementsCubit extends Cubit<MeasurementsState> {
  MeasurementsCubit(this._repository, {required this.shopId})
      : super(const MeasurementsState()) {
    _subscribe();
  }

  final MeasurementRepository _repository;
  final String shopId;
  StreamSubscription<List<Measurement>>? _subscription;

  void _subscribe() {
    _subscription?.cancel();
    emit(state.copyWith(status: MeasurementsStatus.loading, clearError: true));

    _subscription = _repository.watchMeasurements(shopId).listen(
          (items) {
        final sorted = [...items]..sort(_newestFirst);
        emit(
          state.copyWith(
            status: MeasurementsStatus.loaded,
            measurements: sorted,
            clearError: true,
          ),
        );
      },
      onError: (Object error) {
        debugPrint('[MeasurementsCubit] stream error: $error');
        emit(
          state.copyWith(
            status: MeasurementsStatus.failure,
            errorMessage: FirestoreErrorMapper.fromError(error),
          ),
        );
      },
    );
  }

  /// A null timestamp means "just saved, server has not confirmed yet",
  /// so it counts as the newest.
  static int _newestFirst(Measurement a, Measurement b) {
    final now = DateTime.now();
    return (b.updatedAt ?? now).compareTo(a.updatedAt ?? now);
  }

  void retry() => _subscribe();

  void setQuery(String query) => emit(state.copyWith(query: query));

  void setGarmentFilter(GarmentType? type) {
    emit(
      type == null
          ? state.copyWith(clearGarmentFilter: true)
          : state.copyWith(garmentFilter: type),
    );
  }

  /// Creates a set (when [id] is null) or updates one. Returns its id.
  /// Throws AppFailure with a friendly message.
  Future<String> saveMeasurement({
    String? id,
    required String customerId,
    required GarmentType garmentType,
    required String label,
    required Map<String, double> values,
    required Map<String, List<String>> styles,
    required String notes,
  }) async {
    final measurement = Measurement(
      id: id ?? _repository.newId(shopId),
      customerId: customerId,
      garmentType: garmentType,
      label: label.trim(),
      values: values,
      styles: styles,
      notes: notes.trim(),
    );

    if (id == null) {
      await awaitWriteBriefly(
        _repository.createMeasurement(shopId, measurement),
      );
    } else {
      await awaitWriteBriefly(
        _repository.updateMeasurement(shopId, measurement),
      );
    }
    return measurement.id;
  }

  Future<void> delete(String id) =>
      awaitWriteBriefly(_repository.deleteMeasurement(shopId, id));

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}