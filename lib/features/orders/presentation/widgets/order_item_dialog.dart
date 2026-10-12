import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/utils/money.dart';
import 'package:tailor_app/core/utils/validators.dart';
import 'package:tailor_app/features/orders/data/models/order_item.dart';
import 'package:tailor_app/features/orders/data/order_money.dart';

const List<String> _suggestions = [
  'Shalwar Kameez',
  'Kurta',
  'Shalwar',
  'Waistcoat',
  'Shirt',
  'Pant',
  'Coat',
  'Sherwani',
];

/// Add a new item, or edit one when [initial] is given.
Future<OrderItem?> showOrderItemDialog(
    BuildContext context, {
      OrderItem? initial,
    }) {
  return showDialog<OrderItem>(
    context: context,
    builder: (_) => _OrderItemDialog(initial: initial),
  );
}

class _OrderItemDialog extends StatefulWidget {
  const _OrderItemDialog({this.initial});

  final OrderItem? initial;

  @override
  State<_OrderItemDialog> createState() => _OrderItemDialogState();
}

class _OrderItemDialogState extends State<_OrderItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late int _quantity;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _priceController = TextEditingController(
      text: initial == null ? '' : initial.unitPrice.toString(),
    );
    _quantity = initial?.quantity ?? 1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String? _validatePrice(String? value) {
    final price = int.tryParse(value?.trim() ?? '');
    if (price == null) return 'Enter the price';
    if (price <= 0) return 'Price must be greater than 0';
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.pop(
      context,
      OrderItem(
        name: _nameController.text.trim(),
        quantity: _quantity,
        unitPrice: int.parse(_priceController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final price = int.tryParse(_priceController.text.trim()) ?? 0;
    final lineTotal =
    OrderMoney.lineTotal(OrderItem(name: '', quantity: _quantity, unitPrice: price));

    return AlertDialog(
      title: Text(widget.initial == null ? 'Add item' : 'Edit item'),
      scrollable: true,
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [LengthLimitingTextInputFormatter(60)],
                validator: (value) =>
                    Validators.requiredField(value, fieldName: 'Item name'),
                decoration: const InputDecoration(
                  labelText: 'Item',
                  hintText: 'e.g. Shalwar Kameez',
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final suggestion in _suggestions)
                    ActionChip(
                      label: Text(suggestion),
                      onPressed: () =>
                          setState(() => _nameController.text = suggestion),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Quantity',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton.outlined(
                    tooltip: 'Decrease quantity',
                    onPressed:
                    _quantity > 1 ? () => setState(() => _quantity--) : null,
                    icon: const Icon(Icons.remove),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '$_quantity',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton.outlined(
                    tooltip: 'Increase quantity',
                    onPressed:
                    _quantity < 99 ? () => setState(() => _quantity++) : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                validator: _validatePrice,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Price per item',
                  prefixText: 'Rs. ',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Line total: ${Money.pkr(lineTotal)}',
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate700,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.initial == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}