import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/router/app_routes.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/core/widgets/app_snackbar.dart';
import 'package:tailor_app/core/widgets/state_views.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:tailor_app/features/customers/presentation/widgets/customer_picker_dialog.dart';
import 'package:tailor_app/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:tailor_app/features/orders/presentation/cubit/orders_state.dart';
import 'package:tailor_app/features/orders/presentation/widgets/order_card.dart';

import 'package:tailor_app/core/l10n/app_strings.dart';

import '../../../../core/widgets/fade_slide_in.dart';

/// Pick a customer, then open the new-order form.
Future<void> _startNewOrder(BuildContext context) async {
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
      appBar: AppBar(title: Text(S.current.orders)),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: context.pal.brand,
        foregroundColor: AppColors.gold,
        onPressed: () => _startNewOrder(context),
        icon: const Icon(Icons.add),
        label: Text(S.current.newOrder),
      ),
      body: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: cubit.setQuery,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: S.current.searchCustomerOrOrder,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, value, _) => value.text.isEmpty
                          ? const SizedBox.shrink()
                          : IconButton(
                              tooltip: S.current.clearSearch,
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
          message: state.errorMessage ?? S.current.couldNotLoadOrders,
          onRetry: context.read<OrdersCubit>().retry,
        );
      case OrdersStatus.loaded:
        break;
    }

    // Build the lookup once instead of searching per item.
    final names = {
      for (final customer in customersState.customers)
        customer.id: customer.name,
    };
    String nameOf(String id) => names[id] ?? S.current.unknownCustomer;

    final orders = state.filtered(nameOf);

    if (orders.isEmpty) {
      if (state.query.trim().isNotEmpty) {
        return EmptyState(
          icon: Icons.search_off,
          title: S.current.noMatches,
          message: S.current.noOrdersMatchSearch,
        );
      }
      if (state.orders.isEmpty) {
        return EmptyState(
          icon: Icons.receipt_long_outlined,
          title: S.current.noOrdersYet,
          message: S.current.createFirstOrder,
          actionLabel: S.current.newOrder,
          onAction: () => _startNewOrder(context),
        );
      }
      return EmptyState(
        icon: Icons.filter_list_off,
        title: S.current.nothingHere,
        message: S.current.noFilterOrders(state.filter.label.toLowerCase()),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView.separated(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 96),
          itemCount: orders.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final order = orders[index];
            return FadeSlideIn(
              delay: Duration(milliseconds: 35 * (index < 8 ? index : 8)),
              child: OrderCard(
                order: order,
                customerName: nameOf(order.customerId),
                onTap: () => context.push(AppRoutes.orderDetails(order.id)),
              ),
            );
          },
        ),
      ),
    );
  }
}
