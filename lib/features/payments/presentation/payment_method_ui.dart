import 'package:flutter/material.dart';
import 'package:tailor_app/features/payments/data/payment_method.dart';

/// How a payment method looks on screen.
extension PaymentMethodUi on PaymentMethod {
  IconData get icon {
    switch (this) {
      case PaymentMethod.cash:
        return Icons.payments_outlined;
      case PaymentMethod.bank:
        return Icons.account_balance_outlined;
      case PaymentMethod.other:
        return Icons.more_horiz;
    }
  }
}
