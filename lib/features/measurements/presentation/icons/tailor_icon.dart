import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tailor_app/core/theme/app_palette.dart';
import 'package:tailor_app/features/measurements/presentation/icons/tailor_glyph.dart';

/// Draws a [TailorGlyph]: the garment in a muted colour and the measured
/// part (or chosen style) in the accent colour, so it is obvious at a
/// glance where the tape goes.
///
/// Usually shown next to a text label, so it is hidden from screen readers
/// unless [semanticLabel] is given. Not mirrored in right-to-left
/// languages: these are drawings of real garments.
class TailorIcon extends StatelessWidget {
  const TailorIcon(
    this.glyph, {
    super.key,
    this.size = 24,
    this.color,
    this.accentColor,
    this.semanticLabel,
  });

  final TailorGlyph glyph;
  final double size;

  /// The garment outline. Defaults to the muted text colour.
  final Color? color;

  /// The highlighted part. Defaults to the brand colour.
  final Color? accentColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final icon = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _TailorIconPainter(
          glyph: glyph,
          color: color ?? context.pal.slate500,
          accentColor: accentColor ?? context.pal.primary,
        ),
      ),
    );

    if (semanticLabel == null) return ExcludeSemantics(child: icon);
    return Semantics(label: semanticLabel, image: true, child: icon);
  }
}

class _TailorIconPainter extends CustomPainter {
  _TailorIconPainter({
    required this.glyph,
    required this.color,
    required this.accentColor,
  });

  final TailorGlyph glyph;
  final Color color;
  final Color accentColor;

  static const double _grid = 24;
  static const double _outlineWidth = 1.4;
  static const double _accentWidth = 2.0;
  static const double _arrowLength = 1.6;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _grid, size.height / _grid);

    final outline = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _outlineWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final cloth = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final accent = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _accentWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final accentFill = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    for (final data in glyph.body) {
      final path = GlyphPaths.parse(data);
      canvas.drawPath(path, cloth);
      canvas.drawPath(path, outline);
    }
    for (final data in glyph.lines) {
      canvas.drawPath(GlyphPaths.parse(data), outline);
    }

    for (final mark in glyph.marks) {
      switch (mark) {
        case Span(:final from, :final to):
          canvas.drawLine(from, to, accent);
          _arrowHead(canvas, tip: from, away: to, paint: accent);
          _arrowHead(canvas, tip: to, away: from, paint: accent);
        case Tape(:final from, :final to, :final bulge):
          canvas.drawPath(_tapePath(from, to, bulge), accent);
        case Ring(:final center, :final radiusX, :final radiusY):
          canvas.drawOval(
            Rect.fromCenter(
              center: center,
              width: radiusX * 2,
              height: radiusY * 2,
            ),
            accent,
          );
        case Accent(:final path, :final fill):
          final shape = GlyphPaths.parse(path);
          if (fill) canvas.drawPath(shape, accentFill);
          canvas.drawPath(shape, accent);
        case Dot(:final center, :final radius):
          canvas.drawCircle(center, radius, accentFill);
      }
    }

    canvas.restore();
  }

  /// Two short strokes at [tip], pointing back towards [away].
  void _arrowHead(
    Canvas canvas, {
    required Offset tip,
    required Offset away,
    required Paint paint,
  }) {
    final direction = away - tip;
    if (direction.distance == 0) return;
    final angle = direction.direction;
    const spread = 0.55; // about 32 degrees either side
    for (final side in const [-1, 1]) {
      final a = angle + side * spread;
      canvas.drawLine(
        tip,
        tip + Offset(math.cos(a), math.sin(a)) * _arrowLength,
        paint,
      );
    }
  }

  /// A curve from [from] to [to] that bows downwards (towards the viewer
  /// on a front view), the way a tape looks when wrapped around a body.
  Path _tapePath(Offset from, Offset to, double bulge) {
    final mid = (from + to) / 2;
    final delta = to - from;
    var normal = Offset(-delta.dy, delta.dx) / delta.distance;
    if (normal.dy < 0) normal = -normal;
    // A quadratic curve reaches half way to its control point.
    final control = mid + normal * (bulge * 2);
    return Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);
  }

  @override
  bool shouldRepaint(_TailorIconPainter old) =>
      old.glyph != glyph ||
      old.color != color ||
      old.accentColor != accentColor;
}
