import 'package:flutter/material.dart';
import 'package:tailor_app/core/theme/app_palette.dart';

/// A rounded summary card: tinted icon, big number, small label.
/// Pass [onTap] to make it a button. [color] tints the icon and the number.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? context.pal.primary;

    return Material(
      color: context.pal.surface,
      elevation: 2,
      shadowColor: const Color(0x2407343E),
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, size: 22, color: tint),
                ),
                const SizedBox(height: 12),
              ],
              // Scales down instead of overflowing when the number is large.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color ?? context.pal.slate900,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.pal.slate500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}