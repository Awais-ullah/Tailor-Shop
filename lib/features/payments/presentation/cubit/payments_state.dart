import 'package:equatable/equatable.dart';
import 'package:tailor_app/core/utils/app_dates.dart';
import 'package:tailor_app/features/payments/data/models/payment.dart';

enum PaymentsStatus { loading, loaded, failure }

class PaymentsState extends Equatable {
  const PaymentsState({
    this.status = PaymentsStatus.loading,
    this.payments = const [],
    this.errorMessage,
  });

  final PaymentsStatus status;

  /// Newest first (including voided ones).
  final List<Payment> payments;
  final String? errorMessage;

  List<Payment> forOrder(String orderId) =>
      payments.where((payment) => payment.orderId == orderId).toList();

  List<Payment> forCustomer(String customerId) =>
      payments.where((payment) => payment.customerId == customerId).toList();

  /// Money received on a given day (voided payments don't count).
  int collectedOn(DateTime day) {
    final target = AppDates.dateOnly(day);
    var sum = 0;
    for (final payment in payments) {
      if (!payment.isVoided && AppDates.dateOnly(payment.paidAt) == target) {
        sum += payment.amount;
      }
    }
    return sum;
  }

  PaymentsState copyWith({
    PaymentsStatus? status,
    List<Payment>? payments,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PaymentsState(
      status: status ?? this.status,
      payments: payments ?? this.payments,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, payments, errorMessage];
}