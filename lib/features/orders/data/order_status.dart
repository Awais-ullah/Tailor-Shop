import 'package:tailor_app/core/l10n/app_strings.dart';

// Icons and colours for these live in presentation/order_status_ui.dart,
// so the stored ids never depend on how they are drawn.

enum OrderStatus {
  booked('booked', 'Booked'),
  cutting('cutting', 'Cutting'),
  stitching('stitching', 'Stitching'),
  ready('ready', 'Ready'),
  delivered('delivered', 'Delivered'),
  cancelled('cancelled', 'Cancelled');

  const OrderStatus(this.id, this._label);

  /// Stored in Firestore. Never change these strings.
  final String id;
  final String _label;

  /// Translated name (falls back to the English text).
  String get label => S.current.dyn('order.$id', _label);

  /// Still being worked on (not finished, not cancelled).
  bool get isActive =>
      this == OrderStatus.booked ||
          this == OrderStatus.cutting ||
          this == OrderStatus.stitching ||
          this == OrderStatus.ready;

  /// The next step in the normal flow, or null at the end.
  OrderStatus? get next {
    switch (this) {
      case OrderStatus.booked:
        return OrderStatus.cutting;
      case OrderStatus.cutting:
        return OrderStatus.stitching;
      case OrderStatus.stitching:
        return OrderStatus.ready;
      case OrderStatus.ready:
        return OrderStatus.delivered;
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        return null;
    }
  }

  static OrderStatus fromId(String? id) {
    for (final status in OrderStatus.values) {
      if (status.id == id) return status;
    }
    return OrderStatus.booked;
  }
}

enum PaymentStatus {
  unpaid('unpaid', 'Unpaid'),
  partial('partial', 'Partial'),
  paid('paid', 'Paid');

  const PaymentStatus(this.id, this._label);

  /// Stored in Firestore. Never change these strings.
  final String id;
  final String _label;

  /// Translated name (falls back to the English text).
  String get label => S.current.dyn('pay.$id', _label);

  static PaymentStatus fromId(String? id) {
    for (final status in PaymentStatus.values) {
      if (status.id == id) return status;
    }
    return PaymentStatus.unpaid;
  }
}
