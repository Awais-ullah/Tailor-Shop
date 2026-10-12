import 'package:flutter/material.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/utils/app_dates.dart';
import 'package:tailor_app/core/utils/inch_format.dart';
import 'package:tailor_app/features/measurements/data/measurement_templates.dart';
import 'package:tailor_app/features/measurements/data/models/measurement.dart';

/// Lets the user tick which saved measurement sets to attach to an order.
/// [available] is passed in (not read from a Cubit) because dialogs open
/// above the app's providers.
Future<List<Measurement>?> showMeasurementAttachDialog(
    BuildContext context,
    List<Measurement> available,
    ) {
  return showDialog<List<Measurement>>(
    context: context,
    builder: (_) => _AttachDialog(available: available),
  );
}

class _AttachDialog extends StatefulWidget {
  const _AttachDialog({required this.available});

  final List<Measurement> available;

  @override
  State<_AttachDialog> createState() => _AttachDialogState();
}

class _AttachDialogState extends State<_AttachDialog> {
  final Set<String> _selected = {};

  String _summary(Measurement measurement) {
    final template = MeasurementTemplates.of(measurement.garmentType);
    return template.fields
        .where((field) => measurement.values.containsKey(field.key))
        .take(3)
        .map((f) => '${f.label} ${InchFormat.format(measurement.values[f.key]!)}')
        .join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Attach measurements'),
      scrollable: true,
      content: SizedBox(
        width: 400,
        child: widget.available.isEmpty
            ? const Text(
          'No saved measurements to attach. You can add them from the '
              "customer's profile.",
          style: TextStyle(color: AppColors.slate700),
        )
            : Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'A copy is saved with the order.',
                style: TextStyle(color: AppColors.slate500),
              ),
            ),
            for (final measurement in widget.available)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _selected.contains(measurement.id),
                onChanged: (checked) => setState(() {
                  checked == true
                      ? _selected.add(measurement.id)
                      : _selected.remove(measurement.id);
                }),
                title: Text(
                  [
                    measurement.garmentType.label,
                    if (measurement.label.isNotEmpty) measurement.label,
                  ].join(' · '),
                ),
                subtitle: Text(
                  [
                    if (measurement.updatedAt != null)
                      AppDates.medium(measurement.updatedAt!),
                    _summary(measurement),
                  ].where((part) => part.isNotEmpty).join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (widget.available.isNotEmpty)
          FilledButton(
            onPressed: _selected.isEmpty
                ? null
                : () => Navigator.pop(
              context,
              widget.available
                  .where((m) => _selected.contains(m.id))
                  .toList(),
            ),
            child: Text(
              _selected.isEmpty ? 'Attach' : 'Attach (${_selected.length})',
            ),
          ),
      ],
    );
  }
}