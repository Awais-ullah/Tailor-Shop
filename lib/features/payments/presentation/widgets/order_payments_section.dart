import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tailor_app/core/errors/app_failure.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/core/utils/money.dart';
import 'package:tailor_app/core/widgets/app_snackbar.dart';
import 'package:tailor_app/features/orders/data/models/order.dart';
import 'package:tailor_app/features/orders/data/order_status.dart';
import 'package:tailor_app/features/payments/data/models/payment.dart';
import 'package:tailor_app/features/payments/presentation/cubit/payments_cubit.dart';
import 'package:tailor_app/features/payments/presentation/cubit/payments_state.dart';
import 'package:tailor_app/features/payments/presentation/widgets/payment_tile.dart';
import 'package:tailor_app/features/payments/presentation/widgets/record_payment_dialog.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';

/// "Payment history" card on the order detail screen, with the
/// Record payment button and Void action.
class OrderPaymentsSection extends StatelessWidget {
  const OrderPaymentsSection({super.key, required this.order});

  final Order order;

  Future<void> _record(BuildContext context) async {
    final cubit = context.read<PaymentsCubit>();

    final input = await showRecordPaymentDialog(
      context,
      remaining: order.remainingAmount,
    );
    if (input == null || !context.mounted) return;

    try {
      await cubit.recordPayment(
        order: order,
        amount: input.amount,
        method: input.method,
        note: input.note,
        date: input.date,
      );
      if (context.mounted) AppSnackbar.showSuccess(context, S.current.paymentRecorded);
    } on AppFailure catch (failure) {
      if (context.mounted) AppSnackbar.showError(context, failure.message);
    }
  }

  Future<void> _void(BuildContext context, Payment payment) async {
    final cubit = context.read<PaymentsCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.current.voidPaymentQ),
        content: Text(
          S.current.voidPaymentBody(Money.pkr(payment.amount)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(S.current.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(S.current.voidPayment),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await cubit.voidPayment(order: order, payment: payment);
      if (context.mounted) AppSnackbar.showSuccess(context, S.current.paymentVoided);
    } on AppFailure catch (failure) {
      if (context.mounted) AppSnackbar.showError(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PaymentsCubit>().state;
    final payments = state.forOrder(order.id);
    final canRecord =
        order.remainingAmount > 0 && order.status != OrderStatus.cancelled;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    S.current.paymentHistory,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                FilledButton.icon(
                  onPressed: canRecord ? () => _record(context) : null,
                  icon: const Icon(Icons.add),
                  label: Text(S.current.recordPayment),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.status == PaymentsStatus.loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (payments.isEmpty)
              Text(
                S.current.noPaymentsYetDot,
                style: TextStyle(color: context.pal.slate500),
              )
            else
              for (final payment in payments)
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: 12),
                  child: PaymentTile(
                    payment: payment,
                    trailing: payment.isVoided
                        ? null
                        : PopupMenuButton<String>(
                      tooltip: S.current.paymentOptions,
                      onSelected: (_) => _void(context, payment),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'void',
                          child: Text(S.current.voidPayment),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}