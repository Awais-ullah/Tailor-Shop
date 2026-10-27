import 'package:flutter_test/flutter_test.dart';
import 'package:tailor_app/features/measurements/data/measurement_templates.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_glyph.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_glyphs.dart';

void main() {
  test('every garment has its own drawing', () {
    final names = {
      for (final type in GarmentType.values) TailorGlyphs.garment(type).name,
    };
    expect(names, hasLength(GarmentType.values.length));
    expect(names, isNot(contains(TailorGlyphs.fallback.name)));
  });

  test('every measurement field in every template has its own drawing', () {
    final missing = <String>[];
    for (final type in GarmentType.values) {
      for (final field in MeasurementTemplates.of(type).fields) {
        if (identical(
          TailorGlyphs.field(type, field.key),
          TailorGlyphs.fallback,
        )) {
          missing.add('${type.id}: ${field.key}');
        }
      }
    }
    expect(
      missing,
      isEmpty,
      reason:
          'Add these to _fields in tailor_glyphs.dart:\n'
          '${missing.join('\n')}',
    );
  });

  test('every style option in every template has its own drawing', () {
    final missing = <String>[];
    for (final type in GarmentType.values) {
      for (final group in MeasurementTemplates.of(type).styleGroups) {
        for (final option in group.options) {
          final glyph = TailorGlyphs.style(type, group.key, option.id);
          if (identical(glyph, TailorGlyphs.fallback)) {
            missing.add('${type.id}: ${group.key}.${option.id}');
          }
        }
      }
    }
    expect(
      missing,
      isEmpty,
      reason:
          'Add these to _styles in tailor_glyphs.dart:\n'
          '${missing.join('\n')}',
    );
  });

  test('unknown ids fall back to the tape measure, never to nothing', () {
    expect(
      TailorGlyphs.field(GarmentType.shirtKurta, 'not_a_field'),
      same(TailorGlyphs.fallback),
    );
    expect(
      TailorGlyphs.style(GarmentType.waistcoat, 'collar', 'band'),
      same(TailorGlyphs.fallback),
    );
  });

  test('every glyph path parses', () {
    final glyphs = <TailorGlyph>[
      TailorGlyphs.fallback,
      for (final type in GarmentType.values) ...[
        TailorGlyphs.garment(type),
        for (final field in MeasurementTemplates.of(type).fields)
          TailorGlyphs.field(type, field.key),
        for (final group in MeasurementTemplates.of(type).styleGroups)
          for (final option in group.options)
            TailorGlyphs.style(type, group.key, option.id),
      ],
    ];
    for (final glyph in glyphs) {
      for (final data in [...glyph.body, ...glyph.lines]) {
        expect(
          () => GlyphPaths.parse(data),
          returnsNormally,
          reason: '${glyph.name}: $data',
        );
      }
      for (final mark in glyph.marks.whereType<Accent>()) {
        expect(
          () => GlyphPaths.parse(mark.path),
          returnsNormally,
          reason: '${glyph.name}: ${mark.path}',
        );
      }
    }
  });
}
