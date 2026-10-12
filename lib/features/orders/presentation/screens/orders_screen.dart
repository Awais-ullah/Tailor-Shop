import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/router/app_routes.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/widgets/app_snackbar.dart';
import 'package:tailor_app/core/widgets/state_views.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:tailor_app/features/customers/presentation/widgets/customer_picker_dialog.dart';
import 'package:tailor_app/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:tailor_app/features/orders/presentation/cubit/orders_state.dart';
import 'package:tailor_app/features/orders/presentation/widgets/order_card.dart';

/// Pick a customer, then open the new-order form.
Future<void> _startNewOrder(BuildContext context) async {
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

  context.push(AppRoutes.orderNewFor(customer.id));
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrdersCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _startNewOrder(context),
        icon: const Icon(Icons.add),
        label: const Text('New order'),
      ),
      body: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: cubit.setQuery,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search by customer or order number',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, value, _) => value.text.isEmpty
                          ? const SizedBox.shrink()
                          : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          cubit.setQuery('');
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const _FilterBar(),
          const Expanded(child: _Content()),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrdersCubit>();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: BlocBuilder<OrdersCubit, OrdersState>(
          buildWhen: (previous, current) => previous.filter != current.filter,
          builder: (context, state) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  for (final filter in OrderFilter.values) ...[
                    ChoiceChip(
                      label: Text(filter.label),
                      selected: state.filter == filter,
                      onSelected: (_) => cubit.setFilter(filter),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<OrdersCubit>().state;
    final customersState = context.watch<CustomersCubit>().state;

    switch (state.status) {
      case OrdersStatus.loading:
        return const LoadingView();
      case OrdersStatus.failure:
        return ErrorState(
          message: state.errorMessage ?? 'Could not load orders.',
          onRetry: context.read<OrdersCubit>().retry,
        );
      case OrdersStatus.loaded:
        break;
    }

    // Build the lookup once instead of searching per item.
    final names = {
      for (final customer in customersState.customers) customer.id: customer.name,
    };
    String nameOf(String id) => names[id] ?? 'Unknown customer';

    final orders = state.filtered(nameOf);

    if (orders.isEmpty) {
      if (state.query.trim().isNotEmpty) {
        return const EmptyState(
          icon: Icons.search_off,
          title: 'No matches',
          message: 'No orders match your search.',
        );
      }
      if (state.orders.isEmpty) {
        return EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No orders yet',
          message: 'Create your first order to start tracking work.',
          actionLabel: 'New order',
          onAction: () => _startNewOrder(context),
        );
      }
      return EmptyState(
        icon: Icons.filter_list_off,
        title: 'Nothing here',
        message: 'No ${state.filter.label.toLowerCase()} orders right now.',
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          itemCount: orders.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final order = orders[index];
            return OrderCard(
              order: order,
              customerName: nameOf(order.customerId),
              onTap: () => context.push(AppRoutes.orderDetails(order.id)),
            );
          },
        ),
      ),
    );
  }
}