import 'package:flutter/material.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/core/utils/phone_utils.dart';
import 'package:tailor_app/features/customers/data/models/customer.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';

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
              padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 12),
              child: Text(
                S.current.chooseCustomer,
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
                decoration: InputDecoration(
                  hintText: S.current.searchNameOrPhone,
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Flexible + shrinkWrap: the list takes only the space it needs
            // and shrinks when the keyboard opens.
            Flexible(
              child: results.isEmpty
                  ? Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text(S.current.noCustomersFound)),
              )
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final customer = results[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: context.pal.primarySoft,
                      child: Text(
                        customer.initial,
                        style: TextStyle(
                          color: context.pal.primary,
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
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 12, 8),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(S.current.cancel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}