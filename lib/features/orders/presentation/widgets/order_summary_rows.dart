import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/errors/app_failure.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/core/utils/app_dates.dart';
import 'package:tailor_app/core/utils/inch_format.dart';
import 'package:tailor_app/core/utils/money.dart';
import 'package:tailor_app/core/widgets/app_snackbar.dart';
import 'package:tailor_app/core/widgets/state_views.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:tailor_app/features/measurements/data/measurement_templates.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_glyphs.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_icon.dart';
import 'package:tailor_app/features/orders/data/models/order.dart';
import 'package:tailor_app/features/orders/data/models/order_measurement.dart';
import 'package:tailor_app/features/orders/data/order_money.dart';
import 'package:tailor_app/features/orders/data/order_status.dart';
import 'package:tailor_app/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:tailor_app/features/orders/presentation/order_status_ui.dart';
import 'package:tailor_app/features/orders/presentation/widgets/measurement_snapshot_block.dart';
import 'package:tailor_app/features/orders/presentation/widgets/status_chips.dart';
import 'package:tailor_app/features/orders/presentation/widgets/status_steps.dart';
import 'package:tailor_app/features/payments/presentation/widgets/order_payments_section.dart';

// Date and money rows on the order detail screen.

class OrderDateInfo extends StatelessWidget {
  const OrderDateInfo({
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
          style: Theme.of(context)
              .textTheme
              .labelMedium
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
