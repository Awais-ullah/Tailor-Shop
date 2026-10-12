import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tailor_app/core/errors/firestore_error_mapper.dart';
import 'package:tailor_app/core/utils/offline_write.dart';
import 'package:tailor_app/core/utils/phone_utils.dart';
import 'package:tailor_app/features/customers/data/models/customer.dart';
import 'package:tailor_app/features/customers/data/repositories/customer_repository.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_state.dart';

class CustomersCubit extends Cubit<CustomersState> {
  CustomersCubit(this._repository, {required this.shopId})
      : super(const CustomersState()) {
    _subscribe();
  }

  final CustomerRepository _repository;
  final String shopId;
  StreamSubscription<List<Customer>>? _subscription;

  void _subscribe() {
    _subscription?.cancel();
    emit(state.copyWith(status: CustomersStatus.loading, clearError: true));

    _subscription = _repository.watchCustomers(shopId).listen(
          (customers) => emit(
        state.copyWith(
          status: CustomersStatus.loaded,
          customers: customers,
          clearError: true,
        ),
      ),
      onError: (Object error) {
        debugPrint('[CustomersCubit] stream error: $error');
        emit(
          state.copyWith(
            status: CustomersStatus.failure,
            errorMessage: FirestoreErrorMapper.fromError(error),
          ),
        );
      },
    );
  }

  void retry() => _subscribe();

  void setQuery(String query) => emit(state.copyWith(query: query));

  void toggleArchived() =>
      emit(state.copyWith(showArchived: !state.showArchived));

  /// Another active customer with the same phone number, if any.
  /// Works offline because it checks the list already on the device.
  Customer? findDuplicatePhone(String phone, {String? excludeId}) {
    final normalized = PhoneUtils.normalize(phone);
    if (normalized.isEmpty) return null;

    for (final customer in state.customers) {
      if (customer.id == excludeId || customer.isArchived) continue;
      if (customer.phoneNormalized == normalized) return customer;
    }
    return null;
  }

  /// Creates a customer (when [id] is null) or updates an existing one.
  /// Returns the customer's id. Throws AppFailure with a friendly message.
  Future<String> saveCustomer({
    String? id,
    required String name,
    required String phone,
    required String address,
    required String notes,
  }) async {
    final customer = Customer(
      id: id ?? _repository.newId(shopId),
      name: name.trim().replaceAll(RegExp(r'\s+'), ' '),
      phone: phone.trim(),
      address: address.trim(),
      notes: notes.trim(),
    );

    if (id == null) {
      await awaitWriteBriefly(_repository.createCustomer(shopId, customer));
    } else {
      await awaitWriteBriefly(_repository.updateCustomer(shopId, customer));
    }
    return customer.id;
  }

  Future<void> archive(String id) =>
      awaitWriteBriefly(_repository.setArchived(shopId, id, true));

  Future<void> restore(String id) =>
      awaitWriteBriefly(_repository.setArchived(shopId, id, false));

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}