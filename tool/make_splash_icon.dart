// Run once with:  dart run tool/make_splash_icon.dart
// Makes assets/icon/splash_icon.png: your icon centred on a transparent
// 1152x1152 canvas, small enough to sit inside Android's splash circle.
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  const canvasSize = 1152;
  const iconSize = 540;

  final file = File('assets/icon/app_icon.png');
  if (!file.existsSync()) {
    stderr.writeln('Could not find assets/icon/app_icon.png');
    exit(1);
  }

  final source = img.decodePng(file.readAsBytesSync());
  if (source == null) {
    stderr.writeln('assets/icon/app_icon.png is not a valid PNG');
    exit(1);
  }

  // Fit the icon inside iconSize x iconSize, keeping its proportions.
  final longest = source.width > source.height ? source.width : source.height;
  final scale = iconSize / longest;
  final width = (source.width * scale).round();
  final height = (source.height * scale).round();

  final resized = img.copyResize(
    source,
    width: width,
    height: height,
    interpolation: img.Interpolation.cubic,
  );

  final canvas = img.Image(width: canvasSize, height: canvasSize, numChannels: 4);
  img.compositeImage(
    canvas,
    resized,
    dstX: (canvasSize - width) ~/ 2,
    dstY: (canvasSize - height) ~/ 2,
  );

  File('assets/icon/splash_icon.png').writeAsBytesSync(img.encodePng(canvas));
  stdout.writeln('Created assets/icon/splash_icon.png');
}