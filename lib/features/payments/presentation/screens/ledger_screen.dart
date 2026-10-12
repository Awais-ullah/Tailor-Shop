import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/router/app_routes.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/utils/app_dates.dart';
import 'package:tailor_app/core/utils/money.dart';
import 'package:tailor_app/core/widgets/adaptive_wrap.dart';
import 'package:tailor_app/core/widgets/state_views.dart';
import 'package:tailor_app/core/widgets/stat_tile.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:tailor_app/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:tailor_app/features/orders/presentation/cubit/orders_state.dart';
import 'package:tailor_app/features/payments/data/ledger_calculator.dart';
import 'package:tailor_app/features/payments/presentation/cubit/payments_cubit.dart';
import 'package:tailor_app/features/payments/presentation/cubit/payments_state.dart';
import 'package:tailor_app/features/payments/presentation/widgets/payment_tile.dart';

class LedgerScreen extends StatelessWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ordersState = context.watch<OrdersCubit>().state;
    final paymentsState = context.watch<PaymentsCubit>().state;
    final customersState = context.watch<CustomersCubit>().state;

    Widget body;
    if (ordersState.status == OrdersStatus.loading ||
        paymentsState.status == PaymentsStatus.loading) {
      body = const LoadingView();
    } else if (ordersState.status == OrdersStatus.failure) {
      body = ErrorState(
        message: ordersState.errorMessage ?? 'Could not load orders.',
        onRetry: context.read<OrdersCubit>().retry,
      );
    } else if (paymentsState.status == PaymentsStatus.failure) {
      body = ErrorState(
        message: paymentsState.errorMessage ?? 'Could not load payments.',
        onRetry: context.read<PaymentsCubit>().retry,
      );
    } else {
      final names = {
        for (final customer in customersState.customers) customer.id: customer.name,
      };
      String nameOf(String id) => names[id] ?? 'Unknown customer';

      final balances = LedgerCalculator.outstandingBalances(ordersState.orders);
      final totalOutstanding = LedgerCalculator.totalOutstanding(ordersState.orders);
      final collectedToday = paymentsState.collectedOn(AppDates.today());
      final orderNumbers = {
        for (final order in ordersState.orders) order.id: order.orderNumber,
      };
      final recent = paymentsState.payments.take(10).toList();
      final textTheme = Theme.of(context).textTheme;

      body = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AdaptiveWrap(
                minItemWidth: 200,
                children: [
                  StatTile(
                    label: 'Total outstanding',
                    value: Money.pkr(totalOutstanding),
                    color: totalOutstanding > 0
                        ? AppColors.danger
                        : AppColors.success,
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  StatTile(
                    label: 'Collected today',
                    value: Money.pkr(collectedToday),
                    color: AppColors.success,
                    icon: Icons.payments_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Outstanding balances',
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (balances.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'All settled up. Nobody owes anything right now.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.slate500),
                    ),
                  ),
                )
              else
                for (final balance in balances) ...[
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () =>
                          context.push(AppRoutes.ledgerCustomer(balance.customerId)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primarySoft,
                              child: Text(
                                customersState
                                    .customerById(balance.customerId)
                                    ?.initial ??
                                    '?',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nameOf(balance.customerId),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${balance.openOrders} open '
                                        '${balance.openOrders == 1 ? 'order' : 'orders'}',
                                    style: const TextStyle(
                                      color: AppColors.slate500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              Money.pkr(balance.outstanding),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              const SizedBox(height: 16),
              Text(
                'Recent payments',
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (recent.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No payments recorded yet.',
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
                        for (final payment in recent)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: PaymentTile(
                              payment: payment,
                              subtitleExtra: [
                                nameOf(payment.customerId),
                                if (orderNumbers[payment.orderId] != null)
                                  '#${orderNumbers[payment.orderId]}',
                              ].join(' '),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Ledger')),
      body: body,
    );
  }
}