import 'package:flutter/material.dart';
import 'package:tailor_app/core/theme/app_colors.dart';

class BottomBarItem {
  const BottomBarItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// The phone's bottom navigation. Every tab has an identical layout, so
/// icons and labels always line up, and every label stays on ONE line.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<BottomBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.slate200)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _BottomBarButton(
                      item: items[i],
                      selected: i == selectedIndex,
                      onTap: () => onSelected(i),
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

class _BottomBarButton extends StatelessWidget {
  const _BottomBarButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final BottomBarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.slate500;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: 56,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primarySoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                // FittedBox shrinks a long word instead of wrapping it.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}