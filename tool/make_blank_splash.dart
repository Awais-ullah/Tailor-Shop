// Run once with:  dart run tool/make_blank_splash.dart
// Makes assets/icon/splash_blank.png: a fully transparent image, so the
// phone's own splash shows nothing but a plain white screen.
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  // A new 4-channel image starts fully transparent.
  final canvas = img.Image(width: 1152, height: 1152, numChannels: 4);

  File('assets/icon/splash_blank.png').writeAsBytesSync(img.encodePng(canvas));
  stdout.writeln('Created assets/icon/splash_blank.png');
}