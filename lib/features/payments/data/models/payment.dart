import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:tailor_app/features/payments/data/payment_method.dart';

class Payment extends Equatable {
  const Payment({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.amount,
    this.method = PaymentMethod.cash,
    this.note = '',
    required this.paidAt,
    this.isVoided = false,
    this.voidedAt,
    this.createdAt,
  });

  final String id;
  final String orderId;
  final String customerId;

  /// Whole rupees, always above 0.
  final int amount;
  final PaymentMethod method;
  final String note;

  /// The day the money was received (whole day).
  final DateTime paidAt;

  /// A voided payment stays in the history but no longer counts.
  final bool isVoided;
  final DateTime? voidedAt;

  /// Null while a freshly written server timestamp is not confirmed yet.
  final DateTime? createdAt;

  factory Payment.fromMap(String id, Map<String, dynamic> map) {
    return Payment(
      id: id,
      orderId: (map['orderId'] as String?) ?? '',
      customerId: (map['customerId'] as String?) ?? '',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      method: PaymentMethod.fromId(map['method'] as String?),
      note: (map['note'] as String?) ?? '',
      paidAt: _toDate(map['paidAt']) ?? DateTime.now(),
      isVoided: (map['isVoided'] as bool?) ?? false,
      voidedAt: _toDate(map['voidedAt']),
      createdAt: _toDate(map['createdAt']),
    );
  }

  /// Full document, used when CREATING a payment. New payments are
  /// never voided.
  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'customerId': customerId,
      'amount': amount,
      'method': method.id,
      'note': note,
      'paidAt': Timestamp.fromDate(paidAt),
      'isVoided': false,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _toDate(Object? value) =>
      value is Timestamp ? value.toDate() : null;

  @override
  List<Object?> get props => [
    id,
    orderId,
    customerId,
    amount,
    method,
    note,
    paidAt,
    isVoided,
    voidedAt,
    createdAt,
  ];
}