import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tailor_app/core/errors/app_failure.dart';
import 'package:tailor_app/core/router/app_routes.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/widgets/app_snackbar.dart';
import 'package:tailor_app/core/widgets/state_views.dart';
import 'package:tailor_app/features/customers/data/models/customer.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_state.dart';

import '../../../measurements/presentation/widgets/customer_measurements_tab.dart';
import '../../../orders/presentation/widgets/customer_orders_tab.dart';
import '../../../payments/presentation/widgets/customer_ledger_view.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key, required this.customerId});

  final String customerId;

  Future<void> _confirmArchive(BuildContext context, Customer customer) async {
    final cubit = context.read<CustomersCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archive this customer?'),
        content: const Text(
          "They'll be hidden from the customer list, but their history is "
              'kept. You can restore them at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await cubit.archive(customer.id);
      if (!context.mounted) return;
      AppSnackbar.showSuccess(context, 'Customer archived');
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
        AppSnackbar.showSuccess(context, 'Customer restored');
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
              title: 'Customer not found',
              message: 'This customer may have been removed.',
              actionLabel: 'Back to customers',
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
                  tooltip: 'Edit customer',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () =>
                      context.push(AppRoutes.customerEdit(customer.id)),
                ),
                PopupMenuButton<String>(
                  tooltip: 'More options',
                  onSelected: (value) {
                    if (value == 'archive') _confirmArchive(context, customer);
                    if (value == 'restore') _restore(context, customer);
                  },
                  itemBuilder: (context) => [
                    if (customer.isArchived)
                      const PopupMenuItem(
                        value: 'restore',
                        child: Text('Restore customer'),
                      )
                    else
                      const PopupMenuItem(
                        value: 'archive',
                        child: Text('Archive customer'),
                      ),
                  ],
                ),
              ],
              bottom: const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Measurements'),
                  Tab(text: 'Orders'),
                  Tab(text: 'Payments'),
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
    createdAt == null ? 'Just now' : DateFormat('d MMM y').format(createdAt);

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
                      backgroundColor: AppColors.primarySoft,
                      child: Text(
                        customer.initial,
                        style: const TextStyle(
                          color: AppColors.primary,
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
                            const Chip(
                              label: Text('Archived'),
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
                      label: 'Phone',
                      value: customer.phone,
                      trailing: customer.phone.isEmpty
                          ? null
                          : IconButton(
                        tooltip: 'Copy phone number',
                        icon: const Icon(Icons.copy_outlined, size: 20),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: customer.phone),
                          );
                          if (context.mounted) {
                            AppSnackbar.showSuccess(
                              context,
                              'Phone number copied',
                            );
                          }
                        },
                      ),
                    ),
                    const Divider(height: 28),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: customer.address,
                    ),
                    const Divider(height: 28),
                    _InfoRow(
                      icon: Icons.notes_outlined,
                      label: 'Notes',
                      value: customer.notes,
                    ),
                    const Divider(height: 28),
                    _InfoRow(
                      icon: Icons.event_outlined,
                      label: 'Customer since',
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
        Icon(icon, size: 20, color: AppColors.slate500),
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
                    ?.copyWith(color: AppColors.slate500),
              ),
              const SizedBox(height: 2),
              Text(
                isEmpty ? 'Not added' : value,
                style: TextStyle(color: isEmpty ? AppColors.slate500 : null),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}