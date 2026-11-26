import 'package:flutter/material.dart';

/// The HerbAI logo (assets/images/herbai_logo.png) as a rounded square.
/// Used at the app's brand spots: splash, login, register, About, app bar.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    // Decode at roughly the displayed pixel size instead of the full
    // 1024px source, so a 32px app-bar logo doesn't hold a 4 MB bitmap.
    final cachePx = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.2),
      child: Image.asset(
        'assets/images/herbai_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: cachePx,
        cacheHeight: cachePx,
      ),
    );
  }
}
