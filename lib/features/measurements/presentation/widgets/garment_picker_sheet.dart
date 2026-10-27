import 'package:flutter/material.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/features/measurements/data/measurement_templates.dart';

import 'package:tailor_app/core/l10n/app_strings.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_glyphs.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_icon.dart';

/// Bottom sheet asking which garment the measurements are for.
Future<GarmentType?> showGarmentPicker(BuildContext context) {
  return showModalBottomSheet<GarmentType>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (sheetContext) {
      return SafeArea(
        // Scrolls on very short screens (for example a phone in landscape).
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 8),
                child: Text(
                  S.current.chooseGarment,
                  style: Theme.of(sheetContext)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              for (final type in GarmentType.values)
                ListTile(
                  minTileHeight: 56,
                  leading: TailorIcon(TailorGlyphs.garment(type), size: 32),
                  title: Text(type.label),
                  trailing:
                  Icon(Icons.chevron_right, color: context.pal.slate500),
                  onTap: () => Navigator.pop(sheetContext, type),
                ),
            ],
          ),
        ),
      );
    },
  );
}