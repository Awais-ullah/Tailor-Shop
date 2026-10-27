import 'package:flutter/material.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/core/utils/app_dates.dart';
import 'package:tailor_app/core/utils/money.dart';
import 'package:tailor_app/features/orders/data/models/order.dart';
import 'package:tailor_app/features/orders/data/order_status.dart';
import 'package:tailor_app/features/orders/presentation/widgets/status_chips.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';

/// One order in a list. Pass [customerName] on the global list; leave it
/// null on a customer's own tab.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.customerName,
  });

  final Order order;
  final VoidCallback onTap;
  final String? customerName;

  /// How many of the 4 progress segments are filled.
  static int _stage(OrderStatus status) {
    switch (status) {
      case OrderStatus.booked:
        return 1;
      case OrderStatus.cutting:
        return 2;
      case OrderStatus.stitching:
        return 3;
      case OrderStatus.ready:
      case OrderStatus.delivered:
        return 4;
      case OrderStatus.cancelled:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final overdue = order.isOverdue;
    final stage = _stage(order.status);
    final dueColor = overdue ? context.pal.danger : context.pal.slate500;
    final name = customerName;
    final itemCount = order.items.length;

    final title = name ?? '#${order.orderNumber}';
    final subtitle = name != null
        ? S.current.orderNumber(order.orderNumber)
        : S.current.itemCountLabel(itemCount);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: context.pal.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: name == null || name.isEmpty
                        ? Icon(
                            Icons.receipt_long_outlined,
                            size: 22,
                            color: context.pal.primary,
                          )
                        : Text(
                            String.fromCharCode(name.runes.first).toUpperCase(),
                            style: TextStyle(
                              color: context.pal.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.pal.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OrderStatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                order.itemsSummary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: context.pal.slate700),
              ),
              if (stage > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (var i = 0; i < 4; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: i < stage
                                ? AppColors.gold
                                : context.pal.slate200,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.event_outlined, size: 16, color: dueColor),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            overdue
                                ? S.current.dueDateOverdue(
                                    AppDates.short(order.deliveryDate),
                                  )
                                : S.current.dueDate(
                                    AppDates.short(order.deliveryDate),
                                  ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: dueColor,
                              fontWeight: overdue
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (order.remainingAmount > 0)
                    Text.rich(
                      TextSpan(
                        text: S.current.balanceLabel,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.pal.slate500,
                        ),
                        children: [
                          TextSpan(
                            text: Money.pkr(order.remainingAmount),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: context.pal.slate900,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      S.current.paidInFull,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.pal.success,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
