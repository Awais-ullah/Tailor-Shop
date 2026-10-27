import 'package:flutter/material.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/core/utils/inch_format.dart';
import 'package:tailor_app/features/measurements/data/measurement_templates.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_glyphs.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_icon.dart';
import 'package:tailor_app/features/orders/data/models/order_measurement.dart';

// A measurement copy saved inside an order.

/// One attached measurement copy: garment, label, values, styles, notes.
class MeasurementSnapshotBlock extends StatelessWidget {
  const MeasurementSnapshotBlock({super.key, required this.measurement});

  final OrderMeasurement measurement;

  @override
  Widget build(BuildContext context) {
    final template = MeasurementTemplates.of(measurement.garmentType);

    final fields = template.fields
        .where((field) => measurement.values.containsKey(field.key))
        .toList();
    final styleLines = <String>[];
    for (final group in template.styleGroups) {
      final ids = measurement.styles[group.key] ?? const <String>[];
      if (ids.isEmpty) continue;
      styleLines.add(
        '${group.label}: ${ids.map((id) => template.optionLabel(group.key, id)).join(', ')}',
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.pal.slate50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.pal.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TailorIcon(
                TailorGlyphs.garment(measurement.garmentType),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  [
                    measurement.garmentType.label,
                    if (measurement.label.isNotEmpty) measurement.label,
                  ].join(' · '),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final field in fields)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.pal.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.pal.slate200),
                  ),
                  child: Text(
                    '${field.label} ${InchFormat.format(measurement.values[field.key]!)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
            ],
          ),
          for (final line in styleLines)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 6),
              child: Text(
                line,
                style: TextStyle(color: context.pal.slate700, fontSize: 13),
              ),
            ),
          if (measurement.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 6),
              child: Text(
                measurement.notes,
                style: TextStyle(color: context.pal.slate500, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
