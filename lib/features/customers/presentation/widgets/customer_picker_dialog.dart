import 'package:flutter/material.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/utils/phone_utils.dart';
import 'package:tailor_app/features/customers/data/models/customer.dart';

/// Searchable "choose a customer" dialog.
Future<Customer?> showCustomerPicker(
    BuildContext context,
    List<Customer> customers,
    ) {
  return showDialog<Customer>(
    context: context,
    builder: (_) => _CustomerPickerDialog(customers: customers),
  );
}

class _CustomerPickerDialog extends StatefulWidget {
  const _CustomerPickerDialog({required this.customers});

  final List<Customer> customers;

  @override
  State<_CustomerPickerDialog> createState() => _CustomerPickerDialogState();
}

class _CustomerPickerDialogState extends State<_CustomerPickerDialog> {
  String _query = '';

  List<Customer> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.customers;

    final digits = PhoneUtils.normalize(q);
    return widget.customers.where((customer) {
      return customer.nameLower.contains(q) ||
          (digits.isNotEmpty && customer.phoneNormalized.contains(digits));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                'Choose a customer',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Search by name or phone',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Flexible + shrinkWrap: the list takes only the space it needs
            // and shrinks when the keyboard opens.
            Flexible(
              child: results.isEmpty
                  ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No customers found')),
              )
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final customer = results[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primarySoft,
                      child: Text(
                        customer.initial,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: customer.phone.isEmpty
                        ? null
                        : Text(
                      customer.phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.pop(context, customer),
                  );
                },
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}