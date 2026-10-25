import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/utils/app_dates.dart';
import 'package:tailor_app/core/errors/app_failure.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/core/utils/inch_format.dart';
import 'package:tailor_app/core/widgets/adaptive_wrap.dart';
import 'package:tailor_app/core/widgets/app_snackbar.dart';
import 'package:tailor_app/core/widgets/state_views.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:tailor_app/features/measurements/data/measurement_templates.dart';
import 'package:tailor_app/features/measurements/data/models/measurement.dart';
import 'package:tailor_app/features/measurements/presentation/cubit/measurements_cubit.dart';

import 'package:tailor_app/core/l10n/app_strings.dart';

/// New measurements: pass [customerId] and [garmentType].
/// Editing: pass [measurementId] only.
class MeasurementFormScreen extends StatefulWidget {
  const MeasurementFormScreen({
    super.key,
    this.measurementId,
    this.customerId,
    this.garmentType,
    this.returnToCaller = false,
  });

  final String? measurementId;
  final String? customerId;
  final GarmentType? garmentType;

  /// true when another screen (the order form) opened this form with
  /// Navigator.push and wants the new measurement's id back.
  final bool returnToCaller;

  @override
  State<MeasurementFormScreen> createState() => _MeasurementFormScreenState();
}

class _MeasurementFormScreenState extends State<MeasurementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _notesController = TextEditingController();
  final Map<String, TextEditingController> _valueControllers = {};
  final Map<String, FocusNode> _valueFocusNodes = {};
  final Map<String, Set<String>> _styles = {};

  Measurement? _existing;
  String? _customerId;
  GarmentType? _garmentType;
  String? _focusedKey;
  bool _saving = false;

  bool get _isEditing => widget.measurementId != null;

  /// Closes the screen. [result] (the saved id) goes back to the screen that
  /// opened this form, when it asked for it.
  void _close([String? result]) {
    if (widget.returnToCaller) {
      Navigator.of(context).pop(result);
    } else {
      context.pop();
    }
  }

  GarmentTemplate? get _template =>
      _garmentType == null ? null : MeasurementTemplates.of(_garmentType!);

  @override
  void initState() {
    super.initState();

    final measurementId = widget.measurementId;
    if (measurementId != null) {
      final existing =
      context.read<MeasurementsCubit>().state.byId(measurementId);
      _existing = existing;
      if (existing != null) {
        _customerId = existing.customerId;
        _garmentType = existing.garmentType;
      }
    } else {
      _customerId = widget.customerId;
      _garmentType = widget.garmentType;
    }

    final template = _template;
    if (template == null) return;

    for (final field in template.fields) {
      _valueControllers[field.key] = TextEditingController();
      final focusNode = FocusNode();
      focusNode.addListener(() => _onFocusChanged(field.key, focusNode.hasFocus));
      _valueFocusNodes[field.key] = focusNode;
    }
    for (final group in template.styleGroups) {
      _styles[group.key] = <String>{};
    }

    final existing = _existing;
    if (existing != null) {
      _fillFrom(existing);
      _labelController.text = existing.label;
      _notesController.text = existing.notes;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _notesController.dispose();
    for (final controller in _valueControllers.values) {
      controller.dispose();
    }
    for (final node in _valueFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _onFocusChanged(String key, bool hasFocus) {
    if (!mounted) return;
    if (hasFocus) {
      setState(() => _focusedKey = key);
    } else if (_focusedKey == key) {
      setState(() => _focusedKey = null);
    }
  }

  /// Copies numbers and styles (not label or notes) from another set.
  void _fillFrom(Measurement source) {
    final template = _template;
    if (template == null) return;

    for (final field in template.fields) {
      final value = source.values[field.key];
      _valueControllers[field.key]!.text =
      value == null ? '' : InchFormat.format(value);
    }
    for (final group in template.styleGroups) {
      final ids = source.styles[group.key] ?? const <String>[];
      _styles[group.key] = ids.toSet();
    }
  }

  /// Sets the fractional part of the focused field: 0 = whole number only.
  void _applyFraction(int eighths) {
    final key = _focusedKey;
    if (key == null) return;

    final controller = _valueControllers[key]!;
    final current = InchFormat.parse(controller.text) ?? 0;
    final value = current.floor() + eighths / 8;

    controller.text = value == 0 ? '' : InchFormat.format(value);
    controller.selection =
        TextSelection.collapsed(offset: controller.text.length);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final template = _template!;

    final values = <String, double>{};
    for (final field in template.fields) {
      final parsed = InchFormat.parse(_valueControllers[field.key]!.text);
      if (parsed != null) values[field.key] = parsed;
    }
    if (values.isEmpty) {
      AppSnackbar.showError(context, S.current.enterAtLeastOneMeasurement);
      return;
    }

    final styles = <String, List<String>>{};
    for (final group in template.styleGroups) {
      final chosen = _styles[group.key] ?? <String>{};
      if (chosen.isNotEmpty) styles[group.key] = chosen.toList()..sort();
    }

    final cubit = context.read<MeasurementsCubit>();

    setState(() => _saving = true);
    try {
      final savedId = await cubit.saveMeasurement(
        id: widget.measurementId,
        customerId: _customerId!,
        garmentType: _garmentType!,
        label: _labelController.text,
        values: values,
        styles: styles,
        notes: _notesController.text,
      );
      if (!mounted) return;
      AppSnackbar.showSuccess(
        context,
        _isEditing ? S.current.measurementsUpdated : S.current.measurementsSaved,
      );
      _close(savedId);
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
    final template = _template;
    final customerId = _customerId;

    if (template == null || customerId == null || (_isEditing && _existing == null)) {
      return Scaffold(
        appBar: AppBar(title: Text(S.current.measurements)),
        body: EmptyState(
          icon: Icons.straighten_outlined,
          title: S.current.measurementsNotFound,
          message: S.current.somethingMissing,
          actionLabel: S.current.goBack,
          onAction: _close,
        ),
      );
    }

    final garmentType = _garmentType!;
    final customer = context.read<CustomersCubit>().state.customerById(customerId);
    final previous = _isEditing
        ? null
        : context
        .read<MeasurementsCubit>()
        .state
        .latestFor(customerId, garmentType);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? S.current.editGarment(garmentType.label) : S.current.newGarment(garmentType.label),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      // The fraction bar lives INSIDE the body, so it always sits directly
      // above the keyboard (the Scaffold shrinks the body for the keyboard).
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CustomerHeader(
                          name: customer?.name ?? S.current.unknownCustomer,
                          initial: customer?.initial ?? '?',
                          garment: garmentType,
                        ),
                        if (previous != null) ...[
                          const SizedBox(height: 12),
                          _CopyBanner(
                            previous: previous,
                            onCopy: () {
                              setState(() => _fillFrom(previous));
                              AppSnackbar.showSuccess(
                                context,
                                S.current.copiedAdjust,
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _labelController,
                          textCapitalization: TextCapitalization.sentences,
                          inputFormatters: [LengthLimitingTextInputFormatter(60)],
                          decoration: InputDecoration(
                            labelText: S.current.labelOptional,
                            hintText: S.current.labelExample,
                            prefixIcon: Icon(Icons.label_outline),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          S.current.measurementsInches,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          S.current.fillWhatYouNeed,
                          style: TextStyle(color: context.pal.slate500),
                        ),
                        const SizedBox(height: 12),
                        AdaptiveWrap(
                          minItemWidth: 140,
                          children: [
                            for (final field in template.fields)
                              TextFormField(
                                controller: _valueControllers[field.key],
                                focusNode: _valueFocusNodes[field.key],
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                textInputAction: TextInputAction.next,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.,/\s¼½¾⅛⅜⅝⅞]'),
                                  ),
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                validator: InchFormat.validateOptional,
                                decoration: InputDecoration(
                                  labelText: field.label,
                                  prefixIcon: Icon(field.icon, size: 20),
                                  helperText: field.hint,
                                  suffixText: 'in',
                                  errorMaxLines: 2,
                                ),
                              ),
                          ],
                        ),
                        for (final group in template.styleGroups) ...[
                          const SizedBox(height: 24),
                          _StyleGroupSection(
                            group: group,
                            selected: _styles[group.key] ?? <String>{},
                            onToggle: (optionId, isSelected) {
                              setState(() {
                                final chosen =
                                _styles.putIfAbsent(group.key, () => <String>{});
                                if (group.multiSelect) {
                                  isSelected
                                      ? chosen.add(optionId)
                                      : chosen.remove(optionId);
                                } else {
                                  chosen.clear();
                                  if (isSelected) chosen.add(optionId);
                                }
                              });
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _notesController,
                          minLines: 3,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                          decoration: InputDecoration(
                            labelText: S.current.notes,
                            hintText: S.current.notesExample,
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.notes_outlined),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _saving ? null : _close,
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
                                    : Text(S.current.save),
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
          ),
          if (_focusedKey != null) _FractionBar(onFraction: _applyFraction),
        ],
      ),
    );
  }
}

class _CustomerHeader extends StatelessWidget {
  const _CustomerHeader({
    required this.name,
    required this.initial,
    required this.garment,
  });

  final String name;
  final String initial;
  final GarmentType garment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: context.pal.primarySoft,
              child: Text(
                initial,
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
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    garment.label,
                    style: TextStyle(color: context.pal.slate500),
                  ),
                ],
              ),
            ),
            Icon(garment.icon, color: context.pal.primary),
          ],
        ),
      ),
    );
  }
}

class _CopyBanner extends StatelessWidget {
  const _CopyBanner({required this.previous, required this.onCopy});

  final Measurement previous;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final updatedAt = previous.updatedAt;
    final date =
    updatedAt == null ? S.current.justNow : AppDates.medium(updatedAt);
    final name = previous.label.isEmpty ? S.current.theLastSet : '"${previous.label}"';

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: context.pal.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.history, color: context.pal.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              S.current.copyFromQ(name, date),
              style: TextStyle(color: context.pal.slate700),
            ),
          ),
          TextButton(onPressed: onCopy, child: Text(S.current.copy)),
        ],
      ),
    );
  }
}

class _StyleGroupSection extends StatelessWidget {
  const _StyleGroupSection({
    required this.group,
    required this.selected,
    required this.onToggle,
  });

  final StyleGroup group;
  final Set<String> selected;
  final void Function(String optionId, bool isSelected) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group.multiSelect ? S.current.chooseAny(group.label) : group.label,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in group.options)
              FilterChip(
                label: Text(option.label),
                selected: selected.contains(option.id),
                onSelected: (isSelected) => onToggle(option.id, isSelected),
              ),
          ],
        ),
      ],
    );
  }
}

/// Quick fraction buttons shown above the keyboard while a measurement
/// field is focused. Phone number keypads have no "/" or "½" key.
class _FractionBar extends StatelessWidget {
  const _FractionBar({required this.onFraction});

  final ValueChanged<int> onFraction;

  static List<String> get _labels => [
    S.current.whole,
    '⅛',
    '¼',
    '⅜',
    '½',
    '⅝',
    '¾',
    '⅞',
  ];

  @override
  Widget build(BuildContext context) {
    // TextFieldTapRegion: tapping here must not count as "tapped outside
    // the text field", otherwise desktop would drop focus first.
    return TextFieldTapRegion(
      child: Material(
        color: context.pal.surface,
        elevation: 8,
        child: SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              for (var eighths = 0; eighths < _labels.length; eighths++)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ActionChip(
                    label: Text(
                      _labels[eighths],
                      style: const TextStyle(fontSize: 16),
                    ),
                    onPressed: () => onFraction(eighths),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}