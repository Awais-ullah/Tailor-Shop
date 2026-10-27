import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';
import 'package:tailor_app/core/router/app_routes.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/core/utils/app_dates.dart';
import 'package:tailor_app/core/utils/money.dart';
import 'package:tailor_app/features/orders/data/models/order.dart';
import 'package:tailor_app/features/orders/presentation/widgets/status_chips.dart';
import 'package:tailor_app/features/payments/data/ledger_calculator.dart';

// Building blocks of the dashboard screen.

/// Teal gradient header with a floating "Collected / Outstanding" card.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.topInset,
    required this.greeting,
    required this.date,
    required this.collected,
    required this.outstanding,
  });

  final double topInset;
  final String greeting;
  final String date;
  final int collected;
  final int outstanding;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsetsDirectional.fromSTEB(20, topInset + 16, 20, 64),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryLight,
                AppColors.primary,
                AppColors.primaryDark,
              ],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.content_cut,
                          size: 22,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        S.current.appName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    greeting,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: -48,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Material(
                color: context.pal.surface,
                elevation: 6,
                shadowColor: const Color(0x3307343E),
                surfaceTintColor: Colors.transparent,
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.current.collectedToday,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: context.pal.slate500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                Money.pkr(collected),
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: context.pal.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 44,
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                        color: context.pal.slate200,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              S.current.outstanding,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: context.pal.slate500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerEnd,
                              child: Text(
                                Money.pkr(outstanding),
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: outstanding > 0
                                      ? context.pal.danger
                                      : context.pal.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Square rounded icon button with a one-line label underneath.
class DashboardQuickAction extends StatelessWidget {
  const DashboardQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: highlighted ? context.pal.brand : context.pal.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: highlighted
                ? BorderSide.none
                : BorderSide(color: context.pal.slate200),
          ),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(
                icon,
                size: 24,
                color: highlighted ? AppColors.gold : context.pal.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.pal.slate900,
            ),
          ),
        ),
      ],
    );
  }
}

class DashboardSectionCard extends StatelessWidget {
  const DashboardSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    );
  }
}

class DashboardEmptyLine extends StatelessWidget {
  const DashboardEmptyLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: TextStyle(color: context.pal.slate500)),
    );
  }
}

class DashboardOrderRow extends StatelessWidget {
  const DashboardOrderRow({
    super.key,
    required this.order,
    required this.customerName,
  });

  final Order order;
  final String customerName;

  @override
  Widget build(BuildContext context) {
    final overdue = order.isOverdue;

    return InkWell(
      onTap: () => context.go(AppRoutes.orderDetails(order.id)),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: context.pal.primarySoft,
              child: Text(
                customerName.isEmpty
                    ? '?'
                    : String.fromCharCode(customerName.runes.first)
                          .toUpperCase(),
                style: TextStyle(
                  color: context.pal.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${order.orderNumber} · $customerName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    overdue
                        ? S.current.dueDateOverdue(
                            AppDates.short(order.deliveryDate),
                          )
                        : S.current.dueDate(AppDates.short(order.deliveryDate)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: overdue
                          ? context.pal.danger
                          : context.pal.slate500,
                      fontWeight: overdue ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OrderStatusChip(status: order.status),
          ],
        ),
      ),
    );
  }
}

class DashboardBalanceRow extends StatelessWidget {
  const DashboardBalanceRow({
    super.key,
    required this.balance,
    required this.name,
  });

  final CustomerBalance balance;
  final String name;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(AppRoutes.ledgerCustomer(balance.customerId)),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: context.pal.primarySoft,
              child: Text(
                name.isEmpty
                    ? '?'
                    : String.fromCharCode(name.runes.first).toUpperCase(),
                style: TextStyle(
                  color: context.pal.primary,
                  fontWeight: FontWeight.w700,
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
                    S.current.openOrdersCount(balance.openOrders),
                    style: TextStyle(color: context.pal.slate500, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              Money.pkr(balance.outstanding),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: context.pal.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
