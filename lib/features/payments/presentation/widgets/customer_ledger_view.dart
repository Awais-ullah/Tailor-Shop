import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/utils/money.dart';
import 'package:tailor_app/core/widgets/adaptive_wrap.dart';
import 'package:tailor_app/core/widgets/state_views.dart';
import 'package:tailor_app/core/widgets/stat_tile.dart';
import 'package:tailor_app/features/orders/data/models/order.dart';
import 'package:tailor_app/features/orders/data/order_money.dart';
import 'package:tailor_app/features/orders/data/order_status.dart';
import 'package:tailor_app/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:tailor_app/features/orders/presentation/cubit/orders_state.dart';
import 'package:tailor_app/features/orders/presentation/widgets/status_chips.dart';
import 'package:tailor_app/features/payments/data/ledger_calculator.dart';
import 'package:tailor_app/features/payments/presentation/cubit/payments_cubit.dart';
import 'package:tailor_app/features/payments/presentation/cubit/payments_state.dart';
import 'package:tailor_app/features/payments/presentation/widgets/payment_tile.dart';

/// One customer's money: totals, each order's balance, and every payment.
/// [onOpenOrder] decides where tapping an order goes.
class CustomerLedgerView extends StatelessWidget {
  const CustomerLedgerView({
    super.key,
    required this.customerId,
    required this.onOpenOrder,
  });

  final String customerId;
  final void Function(Order order) onOpenOrder;

  @override
  Widget build(BuildContext context) {
    final ordersState = context.watch<OrdersCubit>().state;
    final paymentsState = context.watch<PaymentsCubit>().state;

    if (ordersState.status == OrdersStatus.loading ||
        paymentsState.status == PaymentsStatus.loading) {
      return const LoadingView();
    }
    if (ordersState.status == OrdersStatus.failure) {
      return ErrorState(
        message: ordersState.errorMessage ?? 'Could not load orders.',
        onRetry: context.read<OrdersCubit>().retry,
      );
    }
    if (paymentsState.status == PaymentsStatus.failure) {
      return ErrorState(
        message: paymentsState.errorMessage ?? 'Could not load payments.',
        onRetry: context.read<PaymentsCubit>().retry,
      );
    }

    final orders = ordersState.forCustomer(customerId);
    if (orders.isEmpty) {
      return const EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'No balance yet',
        message: 'Payments and balances appear here once this customer has an order.',
      );
    }

    final balance = LedgerCalculator.forCustomer(customerId, orders);
    final payments = paymentsState.forCustomer(customerId);
    final orderNumbers = {for (final order in orders) order.id: order.orderNumber};
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AdaptiveWrap(
              minItemWidth: 150,
              children: [
                StatTile(
                  label: 'Total billed',
                  value: Money.pkr(balance.totalBilled),
                  icon: Icons.receipt_long_outlined,
                ),
                StatTile(
                  label: 'Paid',
                  value: Money.pkr(balance.totalPaid),
                  color: AppColors.success,
                  icon: Icons.check_circle_outline,
                ),
                StatTile(
                  label: 'Outstanding',
                  value: Money.pkr(balance.outstanding),
                  color: balance.outstanding > 0
                      ? AppColors.danger
                      : AppColors.success,
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Orders',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final order in orders) ...[
              _OrderBalanceRow(order: order, onTap: () => onOpenOrder(order)),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            Text(
              'Payment history',
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (payments.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No payments yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.slate500),
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      for (final payment in payments)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PaymentTile(
                            payment: payment,
                            subtitleExtra: orderNumbers[payment.orderId] == null
                                ? null
                                : '#${orderNumbers[payment.orderId]}',
                          ),
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

class _OrderBalanceRow extends StatelessWidget {
  const _OrderBalanceRow({required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cancelled = order.status == OrderStatus.cancelled;
    final remaining = OrderMoney.remaining(
      total: order.totalAmount,
      paid: order.totalPaid,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${order.orderNumber} · ${order.itemsSummary}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (cancelled)
                    OrderStatusChip(status: order.status)
                  else
                    PaymentStatusChip(status: order.paymentStatus),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                cancelled
                    ? 'Cancelled · not counted in the balance'
                    : 'Total ${Money.pkr(order.totalAmount)} · '
                    'Paid ${Money.pkr(order.totalPaid)} · '
                    'Remaining ${Money.pkr(remaining)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.slate500, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}