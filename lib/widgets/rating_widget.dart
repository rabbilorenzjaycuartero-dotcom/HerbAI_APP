import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class RatingWidget extends StatelessWidget {
  final double rating;
  final double starSize;
  final bool showText;
  final MainAxisAlignment alignment;

  const RatingWidget({
    super.key,
    required this.rating,
    this.starSize = 16.0,
    this.showText = false,
    this.alignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      children: [
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < rating.floor()
                  ? Icons.star
                  : index < rating
                      ? Icons.star_half
                      : Icons.star_border,
              color: AppTheme.secondary,
              size: starSize,
            );
          }),
        ),
        if (showText)
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              rating.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
      ],
    );
  }
}
