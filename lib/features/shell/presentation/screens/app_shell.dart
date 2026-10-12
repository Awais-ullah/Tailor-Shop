import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/responsive/breakpoints.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/features/shell/presentation/widgets/app_bottom_bar.dart';
import 'package:tailor_app/features/sync/presentation/widgets/sync_banner.dart';

import '../../../../core/widgets/app_logo.dart';

/// One navigation entry. [branchIndex] must match the order of the
/// branches in lib/core/router/app_router.dart.
class _NavItem {
  const _NavItem(this.label, this.icon, this.selectedIcon, this.branchIndex);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int branchIndex;
}

// Branch order: 0 dashboard, 1 customers, 2 measurements, 3 orders,
// 4 ledger, 5 reports, 6 settings, 7 more
const List<_NavItem> _mobileItems = [
  _NavItem('Home', Icons.home_outlined, Icons.home_rounded, 0),
  _NavItem('Customers', Icons.people_outline, Icons.people_rounded, 1),
  _NavItem('Orders', Icons.receipt_long_outlined, Icons.receipt_long, 3),
  _NavItem('Ledger', Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet, 4),
  _NavItem('More', Icons.more_horiz, Icons.more_horiz, 7),
];

const List<_NavItem> _wideItems = [
  _NavItem('Dashboard', Icons.dashboard_outlined, Icons.dashboard_rounded, 0),
  _NavItem('Customers', Icons.people_outline, Icons.people_rounded, 1),
  _NavItem('Measurements', Icons.straighten_outlined, Icons.straighten, 2),
  _NavItem('Orders', Icons.receipt_long_outlined, Icons.receipt_long, 3),
  _NavItem('Ledger', Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet, 4),
  _NavItem('Reports', Icons.bar_chart_outlined, Icons.bar_chart_rounded, 5),
  _NavItem('Settings', Icons.settings_outlined, Icons.settings_rounded, 6),
];

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goTo(_NavItem item) {
    navigationShell.goBranch(
      item.branchIndex,
      // Tapping the active tab again returns to that tab's first screen.
      initialLocation: item.branchIndex == navigationShell.currentIndex,
    );
  }

  int _selectedIndex(List<_NavItem> items, int fallback) {
    final index = items
        .indexWhere((item) => item.branchIndex == navigationShell.currentIndex);
    return index == -1 ? fallback : index;
  }

  /// The page content with the sync status strip underneath it.
  Widget _content() {
    return Column(
      children: [
        Expanded(child: navigationShell),
        const SyncBanner(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        switch (Breakpoints.of(constraints.maxWidth)) {
          case ScreenSize.mobile:
            return _buildMobile();
          case ScreenSize.tablet:
            return _buildTablet();
          case ScreenSize.desktop:
            return _buildDesktop();
        }
      },
    );
  }

  Widget _buildMobile() {
    // Measurements / Reports / Settings live under "More" on mobile,
    // so when one of them is open we highlight "More".
    final selected = _selectedIndex(_mobileItems, _mobileItems.length - 1);

    return Scaffold(
      // Stops the bottom bar from riding up above the keyboard and eating
      // space on forms. Each page's own Scaffold handles the keyboard.
      resizeToAvoidBottomInset: false,
      body: _content(),
      bottomNavigationBar: AppBottomBar(
        selectedIndex: selected,
        onSelected: (i) => _goTo(_mobileItems[i]),
        items: [
          for (final item in _mobileItems)
            BottomBarItem(
              label: item.label,
              icon: item.icon,
              selectedIcon: item.selectedIcon,
            ),
        ],
      ),
    );
  }

  Widget _buildTablet() {
    final selected = _selectedIndex(_wideItems, 0);

    return Scaffold(
      body: Row(
        children: [
          // Standard Flutter pattern: makes the rail scroll instead of
          // overflowing when the window is not tall enough.
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: NavigationRail(
                      selectedIndex: selected,
                      onDestinationSelected: (i) => _goTo(_wideItems[i]),
                      labelType: NavigationRailLabelType.selected,
                      destinations: [
                        for (final item in _wideItems)
                          NavigationRailDestination(
                            icon: Icon(item.icon),
                            selectedIcon: Icon(item.selectedIcon),
                            label: Text(item.label),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const VerticalDivider(),
          Expanded(child: _content()),
        ],
      ),
    );
  }

  Widget _buildDesktop() {
    final selected = _selectedIndex(_wideItems, 0);

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            items: _wideItems,
            selectedIndex: selected,
            onSelected: (i) => _goTo(_wideItems[i]),
          ),
          Expanded(child: _content()),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppColors.slate200)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  const AppLogo(size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tailor Shop',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            // ListView (not Column) so the menu scrolls on short windows.
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: items.length,
                itemBuilder: (context, i) => _SidebarTile(
                  item: items[i],
                  selected: i == selectedIndex,
                  onTap: () => onSelected(i),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.slate700;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? AppColors.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Icon(selected ? item.selectedIcon : item.icon,
                    color: color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}