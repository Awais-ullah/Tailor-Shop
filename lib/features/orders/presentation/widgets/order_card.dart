import 'package:flutter/material.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/utils/app_dates.dart';
import 'package:tailor_app/core/utils/money.dart';
import 'package:tailor_app/features/orders/data/models/order.dart';
import 'package:tailor_app/features/orders/presentation/widgets/status_chips.dart';

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

  @override
  Widget build(BuildContext context) {
    final overdue = order.isOverdue;
    final title = customerName == null
        ? '#${order.orderNumber}'
        : '#${order.orderNumber} · $customerName';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OrderStatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                order.itemsSummary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.slate700),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_outlined,
                          size: 16,
                          color: overdue ? AppColors.danger : AppColors.slate500,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Due ${AppDates.short(order.deliveryDate)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color:
                              overdue ? AppColors.danger : AppColors.slate500,
                              fontWeight:
                              overdue ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (overdue) ...[
                          const SizedBox(width: 8),
                          const Text(
                            'Overdue',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Money.pkr(order.totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.w600),
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