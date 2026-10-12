import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tailor_app/core/errors/app_failure.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/utils/offline_write.dart';
import 'package:tailor_app/core/utils/validators.dart';
import 'package:tailor_app/core/widgets/app_snackbar.dart';
import 'package:tailor_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:tailor_app/features/auth/presentation/widgets/account_tile.dart';
import 'package:tailor_app/features/shop/data/models/shop.dart';
import 'package:tailor_app/features/shop/data/repositories/shop_repository.dart';

/// Keep in step with `version:` in pubspec.yaml.
const String _appVersion = '1.0.0';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _uid;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _shopStream;

  @override
  void initState() {
    super.initState();
    _uid = context.read<AuthCubit>().state.user?.uid;
    final uid = _uid;
    if (uid != null) {
      // Created once, so rebuilds do not re-subscribe.
      _shopStream = context.read<ShopRepository>().watchShopSnapshot(uid);
    }
  }

  Future<void> _editShopName(String current) async {
    final uid = _uid;
    if (uid == null) return;
    final repository = context.read<ShopRepository>();

    final name = await showDialog<String>(
      context: context,
      builder: (_) => _ShopNameDialog(initial: current),
    );
    if (name == null || name == current || !mounted) return;

    try {
      await awaitWriteBriefly(repository.updateShopName(uid, name));
      if (mounted) AppSnackbar.showSuccess(context, 'Shop name updated');
    } on AppFailure catch (failure) {
      if (mounted) AppSnackbar.showError(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Account',
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const AccountTile(),
              const SizedBox(height: 24),
              Text(
                'Shop',
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _shopStream == null
                      ? const Text('Sign in to manage your shop.')
                      : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: _shopStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Text(
                          "Couldn't load your shop details.",
                          style: TextStyle(color: AppColors.danger),
                        );
                      }
                      final doc = snapshot.data;
                      if (doc == null) {
                        return const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      final data = doc.data();
                      final shop =
                      data == null ? null : Shop.fromMap(doc.id, data);

                      return Column(
                        children: [
                          _SettingRow(
                            icon: Icons.storefront_outlined,
                            label: 'Shop name',
                            value: shop?.name ?? 'Not created yet',
                            trailing: shop == null
                                ? null
                                : IconButton(
                              tooltip: 'Edit shop name',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _editShopName(shop.name),
                            ),
                          ),
                          const Divider(height: 28),
                          const _SettingRow(
                            icon: Icons.payments_outlined,
                            label: 'Currency',
                            value: 'Pakistani Rupee (Rs.)',
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'About',
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _SettingRow(
                        icon: Icons.info_outline,
                        label: 'Tailor Shop',
                        value: 'Version $_appVersion',
                      ),
                      Divider(height: 28),
                      _SettingRow(
                        icon: Icons.cloud_done_outlined,
                        label: 'Works offline',
                        value:
                        'Changes are saved on this device and sync '
                            'automatically when you are back online.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.slate500),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppColors.slate500),
              ),
              const SizedBox(height: 2),
              Text(value),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _ShopNameDialog extends StatefulWidget {
  const _ShopNameDialog({required this.initial});

  final String initial;

  @override
  State<_ShopNameDialog> createState() => _ShopNameDialogState();
}

class _ShopNameDialogState extends State<_ShopNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(
      context,
      _controller.text.trim().replaceAll(RegExp(r'\s+'), ' '),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Shop name'),
      scrollable: true,
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [LengthLimitingTextInputFormatter(60)],
            validator: (value) =>
                Validators.requiredField(value, fieldName: 'Shop name'),
            onFieldSubmitted: (_) => _submit(),
            decoration: const InputDecoration(labelText: 'Shop name'),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}