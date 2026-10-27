import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/core/utils/inch_format.dart';
import 'package:tailor_app/core/utils/money.dart';
import 'package:tailor_app/core/widgets/adaptive_wrap.dart';
import 'package:tailor_app/features/customers/data/models/customer.dart';
import 'package:tailor_app/features/measurements/data/measurement_templates.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_glyphs.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_icon.dart';
import 'package:tailor_app/features/orders/data/models/order_item.dart';
import 'package:tailor_app/features/orders/data/models/order_measurement.dart';
import 'package:tailor_app/features/orders/data/order_money.dart';
import 'package:tailor_app/features/payments/data/payment_method.dart';
import 'package:tailor_app/features/payments/presentation/payment_method_ui.dart';

// Sections of the order form screen.

/// Optional money received when the order is booked.
class OrderAdvanceSection extends StatelessWidget {
  const OrderAdvanceSection({
    super.key,
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
          style: Theme.of(context).textTheme.titleSmall
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
              S.current.remainingAfterAdvance(
                Money.pkr(OrderMoney.remaining(total: total, paid: amount)),
              ),
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
    super.key,
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
  const AttachedMeasurementRow({
    super.key,
    required this.measurement,
    required this.onRemove,
  });

  final OrderMeasurement measurement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final template = MeasurementTemplates.of(measurement.garmentType);
    final summary = template.fields
        .where((field) => measurement.values.containsKey(field.key))
        .take(4)
        .map(
          (f) => '${f.label} ${InchFormat.format(measurement.values[f.key]!)}',
        )
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

/// Who the order is for: initial, name and phone.
class OrderCustomerCard extends StatelessWidget {
  const OrderCustomerCard({super.key, required this.customer});

  /// Null when the customer is no longer on the device.
  final Customer? customer;

  @override
  Widget build(BuildContext context) {
    final customer = this.customer;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: context.pal.primarySoft,
              child: Text(
                customer?.initial ?? '?',
                style: TextStyle(
                  color: context.pal.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer?.name ?? S.current.unknownCustomer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (customer != null && customer.phone.isNotEmpty)
                    Text(
                      customer.phone,
                      style: TextStyle(color: context.pal.slate500),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Order and delivery date fields. Both open a date picker on tap.
class OrderDateFields extends StatelessWidget {
  const OrderDateFields({
    super.key,
    required this.orderDateController,
    required this.deliveryDateController,
    required this.onPickOrderDate,
    required this.onPickDeliveryDate,
    required this.validateDelivery,
  });

  final TextEditingController orderDateController;
  final TextEditingController deliveryDateController;
  final VoidCallback onPickOrderDate;
  final VoidCallback onPickDeliveryDate;

  /// Returns an error message, or null when the delivery date is fine.
  final String? Function() validateDelivery;

  @override
  Widget build(BuildContext context) {
    return AdaptiveWrap(
      minItemWidth: 220,
      children: [
        TextFormField(
          controller: orderDateController,
          readOnly: true,
          onTap: onPickOrderDate,
          decoration: InputDecoration(
            labelText: S.current.orderDate,
            prefixIcon: const Icon(Icons.event_outlined),
          ),
        ),
        TextFormField(
          controller: deliveryDateController,
          readOnly: true,
          onTap: onPickDeliveryDate,
          validator: (_) => validateDelivery(),
          decoration: InputDecoration(
            labelText: S.current.deliveryDate,
            prefixIcon: const Icon(Icons.local_shipping_outlined),
          ),
        ),
      ],
    );
  }
}

/// A bold section title with an action button on the right
/// ("Items · Add item", "Measurements · Attach").
class OrderSectionHeader extends StatelessWidget {
  const OrderSectionHeader({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onAction,
          icon: Icon(actionIcon),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}

/// The order's items with the running total underneath.
class OrderItemsCard extends StatelessWidget {
  const OrderItemsCard({
    super.key,
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

  final List<OrderItem> items;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  S.current.noItemsYet,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.pal.slate500),
                ),
              )
            else
              for (var i = 0; i < items.length; i++)
                OrderItemRow(
                  item: items[i],
                  onTap: () => onEdit(i),
                  onDelete: () => onDelete(i),
                ),
            const Divider(),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      S.current.total,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    Money.pkr(OrderMoney.total(items)),
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The measurement copies attached to the order, or a note that there
/// are none yet.
class AttachedMeasurementsList extends StatelessWidget {
  const AttachedMeasurementsList({
    super.key,
    required this.attached,
    required this.onRemove,
  });

  final List<OrderMeasurement> attached;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    if (attached.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            S.current.noMeasurementsAttached,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.pal.slate500),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < attached.length; i++)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 8),
            child: AttachedMeasurementRow(
              measurement: attached[i],
              onRemove: () => onRemove(i),
            ),
          ),
      ],
    );
  }
}

/// Cancel and save, side by side. Both are disabled while saving.
class OrderFormActions extends StatelessWidget {
  const OrderFormActions({
    super.key,
    required this.saving,
    required this.saveLabel,
    required this.onCancel,
    required this.onSave,
  });

  final bool saving;
  final String saveLabel;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: saving ? null : onCancel,
            child: Text(S.current.cancel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: saving ? null : onSave,
            child: saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(saveLabel),
          ),
        ),
      ],
    );
  }
}
