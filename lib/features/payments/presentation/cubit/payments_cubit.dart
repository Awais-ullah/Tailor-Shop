import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tailor_app/core/errors/app_failure.dart';
import 'package:tailor_app/core/errors/firestore_error_mapper.dart';
import 'package:tailor_app/core/utils/app_dates.dart';
import 'package:tailor_app/core/utils/money.dart';
import 'package:tailor_app/core/utils/offline_write.dart';
import 'package:tailor_app/features/orders/data/models/order.dart';
import 'package:tailor_app/features/orders/data/order_status.dart';
import 'package:tailor_app/features/payments/data/models/payment.dart';
import 'package:tailor_app/features/payments/data/payment_method.dart';
import 'package:tailor_app/features/payments/data/repositories/payment_repository.dart';
import 'package:tailor_app/features/payments/presentation/cubit/payments_state.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';

class PaymentsCubit extends Cubit<PaymentsState> {
  PaymentsCubit(this._repository, {required this.shopId})
      : super(const PaymentsState()) {
    _subscribe();
  }

  final PaymentRepository _repository;
  final String shopId;
  StreamSubscription<List<Payment>>? _subscription;

  void _subscribe() {
    _subscription?.cancel();
    emit(state.copyWith(status: PaymentsStatus.loading, clearError: true));

    _subscription = _repository.watchPayments(shopId).listen(
          (items) {
        final sorted = [...items]..sort(_newestFirst);
        emit(
          state.copyWith(
            status: PaymentsStatus.loaded,
            payments: sorted,
            clearError: true,
          ),
        );
      },
      onError: (Object error) {
        debugPrint('[PaymentsCubit] stream error: $error');
        emit(
          state.copyWith(
            status: PaymentsStatus.failure,
            errorMessage: FirestoreErrorMapper.fromError(error),
          ),
        );
      },
    );
  }

  /// Newest payment day first; within a day, the one saved last.
  static int _newestFirst(Payment a, Payment b) {
    final byDay = b.paidAt.compareTo(a.paidAt);
    if (byDay != 0) return byDay;
    final now = DateTime.now();
    return (b.createdAt ?? now).compareTo(a.createdAt ?? now);
  }

  void retry() => _subscribe();

  /// Records a payment. Throws AppFailure with a friendly message.
  Future<void> recordPayment({
    required Order order,
    required int amount,
    required PaymentMethod method,
    required String note,
    required DateTime date,
  }) async {
    if (order.status == OrderStatus.cancelled) {
      throw AppFailure(S.current.cantPayCancelled);
    }
    if (amount <= 0) {
      throw AppFailure(S.current.enterAmountOver0Dot);
    }
    if (amount > order.remainingAmount) {
      throw AppFailure(
        S.current.moreThanRemaining(Money.pkr(order.remainingAmount)),
      );
    }

    final payment = Payment(
      id: _repository.newId(shopId),
      orderId: order.id,
      customerId: order.customerId,
      amount: amount,
      method: method,
      note: note.trim(),
      paidAt: AppDates.dateOnly(date),
    );

    await awaitWriteBriefly(
      _repository.recordPayment(shopId, order: order, payment: payment),
    );
  }

  /// Voids a payment: its amount returns to the order's balance.
  Future<void> voidPayment({
    required Order order,
    required Payment payment,
  }) async {
    if (payment.isVoided) {
      throw AppFailure(S.current.alreadyVoided);
    }
    if (payment.amount > order.totalPaid) {
      throw AppFailure(
        S.current.cantVoidLarger,
      );
    }

    await awaitWriteBriefly(
      _repository.voidPayment(shopId, order: order, payment: payment),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}