import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailor_app/core/theme/app_theme.dart';
import 'package:tailor_app/features/measurements/data/measurement_templates.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_icon.dart';
import 'package:tailor_app/features/measurements/presentation/widgets/measurement_form_parts.dart';

/// The measurement form needs Firebase, but its parts don't: render them
/// for every garment, on a phone-sized screen, at normal and large text,
/// and make sure every option shows its drawing without overflowing.
void main() {
  Future<void> pump(WidgetTester tester, Widget child, double textScale) async {
    await tester.binding.setSurfaceSize(const Size(360, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(360, 1400),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  for (final scale in [1.0, 1.5]) {
    for (final garment in GarmentType.values) {
      testWidgets('${garment.id} style chips show icons at ${scale}x text', (
        tester,
      ) async {
        final groups = MeasurementTemplates.of(garment).styleGroups;
        await pump(
          tester,
          Column(
            children: [
              MeasurementCustomerHeader(
                name: 'Ali Khan',
                initial: 'A',
                garment: garment,
              ),
              for (final group in groups)
                StyleGroupSection(
                  garment: garment,
                  group: group,
                  selected: {group.options.first.id},
                  onToggle: (_, _) {},
                ),
            ],
          ),
          scale,
        );

        final options = groups.fold<int>(0, (n, g) => n + g.options.length);
        // One icon per option, plus the garment in the header.
        expect(find.byType(TailorIcon), findsNWidgets(options + 1));
        expect(find.byType(StyleOptionTile), findsNWidgets(options));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('tapping a style tile toggles it and reports selection', (
    tester,
  ) async {
    final group = MeasurementTemplates.of(GarmentType.values.first)
        .styleGroups
        .first;
    final first = group.options.first;
    final calls = <(String, bool)>[];

    await pump(
      tester,
      StyleGroupSection(
        garment: GarmentType.values.first,
        group: group,
        selected: {first.id},
        onToggle: (id, isSelected) => calls.add((id, isSelected)),
      ),
      1.0,
    );

    expect(
      tester.getSemantics(find.byType(StyleOptionTile).first),
      matchesSemantics(
        label: first.label,
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
      ),
    );

    // Tapping the selected tile deselects it; another one selects it.
    await tester.tap(find.text(first.label));
    await tester.tap(find.text(group.options[1].label));
    expect(calls, [(first.id, false), (group.options[1].id, true)]);
  });
}
