import 'package:flutter/material.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/core/utils/app_dates.dart';
import 'package:tailor_app/core/utils/money.dart';
import 'package:tailor_app/features/orders/presentation/widgets/status_chips.dart';
import 'package:tailor_app/features/payments/data/models/payment.dart';
import 'package:tailor_app/features/payments/presentation/payment_method_ui.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';

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
                ? context.pal.slate100
                : context.pal.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            payment.method.icon,
            size: 20,
            color: voided ? context.pal.slate500 : context.pal.success,
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
                  color: voided ? context.pal.slate500 : null,
                  decoration: voided ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(
                details,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.pal.slate500, fontSize: 13),
              ),
            ],
          ),
        ),
        if (voided)
          Padding(
            padding: EdgeInsetsDirectional.only(start: 8),
            child: StatusPill(
              label: S.current.voided,
              color: context.pal.slate500,
              icon: Icons.block,
            ),
          ),
        ?trailing,
      ],
    );
  }
}