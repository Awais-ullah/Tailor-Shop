import 'package:flutter/material.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/features/orders/data/order_status.dart';

/// How an order status looks on screen.
extension OrderStatusUi on OrderStatus {
  IconData get icon {
    switch (this) {
      case OrderStatus.booked:
        return Icons.event_note_outlined;
      case OrderStatus.cutting:
        return Icons.content_cut;
      case OrderStatus.stitching:
        return Icons.design_services_outlined;
      case OrderStatus.ready:
        return Icons.check_circle_outline;
      case OrderStatus.delivered:
        return Icons.task_alt;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.booked:
        return AppColors.slate500;
      case OrderStatus.cutting:
        return AppColors.warning;
      case OrderStatus.stitching:
        return AppColors.info;
      case OrderStatus.ready:
        return AppColors.success;
      case OrderStatus.delivered:
        return AppColors.primary;
      case OrderStatus.cancelled:
        return AppColors.danger;
    }
  }
}

/// How a payment status (Paid / Partial / Unpaid) looks on screen.
extension PaymentStatusUi on PaymentStatus {
  IconData get icon {
    switch (this) {
      case PaymentStatus.unpaid:
        return Icons.radio_button_unchecked;
      case PaymentStatus.partial:
        return Icons.timelapse;
      case PaymentStatus.paid:
        return Icons.check_circle;
    }
  }

  Color get color {
    switch (this) {
      case PaymentStatus.unpaid:
        return AppColors.danger;
      case PaymentStatus.partial:
        return AppColors.warning;
      case PaymentStatus.paid:
        return AppColors.success;
    }
  }
}
