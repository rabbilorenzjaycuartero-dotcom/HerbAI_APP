import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Soft rounded-square shapes peeking from the top-right and bottom-left
/// corners, approximating the organic blob background used throughout the
/// app's Figma designs (splash, login, register).
class DecorativeBlobs extends StatelessWidget {
  const DecorativeBlobs({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _blob(alignment: Alignment.topRight, size: 260, offset: const Offset(90, -110)),
        _blob(alignment: Alignment.bottomLeft, size: 300, offset: const Offset(-110, 110)),
      ],
    );
  }

  Widget _blob({
    required Alignment alignment,
    required double size,
    required Offset offset,
  }) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: offset,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(size * 0.4),
          ),
        ),
      ),
    );
  }
}
