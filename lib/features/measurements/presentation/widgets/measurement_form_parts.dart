import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_app/core/errors/app_failure.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/core/utils/app_dates.dart';
import 'package:tailor_app/core/utils/inch_format.dart';
import 'package:tailor_app/core/widgets/adaptive_wrap.dart';
import 'package:tailor_app/core/widgets/app_snackbar.dart';
import 'package:tailor_app/core/widgets/state_views.dart';
import 'package:tailor_app/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:tailor_app/features/measurements/data/measurement_templates.dart';
import 'package:tailor_app/features/measurements/data/models/measurement.dart';
import 'package:tailor_app/features/measurements/presentation/cubit/measurements_cubit.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_glyphs.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_icon.dart';

// Sections of the measurement form screen.

class MeasurementCustomerHeader extends StatelessWidget {
  const MeasurementCustomerHeader({
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
            TailorIcon(TailorGlyphs.garment(garment), size: 32),
          ],
        ),
      ),
    );
  }
}

class CopyFromPreviousBanner extends StatelessWidget {
  const CopyFromPreviousBanner({required this.previous, required this.onCopy});

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

class StyleGroupSection extends StatelessWidget {
  const StyleGroupSection({
    required this.garment,
    required this.group,
    required this.selected,
    required this.onToggle,
  });

  final GarmentType garment;
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
                // The drawing replaces the checkmark: a selected chip is
                // filled, and the icon shows what the style looks like.
                avatar: TailorIcon(
                  TailorGlyphs.style(garment, group.key, option.id),
                  size: 22,
                ),
                showCheckmark: false,
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
class FractionBar extends StatelessWidget {
  const FractionBar({required this.onFraction});

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
