import 'package:tailor_app/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';

enum PaymentMethod {
  cash('cash', 'Cash', Icons.payments_outlined),
  bank('bank', 'Bank', Icons.account_balance_outlined),
  other('other', 'Other', Icons.more_horiz);

  const PaymentMethod(this.id, this._label, this.icon);

  /// Stored in Firestore. Never change these strings.
  final String id;
  final String _label;

  /// Translated name (falls back to the English text).
  String get label => S.current.dyn('method.$id', _label);
  final IconData icon;

  static PaymentMethod fromId(String? id) {
    for (final method in PaymentMethod.values) {
      if (method.id == id) return method;
    }
    return PaymentMethod.other;
  }
}