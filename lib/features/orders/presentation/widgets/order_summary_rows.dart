import 'package:flutter/material.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/core/utils/money.dart';

// Date and money rows on the order detail screen.

class OrderDateInfo extends StatelessWidget {
  const OrderDateInfo({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
    this.suffix,
  });

  final String label;
  final String value;
  final bool highlight;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? context.pal.danger : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: context.pal.slate500),
        ),
        Text(
          suffix == null ? value : '$value · $suffix',
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

class OrderMoneyRow extends StatelessWidget {
  const OrderMoneyRow({
    super.key,
    required this.label,
    required this.amount,
    this.bold = false,
    this.color,
  });

  final String label;
  final int amount;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      fontSize: bold ? 16 : null,
      color: color,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(Money.pkr(amount), style: style),
        ],
      ),
    );
  }
}
