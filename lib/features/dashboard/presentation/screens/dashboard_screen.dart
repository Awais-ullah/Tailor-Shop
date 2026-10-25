import 'package:flutter/material.dart';
import 'package:tailor_app/core/widgets/fade_slide_in.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/router/app_routes.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
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
import 'package:tailor_app/features/measurements/presentation/widgets/garment_picker_sheet.dart';
import 'package:tailor_app/features/orders/data/models/order.dart';
import 'package:tailor_app/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:tailor_app/features/orders/presentation/cubit/orders_state.dart';
import 'package:tailor_app/features/orders/presentation/widgets/status_chips.dart';
import 'package:tailor_app/features/payments/data/ledger_calculator.dart';
import 'package:tailor_app/features/payments/presentation/cubit/payments_cubit.dart';
import 'package:tailor_app/features/payments/presentation/cubit/payments_state.dart';
import 'package:tailor_app/features/payments/presentation/widgets/payment_tile.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return S.current.goodMorning;
  if (hour < 17) return S.current.goodAfternoon;
  return S.current.goodEvening;
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
    AppSnackbar.showError(context, S.current.addCustomerFirstOrder);
    return;
  }

  final customer = await showCustomerPicker(context, customers);
  if (customer == null || !context.mounted) return;

  context.go(AppRoutes.orderNewFor(customer.id));
}

/// Pick a customer, pick a garment, then open the measurement form.
Future<void> _newMeasurement(BuildContext context) async {
  final customers = context
      .read<CustomersCubit>()
      .state
      .customers
      .where((customer) => !customer.isArchived)
      .toList();

  if (customers.isEmpty) {
    AppSnackbar.showError(
      context,
      S.current.addCustomerFirstMeasure,
    );
    return;
  }

  final customer = await showCustomerPicker(context, customers);
  if (customer == null || !context.mounted) return;

  final garment = await showGarmentPicker(context);
  if (garment == null || !context.mounted) return;

  context.go(AppRoutes.measurementNewFor(customer.id, garment.id));
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
      body = const SafeArea(child: LoadingView());
    } else if (customersState.status == CustomersStatus.failure) {
      body = SafeArea(
        child: ErrorState(
          message: customersState.errorMessage ?? S.current.couldNotLoadCustomers,
          onRetry: context.read<CustomersCubit>().retry,
        ),
      );
    } else if (ordersState.status == OrdersStatus.failure) {
      body = SafeArea(
        child: ErrorState(
          message: ordersState.errorMessage ?? S.current.couldNotLoadOrders,
          onRetry: context.read<OrdersCubit>().retry,
        ),
      );
    } else if (paymentsState.status == PaymentsStatus.failure) {
      body = SafeArea(
        child: ErrorState(
          message: paymentsState.errorMessage ?? S.current.couldNotLoadPayments,
          onRetry: context.read<PaymentsCubit>().retry,
        ),
      );
    } else {
      body = _DashboardBody(
        customers: customersState,
        orders: ordersState,
        payments: paymentsState,
      );
    }

    // No AppBar: the teal header in _DashboardBody replaces it.
    return Scaffold(body: body);
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
    String nameOf(String id) => names[id] ?? S.current.unknownCustomer;
    final orderNumbers = {
      for (final order in orders.orders) order.id: order.orderNumber,
    };

    final user = context.select((AuthCubit cubit) => cubit.state.user);
    final fullName = user?.displayName?.trim() ?? '';
    final firstName = fullName.isEmpty ? '' : fullName.split(' ').first;
    final topInset = MediaQuery.paddingOf(context).top;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Header(
          topInset: topInset,
          greeting:
          firstName.isEmpty ? _greeting() : '${_greeting()}, $firstName',
          date: AppDates.long(today),
          collected: summary.collectedToday,
          outstanding: summary.totalOutstanding,
        ),
        // Room for the part of the floating card that hangs below the header.
        const SizedBox(height: 68),
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeSlideIn(
                      delay: const Duration(milliseconds: 80),
                      child: Row(
                        children: [
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.add_rounded,
                              label: S.current.newOrder,
                              highlighted: true,
                              onTap: () => _newOrder(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.person_add_alt_1_outlined,
                              label: S.current.newCustomer,
                              onTap: () => context.go(AppRoutes.customerNew),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.straighten_outlined,
                              label: S.current.measurement,
                              onTap: () => _newMeasurement(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.account_balance_wallet_outlined,
                              label: S.current.ledger,
                              onTap: () => context.go(AppRoutes.ledger),
                            ),
                          ),
                        ],
                      )
                  ),
                  const SizedBox(height: 20),
                  FadeSlideIn(
                      delay: const Duration(milliseconds: 170),
                      child: AdaptiveWrap(
                        minItemWidth: 150,
                        children: [
                          StatTile(
                            label: S.current.overdue,
                            value: '${summary.overdueOrders}',
                            icon: Icons.warning_amber_rounded,
                            color: summary.overdueOrders > 0
                                ? context.pal.danger
                                : null,
                            onTap: () => _openOrders(context, OrderFilter.active),
                          ),
                          StatTile(
                            label: S.current.dueToday,
                            value: '${summary.dueToday}',
                            icon: Icons.event_available_outlined,
                            onTap: () => _openOrders(context, OrderFilter.active),
                          ),
                          StatTile(
                            label: S.current.readyForPickup,
                            value: '${summary.readyOrders}',
                            icon: Icons.check_circle_outline,
                            color:
                            summary.readyOrders > 0 ? context.pal.success : null,
                            onTap: () => _openOrders(context, OrderFilter.ready),
                          ),
                          StatTile(
                            label: S.current.pendingOrders,
                            value: '${summary.pendingOrders}',
                            icon: Icons.content_cut,
                            color: context.pal.goldDeep,
                            onTap: () => _openOrders(context, OrderFilter.active),
                          ),
                          StatTile(
                            label: S.current.todaysOrders,
                            value: '${summary.todaysOrders}',
                            icon: Icons.today_outlined,
                            onTap: () => _openOrders(context, OrderFilter.all),
                          ),
                          StatTile(
                            label: S.current.customers,
                            value: '${summary.totalCustomers}',
                            icon: Icons.people_outline,
                            onTap: () => context.go(AppRoutes.customers),
                          ),
                          StatTile(
                            label: S.current.totalOrders,
                            value: '${summary.totalOrders}',
                            icon: Icons.receipt_long_outlined,
                            onTap: () => _openOrders(context, OrderFilter.all),
                          ),
                          StatTile(
                            label: S.current.delivered,
                            value: '${summary.deliveredOrders}',
                            icon: Icons.task_alt,
                            onTap: () =>
                                _openOrders(context, OrderFilter.delivered),
                          ),
                        ],
                      )
                  ),
                  const SizedBox(height: 24),
                  FadeSlideIn(
                      delay: const Duration(milliseconds: 260),
                      child: AdaptiveWrap(
                        minItemWidth: 440,
                        children: [
                          _SectionCard(
                            title: S.current.dueSoon,
                            actionLabel: S.current.viewAll,
                            onAction: () =>
                                _openOrders(context, OrderFilter.active),
                            child: summary.upcomingDeliveries.isEmpty
                                ? _EmptyLine(S.current.nothingDue7)
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
                            title: S.current.recentOrders,
                            actionLabel: S.current.viewAll,
                            onAction: () => _openOrders(context, OrderFilter.all),
                            child: summary.recentOrders.isEmpty
                                ? _EmptyLine(S.current.noOrdersYetDot)
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
                            title: S.current.whoOwesMoney,
                            actionLabel: S.current.viewLedger,
                            onAction: () => context.go(AppRoutes.ledger),
                            child: summary.topBalances.isEmpty
                                ? _EmptyLine(
                                S.current.allSettledUp)
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
                            title: S.current.recentPayments,
                            actionLabel: S.current.viewLedger,
                            onAction: () => context.go(AppRoutes.ledger),
                            child: summary.recentPayments.isEmpty
                                ? _EmptyLine(S.current.noPaymentsYet)
                                : Column(
                              children: [
                                for (final payment in summary.recentPayments)
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(bottom: 12),
                                    child: PaymentTile(
                                      payment: payment,
                                      subtitleExtra: [
                                        nameOf(payment.customerId),
                                        if (orderNumbers[payment.orderId] !=
                                            null)
                                          '#${orderNumbers[payment.orderId]}',
                                      ].join(' '),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      )
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Teal gradient header with a floating "Collected / Outstanding" card.
class _Header extends StatelessWidget {
  const _Header({
    required this.topInset,
    required this.greeting,
    required this.date,
    required this.collected,
    required this.outstanding,
  });

  final double topInset;
  final String greeting;
  final String date;
  final int collected;
  final int outstanding;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsetsDirectional.fromSTEB(20, topInset + 16, 20, 64),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryLight,
                AppColors.primary,
                AppColors.primaryDark,
              ],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.content_cut,
                          size: 22,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        S.current.appName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    greeting,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: -48,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Material(
                color: context.pal.surface,
                elevation: 6,
                shadowColor: const Color(0x3307343E),
                surfaceTintColor: Colors.transparent,
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.current.collectedToday,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: context.pal.slate500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                Money.pkr(collected),
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: context.pal.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 44,
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        color: context.pal.slate200,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              S.current.outstanding,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: context.pal.slate500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerEnd,
                              child: Text(
                                Money.pkr(outstanding),
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: outstanding > 0
                                      ? context.pal.danger
                                      : context.pal.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Square rounded icon button with a one-line label underneath.
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: highlighted ? context.pal.brand : context.pal.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: highlighted
                ? BorderSide.none
                : BorderSide(color: context.pal.slate200),
          ),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(
                icon,
                size: 24,
                color: highlighted ? AppColors.gold : context.pal.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.pal.slate900,
            ),
          ),
        ),
      ],
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ),
            const SizedBox(height: 4),
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
      child: Text(text, style: TextStyle(color: context.pal.slate500)),
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
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: context.pal.primarySoft,
              child: Text(
                customerName.isEmpty
                    ? '?'
                    : String.fromCharCode(customerName.runes.first)
                    .toUpperCase(),
                style: TextStyle(
                  color: context.pal.primary,
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
                    '#${order.orderNumber} · $customerName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    overdue
                        ? S.current.dueDateOverdue(AppDates.short(order.deliveryDate))
                        : S.current.dueDate(AppDates.short(order.deliveryDate)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: overdue ? context.pal.danger : context.pal.slate500,
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
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: context.pal.primarySoft,
              child: Text(
                name.isEmpty
                    ? '?'
                    : String.fromCharCode(name.runes.first).toUpperCase(),
                style: TextStyle(
                  color: context.pal.primary,
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
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    S.current.openOrdersCount(balance.openOrders),
                    style: TextStyle(
                      color: context.pal.slate500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              Money.pkr(balance.outstanding),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: context.pal.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}