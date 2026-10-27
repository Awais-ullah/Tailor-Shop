import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/router/app_routes.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';

/// Mobile-only menu for sections that don't fit in the bottom bar.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.current.more)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MoreTile(
            icon: Icons.account_balance_wallet_outlined,
            label: S.current.ledger,
            subtitle: S.current.paymentsAndBalances,
            route: AppRoutes.ledger,
          ),
          SizedBox(height: 12),
          _MoreTile(
            icon: Icons.straighten_outlined,
            label: S.current.measurements,
            subtitle: S.current.savedSizesForEvery,
            route: AppRoutes.measurements,
          ),
          SizedBox(height: 12),
          _MoreTile(
            icon: Icons.bar_chart_outlined,
            label: S.current.reports,
            subtitle: S.current.ordersPaymentsSummary,
            route: AppRoutes.reports,
          ),
          SizedBox(height: 12),
          _MoreTile(
            icon: Icons.settings_outlined,
            label: S.current.settings,
            subtitle: S.current.yourShopAccount,
            route: AppRoutes.settings,
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.pal.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 22, color: context.pal.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
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
              Icon(Icons.chevron_right, color: context.pal.slate500),
            ],
          ),
        ),
      ),
    );
  }
}