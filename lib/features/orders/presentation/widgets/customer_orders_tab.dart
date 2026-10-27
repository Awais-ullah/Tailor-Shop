import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/router/app_routes.dart';
import 'package:tailor_app/core/widgets/state_views.dart';
import 'package:tailor_app/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:tailor_app/features/orders/presentation/cubit/orders_state.dart';
import 'package:tailor_app/features/orders/presentation/widgets/order_card.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';

/// The "Orders" tab on a customer's profile.
class CustomerOrdersTab extends StatelessWidget {
  const CustomerOrdersTab({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, state) {
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

        final orders = state.forCustomer(customerId);
        if (orders.isEmpty) {
          return EmptyState(
            icon: Icons.receipt_long_outlined,
            title: S.current.noOrdersYet,
            message: S.current.customerOrdersAppear,
            actionLabel: S.current.newOrder,
            onAction: () =>
                context.push(AppRoutes.customerOrderNew(customerId)),
          );
        }

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FilledButton.icon(
                  onPressed: () =>
                      context.push(AppRoutes.customerOrderNew(customerId)),
                  icon: const Icon(Icons.add),
                  label: Text(S.current.newOrder),
                ),
                const SizedBox(height: 12),
                for (final order in orders) ...[
                  OrderCard(
                    order: order,
                    onTap: () => context.push(
                      AppRoutes.customerOrderDetails(customerId, order.id),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
