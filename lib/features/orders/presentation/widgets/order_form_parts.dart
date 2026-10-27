import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/errors/app_failure.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/core/utils/app_dates.dart';
import 'package:tailor_app/core/utils/inch_format.dart';
import 'package:tailor_app/core/utils/money.dart';
import 'package:tailor_app/core/widgets/adaptive_wrap.dart';
import 'package:tailor_app/core/widgets/app_snackbar.dart';
import 'package:tailor_app/core/widgets/state_views.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:tailor_app/features/measurements/data/measurement_templates.dart';
import 'package:tailor_app/features/measurements/data/models/measurement.dart';
import 'package:tailor_app/features/measurements/presentation/cubit/measurements_cubit.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_glyphs.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_icon.dart';
import 'package:tailor_app/features/measurements/presentation/screens/measurement_form_screen.dart';
import 'package:tailor_app/features/measurements/presentation/widgets/garment_picker_sheet.dart';
import 'package:tailor_app/features/orders/data/models/order.dart';
import 'package:tailor_app/features/orders/data/models/order_item.dart';
import 'package:tailor_app/features/orders/data/models/order_measurement.dart';
import 'package:tailor_app/features/orders/data/order_money.dart';
import 'package:tailor_app/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:tailor_app/features/orders/presentation/widgets/measurement_attach_dialog.dart';
import 'package:tailor_app/features/orders/presentation/widgets/order_item_dialog.dart';
import 'package:tailor_app/features/payments/data/payment_method.dart';
import 'package:tailor_app/features/payments/presentation/payment_method_ui.dart';

// Sections of the order form screen.

/// Optional money received when the order is booked.
class OrderAdvanceSection extends StatelessWidget {
  const OrderAdvanceSection({
    required this.controller,
    required this.method,
    required this.total,
    required this.onMethodChanged,
    required this.onChanged,
  });

  final TextEditingController controller;
  final PaymentMethod method;
  final int total;
  final ValueChanged<PaymentMethod> onMethodChanged;
  final VoidCallback onChanged;

  String? _validate(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;

    final amount = int.tryParse(text);
    if (amount == null || amount <= 0) return S.current.enterAmountOver0;
    if (amount > total) {
      return S.current.cantExceedTotal(Money.pkr(total));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final amount = int.tryParse(controller.text.trim()) ?? 0;
    final isValid = amount > 0 && amount <= total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.current.advancePaymentOptional,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          S.current.moneyReceivedNow,
          style: TextStyle(color: context.pal.slate500, fontSize: 13),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          validator: _validate,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: S.current.advanceAmount,
            prefixText: Money.prefix,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final option in PaymentMethod.values)
              ChoiceChip(
                avatar: Icon(option.icon, size: 18),
                label: Text(option.label),
                selected: method == option,
                onSelected: (_) => onMethodChanged(option),
              ),
          ],
        ),
        if (isValid)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 12),
            child: Text(
              S.current.remainingAfterAdvance(Money.pkr(OrderMoney.remaining(total: total, paid: amount))),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: context.pal.slate700,
              ),
            ),
          ),
      ],
    );
  }
}

class OrderItemRow extends StatelessWidget {
  const OrderItemRow({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final OrderItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 0, 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${item.quantity} × ${Money.pkr(item.unitPrice)}',
                    style: TextStyle(color: context.pal.slate500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              Money.pkr(OrderMoney.lineTotal(item)),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            IconButton(
              tooltip: S.current.removeItem,
              icon: const Icon(Icons.close, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class AttachedMeasurementRow extends StatelessWidget {
  const AttachedMeasurementRow({required this.measurement, required this.onRemove});

  final OrderMeasurement measurement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final template = MeasurementTemplates.of(measurement.garmentType);
    final summary = template.fields
        .where((field) => measurement.values.containsKey(field.key))
        .take(4)
        .map((f) => '${f.label} ${InchFormat.format(measurement.values[f.key]!)}')
        .join(' · ');

    return Card(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 0, 8),
        child: Row(
          children: [
            TailorIcon(TailorGlyphs.garment(measurement.garmentType), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      measurement.garmentType.label,
                      if (measurement.label.isNotEmpty) measurement.label,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (summary.isNotEmpty)
                    Text(
                      summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.pal.slate500,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: S.current.removeMeasurements,
              icon: const Icon(Icons.close, size: 20),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
