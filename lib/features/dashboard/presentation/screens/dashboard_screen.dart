import 'package:flutter/material.dart';
import 'package:tailor_app/core/widgets/fade_slide_in.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/router/app_routes.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/core/utils/app_dates.dart';
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
import 'package:tailor_app/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:tailor_app/features/orders/presentation/cubit/orders_state.dart';
import 'package:tailor_app/features/payments/presentation/cubit/payments_cubit.dart';
import 'package:tailor_app/features/payments/presentation/cubit/payments_state.dart';
import 'package:tailor_app/features/payments/presentation/widgets/payment_tile.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';
import 'package:tailor_app/features/dashboard/presentation/widgets/dashboard_sections.dart';

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
        DashboardHeader(
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
                            child: DashboardQuickAction(
                              icon: Icons.add_rounded,
                              label: S.current.newOrder,
                              highlighted: true,
                              onTap: () => _newOrder(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DashboardQuickAction(
                              icon: Icons.person_add_alt_1_outlined,
                              label: S.current.newCustomer,
                              onTap: () => context.go(AppRoutes.customerNew),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DashboardQuickAction(
                              icon: Icons.straighten_outlined,
                              label: S.current.measurement,
                              onTap: () => _newMeasurement(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DashboardQuickAction(
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
                          DashboardSectionCard(
                            title: S.current.dueSoon,
                            actionLabel: S.current.viewAll,
                            onAction: () =>
                                _openOrders(context, OrderFilter.active),
                            child: summary.upcomingDeliveries.isEmpty
                                ? DashboardEmptyLine(S.current.nothingDue7)
                                : Column(
                              children: [
                                for (final order in summary.upcomingDeliveries)
                                  DashboardOrderRow(
                                    order: order,
                                    customerName: nameOf(order.customerId),
                                  ),
                              ],
                            ),
                          ),
                          DashboardSectionCard(
                            title: S.current.recentOrders,
                            actionLabel: S.current.viewAll,
                            onAction: () => _openOrders(context, OrderFilter.all),
                            child: summary.recentOrders.isEmpty
                                ? DashboardEmptyLine(S.current.noOrdersYetDot)
                                : Column(
                              children: [
                                for (final order in summary.recentOrders)
                                  DashboardOrderRow(
                                    order: order,
                                    customerName: nameOf(order.customerId),
                                  ),
                              ],
                            ),
                          ),
                          DashboardSectionCard(
                            title: S.current.whoOwesMoney,
                            actionLabel: S.current.viewLedger,
                            onAction: () => context.go(AppRoutes.ledger),
                            child: summary.topBalances.isEmpty
                                ? DashboardEmptyLine(
                                S.current.allSettledUp)
                                : Column(
                              children: [
                                for (final balance in summary.topBalances)
                                  DashboardBalanceRow(
                                    balance: balance,
                                    name: nameOf(balance.customerId),
                                  ),
                              ],
                            ),
                          ),
                          DashboardSectionCard(
                            title: S.current.recentPayments,
                            actionLabel: S.current.viewLedger,
                            onAction: () => context.go(AppRoutes.ledger),
                            child: summary.recentPayments.isEmpty
                                ? DashboardEmptyLine(S.current.noPaymentsYet)
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
