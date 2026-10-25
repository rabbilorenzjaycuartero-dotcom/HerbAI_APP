import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/rating_service.dart';
import 'rating_widget.dart';

/// Real, plant-specific reviews from Firestore (RatingService.getReviews),
/// replacing the old static MockData.getReviews() list that showed the
/// same 3 fake reviews on every plant.
class PlantReviewsSection extends StatefulWidget {
  final String plantId;

  const PlantReviewsSection({super.key, required this.plantId});

  @override
  State<PlantReviewsSection> createState() => _PlantReviewsSectionState();
}

class _PlantReviewsSectionState extends State<PlantReviewsSection> {
  List<PlantReview> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final reviews = await RatingService.getReviews(widget.plantId);
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load reviews: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reviews',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (_reviews.isEmpty)
          Text(
            'No reviews yet — be the first to review this plant!',
            style: TextStyle(color: AppTheme.textSecondary),
          )
        else
          ..._reviews.map((review) => Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primaryLight,
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  review.userName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (review.updatedAt != null)
                                  Text(
                                    '${review.updatedAt!.day}/${review.updatedAt!.month}/${review.updatedAt!.year}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          RatingWidget(rating: review.rating, starSize: 14),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        review.comment,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}
