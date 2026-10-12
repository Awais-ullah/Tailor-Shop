import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/router/app_routes.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:tailor_app/features/payments/presentation/widgets/customer_ledger_view.dart';

class CustomerLedgerScreen extends StatelessWidget {
  const CustomerLedgerScreen({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context) {
    final customer =
    context.watch<CustomersCubit>().state.customerById(customerId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          customer?.name ?? 'Customer ledger',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: CustomerLedgerView(
        customerId: customerId,
        // Orders are managed on the Orders tab.
        onOpenOrder: (order) => context.go(AppRoutes.orderDetails(order.id)),
      ),
    );
  }
}