import 'package:tailor_app/core/l10n/app_strings.dart';
import 'package:equatable/equatable.dart';
import 'package:tailor_app/features/orders/data/models/order.dart';
import 'package:tailor_app/features/orders/data/order_status.dart';

enum OrdersStatus { loading, loaded, failure }

/// The chips on the orders list.
enum OrderFilter {
  active('Active', null),
  all('All', null),
  booked('Booked', OrderStatus.booked),
  cutting('Cutting', OrderStatus.cutting),
  stitching('Stitching', OrderStatus.stitching),
  ready('Ready', OrderStatus.ready),
  delivered('Delivered', OrderStatus.delivered),
  cancelled('Cancelled', OrderStatus.cancelled);

  const OrderFilter(this._label, this.status);

  final String _label;

  String get label {
    switch (this) {
      case OrderFilter.active:
        return S.current.active;
      case OrderFilter.all:
        return S.current.all;
      default:
        return S.current.dyn('order.${status!.id}', _label);
    }
  }

  final OrderStatus? status;

  bool matches(OrderStatus other) {
    if (this == OrderFilter.active) return other.isActive;
    if (this == OrderFilter.all) return true;
    return other == status;
  }
}

class OrdersState extends Equatable {
  const OrdersState({
    this.status = OrdersStatus.loading,
    this.orders = const [],
    this.query = '',
    this.filter = OrderFilter.active,
    this.errorMessage,
  });

  final OrdersStatus status;

  /// Newest order number first.
  final List<Order> orders;
  final String query;
  final OrderFilter filter;
  final String? errorMessage;

  /// Highest known order number + 1.
  int get nextOrderNumber {
    var highest = 0;
    for (final order in orders) {
      if (order.orderNumber > highest) highest = order.orderNumber;
    }
    return highest + 1;
  }

  Order? byId(String id) {
    for (final order in orders) {
      if (order.id == id) return order;
    }
    return null;
  }

  List<Order> forCustomer(String customerId) =>
      orders.where((order) => order.customerId == customerId).toList();

  /// For the orders list: status filter plus search by customer name or
  /// order number. [customerNameOf] is supplied by the screen.
  List<Order> filtered(String Function(String customerId) customerNameOf) {
    final q = query.trim().toLowerCase();
    final numberQuery = q.startsWith('#') ? q.substring(1) : q;

    final result = orders.where((order) {
      if (!filter.matches(order.status)) return false;
      if (q.isEmpty) return true;

      return customerNameOf(order.customerId).toLowerCase().contains(q) ||
          (numberQuery.isNotEmpty &&
              order.orderNumber.toString().contains(numberQuery));
    }).toList();

    // Work in progress: most urgent delivery first.
    // Finished or cancelled: newest first.
    final byDelivery = filter == OrderFilter.active ||
        (filter.status != null && filter.status!.isActive);

    if (byDelivery) {
      result.sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));
    } else {
      result.sort((a, b) => b.orderNumber.compareTo(a.orderNumber));
    }
    return result;
  }

  OrdersState copyWith({
    OrdersStatus? status,
    List<Order>? orders,
    String? query,
    OrderFilter? filter,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      query: query ?? this.query,
      filter: filter ?? this.filter,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, orders, query, filter, errorMessage];
}