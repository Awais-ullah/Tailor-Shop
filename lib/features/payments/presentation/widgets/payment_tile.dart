import 'package:flutter/material.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/utils/app_dates.dart';
import 'package:tailor_app/core/utils/money.dart';
import 'package:tailor_app/features/orders/presentation/widgets/status_chips.dart';
import 'package:tailor_app/features/payments/data/models/payment.dart';

/// One payment line. [subtitleExtra] adds context such as "#12" or a
/// customer name. [trailing] is for actions (for example "Void").
class PaymentTile extends StatelessWidget {
  const PaymentTile({
    super.key,
    required this.payment,
    this.subtitleExtra,
    this.trailing,
  });

  final Payment payment;
  final String? subtitleExtra;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final voided = payment.isVoided;
    final details = [
      AppDates.medium(payment.paidAt),
      payment.method.label,
      ?subtitleExtra,
      if (payment.note.isNotEmpty) payment.note,
    ].join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: voided
                ? AppColors.slate100
                : AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            payment.method.icon,
            size: 20,
            color: voided ? AppColors.slate500 : AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Money.pkr(payment.amount),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: voided ? AppColors.slate500 : null,
                  decoration: voided ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(
                details,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.slate500, fontSize: 13),
              ),
            ],
          ),
        ),
        if (voided)
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: StatusPill(
              label: 'Voided',
              color: AppColors.slate500,
              icon: Icons.block,
            ),
          ),
        ?trailing,
      ],
    );
  }
}