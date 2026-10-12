import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:tailor_app/core/router/splash_gate.dart';
import 'package:tailor_app/core/theme/app_colors.dart';
import 'package:tailor_app/core/widgets/app_logo.dart';

/// Continues the phone's own splash: your icon starts exactly where the
/// native splash left it (centre of the screen), then lifts up while a
/// needle stitches a line beneath it and "Tailor Shop" appears.
/// When it finishes it opens [gate] so the router can move on.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.gate});

  final SplashGate gate;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Tweak these to taste.
  static const Duration _duration = Duration(milliseconds: 1900);
  static const double _iconBox = 110; // final icon size
  static const double _stitchWidth = 220;

  /// The icon's size in the phone's native splash, so the first frame
  /// matches it. Change this if your icon looks like it "jumps" at the start.
  static const double _nativeIconSize = 135;

  // Fixed heights, so the starting position can be calculated exactly.
  static const double _gapAfterIcon = 24;
  static const double _stitchHeight = 32;
  static const double _gapAfterStitch = 12;
  static const double _titleHeight = 64;
  static const double _gapAfterTitle = 24;
  static const double _loaderSize = 24;

  static const double _groupHeight = _iconBox +
      _gapAfterIcon +
      _stitchHeight +
      _gapAfterStitch +
      _titleHeight +
      _gapAfterTitle +
      _loaderSize;

  /// How far DOWN the whole group starts, so the icon sits at the exact
  /// centre of the screen, just like in the native splash.
  static const double _startOffset = _groupHeight / 2 - _iconBox / 2;

  late final AnimationController _controller;
  late final Animation<double> _lift;
  late final Animation<double> _stitch;
  late final Animation<double> _titleFade;
  late final Animation<double> _loaderFade;

  bool _started = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: _duration);

    // Each part of the animation owns a slice of the timeline (0.0 - 1.0).
    _lift = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.06, 0.42, curve: Curves.easeInOutCubic),
    );
    _stitch = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.32, 0.80, curve: Curves.easeInOut),
    );
    _titleFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.72, 0.95, curve: Curves.easeOut),
    );
    _loaderFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.90, 1.0, curve: Curves.easeIn),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _prepareAndPlay();
  }

  Future<void> _prepareAndPlay() async {
    // Load the icon BEFORE the phone's splash is removed, so there is no
    // blank flash between the two.
    try {
      await precacheImage(const AssetImage(AppLogo.asset), context);
    } catch (_) {
      // If the image fails to load we still carry on.
    }
    if (!mounted) return;

    FlutterNativeSplash.remove();

    final reduceMotion = WidgetsBinding
        .instance.platformDispatcher.accessibilityFeatures.disableAnimations;

    if (reduceMotion) {
      // Respect the phone's "remove animations" setting.
      _controller.value = 1.0;
      Future.delayed(const Duration(milliseconds: 300), widget.gate.open);
    } else {
      _controller.forward().whenComplete(() {
        // A short pause on the finished frame, then continue.
        Future.delayed(const Duration(milliseconds: 150), widget.gate.open);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const startScale = _nativeIconSize / _iconBox;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        // FittedBox shrinks everything slightly on a very small screen
        // instead of overflowing.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final lift = _lift.value;

                return Transform.translate(
                  offset: Offset(0, _startOffset * (1 - lift)),
                  child: SizedBox(
                    height: _groupHeight,
                    child: Column(
                      children: [
                        Transform.scale(
                          scale: startScale + (1 - startScale) * lift,
                          child: Image.asset(
                            AppLogo.asset,
                            width: _iconBox,
                            height: _iconBox,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                        const SizedBox(height: _gapAfterIcon),
                        SizedBox(
                          width: _stitchWidth,
                          height: _stitchHeight,
                          child: CustomPaint(
                            painter: _StitchPainter(progress: _stitch.value),
                          ),
                        ),
                        const SizedBox(height: _gapAfterStitch),
                        SizedBox(
                          height: _titleHeight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Opacity(
                              opacity: _titleFade.value.clamp(0.0, 1.0),
                              child: Transform.translate(
                                offset: Offset(0, 12 * (1 - _titleFade.value)),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Tailor Shop',
                                      style: textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Orders · Measurements · Payments',
                                      style: textTheme.bodyMedium
                                          ?.copyWith(color: AppColors.slate500),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: _gapAfterTitle),
                        Opacity(
                          opacity: _loaderFade.value.clamp(0.0, 1.0),
                          child: const SizedBox(
                            width: _loaderSize,
                            height: _loaderSize,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws a dashed "stitch" line up to [progress] (0 - 1), with a needle
/// at the leading edge that bobs up and down and trails a thread.
class _StitchPainter extends CustomPainter {
  const _StitchPainter({required this.progress});

  final double progress;

  static const double _dash = 10;
  static const double _gap = 8;
  static const double _needleAngle = 0.6;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final y = size.height / 2;
    final progressX = size.width * progress;

    // The stitches the needle has already made.
    final stitchPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (var x = 0.0; x < progressX; x += _dash + _gap) {
      final end = math.min(x + _dash, progressX);
      canvas.drawLine(Offset(x, y), Offset(end, y), stitchPaint);
    }

    // The needle fades out as it reaches the end of the line.
    final needleOpacity =
    progress >= 0.92 ? ((1 - progress) / 0.08).clamp(0.0, 1.0) : 1.0;
    if (needleOpacity <= 0) return;

    // Dips up and down like it is going in and out of the fabric.
    final bob = math.sin(progress * math.pi * 2 * 6) * 5;
    final center = Offset(progressX, y + bob);

    // Thread trailing back from the needle's eye.
    final eye = center +
        Offset(
          -10 * math.cos(_needleAngle),
          -10 * math.sin(_needleAngle),
        );
    final tail = Offset(math.max(0, progressX - 46), y - 2);
    final threadPath = Path()
      ..moveTo(eye.dx, eye.dy)
      ..quadraticBezierTo(eye.dx - 14, eye.dy - 14, tail.dx, tail.dy);
    canvas.drawPath(
      threadPath,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.7 * needleOpacity)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // The needle itself.
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_needleAngle);
    canvas.drawLine(
      const Offset(-14, 0),
      const Offset(14, 0),
      Paint()
        ..color = AppColors.slate700.withValues(alpha: needleOpacity)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(-10, 0), width: 5, height: 2.5),
      Paint()
        ..color = Colors.white.withValues(alpha: needleOpacity)
        ..style = PaintingStyle.fill,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StitchPainter oldDelegate) =>
      oldDelegate.progress != progress;
}