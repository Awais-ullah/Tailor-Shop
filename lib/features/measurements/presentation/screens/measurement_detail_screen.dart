import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tailor_app/core/errors/app_failure.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/utils/inch_format.dart';
import 'package:tailor_app/core/widgets/adaptive_wrap.dart';
import 'package:tailor_app/core/widgets/app_snackbar.dart';
import 'package:tailor_app/core/widgets/state_views.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:tailor_app/features/measurements/data/measurement_templates.dart';
import 'package:tailor_app/features/measurements/data/models/measurement.dart';
import 'package:tailor_app/features/measurements/presentation/cubit/measurements_cubit.dart';

/// Read-only view of one measurement set: the page a tailor looks at
/// while cutting. [editLocation] is supplied by the router, because the
/// edit route differs depending on where this screen was opened from.
class MeasurementDetailScreen extends StatelessWidget {
  const MeasurementDetailScreen({
    super.key,
    required this.measurementId,
    required this.editLocation,
  });

  final String measurementId;
  final String editLocation;

  Future<void> _confirmDelete(
      BuildContext context,
      Measurement measurement,
      ) async {
    final cubit = context.read<MeasurementsCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete these measurements?'),
        content: const Text(
          'This cannot be undone. Orders that already used these '
              'measurements keep their own copy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await cubit.delete(measurement.id);
      if (!context.mounted) return;
      AppSnackbar.showSuccess(context, 'Measurements deleted');
      context.pop();
    } on AppFailure catch (failure) {
      if (context.mounted) AppSnackbar.showError(context, failure.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final measurement =
    context.watch<MeasurementsCubit>().state.byId(measurementId);

    if (measurement == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.straighten_outlined,
          title: 'Measurements not found',
          message: 'These measurements may have been deleted.',
          actionLabel: 'Go back',
          onAction: () => context.pop(),
        ),
      );
    }

    final customer =
    context.watch<CustomersCubit>().state.customerById(measurement.customerId);
    final template = MeasurementTemplates.of(measurement.garmentType);
    final textTheme = Theme.of(context).textTheme;

    final filledFields = template.fields
        .where((field) => measurement.values.containsKey(field.key))
        .toList();
    final chosenStyles = template.styleGroups
        .where((group) => (measurement.styles[group.key] ?? []).isNotEmpty)
        .toList();

    final updatedAt = measurement.updatedAt;
    final updated =
    updatedAt == null ? 'Just now' : DateFormat('d MMM y').format(updatedAt);

    final String initialChar = customer != null && customer.name.isNotEmpty
        ? customer.name[0].toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(
        title: Text(measurement.garmentType.label),
        actions: [
          IconButton(
            tooltip: 'Edit measurements',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(editLocation),
          ),
          IconButton(
            tooltip: 'Delete measurements',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, measurement),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primarySoft,
                        child: Text(
                          initialChar,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              [
                                if (measurement.label.isNotEmpty)
                                  measurement.label,
                                'Updated $updated',
                              ].join(' · '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.slate500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Measurements (inches)',
                        style: textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      if (filledFields.isEmpty)
                        const Text(
                          'No measurements recorded.',
                          style: TextStyle(color: AppColors.slate500),
                        )
                      else
                        AdaptiveWrap(
                          minItemWidth: 120,
                          children: [
                            for (final field in filledFields)
                              _ValueTile(
                                label: field.label,
                                value: InchFormat.format(
                                  measurement.values[field.key]!,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              if (chosenStyles.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Style',
                          style: textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        for (final group in chosenStyles)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    group.label,
                                    style: const TextStyle(
                                      color: AppColors.slate500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    measurement.styles[group.key]!
                                        .map((id) =>
                                        template.optionLabel(group.key, id))
                                        .join(', '),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              if (measurement.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes',
                          style: textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(measurement.notes),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AppColors.slate500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}