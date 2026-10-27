import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/errors/app_failure.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/core/utils/app_dates.dart';
import 'package:tailor_app/core/utils/inch_format.dart';
import 'package:tailor_app/core/utils/money.dart';
import 'package:tailor_app/core/widgets/app_snackbar.dart';
import 'package:tailor_app/core/widgets/state_views.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:tailor_app/features/measurements/data/measurement_templates.dart';
import 'package:tailor_app/features/orders/data/models/order.dart';
import 'package:tailor_app/features/orders/data/models/order_measurement.dart';
import 'package:tailor_app/features/orders/data/order_money.dart';
import 'package:tailor_app/features/orders/data/order_status.dart';
import 'package:tailor_app/features/orders/presentation/order_status_ui.dart';
import 'package:tailor_app/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:tailor_app/features/orders/presentation/widgets/status_chips.dart';

import '../../../payments/presentation/widgets/order_payments_section.dart';

import 'package:tailor_app/core/l10n/app_strings.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_glyphs.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_icon.dart';
import 'package:tailor_app/features/orders/presentation/widgets/order_summary_rows.dart';
import 'package:tailor_app/features/orders/presentation/widgets/status_steps.dart';
import 'package:tailor_app/features/orders/presentation/widgets/measurement_snapshot_block.dart';

/// [editLocation] is supplied by the router, because the edit route
/// depends on where this screen was opened from.
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.editLocation,
  });

  final String orderId;
  final String editLocation;

  Future<void> _applyStatus(
      BuildContext context,
      OrdersCubit cubit,
      Order order,
      OrderStatus status,
      ) async {
    try {
      // Handing over work that has not been paid for deserves a pause.
      if (status == OrderStatus.delivered && order.remainingAmount > 0) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(S.current.balanceStillDue),
            content: Text(
              S.current.customerStillOwes(Money.pkr(order.remainingAmount)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(S.current.notYet),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(S.current.deliverAnyway),
              ),
            ],
          ),
        );
        if (proceed != true || !context.mounted) return;
      }
      await cubit.updateStatus(order.id, status);
      if (context.mounted) {
        AppSnackbar.showSuccess(context, S.current.markedAs(status.label.toLowerCase()));
      }
    } on AppFailure catch (failure) {
      if (context.mounted) AppSnackbar.showError(context, failure.message);
    }
  }

  Future<void> _changeStatus(BuildContext context, Order order) async {
    final cubit = context.read<OrdersCubit>();

    final chosen = await showModalBottomSheet<OrderStatus>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 8),
                child: Text(
                  S.current.changeStatus,
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              for (final status in OrderStatus.values)
                ListTile(
                  minTileHeight: 56,
                  leading: Icon(status.icon, color: context.pal.adapt(status.color)),
                  title: Text(status.label),
                  trailing: status == order.status
                      ? Icon(Icons.check, color: context.pal.primary)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, status),
                ),
            ],
          ),
        ),
      ),
    );
    if (chosen == null || chosen == order.status || !context.mounted) return;

    if (chosen == OrderStatus.cancelled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(S.current.cancelOrderQ),
          content: Text(
            S.current.cancelOrderBody,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(S.current.keepOrder),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(S.current.cancelOrder),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    await _applyStatus(context, cubit, order, chosen);
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<OrdersCubit>().state.byId(orderId);

    if (order == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: S.current.orderNotFound,
          message: S.current.orderMayBeRemoved,
          actionLabel: S.current.goBack,
          onAction: () => context.pop(),
        ),
      );
    }

    final customer =
    context.watch<CustomersCubit>().state.customerById(order.customerId);
    final textTheme = Theme.of(context).textTheme;
    final nextStatus = order.status.next;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.current.orderNumber(order.orderNumber)),
        actions: [
          IconButton(
            tooltip: S.current.editOrder,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(editLocation),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              customer?.name ?? S.current.unknownCustomer,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OrderStatusChip(status: order.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 24,
                        runSpacing: 8,
                        children: [
                          OrderDateInfo(
                            label: S.current.ordered,
                            value: AppDates.medium(order.orderDate),
                          ),
                          OrderDateInfo(
                            label: S.current.due,
                            value: AppDates.medium(order.deliveryDate),
                            highlight: order.isOverdue,
                            suffix: order.isOverdue ? S.current.overdue : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Status workflow
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        S.current.progress,
                        style: textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      if (order.status == OrderStatus.cancelled)
                        Text(
                          S.current.orderWasCancelled,
                          style: TextStyle(
                            color: context.pal.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        OrderStatusSteps(current: order.status),
                      const SizedBox(height: 16),
                      if (nextStatus != null)
                        FilledButton.icon(
                          onPressed: () => _applyStatus(
                            context,
                            context.read<OrdersCubit>(),
                            order,
                            nextStatus,
                          ),
                          icon: Icon(nextStatus.icon),
                          label: Text(S.current.markAsNext(nextStatus.label.toLowerCase())),
                        ),
                      if (nextStatus != null) const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => _changeStatus(context, order),
                        child: Text(S.current.changeStatus),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Items
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.current.items,
                        style: textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      for (final item in order.items)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${item.quantity} × ${Money.pkr(item.unitPrice)}',
                                      style: TextStyle(
                                        color: context.pal.slate500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                Money.pkr(OrderMoney.lineTotal(item)),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Money
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              S.current.payment,
                              style: textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          PaymentStatusChip(status: order.paymentStatus),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OrderMoneyRow(label: S.current.orderTotal, amount: order.totalAmount),
                      OrderMoneyRow(label: S.current.paid, amount: order.totalPaid),
                      const Divider(height: 24),
                      OrderMoneyRow(
                        label: S.current.remaining,
                        amount: order.remainingAmount,
                        bold: true,
                        color: order.remainingAmount > 0
                            ? context.pal.danger
                            : context.pal.success,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              OrderPaymentsSection(order: order),

              if (order.measurements.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.current.measurementsInches,
                          style: textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        for (final measurement in order.measurements)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(bottom: 12),
                            child: MeasurementSnapshotBlock(measurement: measurement),
                          ),
                      ],
                    ),
                  ),
                ),
              ],

              if (order.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.current.notes,
                          style: textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(order.notes),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
