import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/router/app_routes.dart';
import 'package:tailor_app/core/theme/app_colors.dart';

/// Mobile-only menu for sections that don't fit in the bottom bar.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _MoreTile(
                  icon: Icons.straighten_outlined,
                  label: 'Measurements',
                  route: AppRoutes.measurements,
                ),
                Divider(),
                _MoreTile(
                  icon: Icons.bar_chart_outlined,
                  label: 'Reports',
                  route: AppRoutes.reports,
                ),
                Divider(),
                _MoreTile(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  route: AppRoutes.settings,
                ),
              ],
            ),
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
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 56,
      leading: Icon(icon, color: AppColors.slate700),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.slate500),
      onTap: () => context.go(route),
    );
  }
}