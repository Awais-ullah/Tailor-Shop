import 'package:tailor_app/core/l10n/locale_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tailor_app/core/errors/app_failure.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/core/theme/theme_controller.dart';
import 'package:tailor_app/core/utils/offline_write.dart';
import 'package:tailor_app/core/utils/validators.dart';
import 'package:tailor_app/core/widgets/app_snackbar.dart';
import 'package:tailor_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:tailor_app/features/auth/presentation/widgets/account_tile.dart';
import 'package:tailor_app/features/shop/data/models/shop.dart';
import 'package:tailor_app/features/shop/data/repositories/shop_repository.dart';

import 'package:tailor_app/core/l10n/app_strings.dart';

import '../../../../core/currency/currency_controller.dart';

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
  Future<void> _chooseCurrency() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 8),
                child: Text(
                  S.current.currency,
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              for (final currency in AppCurrency.all)
                ListTile(
                  title: Text(currency.name),
                  subtitle: Text('${currency.code} · ${currency.symbol}'),
                  trailing: currency.code ==
                      CurrencyController.instance.value.code
                      ? Icon(
                    Icons.check_circle,
                    color: Theme.of(sheetContext).colorScheme.primary,
                  )
                      : null,
                  onTap: () {
                    CurrencyController.instance.setCurrency(currency);
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        ),
      ),
    );
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
      if (mounted) AppSnackbar.showSuccess(context, S.current.shopNameUpdated);
    } on AppFailure catch (failure) {
      if (mounted) AppSnackbar.showError(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(S.current.settings)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                S.current.account,
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const AccountTile(),
              const SizedBox(height: 24),
              Text(
                S.current.shop,
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _shopStream == null
                      ? Text(S.current.signInToManage)
                      : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: _shopStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text(
                          S.current.couldNotLoadShop,
                          style: TextStyle(color: context.pal.danger),
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
                            label: S.current.shopName,
                            value: shop?.name ?? S.current.notCreatedYet,
                            trailing: shop == null
                                ? null
                                : IconButton(
                              tooltip: S.current.editShopName,
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _editShopName(shop.name),
                            ),
                          ),
                          const Divider(height: 28),
                          ValueListenableBuilder<AppCurrency>(
                            valueListenable: CurrencyController.instance,
                            builder: (context, currency, _) => InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: _chooseCurrency,
                              child: _SettingRow(
                                icon: Icons.payments_outlined,
                                label: S.current.currency,
                                value: currency.display,
                                trailing: const Icon(Icons.chevron_right),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                S.current.appearance,
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ValueListenableBuilder<ThemeMode>(
                    valueListenable: ThemeController.instance,
                    builder: (context, mode, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.brightness_6_outlined,
                              size: 20,
                              color: context.pal.slate500,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              S.current.theme,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(color: context.pal.slate500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<ThemeMode>(
                          showSelectedIcon: false,
                          expandedInsets: EdgeInsets.zero,
                          segments: [
                            ButtonSegment(
                              value: ThemeMode.light,
                              icon: Icon(Icons.light_mode_outlined),
                              label: Text(S.current.themeLight),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              icon: Icon(Icons.dark_mode_outlined),
                              label: Text(S.current.themeDark),
                            ),
                            ButtonSegment(
                              value: ThemeMode.system,
                              icon: Icon(Icons.brightness_auto_outlined),
                              label: Text(S.current.themeSystem),
                            ),
                          ],
                          selected: {mode},
                          onSelectionChanged: (selection) =>
                              ThemeController.instance.setMode(selection.first),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                S.current.language,
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Card(
                clipBehavior: Clip.antiAlias,
                child: ValueListenableBuilder<String?>(
                  valueListenable: LocaleController.instance,
                  builder: (context, selected, _) => Column(
                    children: [
                      _LanguageTile(
                        title: S.current.systemDefault,
                        selected: selected == null,
                        onTap: () => LocaleController.instance.setLanguage(null),
                      ),
                      for (final language in AppLanguage.all) ...[
                        const Divider(height: 1),
                        _LanguageTile(
                          title: language.nativeName,
                          selected: selected == language.code,
                          onTap: () =>
                              LocaleController.instance.setLanguage(language.code),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                S.current.about,
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _SettingRow(
                        icon: Icons.info_outline,
                        label: S.current.appName,
                        value: S.current.versionLabel(_appVersion),
                      ),
                      Divider(height: 28),
                      _SettingRow(
                        icon: Icons.cloud_done_outlined,
                        label: S.current.worksOffline,
                        value:
                        S.current.worksOfflineBody,
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
        Icon(icon, size: 20, color: context.pal.slate500),
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
                    ?.copyWith(color: context.pal.slate500),
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
      title: Text(S.current.shopName),
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
                Validators.requiredField(value, fieldName: S.current.shopName),
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(labelText: S.current.shopName),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(S.current.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(S.current.save)),
      ],
    );
  }
}

/// One row in the language list.
class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: selected
          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
