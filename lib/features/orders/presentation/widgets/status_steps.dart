import 'package:flutter/material.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/features/orders/data/order_status.dart';
import 'package:tailor_app/features/orders/presentation/order_status_ui.dart';
import 'package:tailor_app/features/orders/presentation/widgets/status_chips.dart';

// The Booked → Delivered progress strip on the order detail screen.

/// Booked -> Cutting -> Stitching -> Ready -> Delivered, with finished
/// steps ticked and the current step highlighted. Wraps on narrow screens.
class OrderStatusSteps extends StatelessWidget {
  const OrderStatusSteps({super.key, required this.current});

  final OrderStatus current;

  static const List<OrderStatus> _steps = [
    OrderStatus.booked,
    OrderStatus.cutting,
    OrderStatus.stitching,
    OrderStatus.ready,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = _steps.indexOf(current);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < _steps.length; i++)
          _stepPill(
            _steps[i],
            done: i < currentIndex,
            active: i == currentIndex,
          ),
      ],
    );
  }

  Widget _stepPill(
    OrderStatus status, {
    required bool done,
    required bool active,
  }) {
    if (active) {
      return StatusPill(
        label: status.label,
        color: status.color,
        icon: status.icon,
      );
    }
    if (done) {
      return const _DonePill();
    }
    return _UpcomingPill(label: status.label);
  }
}

class _DonePill extends StatelessWidget {
  const _DonePill();

  @override
  Widget build(BuildContext context) {
    return StatusPill(
      label: S.current.done,
      color: AppColors.success,
      icon: Icons.check,
    );
  }
}

class _UpcomingPill extends StatelessWidget {
  const _UpcomingPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.pal.slate100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: context.pal.slate500,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
