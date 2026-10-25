import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/utils/app_dates.dart';
import 'package:tailor_app/core/errors/app_failure.dart';
import 'package:tailor_app/core/router/app_routes.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/core/widgets/app_snackbar.dart';
import 'package:tailor_app/core/widgets/state_views.dart';
import 'package:tailor_app/features/customers/data/models/customer.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_state.dart';

import '../../../measurements/presentation/widgets/customer_measurements_tab.dart';
import '../../../orders/presentation/widgets/customer_orders_tab.dart';
import '../../../payments/presentation/widgets/customer_ledger_view.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key, required this.customerId});

  final String customerId;

  Future<void> _confirmArchive(BuildContext context, Customer customer) async {
    final cubit = context.read<CustomersCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.current.archiveCustomerQ),
        content: Text(
          S.current.archiveCustomerBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(S.current.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(S.current.archive),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await cubit.archive(customer.id);
      if (!context.mounted) return;
      AppSnackbar.showSuccess(context, S.current.customerArchived);
      context.pop();
    } on AppFailure catch (failure) {
      if (context.mounted) AppSnackbar.showError(context, failure.message);
    }
  }

  Future<void> _restore(BuildContext context, Customer customer) async {
    final cubit = context.read<CustomersCubit>();

    try {
      await cubit.restore(customer.id);
      if (context.mounted) {
        AppSnackbar.showSuccess(context, S.current.customerRestored);
      }
    } on AppFailure catch (failure) {
      if (context.mounted) AppSnackbar.showError(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomersCubit, CustomersState>(
      builder: (context, state) {
        final customer = state.customerById(customerId);

        if (customer == null) {
          return Scaffold(
            appBar: AppBar(),
            body: state.status == CustomersStatus.loading
                ? const LoadingView()
                : EmptyState(
              icon: Icons.person_off_outlined,
              title: S.current.customerNotFound,
              message: S.current.customerMayBeRemoved,
              actionLabel: S.current.backToCustomers,
              onAction: () => context.go(AppRoutes.customers),
            ),
          );
        }

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                customer.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  tooltip: S.current.editCustomer,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () =>
                      context.push(AppRoutes.customerEdit(customer.id)),
                ),
                PopupMenuButton<String>(
                  tooltip: S.current.moreOptions,
                  onSelected: (value) {
                    if (value == 'archive') _confirmArchive(context, customer);
                    if (value == 'restore') _restore(context, customer);
                  },
                  itemBuilder: (context) => [
                    if (customer.isArchived)
                      PopupMenuItem(
                        value: 'restore',
                        child: Text(S.current.restoreCustomer),
                      )
                    else
                      PopupMenuItem(
                        value: 'archive',
                        child: Text(S.current.archiveCustomer),
                      ),
                  ],
                ),
              ],
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: S.current.overview),
                  Tab(text: S.current.measurements),
                  Tab(text: S.current.orders),
                  Tab(text: S.current.payments),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _OverviewTab(customer: customer),
                CustomerMeasurementsTab(customerId: customer.id),
                CustomerOrdersTab(customerId: customer.id),
                CustomerLedgerView(
                  customerId: customer.id,
                  onOpenOrder: (order) => context.push(
                    AppRoutes.customerOrderDetails(customer.id, order.id),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final createdAt = customer.createdAt;
    final since =
    createdAt == null ? S.current.justNow : AppDates.medium(createdAt);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: context.pal.primarySoft,
                      child: Text(
                        customer.initial,
                        style: TextStyle(
                          color: context.pal.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (customer.isArchived) ...[
                            const SizedBox(height: 6),
                            Chip(
                              label: Text(S.current.archived),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: S.current.phone,
                      value: customer.phone,
                      trailing: customer.phone.isEmpty
                          ? null
                          : IconButton(
                        tooltip: S.current.copyPhone,
                        icon: const Icon(Icons.copy_outlined, size: 20),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: customer.phone),
                          );
                          if (context.mounted) {
                            AppSnackbar.showSuccess(
                              context,
                              S.current.phoneCopied,
                            );
                          }
                        },
                      ),
                    ),
                    const Divider(height: 28),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: S.current.address,
                      value: customer.address,
                    ),
                    const Divider(height: 28),
                    _InfoRow(
                      icon: Icons.notes_outlined,
                      label: S.current.notes,
                      value: customer.notes,
                    ),
                    const Divider(height: 28),
                    _InfoRow(
                      icon: Icons.event_outlined,
                      label: S.current.customerSince,
                      value: since,
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isEmpty = value.trim().isEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: context.pal.slate500),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: context.pal.slate500),
              ),
              const SizedBox(height: 2),
              Text(
                isEmpty ? S.current.notAdded : value,
                style: TextStyle(color: isEmpty ? context.pal.slate500 : null),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}