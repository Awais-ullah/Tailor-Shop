import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/errors/app_failure.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/utils/app_dates.dart';
import 'package:tailor_app/core/utils/inch_format.dart';
import 'package:tailor_app/core/utils/money.dart';
import 'package:tailor_app/core/widgets/adaptive_wrap.dart';
import 'package:tailor_app/core/widgets/app_snackbar.dart';
import 'package:tailor_app/core/widgets/state_views.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:tailor_app/features/measurements/data/measurement_templates.dart';
import 'package:tailor_app/features/measurements/presentation/cubit/measurements_cubit.dart';
import 'package:tailor_app/features/orders/data/models/order.dart';
import 'package:tailor_app/features/orders/data/models/order_item.dart';
import 'package:tailor_app/features/orders/data/models/order_measurement.dart';
import 'package:tailor_app/features/orders/data/order_money.dart';
import 'package:tailor_app/features/orders/presentation/cubit/orders_cubit.dart';
import 'package:tailor_app/features/orders/presentation/widgets/measurement_attach_dialog.dart';
import 'package:tailor_app/features/orders/presentation/widgets/order_item_dialog.dart';
import 'package:tailor_app/features/payments/data/payment_method.dart';

/// New order: pass [customerId]. Editing: pass [orderId] only.
class OrderFormScreen extends StatefulWidget {
  const OrderFormScreen({super.key, this.orderId, this.customerId});

  final String? orderId;
  final String? customerId;

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _orderDateController = TextEditingController();
  final _deliveryDateController = TextEditingController();
  final _advanceController = TextEditingController();

  Order? _existing;
  String? _customerId;
  List<OrderItem> _items = [];
  List<OrderMeasurement> _attached = [];
  late DateTime _orderDate;
  late DateTime _deliveryDate;
  PaymentMethod _advanceMethod = PaymentMethod.cash;
  bool _saving = false;

  bool get _isEditing => widget.orderId != null;

  @override
  void initState() {
    super.initState();

    final today = AppDates.today();
    _orderDate = today;
    _deliveryDate = AppDates.addDays(today, 7);

    final orderId = widget.orderId;
    if (orderId != null) {
      final existing = context.read<OrdersCubit>().state.byId(orderId);
      _existing = existing;
      if (existing != null) {
        _customerId = existing.customerId;
        _items = List.of(existing.items);
        _attached = List.of(existing.measurements);
        _orderDate = existing.orderDate;
        _deliveryDate = existing.deliveryDate;
        _notesController.text = existing.notes;
      }
    } else {
      _customerId = widget.customerId;
    }
    _syncDateFields();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _orderDateController.dispose();
    _deliveryDateController.dispose();
    _advanceController.dispose();
    super.dispose();
  }

  void _syncDateFields() {
    _orderDateController.text = AppDates.long(_orderDate);
    _deliveryDateController.text = AppDates.long(_deliveryDate);
  }

  Future<void> _pickOrderDate() async {
    final today = AppDates.today();
    final earliest = AppDates.addDays(today, -365);
    final latest = AppDates.addDays(today, 365);

    // initialDate must lie inside [firstDate, lastDate], even when editing
    // an old order, so the range is widened to include the current value.
    final picked = await showDatePicker(
      context: context,
      initialDate: _orderDate,
      firstDate: _orderDate.isBefore(earliest) ? _orderDate : earliest,
      lastDate: _orderDate.isAfter(latest) ? _orderDate : latest,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _orderDate = AppDates.dateOnly(picked);
      if (_deliveryDate.isBefore(_orderDate)) _deliveryDate = _orderDate;
      _syncDateFields();
    });
  }

  Future<void> _pickDeliveryDate() async {
    final latest = AppDates.addDays(_orderDate, 365);

    final picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate,
      firstDate: _orderDate,
      lastDate: _deliveryDate.isAfter(latest) ? _deliveryDate : latest,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _deliveryDate = AppDates.dateOnly(picked);
      _syncDateFields();
    });
  }

  Future<void> _addItem() async {
    final item = await showOrderItemDialog(context);
    if (item != null && mounted) setState(() => _items.add(item));
  }

  Future<void> _editItem(int index) async {
    final item = await showOrderItemDialog(context, initial: _items[index]);
    if (item != null && mounted) setState(() => _items[index] = item);
  }

  Future<void> _attachMeasurements() async {
    final alreadyAttached = _attached.map((m) => m.sourceId).toSet();
    final available = context
        .read<MeasurementsCubit>()
        .state
        .forCustomer(_customerId!)
        .where((m) => !alreadyAttached.contains(m.id))
        .toList();

    final chosen = await showMeasurementAttachDialog(context, available);
    if (chosen == null || chosen.isEmpty || !mounted) return;

    setState(() {
      _attached.addAll(chosen.map(OrderMeasurement.fromMeasurement));
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (_items.isEmpty) {
      AppSnackbar.showError(context, 'Add at least one item.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = context.read<OrdersCubit>();

    setState(() => _saving = true);
    try {
      await cubit.saveOrder(
        id: widget.orderId,
        customerId: _customerId!,
        items: _items,
        measurements: _attached,
        orderDate: _orderDate,
        deliveryDate: _deliveryDate,
        notes: _notesController.text,
        advanceAmount: int.tryParse(_advanceController.text.trim()) ?? 0,
        advanceMethod: _advanceMethod,
      );
      if (!mounted) return;
      AppSnackbar.showSuccess(
        context,
        _isEditing ? 'Order updated' : 'Order created',
      );
      context.pop();
    } on AppFailure catch (failure) {
      if (mounted) AppSnackbar.showError(context, failure.message);
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(context, 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerId = _customerId;

    if (customerId == null || (_isEditing && _existing == null)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'Order not found',
          message: 'Something is missing. Please go back and try again.',
          actionLabel: 'Go back',
          onAction: () => context.pop(),
        ),
      );
    }

    final customer = context.read<CustomersCubit>().state.customerById(customerId);
    final total = OrderMoney.total(_items);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit order #${_existing!.orderNumber}' : 'New order',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primarySoft,
                            child: Text(
                              customer?.initial ?? '?',
                              style: const TextStyle(
                                color: AppColors.primary,
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
                                  customer?.name ?? 'Unknown customer',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (customer != null && customer.phone.isNotEmpty)
                                  Text(
                                    customer.phone,
                                    style: const TextStyle(
                                      color: AppColors.slate500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AdaptiveWrap(
                    minItemWidth: 220,
                    children: [
                      TextFormField(
                        controller: _orderDateController,
                        readOnly: true,
                        onTap: _pickOrderDate,
                        decoration: const InputDecoration(
                          labelText: 'Order date',
                          prefixIcon: Icon(Icons.event_outlined),
                        ),
                      ),
                      TextFormField(
                        controller: _deliveryDateController,
                        readOnly: true,
                        onTap: _pickDeliveryDate,
                        validator: (_) {
                          if (_deliveryDate.isBefore(_orderDate)) {
                            return 'Cannot be before the order date';
                          }
                          if (_deliveryDate
                              .isAfter(AppDates.addDays(_orderDate, 365))) {
                            return 'Delivery date is too far away';
                          }
                          return null;
                        },
                        decoration: const InputDecoration(
                          labelText: 'Delivery date',
                          prefixIcon: Icon(Icons.local_shipping_outlined),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Items',
                          style: textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Add item'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          if (_items.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No items yet. Add what the customer ordered.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.slate500),
                              ),
                            )
                          else
                            for (var i = 0; i < _items.length; i++)
                              _ItemRow(
                                item: _items[i],
                                onTap: () => _editItem(i),
                                onDelete: () => setState(() => _items.removeAt(i)),
                              ),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Total',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Text(
                                  Money.pkr(total),
                                  style: textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!_isEditing) ...[
                    const SizedBox(height: 24),
                    _AdvanceSection(
                      controller: _advanceController,
                      method: _advanceMethod,
                      total: total,
                      onMethodChanged: (method) =>
                          setState(() => _advanceMethod = method),
                      onChanged: () => setState(() {}),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Measurements',
                          style: textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _attachMeasurements,
                        icon: const Icon(Icons.straighten_outlined),
                        label: const Text('Attach'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'A copy is saved with the order, so later changes to the '
                        "customer's measurements won't affect it.",
                    style: TextStyle(color: AppColors.slate500, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  if (_attached.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No measurements attached.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.slate500),
                        ),
                      ),
                    )
                  else
                    for (var i = 0; i < _attached.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _AttachedRow(
                          measurement: _attached[i],
                          onRemove: () => setState(() => _attached.removeAt(i)),
                        ),
                      ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    minLines: 3,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'e.g. Needs it before Eid',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : () => context.pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : Text(_isEditing ? 'Save' : 'Create order'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Optional money received when the order is booked.
class _AdvanceSection extends StatelessWidget {
  const _AdvanceSection({
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
    if (amount == null || amount <= 0) return 'Enter an amount greater than 0';
    if (amount > total) {
      return "Can't be more than the total (${Money.pkr(total)})";
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
          'Advance payment (optional)',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Money received now, when the order is booked.',
          style: TextStyle(color: AppColors.slate500, fontSize: 13),
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
          decoration: const InputDecoration(
            labelText: 'Advance amount',
            prefixText: 'Rs. ',
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
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Remaining after advance: '
                  '${Money.pkr(OrderMoney.remaining(total: total, paid: amount))}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.slate700,
              ),
            ),
          ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
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
        padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
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
                    style: const TextStyle(color: AppColors.slate500),
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
              tooltip: 'Remove item',
              icon: const Icon(Icons.close, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachedRow extends StatelessWidget {
  const _AttachedRow({required this.measurement, required this.onRemove});

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
        padding: const EdgeInsets.fromLTRB(12, 8, 0, 8),
        child: Row(
          children: [
            Icon(measurement.garmentType.icon, color: AppColors.primary),
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
                      style: const TextStyle(
                        color: AppColors.slate500,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove measurements',
              icon: const Icon(Icons.close, size: 20),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}