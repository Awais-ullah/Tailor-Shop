import 'dart:ui';

/// One drawing for [TailorIcon], on a 24 x 24 grid.
///
/// A glyph has two layers:
/// - the garment, drawn in the muted outline colour ([body] shapes get a
///   light fill so the garment reads as a solid piece of cloth), and
/// - [marks], drawn in the accent colour: the part being measured or the
///   style detail being chosen.
///
/// Paths are written like SVG path data, using absolute M, L, Q, C and Z
/// commands only, e.g. 'M10 3 L6.5 4.2 Q12 5 10 3 Z'.
class TailorGlyph {
  const TailorGlyph({
    required this.name,
    this.body = const [],
    this.lines = const [],
    this.marks = const [],
  });

  /// For tests and debugging only; never shown to users.
  final String name;

  /// Closed garment shapes: outline colour, stroked, lightly filled.
  final List<String> body;

  /// Garment seams and details: outline colour, stroked, never filled.
  final List<String> lines;

  /// What the icon is about, in the accent colour.
  final List<GlyphMark> marks;

  @override
  String toString() => 'TailorGlyph($name)';
}

/// Something drawn in the accent colour.
sealed class GlyphMark {
  const GlyphMark();
}

/// A straight measurement with an arrowhead at each end
/// (lengths, shoulder, sleeve).
class Span extends GlyphMark {
  const Span(this.from, this.to);

  final Offset from;
  final Offset to;
}

/// A tape wrapped around the body between two edges (chest, waist,
/// thigh...). It bows towards the viewer by [bulge] to read as "around".
class Tape extends GlyphMark {
  const Tape(this.from, this.to, {this.bulge = 0.9});

  final Offset from;
  final Offset to;
  final double bulge;
}

/// A loop (collar, armhole).
class Ring extends GlyphMark {
  const Ring(this.center, this.radiusX, this.radiusY);

  final Offset center;
  final double radiusX;
  final double radiusY;
}

/// A free shape in the accent colour, stroked, and filled when [fill] is
/// true (buttons, cufflinks).
class Accent extends GlyphMark {
  const Accent(this.path, {this.fill = false});

  final String path;
  final bool fill;
}

/// A small filled circle (buttons).
class Dot extends GlyphMark {
  const Dot(this.center, [this.radius = 0.75]);

  final Offset center;
  final double radius;
}

/// Turns glyph path data into [Path]s. Parsed once per string and cached,
/// because the same garment outline is reused by many glyphs.
class GlyphPaths {
  GlyphPaths._();

  static final Map<String, Path> _cache = {};

  static final RegExp _token = RegExp(r'[MLQCZ]|-?\d*\.?\d+');

  static Path parse(String data) => _cache.putIfAbsent(data, () => _parse(data));

  static Path _parse(String data) {
    final tokens = _token.allMatches(data).map((m) => m.group(0)!).toList();
    final path = Path();
    var i = 0;
    var command = 'M';

    double next() {
      if (i >= tokens.length) {
        throw FormatException('Glyph path ended too early: "$data"');
      }
      return double.parse(tokens[i++]);
    }

    while (i < tokens.length) {
      final token = tokens[i];
      if (RegExp(r'^[MLQCZ]$').hasMatch(token)) {
        command = token;
        i++;
        if (command == 'Z') {
          path.close();
          continue;
        }
      }
      switch (command) {
        case 'M':
          path.moveTo(next(), next());
          // Extra pairs after M are lines, as in SVG.
          command = 'L';
        case 'L':
          path.lineTo(next(), next());
        case 'Q':
          path.quadraticBezierTo(next(), next(), next(), next());
        case 'C':
          path.cubicTo(next(), next(), next(), next(), next(), next());
        default:
          throw FormatException('Unexpected "$token" in glyph path "$data"');
      }
    }
    return path;
  }
}
