import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/theme/app_palette.dart';

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

/// The phone's bottom navigation: an edge-to-edge bar with rounded top
/// corners and a smooth notch for the centre "+" button
/// (the Scaffold's centre-docked floating action button).
///
/// The tabs are split evenly either side of the notch. The selected tab is
/// teal with a small gold pill above its icon. Every label stays on ONE
/// line (FittedBox shrinks instead of wrapping).
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

  /// Room left in the middle of the row for the "+" button.
  static const double _notchGap = 76;

  @override
  Widget build(BuildContext context) {
    final half = items.length ~/ 2;

    Widget tab(int i) => Expanded(
      child: _BottomBarButton(
        item: items[i],
        selected: i == selectedIndex,
        onTap: () => onSelected(i),
      ),
    );

    return BottomAppBar(
      shape: const SmoothNotchedShape(),
      notchMargin: 8,
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      elevation: 12,
      color: context.pal.surface,
      shadowColor: const Color(0x5907343E),
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (var i = 0; i < half; i++) tab(i),
          const SizedBox(width: _notchGap),
          for (var i = half; i < items.length; i++) tab(i),
        ],
      ),
    );
  }
}

/// A rectangle with rounded top corners and a round notch for the
/// floating button, with the notch's shoulders rounded off so the edge
/// flows into it instead of meeting it at a sharp corner.
class SmoothNotchedShape extends NotchedShape {
  const SmoothNotchedShape({this.cornerRadius = 24, this.shoulderRadius = 10});

  final double cornerRadius;
  final double shoulderRadius;

  @override
  Path getOuterPath(Rect host, Rect? guest) {
    final top = host.top;
    final path = Path()
      ..moveTo(host.left, host.bottom)
      ..lineTo(host.left, top + cornerRadius)
      ..arcToPoint(
        Offset(host.left + cornerRadius, top),
        radius: Radius.circular(cornerRadius),
      );

    if (guest != null && host.overlaps(guest)) {
      // guest is the button grown by the notch margin.
      final r = guest.width / 2;
      final f = shoulderRadius;
      final cx = guest.center.dx;
      final cy = guest.center.dy;

      // Each shoulder is a small circle sitting inside the bar, touching
      // the top edge and the notch circle: its centre is (cx ± dx, top + f)
      // and it lies r + f away from the notch centre.
      final dy = top + f - cy;
      final dx = math.sqrt(math.max(0, (r + f) * (r + f) - dy * dy));
      // Where each shoulder meets the notch circle.
      final t = r / (r + f);
      final leftTouch = Offset(cx - dx * t, cy + dy * t);
      final rightTouch = Offset(cx + dx * t, cy + dy * t);

      path
        ..lineTo(cx - dx, top)
        ..arcToPoint(leftTouch, radius: Radius.circular(f))
        ..arcToPoint(
          rightTouch,
          radius: Radius.circular(r),
          clockwise: false,
          largeArc: dy < 0,
        )
        ..arcToPoint(Offset(cx + dx, top), radius: Radius.circular(f));
    }

    return path
      ..lineTo(host.right - cornerRadius, top)
      ..arcToPoint(
        Offset(host.right, top + cornerRadius),
        radius: Radius.circular(cornerRadius),
      )
      ..lineTo(host.right, host.bottom)
      ..close();
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
    final color = selected ? context.pal.primary : context.pal.slate500;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 20,
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              AnimatedScale(
                scale: selected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 24,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
