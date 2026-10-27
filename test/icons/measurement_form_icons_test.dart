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
        expect(find.byType(FilterChip), findsNWidgets(options));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
