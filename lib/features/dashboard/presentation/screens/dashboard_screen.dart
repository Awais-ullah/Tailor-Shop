
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/router/app_routes.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/utils/app_dates.dart';
import 'package:tailor_app/core/utils/money.dart';
import 'package:tailor_app/core/widgets/adaptive_wrap.dart';
import 'package:tailor_app/core/widgets/app_snackbar.dart';
import 'package:tailor_app/core/widgets/state_views.dart';
import 'package:tailor_app/core/widgets/stat_tile.dart';
import 'package:tailor_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_state.dart';
import 'package:tailor_app/features/customers/presentation/widgets/customer_picker_dialog.dart';
import 'package:tailor_app/features/dashboard/data/dashboard_summary.dart';
import 'package:tailor_app/features/orders/data/models/order.dart';
import 'package:tailor_app/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:tailor_app/features/orders/presentation/cubit/orders_state.dart';
import 'package:tailor_app/features/orders/presentation/widgets/status_chips.dart';
import 'package:tailor_app/features/payments/data/ledger_calculator.dart';
import 'package:tailor_app/features/payments/presentation/cubit/payments_cubit.dart';
import 'package:tailor_app/features/payments/presentation/cubit/payments_state.dart';
import 'package:tailor_app/features/payments/presentation/widgets/payment_tile.dart';


String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

/// Jumps to the Orders tab with a filter already applied.
void _openOrders(BuildContext context, OrderFilter filter) {
  context.read<OrdersCubit>().setFilter(filter);
  context.go(AppRoutes.orders);
}

Future<void> _newOrder(BuildContext context) async {
  final customers = context
      .read<CustomersCubit>()
      .state
      .customers
      .where((customer) => !customer.isArchived)
      .toList();

  if (customers.isEmpty) {
    AppSnackbar.showError(context, 'Add a customer first, then create their order.');
    return;
  }

  final customer = await showCustomerPicker(context, customers);
  if (customer == null || !context.mounted) return;

  context.go(AppRoutes.orderNewFor(customer.id));
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customersState = context.watch<CustomersCubit>().state;
    final ordersState = context.watch<OrdersCubit>().state;
    final paymentsState = context.watch<PaymentsCubit>().state;

    final loading = customersState.status == CustomersStatus.loading ||
        ordersState.status == OrdersStatus.loading ||
        paymentsState.status == PaymentsStatus.loading;

    Widget body;
    if (loading) {
      body = const LoadingView();
    } else if (customersState.status == CustomersStatus.failure) {
      body = ErrorState(
        message: customersState.errorMessage ?? 'Could not load customers.',
        onRetry: context.read<CustomersCubit>().retry,
      );
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
      body = _DashboardBody(
        customers: customersState,
        orders: ordersState,
        payments: paymentsState,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: body,
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.customers,
    required this.orders,
    required this.payments,
  });

  final CustomersState customers;
  final OrdersState orders;
  final PaymentsState payments;

  @override
  Widget build(BuildContext context) {
    final today = AppDates.today();
    final summary = DashboardSummary.compute(
      customers: customers.customers,
      orders: orders.orders,
      payments: payments.payments,
      today: today,
    );

    final names = {
      for (final customer in customers.customers) customer.id: customer.name,
    };
    String nameOf(String id) => names[id] ?? 'Unknown customer';
    final orderNumbers = {
      for (final order in orders.orders) order.id: order.orderNumber,
    };

    final user = context.select((AuthCubit cubit) => cubit.state.user);
    final fullName = user?.displayName?.trim() ?? '';
    final firstName = fullName.isEmpty ? '' : fullName.split(' ').first;
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              firstName.isEmpty ? _greeting() : '${_greeting()}, $firstName',
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              AppDates.long(today),
              style: const TextStyle(color: AppColors.slate500),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _newOrder(context),
                  icon: const Icon(Icons.add),
                  label: const Text('New order'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.customerNew),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('New customer'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.ledger),
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: const Text('Ledger'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AdaptiveWrap(
              minItemWidth: 150,
              children: [
                StatTile(
                  label: 'Overdue',
                  value: '${summary.overdueOrders}',
                  icon: Icons.warning_amber_rounded,
                  color: summary.overdueOrders > 0 ? AppColors.danger : null,
                  onTap: () => _openOrders(context, OrderFilter.active),
                ),
                StatTile(
                  label: 'Due today',
                  value: '${summary.dueToday}',
                  icon: Icons.event_available_outlined,
                  onTap: () => _openOrders(context, OrderFilter.active),
                ),
                StatTile(
                  label: 'Ready for pickup',
                  value: '${summary.readyOrders}',
                  icon: Icons.check_circle_outline,
                  color: summary.readyOrders > 0 ? AppColors.success : null,
                  onTap: () => _openOrders(context, OrderFilter.ready),
                ),
                StatTile(
                  label: 'Collected today',
                  value: Money.pkr(summary.collectedToday),
                  icon: Icons.payments_outlined,
                  color: AppColors.success,
                  onTap: () => context.go(AppRoutes.ledger),
                ),
                StatTile(
                  label: 'Pending orders',
                  value: '${summary.pendingOrders}',
                  icon: Icons.content_cut,
                  onTap: () => _openOrders(context, OrderFilter.active),
                ),
                StatTile(
                  label: "Today's orders",
                  value: '${summary.todaysOrders}',
                  icon: Icons.today_outlined,
                  onTap: () => _openOrders(context, OrderFilter.all),
                ),
                StatTile(
                  label: 'Outstanding',
                  value: Money.pkr(summary.totalOutstanding),
                  icon: Icons.account_balance_wallet_outlined,
                  color: summary.totalOutstanding > 0 ? AppColors.danger : null,
                  onTap: () => context.go(AppRoutes.ledger),
                ),
                StatTile(
                  label: 'Customers',
                  value: '${summary.totalCustomers}',
                  icon: Icons.people_outline,
                  onTap: () => context.go(AppRoutes.customers),
                ),
                StatTile(
                  label: 'Total orders',
                  value: '${summary.totalOrders}',
                  icon: Icons.receipt_long_outlined,
                  onTap: () => _openOrders(context, OrderFilter.all),
                ),
                StatTile(
                  label: 'Delivered',
                  value: '${summary.deliveredOrders}',
                  icon: Icons.task_alt,
                  onTap: () => _openOrders(context, OrderFilter.delivered),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AdaptiveWrap(
              minItemWidth: 440,
              children: [
                _SectionCard(
                  title: 'Due soon',
                  actionLabel: 'View all',
                  onAction: () => _openOrders(context, OrderFilter.active),
                  child: summary.upcomingDeliveries.isEmpty
                      ? const _EmptyLine('Nothing due in the next 7 days.')
                      : Column(
                    children: [
                      for (final order in summary.upcomingDeliveries)
                        _OrderRow(
                          order: order,
                          customerName: nameOf(order.customerId),
                        ),
                    ],
                  ),
                ),
                _SectionCard(
                  title: 'Recent orders',
                  actionLabel: 'View all',
                  onAction: () => _openOrders(context, OrderFilter.all),
                  child: summary.recentOrders.isEmpty
                      ? const _EmptyLine('No orders yet.')
                      : Column(
                    children: [
                      for (final order in summary.recentOrders)
                        _OrderRow(
                          order: order,
                          customerName: nameOf(order.customerId),
                        ),
                    ],
                  ),
                ),
                _SectionCard(
                  title: 'Who owes money',
                  actionLabel: 'View ledger',
                  onAction: () => context.go(AppRoutes.ledger),
                  child: summary.topBalances.isEmpty
                      ? const _EmptyLine('All settled up. Nobody owes anything.')
                      : Column(
                    children: [
                      for (final balance in summary.topBalances)
                        _BalanceRow(
                          balance: balance,
                          name: nameOf(balance.customerId),
                        ),
                    ],
                  ),
                ),
                _SectionCard(
                  title: 'Recent payments',
                  actionLabel: 'View ledger',
                  onAction: () => context.go(AppRoutes.ledger),
                  child: summary.recentPayments.isEmpty
                      ? const _EmptyLine('No payments recorded yet.')
                      : Column(
                    children: [
                      for (final payment in summary.recentPayments)
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
              ],
            ),

          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: const TextStyle(color: AppColors.slate500)),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.customerName});

  final Order order;
  final String customerName;

  @override
  Widget build(BuildContext context) {
    final overdue = order.isOverdue;

    return InkWell(
      onTap: () => context.go(AppRoutes.orderDetails(order.id)),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${order.orderNumber} · $customerName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    overdue
                        ? 'Due ${AppDates.short(order.deliveryDate)} · Overdue'
                        : 'Due ${AppDates.short(order.deliveryDate)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: overdue ? AppColors.danger : AppColors.slate500,
                      fontWeight: overdue ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OrderStatusChip(status: order.status),
          ],
        ),
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  const _BalanceRow({required this.balance, required this.name});

  final CustomerBalance balance;
  final String name;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(AppRoutes.ledgerCustomer(balance.customerId)),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primarySoft,
              child: Text(
                name.isEmpty ? '?' : String.fromCharCode(name.runes.first).toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
    );
  }
}