import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lays children out in as many equal-width columns as fit
/// (2 on a phone, 3-4 on a tablet or desktop). Rows grow to fit their
/// content, so there are no fixed heights to overflow.
class AdaptiveWrap extends StatelessWidget {
  const AdaptiveWrap({
    super.key,
    required this.children,
    this.minItemWidth = 140,
    this.spacing = 12,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
        constraints.maxWidth.isFinite ? constraints.maxWidth : 600.0;
        final columns = math.max(
          1,
          ((maxWidth + spacing) / (minItemWidth + spacing)).floor(),
        );
        final itemWidth = (maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}