import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/firebase_auth_service.dart';
import '../services/rating_service.dart';
import 'rate_plant_modal.dart';
import 'rating_widget.dart';

/// Shows a plant's real average rating (from Firestore, across every user
/// who's rated it) plus a button that opens RatePlantModal to actually rate
/// and comment -- keeping Plant Details itself a clean summary rather than
/// an always-expanded star-picker + text box.
class PlantRatingSection extends StatefulWidget {
  final String plantId;
  final VoidCallback? onReviewPosted;

  const PlantRatingSection({super.key, required this.plantId, this.onReviewPosted});

  @override
  State<PlantRatingSection> createState() => _PlantRatingSectionState();
}

class _PlantRatingSectionState extends State<PlantRatingSection> {
  PlantRatingAggregate _aggregate = PlantRatingAggregate.empty;
  double _myRating = 0;
  String _myComment = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuthService.currentUser?.uid;
    try {
      final results = await Future.wait([
        RatingService.getAggregate(widget.plantId),
        if (uid != null) RatingService.getUserReview(widget.plantId, uid),
      ]);
      if (!mounted) return;
      final myReview = results.length > 1 ? results[1] as PlantReview? : null;
      setState(() {
        _aggregate = results[0] as PlantRatingAggregate;
        _myRating = myReview?.rating ?? 0;
        _myComment = myReview?.comment ?? '';
        _isLoading = false;
      });
    } catch (e) {
      // Firestore being unreachable (not yet enabled for this project,
      // no connectivity) shouldn't crash the whole plant details screen --
      // fall back to an empty/unrated state, same as any herb nobody's
      // rated yet.
      debugPrint('Failed to load plant rating: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _openRateModal() {
    RatePlantModal.show(
      context,
      plantId: widget.plantId,
      initialRating: _myRating,
      initialComment: _myComment,
      onPosted: () {
        _load();
        widget.onReviewPosted?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 20,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(child: RatingWidget(rating: _aggregate.average, showText: true)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '(${_aggregate.count} ${_aggregate.count == 1 ? 'rating' : 'ratings'})',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildRateButton(),
      ],
    );
  }

  // A soft tinted pill-chip, matching the look already used for the
  // selected-symptom chips elsewhere in the app, instead of a bare
  // outlined CustomButton that read as flat/plain here.
  Widget _buildRateButton() {
    final isEditing = _myRating > 0;
    return Material(
      color: AppTheme.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _openRateModal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isEditing ? Icons.edit_rounded : Icons.star_border_rounded,
                size: 16,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                isEditing ? 'Edit Review' : 'Rate & Review',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
