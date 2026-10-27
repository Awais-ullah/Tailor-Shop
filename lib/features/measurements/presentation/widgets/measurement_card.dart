import 'package:flutter/material.dart';
import 'package:tailor_app/core/utils/app_dates.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/core/utils/inch_format.dart';
import 'package:tailor_app/features/measurements/data/measurement_templates.dart';
import 'package:tailor_app/features/measurements/data/models/measurement.dart';

import 'package:tailor_app/core/l10n/app_strings.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_glyphs.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_icon.dart';

/// One measurement set in a list. Pass [customerName] on the global
/// list (where the customer isn't obvious); leave it null on a
/// customer's own tab.
class MeasurementCard extends StatelessWidget {
  const MeasurementCard({
    super.key,
    required this.measurement,
    required this.onTap,
    this.customerName,
  });

  final Measurement measurement;
  final VoidCallback onTap;
  final String? customerName;

  @override
  Widget build(BuildContext context) {
    final template = MeasurementTemplates.of(measurement.garmentType);
    final garmentLabel = measurement.garmentType.label;

    final filled = template.fields
        .where((field) => measurement.values.containsKey(field.key))
        .toList();
    final summary = filled
        .take(3)
        .map((f) => '${f.label} ${InchFormat.format(measurement.values[f.key]!)}')
        .join(' · ');
    final extra = filled.length - 3;

    final title = customerName ?? garmentLabel;
    final subtitle = [
      if (customerName != null) garmentLabel,
      if (measurement.label.isNotEmpty) measurement.label,
    ].join(' · ');

    final updatedAt = measurement.updatedAt;
    final date =
    updatedAt == null ? S.current.justNow : AppDates.short(updatedAt);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.pal.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: TailorIcon(
                    TailorGlyphs.garment(measurement.garmentType),
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.pal.slate700),
                      ),
                    if (summary.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        extra > 0 ? S.current.summaryPlusMore(summary, extra) : summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.pal.slate500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                date,
                style: TextStyle(color: context.pal.slate500, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}