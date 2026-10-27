import 'package:tailor_app/core/l10n/app_strings.dart';

// Icons for these live in presentation/payment_method_ui.dart.

enum PaymentMethod {
  cash('cash', 'Cash'),
  bank('bank', 'Bank'),
  other('other', 'Other');

  const PaymentMethod(this.id, this._label);

  /// Stored in Firestore. Never change these strings.
  final String id;
  final String _label;

  /// Translated name (falls back to the English text).
  String get label => S.current.dyn('method.$id', _label);

  static PaymentMethod fromId(String? id) {
    for (final method in PaymentMethod.values) {
      if (method.id == id) return method;
    }
    return PaymentMethod.other;
  }
}
