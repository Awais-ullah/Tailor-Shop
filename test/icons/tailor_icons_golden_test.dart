@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailor_app/core/theme/app_theme.dart';
import 'package:tailor_app/features/measurements/data/measurement_templates.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_glyph.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_glyphs.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_icon.dart';

/// A picture of every measurement icon, for reviewing the drawings.
/// Regenerate after changing a glyph with:
///
///   flutter test --update-goldens test/icons/tailor_icons_golden_test.dart
///
/// Anti-aliasing differs between operating systems, so compare these on
/// the machine that generated them.
void main() {
  List<TailorGlyph> rowFor(GarmentType type) {
    final template = MeasurementTemplates.of(type);
    return [
      TailorGlyphs.garment(type),
      for (final field in template.fields) TailorGlyphs.field(type, field.key),
    ];
  }

  List<TailorGlyph> stylesFor(GarmentType type) {
    final template = MeasurementTemplates.of(type);
    return [
      for (final group in template.styleGroups)
        for (final option in group.options)
          TailorGlyphs.style(type, group.key, option.id),
    ];
  }

  final rows = [
    for (final type in GarmentType.values) rowFor(type),
    for (final type in GarmentType.values) stylesFor(type),
    [TailorGlyphs.fallback],
  ];

  Widget gallery(ThemeData theme, double size) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      for (final glyph in row)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: TailorIcon(glyph, size: size),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> capture(
    WidgetTester tester,
    ThemeData theme,
    double size,
    String file,
  ) async {
    final longest = rows.map((row) => row.length).reduce((a, b) => a > b ? a : b);
    final width = 16 + longest * (size + 6);
    final height = 16 + rows.length * (size + 6);
    await tester.binding.setSurfaceSize(Size(width, height));
    tester.view.devicePixelRatio = 1;
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(gallery(theme, size));
    await expectLater(find.byType(Scaffold), matchesGoldenFile(file));
  }

  testWidgets('measurement icons, light, large', (tester) async {
    await capture(tester, AppTheme.light, 64, 'goldens/icons_light_64.png');
  });

  testWidgets('measurement icons, dark, large', (tester) async {
    await capture(tester, AppTheme.dark, 64, 'goldens/icons_dark_64.png');
  });

  testWidgets('measurement icons, light, actual size', (tester) async {
    await capture(tester, AppTheme.light, 28, 'goldens/icons_light_28.png');
  });
}
