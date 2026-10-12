import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tailor_app/core/utils/app_dates.dart';
import 'package:tailor_app/core/utils/money.dart';
import 'package:tailor_app/features/payments/data/payment_method.dart';

class PaymentInput {
  const PaymentInput({
    required this.amount,
    required this.method,
    required this.note,
    required this.date,
  });

  final int amount;
  final PaymentMethod method;
  final String note;
  final DateTime date;
}

/// Asks for the payment details. The caller does the saving, because
/// dialogs open above the app's providers.
Future<PaymentInput?> showRecordPaymentDialog(
    BuildContext context, {
      required int remaining,
    }) {
  return showDialog<PaymentInput>(
    context: context,
    builder: (_) => _RecordPaymentDialog(remaining: remaining),
  );
}

class _RecordPaymentDialog extends StatefulWidget {
  const _RecordPaymentDialog({required this.remaining});

  final int remaining;

  @override
  State<_RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<_RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _dateController = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _date = AppDates.today();
    _dateController.text = AppDates.long(_date);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    final amount = int.tryParse(value?.trim() ?? '');
    if (amount == null) return 'Enter the amount';
    if (amount <= 0) return 'Amount must be greater than 0';
    if (amount > widget.remaining) {
      return 'More than the remaining ${Money.pkr(widget.remaining)}';
    }
    return null;
  }

  Future<void> _pickDate() async {
    final today = AppDates.today();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: AppDates.addDays(today, -365),
      lastDate: today,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _date = AppDates.dateOnly(picked);
      _dateController.text = AppDates.long(_date);
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.pop(
      context,
      PaymentInput(
        amount: int.parse(_amountController.text.trim()),
        method: _method,
        note: _noteController.text,
        date: _date,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record payment'),
      scrollable: true,
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Remaining: ${Money.pkr(widget.remaining)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                validator: _validateAmount,
                decoration: const InputDecoration(
                  labelText: 'Amount received',
                  prefixText: 'Rs. ',
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: ActionChip(
                  label: Text('Full balance · ${Money.pkr(widget.remaining)}'),
                  onPressed: () => setState(
                        () => _amountController.text = widget.remaining.toString(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final method in PaymentMethod.values)
                    ChoiceChip(
                      avatar: Icon(method.icon, size: 18),
                      label: Text(method.label),
                      selected: _method == method,
                      onSelected: (_) => setState(() => _method = method),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: _pickDate,
                decoration: const InputDecoration(
                  labelText: 'Date received',
                  prefixIcon: Icon(Icons.event_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: [LengthLimitingTextInputFormatter(200)],
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  hintText: 'e.g. Second installment',
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
        FilledButton(onPressed: _submit, child: const Text('Save payment')),
      ],
    );
  }
}