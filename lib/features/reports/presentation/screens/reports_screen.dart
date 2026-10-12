import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/utils/money.dart';
import 'package:tailor_app/core/widgets/adaptive_wrap.dart';
import 'package:tailor_app/core/widgets/state_views.dart';
import 'package:tailor_app/core/widgets/stat_tile.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_state.dart';
import 'package:tailor_app/features/orders/data/order_status.dart';
import 'package:tailor_app/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:tailor_app/features/orders/presentation/cubit/orders_state.dart';
import 'package:tailor_app/features/payments/data/ledger_calculator.dart';
import 'package:tailor_app/features/payments/data/payment_method.dart';
import 'package:tailor_app/features/payments/presentation/cubit/payments_cubit.dart';
import 'package:tailor_app/features/payments/presentation/cubit/payments_state.dart';
import 'package:tailor_app/features/reports/data/report_summary.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportPeriod _period = ReportPeriod.thisMonth;

  @override
  Widget build(BuildContext context) {
    final customersState = context.watch<CustomersCubit>().state;
    final ordersState = context.watch<OrdersCubit>().state;
    final paymentsState = context.watch<PaymentsCubit>().state;

    final loading = customersState.status == CustomersStatus.loading ||
        ordersState.status == OrdersStatus.loading ||
        paymentsState.status == PaymentsStatus.loading;

    Widget content;
    if (loading) {
      content = const LoadingView();
    } else if (customersState.status == CustomersStatus.failure) {
      content = ErrorState(
        message: customersState.errorMessage ?? 'Could not load customers.',
        onRetry: context.read<CustomersCubit>().retry,
      );
    } else if (ordersState.status == OrdersStatus.failure) {
      content = ErrorState(
        message: ordersState.errorMessage ?? 'Could not load orders.',
        onRetry: context.read<OrdersCubit>().retry,
      );
    } else if (paymentsState.status == PaymentsStatus.failure) {
      content = ErrorState(
        message: paymentsState.errorMessage ?? 'Could not load payments.',
        onRetry: context.read<PaymentsCubit>().retry,
      );
    } else {
      content = _ReportContent(
        period: _period,
        customers: customersState,
        orders: ordersState,
        payments: paymentsState,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    for (final period in ReportPeriod.values) ...[
                      ChoiceChip(
                        label: Text(period.label),
                        selected: _period == period,
                        onSelected: (_) => setState(() => _period = period),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _ReportContent extends StatelessWidget {
  const _ReportContent({
    required this.period,
    required this.customers,
    required this.orders,
    required this.payments,
  });

  final ReportPeriod period;
  final CustomersState customers;
  final OrdersState orders;
  final PaymentsState payments;

  @override
  Widget build(BuildContext context) {
    final summary = ReportSummary.compute(
      orders: orders.orders,
      payments: payments.payments,
      period: period,
      now: DateTime.now(),
    );
    final outstandingNow = LedgerCalculator.totalOutstanding(orders.orders);

    final names = {
      for (final customer in customers.customers) customer.id: customer.name,
    };

    final statusMax = summary.ordersByStatus.values.fold(0, math.max);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            AdaptiveWrap(
              minItemWidth: 170,
              children: [
                StatTile(
                  label: 'Income',
                  value: Money.pkr(summary.income),
                  icon: Icons.payments_outlined,
                  color: AppColors.success,
                ),
                StatTile(
                  label: 'New orders',
                  value: '${summary.newOrders}',
                  icon: Icons.receipt_long_outlined,
                ),
                StatTile(
                  label: 'Order value booked',
                  value: Money.pkr(summary.bookedValue),
                  icon: Icons.sell_outlined,
                ),
                StatTile(
                  label: 'Outstanding now',
                  value: Money.pkr(outstandingNow),
                  icon: Icons.account_balance_wallet_outlined,
                  color: outstandingNow > 0 ? AppColors.danger : null,
                ),
              ],
            ),
            if (summary.buckets.length > 1) ...[
              const SizedBox(height: 16),
              _Section(
                title: period == ReportPeriod.thisYear
                    ? 'Income by month'
                    : 'Income by day',
                child: _IncomeChart(buckets: summary.buckets),
              ),
            ],
            const SizedBox(height: 16),
            AdaptiveWrap(
              minItemWidth: 380,
              children: [
                _Section(
                  title: 'Income by payment method',
                  child: summary.income == 0
                      ? const _EmptyLine('No payments in this period.')
                      : Column(
                    children: [
                      for (final method in PaymentMethod.values)
                        _BarRow(
                          label: method.label,
                          valueText: Money.pkr(
                            summary.incomeByMethod[method] ?? 0,
                          ),
                          fraction: (summary.incomeByMethod[method] ?? 0) /
                              summary.income,
                          color: AppColors.success,
                        ),
                    ],
                  ),
                ),
                _Section(
                  title: 'Orders by status',
                  child: statusMax == 0
                      ? const _EmptyLine('No orders in this period.')
                      : Column(
                    children: [
                      for (final status in OrderStatus.values)
                        _BarRow(
                          label: status.label,
                          valueText: '${summary.ordersByStatus[status] ?? 0}',
                          fraction:
                          (summary.ordersByStatus[status] ?? 0) / statusMax,
                          color: status.color,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Top customers',
              child: summary.topCustomers.isEmpty
                  ? const _EmptyLine('No orders in this period.')
                  : Column(
                children: [
                  for (final top in summary.topCustomers)
                    _TopCustomerRow(
                      name: names[top.customerId] ?? 'Unknown customer',
                      orderCount: top.orderCount,
                      billed: top.billed,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: const TextStyle(color: AppColors.slate500)),
    );
  }
}

/// A label, a value, and a proportional bar underneath.
class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.valueText,
    required this.fraction,
    required this.color,
  });

  final String label;
  final String valueText;
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                valueText,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 8,
              color: color,
              backgroundColor: AppColors.slate100,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCustomerRow extends StatelessWidget {
  const _TopCustomerRow({
    required this.name,
    required this.orderCount,
    required this.billed,
  });

  final String name;
  final int orderCount;
  final int billed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                  '$orderCount ${orderCount == 1 ? 'order' : 'orders'}',
                  style: const TextStyle(color: AppColors.slate500, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            Money.pkr(billed),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Simple bar chart: one bar per day (or month). Long-press or hover a bar
/// to see its exact amount.
class _IncomeChart extends StatelessWidget {
  const _IncomeChart({required this.buckets});

  final List<IncomeBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final peak = buckets.fold(0, (max, bucket) => math.max(max, bucket.amount));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          peak == 0 ? 'No income in this period yet.' : 'Highest: ${Money.pkr(peak)}',
          style: const TextStyle(color: AppColors.slate500, fontSize: 13),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final bucket in buckets)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Tooltip(
                      message: '${bucket.label}: ${Money.pkr(bucket.amount)}',
                      child: SizedBox(
                        height: 120,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            // A thin stub for zero days keeps the row readable.
                            heightFactor: peak == 0
                                ? 0.02
                                : math.max(0.02, bucket.amount / peak),
                            widthFactor: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: bucket.amount == 0
                                    ? AppColors.slate200
                                    : AppColors.primary,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              buckets.first.label,
              style: const TextStyle(color: AppColors.slate500, fontSize: 12),
            ),
            Text(
              buckets.last.label,
              style: const TextStyle(color: AppColors.slate500, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}