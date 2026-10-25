import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
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
import 'package:tailor_app/core/l10n/app_strings.dart';

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
        message: ordersState.errorMessage ?? S.current.couldNotLoadOrders,
        onRetry: context.read<OrdersCubit>().retry,
      );
    }
    if (paymentsState.status == PaymentsStatus.failure) {
      return ErrorState(
        message: paymentsState.errorMessage ?? S.current.couldNotLoadPayments,
        onRetry: context.read<PaymentsCubit>().retry,
      );
    }

    final orders = ordersState.forCustomer(customerId);
    if (orders.isEmpty) {
      return EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: S.current.noBalanceYet,
        message: S.current.paymentsAppearOnceOrder,
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
                  label: S.current.totalBilled,
                  value: Money.pkr(balance.totalBilled),
                  icon: Icons.receipt_long_outlined,
                ),
                StatTile(
                  label: S.current.paid,
                  value: Money.pkr(balance.totalPaid),
                  color: context.pal.success,
                  icon: Icons.check_circle_outline,
                ),
                StatTile(
                  label: S.current.outstanding,
                  value: Money.pkr(balance.outstanding),
                  color: balance.outstanding > 0
                      ? context.pal.danger
                      : context.pal.success,
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              S.current.orders,
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final order in orders) ...[
              _OrderBalanceRow(order: order, onTap: () => onOpenOrder(order)),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            Text(
              S.current.paymentHistory,
              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (payments.isEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    S.current.noPaymentsYetDot,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.pal.slate500),
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
                          padding: const EdgeInsetsDirectional.only(bottom: 12),
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
                    ? S.current.cancelledNotCounted
                    : S.current.ledgerOrderLine(Money.pkr(order.totalAmount), Money.pkr(order.totalPaid), Money.pkr(remaining)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.pal.slate500, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}