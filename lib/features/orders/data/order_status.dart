import 'package:flutter/material.dart';
import 'package:tailor_app/core/theme/app_colors.dart';

enum OrderStatus {
  booked('booked', 'Booked', Icons.event_note_outlined, AppColors.slate500),
  cutting('cutting', 'Cutting', Icons.content_cut, AppColors.warning),
  stitching(
    'stitching',
    'Stitching',
    Icons.design_services_outlined,
    AppColors.info,
  ),
  ready('ready', 'Ready', Icons.check_circle_outline, AppColors.success),
  delivered('delivered', 'Delivered', Icons.task_alt, AppColors.primary),
  cancelled('cancelled', 'Cancelled', Icons.cancel_outlined, AppColors.danger);

  const OrderStatus(this.id, this.label, this.icon, this.color);

  /// Stored in Firestore. Never change these strings.
  final String id;
  final String label;
  final IconData icon;
  final Color color;

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
  unpaid('unpaid', 'Unpaid', Icons.radio_button_unchecked, AppColors.danger),
  partial('partial', 'Partial', Icons.timelapse, AppColors.warning),
  paid('paid', 'Paid', Icons.check_circle, AppColors.success);

  const PaymentStatus(this.id, this.label, this.icon, this.color);

  /// Stored in Firestore. Never change these strings.
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  static PaymentStatus fromId(String? id) {
    for (final status in PaymentStatus.values) {
      if (status.id == id) return status;
    }
    return PaymentStatus.unpaid;
  }
}