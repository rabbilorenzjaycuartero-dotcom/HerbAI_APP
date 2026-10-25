import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class RatingWidget extends StatelessWidget {
  final double rating;
  final double starSize;
  final bool showText;
  final MainAxisAlignment alignment;
  // When set, each star becomes tappable (1-5) instead of a read-only
  // display -- used by PlantRatingSection to let the user submit their own
  // rating, while every other call site (plant cards, review list entries)
  // leaves this null and stays purely decorative.
  final ValueChanged<int>? onRatingSelected;

  const RatingWidget({
    super.key,
    required this.rating,
    this.starSize = 16.0,
    this.showText = false,
    this.alignment = MainAxisAlignment.start,
    this.onRatingSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      children: [
        Row(
          children: List.generate(5, (index) {
            final star = Icon(
              index < rating.floor()
                  ? Icons.star
                  : index < rating
                      ? Icons.star_half
                      : Icons.star_border,
              color: AppTheme.secondary,
              size: starSize,
            );
            if (onRatingSelected == null) return star;
            return GestureDetector(
              onTap: () => onRatingSelected!(index + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: star,
              ),
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
