import 'package:flutter/material.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/core/utils/app_dates.dart';
import 'package:tailor_app/core/utils/inch_format.dart';
import 'package:tailor_app/features/measurements/data/measurement_templates.dart';
import 'package:tailor_app/features/measurements/data/models/measurement.dart';

import 'package:tailor_app/core/l10n/app_strings.dart';

/// Lets the user tick which saved measurement sets to attach to an order.
/// [available] is passed in (not read from a Cubit) because dialogs open
/// above the app's providers.
///
/// [onNewMeasurement] adds a "New measurement" button: the dialog closes and
/// the callback starts taking a fresh measurement for the customer.
Future<List<Measurement>?> showMeasurementAttachDialog(
  BuildContext context,
  List<Measurement> available, {
  VoidCallback? onNewMeasurement,
}) {
  return showDialog<List<Measurement>>(
    context: context,
    builder: (_) =>
        _AttachDialog(available: available, onNewMeasurement: onNewMeasurement),
  );
}

class _AttachDialog extends StatefulWidget {
  const _AttachDialog({required this.available, this.onNewMeasurement});

  final List<Measurement> available;
  final VoidCallback? onNewMeasurement;

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
        .map(
          (f) => '${f.label} ${InchFormat.format(measurement.values[f.key]!)}',
        )
        .join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.current.attachMeasurements),
      scrollable: true,
      content: SizedBox(
        width: 400,
        child: widget.available.isEmpty
            ? Text(
                S.current.noSavedMeasurementsToAttach,
                style: TextStyle(color: context.pal.slate700),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.only(bottom: 8),
                    child: Text(
                      S.current.copySavedWithOrderShort,
                      style: TextStyle(color: context.pal.slate500),
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
        if (widget.onNewMeasurement != null)
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              widget.onNewMeasurement!();
            },
            icon: const Icon(Icons.add),
            label: Text(S.current.newMeasurements),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(S.current.cancel),
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
              _selected.isEmpty
                  ? S.current.attach
                  : S.current.attachCount(_selected.length),
            ),
          ),
      ],
    );
  }
}
