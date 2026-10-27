import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/errors/app_failure.dart';
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

import 'package:tailor_app/core/l10n/app_strings.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_glyphs.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_icon.dart';
import 'package:tailor_app/features/orders/presentation/widgets/order_form_parts.dart';

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

    final chosen = await showMeasurementAttachDialog(
      context,
      available,
      onNewMeasurement: _takeNewMeasurement,
    );
    if (chosen == null || chosen.isEmpty || !mounted) return;

    setState(() {
      _attached.addAll(chosen.map(OrderMeasurement.fromMeasurement));
    });
  }

  /// Takes a fresh measurement for this customer, then attaches it to the
  /// order straight away.
  Future<void> _takeNewMeasurement() async {
    final customerId = _customerId;
    if (customerId == null || !mounted) return;

    final garment = await showGarmentPicker(context);
    if (garment == null || !mounted) return;

    final measurementsCubit = context.read<MeasurementsCubit>();
    final customersCubit = context.read<CustomersCubit>();

    final savedId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: measurementsCubit),
            BlocProvider.value(value: customersCubit),
          ],
          child: MeasurementFormScreen(
            customerId: customerId,
            garmentType: garment,
            returnToCaller: true,
          ),
        ),
      ),
    );
    if (savedId == null || !mounted) return;

    // The new set arrives through the live list a moment after saving.
    Measurement? saved;
    for (var i = 0; i < 20 && mounted; i++) {
      saved = measurementsCubit.state.byId(savedId);
      if (saved != null) break;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (saved == null || !mounted) return;

    final alreadyAttached = _attached.any((m) => m.sourceId == savedId);
    if (alreadyAttached) return;
    setState(() => _attached.add(OrderMeasurement.fromMeasurement(saved!)));
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (_items.isEmpty) {
      AppSnackbar.showError(context, S.current.addAtLeastOneItem);
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
        _isEditing ? S.current.orderUpdated : S.current.orderCreated,
      );
      context.pop();
    } on AppFailure catch (failure) {
      if (mounted) AppSnackbar.showError(context, failure.message);
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(context, S.current.errorGeneric);
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
        appBar: AppBar(title: Text(S.current.order)),
        body: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: S.current.orderNotFound,
          message: S.current.somethingMissing,
          actionLabel: S.current.goBack,
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
          _isEditing ? S.current.editOrderNumber(_existing!.orderNumber) : S.current.newOrder,
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (customer != null && customer.phone.isNotEmpty)
                                  Text(
                                    customer.phone,
                                    style: TextStyle(
                                      color: context.pal.slate500,
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
                        decoration: InputDecoration(
                          labelText: S.current.orderDate,
                          prefixIcon: Icon(Icons.event_outlined),
                        ),
                      ),
                      TextFormField(
                        controller: _deliveryDateController,
                        readOnly: true,
                        onTap: _pickDeliveryDate,
                        validator: (_) {
                          if (_deliveryDate.isBefore(_orderDate)) {
                            return S.current.cannotBeBeforeOrderDate;
                          }
                          if (_deliveryDate
                              .isAfter(AppDates.addDays(_orderDate, 365))) {
                            return S.current.deliveryTooFar;
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: S.current.deliveryDate,
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
                          S.current.items,
                          style: textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add),
                        label: Text(S.current.addItem),
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
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                S.current.noItemsYet,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: context.pal.slate500),
                              ),
                            )
                          else
                            for (var i = 0; i < _items.length; i++)
                              OrderItemRow(
                                item: _items[i],
                                onTap: () => _editItem(i),
                                onDelete: () => setState(() => _items.removeAt(i)),
                              ),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    S.current.total,
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
                    OrderAdvanceSection(
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
                          S.current.measurements,
                          style: textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _attachMeasurements,
                        icon: const Icon(Icons.straighten_outlined),
                        label: Text(S.current.attach),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    S.current.copySavedWithOrder,
                    style: TextStyle(color: context.pal.slate500, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  if (_attached.isEmpty)
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          S.current.noMeasurementsAttached,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.pal.slate500),
                        ),
                      ),
                    )
                  else
                    for (var i = 0; i < _attached.length; i++)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(bottom: 8),
                        child: AttachedMeasurementRow(
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
                    decoration: InputDecoration(
                      labelText: S.current.notes,
                      hintText: S.current.orderNotesExample,
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
                          child: Text(S.current.cancel),
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
                              : Text(_isEditing ? S.current.save : S.current.createOrder),
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
