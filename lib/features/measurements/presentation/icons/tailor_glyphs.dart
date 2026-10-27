import 'dart:ui';

import 'package:tailor_app/features/measurements/data/measurement_templates.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_glyph.dart';

/// Every icon used on the measurement screens, looked up by the permanent
/// ids from measurement_templates.dart.
///
/// Field and style icons are keyed per garment: "length" or "side pockets"
/// look different on a kurta and on a shalwar. Anything without its own
/// drawing (old data, a field added later) gets [fallback], a tape measure,
/// so an icon is never blank. test/icons/tailor_glyphs_test.dart checks
/// that every field and style in the templates has a real drawing.
class TailorGlyphs {
  TailorGlyphs._();

  static TailorGlyph garment(GarmentType type) {
    switch (type) {
      case GarmentType.shirtKurta:
        return _kurtaGarment;
      case GarmentType.shalwarTrouser:
        return _shalwarGarment;
      case GarmentType.waistcoat:
        return _waistcoatGarment;
    }
  }

  static TailorGlyph field(GarmentType type, String fieldKey) =>
      _fields[type]?[fieldKey] ?? fallback;

  static TailorGlyph style(GarmentType type, String groupKey, String optionId) =>
      _styles[type]?['$groupKey.$optionId'] ?? fallback;

  /// A tape measure: used whenever nothing more specific exists.
  static const TailorGlyph fallback = TailorGlyph(
    name: 'fallback',
    body: [
      'M3.5 11 C3.5 7.96 5.96 5.5 9 5.5 C12.04 5.5 14.5 7.96 14.5 11 '
          'C14.5 14.04 12.04 16.5 9 16.5 C5.96 16.5 3.5 14.04 3.5 11 Z',
    ],
    lines: [
      'M7.5 11 C7.5 10.17 8.17 9.5 9 9.5 C9.83 9.5 10.5 10.17 10.5 11 '
          'C10.5 11.83 9.83 12.5 9 12.5 C8.17 12.5 7.5 11.83 7.5 11 Z',
      'M13.4 16.5 L13.4 18',
      'M16.2 16.5 L16.2 17.6',
      'M19 16.5 L19 18',
    ],
    marks: [Accent('M9 16.5 L21.6 16.5 L21.6 19.4 L10 19.4')],
  );

  // ---------------------------------------------------------------- shapes

  // Front views on the 24 x 24 grid.
  static const String _kurta =
      'M10 3 L6.5 4.2 L2.6 12.8 L4.6 13.7 L7.3 8.4 L7.3 15.5 L6.9 21 '
      'L17.1 21 L16.7 15.5 L16.7 8.4 L19.4 13.7 L21.4 12.8 L17.5 4.2 '
      'L14 3 Q12 5 10 3 Z';

  static const String _shalwar =
      'M6 3 L18 3 L18 4.6 Q20.2 13 17 21 L13.4 21 L12 10.5 L10.6 21 '
      'L7 21 Q3.8 13 6 4.6 Z';
  static const String _shalwarWaistband = 'M6 4.6 L18 4.6';

  static const String _waistcoat =
      'M9.5 3 L7 4 Q8.6 7.6 6 10 L6 19 L12 20.6 L18 19 L18 10 '
      'Q15.4 7.6 17 4 L14.5 3 L12 11 Z';
  static const String _waistcoatFront = 'M12 11 L12 20.6';

  // Close-ups for style details.
  static const String _neckline =
      'M2 21 L2 14 Q4.5 10.6 8.5 9.4 Q12 11 15.5 9.4 Q19.5 10.6 22 14 '
      'L22 21 Z';
  static const String _placket = 'M12 10.6 L12 21';
  static const List<String> _sleeveEnd = ['M6.5 2 L7 13.5', 'M17.5 2 L17 13.5'];
  static const List<String> _hemSides = ['M5 2 L5 12', 'M19 2 L19 12'];
  static const List<String> _ankle = ['M6.5 2 L6 14', 'M17.5 2 L18 14'];
  static const String _waistcoatUpper =
      'M6 17 L6 10 Q8.6 7.6 7 4 L9.5 3 L12 11 L14.5 3 L17 4 Q15.4 7.6 18 10 '
      'L18 17';

  // -------------------------------------------------------------- garments

  static const TailorGlyph _kurtaGarment = TailorGlyph(
    name: 'garment.shirt_kurta',
    body: [_kurta],
    marks: [Accent('M10 3 Q12 5 14 3'), Accent('M12 4 L12 9.6')],
  );

  static const TailorGlyph _shalwarGarment = TailorGlyph(
    name: 'garment.shalwar_trouser',
    body: [_shalwar],
    marks: [
      Accent('M6 3 L18 3 L18 4.6 L6 4.6 Z', fill: true),
      // The drawstring (nala).
      Accent('M12 4.6 L11.2 7.4'),
      Accent('M12 4.6 L12.8 7.4'),
      // Gathered ankle cuffs.
      Accent('M7 21 L10.6 21'),
      Accent('M13.4 21 L17 21'),
    ],
  );

  static const TailorGlyph _waistcoatGarment = TailorGlyph(
    name: 'garment.waistcoat',
    body: [_waistcoat],
    lines: [_waistcoatFront],
    marks: [
      Accent('M9.5 3 L12 11 L14.5 3'),
      Dot(Offset(12, 13.4), 0.85),
      Dot(Offset(12, 15.8), 0.85),
      Dot(Offset(12, 18.2), 0.85),
    ],
  );

  // ---------------------------------------------------------------- fields

  static const Map<GarmentType, Map<String, TailorGlyph>> _fields = {
    GarmentType.shirtKurta: {
      'length': TailorGlyph(
        name: 'kurta.length',
        body: [_kurta],
        marks: [Span(Offset(12, 4.6), Offset(12, 20.4))],
      ),
      'shoulder': TailorGlyph(
        name: 'kurta.shoulder',
        body: [_kurta],
        marks: [Span(Offset(6.6, 4.8), Offset(17.4, 4.8))],
      ),
      'chest': TailorGlyph(
        name: 'kurta.chest',
        body: [_kurta],
        marks: [Tape(Offset(7.3, 9.4), Offset(16.7, 9.4))],
      ),
      'waist': TailorGlyph(
        name: 'kurta.waist',
        body: [_kurta],
        marks: [Tape(Offset(7.3, 12.6), Offset(16.7, 12.6))],
      ),
      'hip': TailorGlyph(
        name: 'kurta.hip',
        body: [_kurta],
        marks: [Tape(Offset(7.3, 15.8), Offset(16.7, 15.8))],
      ),
      'daman': TailorGlyph(
        name: 'kurta.daman',
        body: [_kurta],
        marks: [Accent('M6.9 21 L17.1 21'), Tape(Offset(7, 19.4), Offset(17, 19.4), bulge: 0.6)],
      ),
      'sleeve': TailorGlyph(
        name: 'kurta.sleeve',
        body: [_kurta],
        marks: [Span(Offset(6.5, 5.2), Offset(3.8, 12.4))],
      ),
      'armhole': TailorGlyph(
        name: 'kurta.armhole',
        body: [_kurta],
        marks: [Ring(Offset(7.0, 6.4), 1.1, 2.3)],
      ),
      'collar': TailorGlyph(
        name: 'kurta.collar',
        body: [_kurta],
        marks: [Ring(Offset(12, 3.5), 2.6, 1.2)],
      ),
      'cuff': TailorGlyph(
        name: 'kurta.cuff',
        body: [_kurta],
        marks: [Accent('M2.95 12 L5.05 12.9 L4.6 13.7 L2.6 12.8 Z', fill: true)],
      ),
    },
    GarmentType.shalwarTrouser: {
      'length': TailorGlyph(
        name: 'shalwar.length',
        body: [_shalwar],
        lines: [_shalwarWaistband],
        marks: [Span(Offset(2.6, 3), Offset(2.6, 21))],
      ),
      'waist': TailorGlyph(
        name: 'shalwar.waist',
        body: [_shalwar],
        marks: [Tape(Offset(6, 3.7), Offset(18, 3.7), bulge: 0.5)],
      ),
      'hip': TailorGlyph(
        name: 'shalwar.hip',
        body: [_shalwar],
        lines: [_shalwarWaistband],
        marks: [Tape(Offset(5.3, 7.9), Offset(18.7, 7.9))],
      ),
      'thigh': TailorGlyph(
        name: 'shalwar.thigh',
        body: [_shalwar],
        lines: [_shalwarWaistband],
        marks: [Tape(Offset(5.1, 12.1), Offset(11.8, 12.1), bulge: 0.7)],
      ),
      'knee': TailorGlyph(
        name: 'shalwar.knee',
        body: [_shalwar],
        lines: [_shalwarWaistband],
        marks: [Tape(Offset(5.4, 15.4), Offset(11.35, 15.4), bulge: 0.7)],
      ),
      'bottom': TailorGlyph(
        name: 'shalwar.bottom',
        body: [_shalwar],
        lines: [_shalwarWaistband],
        marks: [Tape(Offset(6.7, 20.2), Offset(10.7, 20.2), bulge: 0.5)],
      ),
    },
    GarmentType.waistcoat: {
      'length': TailorGlyph(
        name: 'waistcoat.length',
        body: [_waistcoat],
        lines: [_waistcoatFront],
        marks: [Span(Offset(20.6, 3.6), Offset(20.6, 19.4))],
      ),
      'shoulder': TailorGlyph(
        name: 'waistcoat.shoulder',
        body: [_waistcoat],
        lines: [_waistcoatFront],
        marks: [Span(Offset(7.0, 4.4), Offset(17.0, 4.4))],
      ),
      'chest': TailorGlyph(
        name: 'waistcoat.chest',
        body: [_waistcoat],
        lines: [_waistcoatFront],
        marks: [Tape(Offset(6, 11.4), Offset(18, 11.4))],
      ),
      'waist': TailorGlyph(
        name: 'waistcoat.waist',
        body: [_waistcoat],
        lines: [_waistcoatFront],
        marks: [Tape(Offset(6, 15.6), Offset(18, 15.6))],
      ),
      'armhole': TailorGlyph(
        name: 'waistcoat.armhole',
        body: [_waistcoat],
        lines: [_waistcoatFront],
        marks: [Ring(Offset(7.4, 7.0), 1.2, 2.8)],
      ),
    },
  };

  // ---------------------------------------------------------------- styles

  static const Map<GarmentType, Map<String, TailorGlyph>> _styles = {
    GarmentType.shirtKurta: {
      'collar.band': TailorGlyph(
        name: 'kurta.collar.band',
        body: [_neckline],
        lines: [_placket],
        marks: [
          Accent('M8.5 9.4 L8.5 6.2 Q12 5 15.5 6.2 L15.5 9.4 Q12 10.6 8.5 9.4 Z'),
        ],
      ),
      'collar.shirt_collar': TailorGlyph(
        name: 'kurta.collar.shirt_collar',
        body: [_neckline],
        lines: [_placket],
        marks: [
          Accent('M8.6 9.2 L8.6 6.4 Q12 5.2 15.4 6.4 L15.4 9.2'),
          Accent('M8.6 6.6 L7.2 12.2 L12 10.6 L16.8 12.2 L15.4 6.6'),
        ],
      ),
      'collar.round_neck': TailorGlyph(
        name: 'kurta.collar.round_neck',
        body: [_neckline],
        marks: [Accent('M8.5 9.4 Q12 13.6 15.5 9.4')],
      ),
      'cuff.round': TailorGlyph(
        name: 'kurta.cuff.round',
        lines: _sleeveEnd,
        marks: [
          Accent('M7 13.5 L7 18 Q7 20.6 9.6 20.6 L14.4 20.6 Q17 20.6 17 18 '
              'L17 13.5 Z'),
          Dot(Offset(14.4, 17), 0.95),
        ],
      ),
      'cuff.square': TailorGlyph(
        name: 'kurta.cuff.square',
        lines: _sleeveEnd,
        marks: [
          Accent('M7 13.5 L7 20.6 L17 20.6 L17 13.5 Z'),
          Dot(Offset(14.4, 17), 0.95),
        ],
      ),
      'cuff.cuff_link': TailorGlyph(
        name: 'kurta.cuff.cuff_link',
        lines: _sleeveEnd,
        marks: [
          Accent('M7 13.5 L7 20.6 L17 20.6 L17 13.5 Z'),
          Accent('M14.6 17 L19.6 17'),
          Dot(Offset(14.6, 17), 1.0),
          Dot(Offset(20.2, 17), 1.6),
        ],
      ),
      'daman.round': TailorGlyph(
        name: 'kurta.daman.round',
        lines: _hemSides,
        marks: [Accent('M5 12 Q5.6 20.4 12 20.6 Q18.4 20.4 19 12')],
      ),
      'daman.straight': TailorGlyph(
        name: 'kurta.daman.straight',
        lines: _hemSides,
        marks: [Accent('M5 12 L5 20.6 L19 20.6 L19 12')],
      ),
      'pockets.front': TailorGlyph(
        name: 'kurta.pockets.front',
        body: [_kurta],
        marks: [Accent('M13 8.8 L15.6 8.8 L15.6 11.6 Q14.3 12.3 13 11.6 Z')],
      ),
      'pockets.side': TailorGlyph(
        name: 'kurta.pockets.side',
        body: [_kurta],
        marks: [
          Accent('M7.3 13.2 Q9.6 14.8 7.3 16.8'),
          Accent('M16.7 13.2 Q14.4 14.8 16.7 16.8'),
        ],
      ),
    },
    GarmentType.shalwarTrouser: {
      'type.shalwar': TailorGlyph(
        name: 'shalwar.type.shalwar',
        marks: [Accent(_shalwar), Accent(_shalwarWaistband)],
      ),
      'type.pajama': TailorGlyph(
        name: 'shalwar.type.pajama',
        marks: [
          Accent('M6.2 3 L17.8 3 L17.8 4.6 L18.8 21 L13.2 21 L12 9.6 L10.8 21 '
              'L5.2 21 L6.2 4.6 Z'),
          Accent('M6.2 4.6 L17.8 4.6'),
        ],
      ),
      'type.trouser': TailorGlyph(
        name: 'shalwar.type.trouser',
        lines: ['M9 7 L9 20.4', 'M15 7 L15 20.4', 'M12 4.6 L12 8'],
        marks: [
          Accent('M6.8 3 L17.2 3 L17.2 4.6 L16.6 21 L13 21 L12 9.2 L11 21 '
              'L7.4 21 L6.8 4.6 Z'),
          Accent('M6.8 4.6 L17.2 4.6'),
        ],
      ),
      'pockets.side': TailorGlyph(
        name: 'shalwar.pockets.side',
        body: [_shalwar],
        lines: [_shalwarWaistband],
        marks: [Accent('M6.4 6 L8.4 9.6'), Accent('M17.6 6 L15.6 9.6')],
      ),
      'pockets.back': TailorGlyph(
        name: 'shalwar.pockets.back',
        body: [_shalwar],
        lines: [_shalwarWaistband],
        marks: [
          Accent('M7.4 6.4 L10.4 6.4 L10.4 9 L8.9 9.9 L7.4 9 Z'),
          Accent('M13.6 6.4 L16.6 6.4 L16.6 9 L15.1 9.9 L13.6 9 Z'),
        ],
      ),
      'bottom.plain': TailorGlyph(
        name: 'shalwar.bottom.plain',
        lines: [..._ankle, 'M6 18.4 L18 18.4'],
        marks: [Accent('M6 14 L6 20.6 L18 20.6 L18 14')],
      ),
      'bottom.pleated': TailorGlyph(
        name: 'shalwar.bottom.pleated',
        lines: [
          ..._ankle,
          'M7.2 15.4 L7.2 20.6',
          'M9.6 15.4 L9.6 20.6',
          'M12 15.4 L12 20.6',
          'M14.4 15.4 L14.4 20.6',
          'M16.8 15.4 L16.8 20.6',
        ],
        marks: [
          Accent('M6 14 L7.2 15.4 L8.4 14 L9.6 15.4 L10.8 14 L12 15.4 L13.2 14 '
              'L14.4 15.4 L15.6 14 L16.8 15.4 L18 14'),
          Accent('M6 14 L6 20.6 L18 20.6 L18 14'),
        ],
      ),
    },
    GarmentType.waistcoat: {
      'front.straight': TailorGlyph(
        name: 'waistcoat.front.straight',
        lines: [_waistcoatUpper, 'M12 11 L12 20.6'],
        marks: [Accent('M6 17 L6 20.6 L18 20.6 L18 17')],
      ),
      'front.curved': TailorGlyph(
        name: 'waistcoat.front.curved',
        lines: [_waistcoatUpper, 'M12 11 L12 17.6'],
        marks: [
          Accent('M6 17 L6 18.6 Q6.6 21 9.6 20.4 Q11.4 19.8 12 17.6 '
              'Q12.6 19.8 14.4 20.4 Q17.4 21 18 18.6 L18 17'),
        ],
      ),
      'pockets.chest': TailorGlyph(
        name: 'waistcoat.pockets.chest',
        body: [_waistcoat],
        lines: [_waistcoatFront],
        marks: [Accent('M13.6 11.8 L16.6 12.4 L16.4 13.4 L13.4 12.8 Z', fill: true)],
      ),
      'pockets.side': TailorGlyph(
        name: 'waistcoat.pockets.side',
        body: [_waistcoat],
        lines: [_waistcoatFront],
        marks: [
          Accent('M7.2 16 L10.4 16 L10.4 17 L7.2 17 Z', fill: true),
          Accent('M13.6 16 L16.8 16 L16.8 17 L13.6 17 Z', fill: true),
        ],
      ),
    },
  };
}
