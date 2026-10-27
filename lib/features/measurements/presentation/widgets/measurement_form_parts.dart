import 'package:flutter/material.dart';
import 'package:tailor_app/core/l10n/app_strings.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/core/utils/app_dates.dart';
import 'package:tailor_app/features/measurements/data/measurement_templates.dart';
import 'package:tailor_app/features/measurements/data/models/measurement.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_glyph.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_glyphs.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_icon.dart';

// Sections of the measurement form screen.

class MeasurementCustomerHeader extends StatelessWidget {
  const MeasurementCustomerHeader({
    super.key,
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
  const CopyFromPreviousBanner({
    super.key,
    required this.previous,
    required this.onCopy,
  });

  final Measurement previous;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final updatedAt = previous.updatedAt;
    final date = updatedAt == null
        ? S.current.justNow
        : AppDates.medium(updatedAt);
    final name = previous.label.isEmpty
        ? S.current.theLastSet
        : '"${previous.label}"';

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
    super.key,
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
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final option in group.options)
              StyleOptionTile(
                glyph: TailorGlyphs.style(garment, group.key, option.id),
                label: option.label,
                selected: selected.contains(option.id),
                onTap: () =>
                    onToggle(option.id, !selected.contains(option.id)),
              ),
          ],
        ),
      ],
    );
  }
}

/// One style choice (a collar, a cuff...): a large drawing with the name
/// under it. The drawing always sits on a light circle, so it stays easy
/// to see when the tile is selected.
class StyleOptionTile extends StatelessWidget {
  const StyleOptionTile({
    super.key,
    required this.glyph,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final TailorGlyph glyph;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const double width = 100;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: selected
          ? BorderSide(color: pal.brand, width: 2)
          : BorderSide(color: pal.slate200),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                decoration: ShapeDecoration(
                  color: selected ? pal.primarySoft : pal.surface,
                  shape: shape,
                ),
                child: Material(
                  type: MaterialType.transparency,
                  shape: shape,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 56,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected ? pal.surface : pal.slate50,
                              shape: BoxShape.circle,
                            ),
                            child: TailorIcon(glyph, size: 40),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.2,
                              fontWeight: FontWeight.w600,
                              color: selected ? pal.primary : pal.slate900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                top: 6,
                end: 6,
                child: IgnorePointer(
                  child: AnimatedScale(
                    scale: selected ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: pal.brand,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: AppColors.gold,
                      ),
                    ),
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

/// Quick fraction buttons shown above the keyboard while a measurement
/// field is focused. Phone number keypads have no "/" or "½" key.
class FractionBar extends StatelessWidget {
  const FractionBar({super.key, required this.onFraction});

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
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: context.pal.surface,
          border: Border(top: BorderSide(color: context.pal.slate200)),
        ),
        child: Row(
          children: [
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsetsDirectional.fromSTEB(12, 8, 4, 8),
                children: [
                  for (var eighths = 0; eighths < _labels.length; eighths++)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ActionChip(
                        labelPadding:
                            const EdgeInsets.symmetric(horizontal: 6),
                        label: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 28),
                          child: Text(
                            _labels[eighths],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        onPressed: () => onFraction(eighths),
                      ),
                    ),
                ],
              ),
            ),
            // Pinned at the end: closes the keyboard (and so this bar).
            IconButton(
              tooltip: S.current.hideKeyboard,
              icon: Icon(
                Icons.keyboard_hide_outlined,
                color: context.pal.primary,
              ),
              onPressed: () => FocusScope.of(context).unfocus(),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
