import 'package:flutter/material.dart';

/// The app's logo: your own icon (assets/icon/app_icon.png).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 48, this.inverted = false});

  /// The image used for the app icon everywhere in the app.
  static const String asset = 'assets/icon/app_icon.png';

  final double size;

  /// On the blue brand panel the icon gets a white frame so it stands out.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      ),
    );

    if (!inverted) return image;

    return Container(
      padding: EdgeInsets.all(size * 0.06),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: image,
    );
  }
}