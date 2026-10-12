import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tailor_app/core/errors/app_failure.dart';
import 'package:tailor_app/core/errors/firestore_error_mapper.dart';
import 'package:tailor_app/core/utils/app_dates.dart';
import 'package:tailor_app/core/utils/money.dart';
import 'package:tailor_app/core/utils/offline_write.dart';
import 'package:tailor_app/features/orders/data/models/order.dart';
import 'package:tailor_app/features/orders/data/models/order_item.dart';
import 'package:tailor_app/features/orders/data/models/order_measurement.dart';
import 'package:tailor_app/features/orders/data/order_money.dart';
import 'package:tailor_app/features/orders/data/order_status.dart';
import 'package:tailor_app/features/orders/data/repositories/order_repository.dart';
import 'package:tailor_app/features/orders/presentation/cubit/orders_state.dart';
import 'package:tailor_app/features/payments/data/models/payment.dart';
import 'package:tailor_app/features/payments/data/payment_method.dart';

class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit(this._repository, {required this.shopId})
      : super(const OrdersState()) {
    _subscribe();
  }

  final OrderRepository _repository;
  final String shopId;
  StreamSubscription<List<Order>>? _subscription;

  void _subscribe() {
    _subscription?.cancel();
    emit(state.copyWith(status: OrdersStatus.loading, clearError: true));

    _subscription = _repository.watchOrders(shopId).listen(
          (items) {
        final sorted = [...items]
          ..sort((a, b) => b.orderNumber.compareTo(a.orderNumber));
        emit(
          state.copyWith(
            status: OrdersStatus.loaded,
            orders: sorted,
            clearError: true,
          ),
        );
      },
      onError: (Object error) {
        debugPrint('[OrdersCubit] stream error: $error');
        emit(
          state.copyWith(
            status: OrdersStatus.failure,
            errorMessage: FirestoreErrorMapper.fromError(error),
          ),
        );
      },
    );
  }

  void retry() => _subscribe();

  void setQuery(String query) => emit(state.copyWith(query: query));

  void setFilter(OrderFilter filter) => emit(state.copyWith(filter: filter));

  /// Creates an order (when [id] is null) or edits one. Returns its id.
  /// [advanceAmount] is only used when creating. Throws AppFailure with
  /// a friendly message.
  Future<String> saveOrder({
    String? id,
    required String customerId,
    required List<OrderItem> items,
    required List<OrderMeasurement> measurements,
    required DateTime orderDate,
    required DateTime deliveryDate,
    required String notes,
    int advanceAmount = 0,
    PaymentMethod advanceMethod = PaymentMethod.cash,
  }) async {
    final existing = id == null ? null : state.byId(id);
    if (id != null && existing == null) {
      throw const AppFailure('This order could not be found.');
    }
    if (items.isEmpty) {
      throw const AppFailure('Add at least one item.');
    }

    final orderDay = AppDates.dateOnly(orderDate);
    final deliveryDay = AppDates.dateOnly(deliveryDate);
    if (deliveryDay.isBefore(orderDay)) {
      throw const AppFailure('Delivery date cannot be before the order date.');
    }

    // All money maths happens in OrderMoney, never here or in the UI.
    final total = OrderMoney.total(items);

    // An advance only exists when creating a new order.
    final advance = existing == null ? advanceAmount : 0;
    if (advance < 0) {
      throw const AppFailure('The advance cannot be negative.');
    }
    if (advance > total) {
      throw AppFailure(
        "The advance can't be more than the order total (${Money.pkr(total)}).",
      );
    }

    final paid = existing?.totalPaid ?? advance;
    if (total < paid) {
      throw AppFailure(
        "The total can't be less than the ${Money.pkr(paid)} already paid.",
      );
    }

    final paymentId = advance > 0 ? _repository.newPaymentId(shopId) : null;

    final order = Order(
      id: id ?? _repository.newId(shopId),
      customerId: customerId,
      orderNumber: existing?.orderNumber ?? state.nextOrderNumber,
      items: items,
      measurements: measurements,
      totalAmount: total,
      totalPaid: paid,
      remainingAmount: OrderMoney.remaining(total: total, paid: paid),
      paymentStatus: OrderMoney.paymentStatus(total: total, paid: paid),
      status: existing?.status ?? OrderStatus.booked,
      orderDate: orderDay,
      deliveryDate: deliveryDay,
      notes: notes.trim(),
      lastPaymentId: paymentId,
    );

    if (existing != null) {
      await awaitWriteBriefly(_repository.updateOrder(shopId, order));
    } else if (paymentId != null) {
      final payment = Payment(
        id: paymentId,
        orderId: order.id,
        customerId: customerId,
        amount: advance,
        method: advanceMethod,
        note: 'Advance',
        paidAt: orderDay,
      );
      await awaitWriteBriefly(
        _repository.createOrderWithAdvance(shopId, order, payment),
      );
    } else {
      await awaitWriteBriefly(_repository.createOrder(shopId, order));
    }
    return order.id;
  }

  Future<void> updateStatus(String id, OrderStatus status) =>
      awaitWriteBriefly(_repository.setStatus(shopId, id, status));

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}