import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/errors/app_failure.dart';
import 'package:tailor_app/core/router/app_routes.dart';
import 'package:tailor_app/core/utils/phone_utils.dart';
import 'package:tailor_app/core/utils/validators.dart';
import 'package:tailor_app/core/widgets/app_snackbar.dart';
import 'package:tailor_app/core/widgets/state_views.dart';
import 'package:tailor_app/features/customers/data/models/customer.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_cubit.dart';

/// Used for both "New customer" (customerId == null) and "Edit customer".
class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({super.key, this.customerId});

  final String? customerId;

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _notesFocus = FocusNode();

  Customer? _existing;
  bool _saving = false;

  bool get _isEditing => widget.customerId != null;

  @override
  void initState() {
    super.initState();

    final id = widget.customerId;
    if (id != null) {
      final existing = context.read<CustomersCubit>().state.customerById(id);
      _existing = existing;
      if (existing != null) {
        _nameController.text = existing.name;
        _phoneController.text = existing.phone;
        _addressController.text = existing.address;
        _notesController.text = existing.notes;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  Future<bool> _confirmDuplicate(Customer duplicate) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Phone number already used'),
        content: Text(
          '${duplicate.name} already has this phone number. Families often '
              'share a number, so you can still continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Go back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save anyway'),
          ),
        ],
      ),
    );
    return proceed == true;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = context.read<CustomersCubit>();

    final duplicate = cubit.findDuplicatePhone(
      _phoneController.text,
      excludeId: widget.customerId,
    );
    if (duplicate != null) {
      final proceed = await _confirmDuplicate(duplicate);
      if (!proceed || !mounted) return;
    }

    setState(() => _saving = true);
    try {
      await cubit.saveCustomer(
        id: widget.customerId,
        name: _nameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        notes: _notesController.text,
      );
      if (!mounted) return;
      AppSnackbar.showSuccess(
        context,
        _isEditing ? 'Customer updated' : 'Customer added',
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
    if (_isEditing && _existing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit customer')),
        body: EmptyState(
          icon: Icons.person_off_outlined,
          title: 'Customer not found',
          message: 'This customer may have been removed.',
          actionLabel: 'Back to customers',
          onAction: () => context.go(AppRoutes.customers),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit customer' : 'New customer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [LengthLimitingTextInputFormatter(100)],
                    validator: (value) =>
                        Validators.requiredField(value, fieldName: 'Name'),
                    onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
                    decoration: const InputDecoration(
                      labelText: 'Full name *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
                      LengthLimitingTextInputFormatter(20),
                    ],
                    validator: PhoneUtils.validateOptional,
                    onFieldSubmitted: (_) => _addressFocus.requestFocus(),
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      hintText: '0300-1234567',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    focusNode: _addressFocus,
                    minLines: 2,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [LengthLimitingTextInputFormatter(300)],
                    onFieldSubmitted: (_) => _notesFocus.requestFocus(),
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    focusNode: _notesFocus,
                    minLines: 3,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                    decoration: const InputDecoration(
                      labelText: 'Notes',
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
                              : const Text('Save'),
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