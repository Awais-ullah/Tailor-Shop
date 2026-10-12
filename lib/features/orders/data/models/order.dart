import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:tailor_app/core/utils/app_dates.dart';
import 'package:tailor_app/features/orders/data/models/order_item.dart';
import 'package:tailor_app/features/orders/data/models/order_measurement.dart';
import 'package:tailor_app/features/orders/data/order_money.dart';
import 'package:tailor_app/features/orders/data/order_status.dart';

class Order extends Equatable {
  const Order({
    required this.id,
    required this.customerId,
    required this.orderNumber,
    required this.items,
    this.measurements = const [],
    required this.totalAmount,
    this.totalPaid = 0,
    required this.remainingAmount,
    required this.paymentStatus,
    this.status = OrderStatus.booked,
    required this.orderDate,
    required this.deliveryDate,
    this.notes = '',
    this.lastPaymentId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String customerId;
  final int orderNumber;
  final List<OrderItem> items;
  final List<OrderMeasurement> measurements;

  // Money, in whole rupees. Always calculated by OrderMoney.
  final int totalAmount;
  final int totalPaid;
  final int remainingAmount;
  final PaymentStatus paymentStatus;

  final OrderStatus status;
  final DateTime orderDate;
  final DateTime deliveryDate;
  final String notes;

  /// The payment that last changed totalPaid. The security rules use it
  /// to check that every change to the money has a matching payment.
  final String? lastPaymentId;

  /// Null while a freshly written server timestamp is not confirmed yet.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isOverdue =>
      status.isActive && AppDates.isBeforeToday(deliveryDate);

  String get itemsSummary =>
      items.map((item) => '${item.quantity}× ${item.name}').join(', ');

  factory Order.fromMap(String id, Map<String, dynamic> map) {
    final rawItems = map['items'];
    final rawMeasurements = map['measurements'];

    final totalAmount = (map['totalAmount'] as num?)?.toInt() ?? 0;
    final totalPaid = (map['totalPaid'] as num?)?.toInt() ?? 0;

    return Order(
      id: id,
      customerId: (map['customerId'] as String?) ?? '',
      orderNumber: (map['orderNumber'] as num?)?.toInt() ?? 0,
      items: rawItems is List
          ? rawItems
          .whereType<Map>()
          .map((m) => OrderItem.fromMap(Map<String, dynamic>.from(m)))
          .toList()
          : const [],
      measurements: rawMeasurements is List
          ? rawMeasurements
          .whereType<Map>()
          .map(
            (m) => OrderMeasurement.fromMap(Map<String, dynamic>.from(m)),
      )
          .toList()
          : const [],
      totalAmount: totalAmount,
      totalPaid: totalPaid,
      // Derived, never trusted from storage.
      remainingAmount:
      OrderMoney.remaining(total: totalAmount, paid: totalPaid),
      paymentStatus:
      OrderMoney.paymentStatus(total: totalAmount, paid: totalPaid),
      status: OrderStatus.fromId(map['status'] as String?),
      orderDate: _toDate(map['orderDate']) ?? DateTime.now(),
      deliveryDate: _toDate(map['deliveryDate']) ?? DateTime.now(),
      notes: (map['notes'] as String?) ?? '',
      lastPaymentId: map['lastPaymentId'] as String?,
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
    );
  }

  /// Full document, used when CREATING an order.
  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'orderNumber': orderNumber,
      'items': items.map((item) => item.toMap()).toList(),
      'measurements': measurements.map((m) => m.toMap()).toList(),
      'totalAmount': totalAmount,
      'totalPaid': totalPaid,
      'remainingAmount': remainingAmount,
      'paymentStatus': paymentStatus.id,
      'status': status.id,
      'orderDate': Timestamp.fromDate(orderDate),
      'deliveryDate': Timestamp.fromDate(deliveryDate),
      'notes': notes,
      if (lastPaymentId != null) 'lastPaymentId': lastPaymentId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// What an edit may change. Never customer, number, status,
  /// totalPaid or createdAt.
  Map<String, dynamic> toUpdateMap() {
    return {
      'items': items.map((item) => item.toMap()).toList(),
      'measurements': measurements.map((m) => m.toMap()).toList(),
      'totalAmount': totalAmount,
      'remainingAmount': remainingAmount,
      'paymentStatus': paymentStatus.id,
      'orderDate': Timestamp.fromDate(orderDate),
      'deliveryDate': Timestamp.fromDate(deliveryDate),
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
    orderNumber,
    items,
    measurements,
    totalAmount,
    totalPaid,
    remainingAmount,
    paymentStatus,
    status,
    orderDate,
    deliveryDate,
    notes,
    lastPaymentId,
    createdAt,
    updatedAt,
  ];
}