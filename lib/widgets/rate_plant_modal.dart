import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/firebase_auth_service.dart';
import '../services/rating_service.dart';
import 'custom_button.dart';
import 'rating_widget.dart';

/// The actual rate-and-comment input, shown as a modal bottom sheet (opened
/// from PlantRatingSection's "Rate & Review" button) instead of sitting
/// inline on the page, so Plant Details stays a clean summary + list.
class RatePlantModal extends StatefulWidget {
  final String plantId;
  final double initialRating;
  final String initialComment;
  final VoidCallback onPosted;

  const RatePlantModal({
    super.key,
    required this.plantId,
    required this.initialRating,
    required this.initialComment,
    required this.onPosted,
  });

  static Future<void> show(
    BuildContext context, {
    required String plantId,
    required double initialRating,
    required String initialComment,
    required VoidCallback onPosted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => RatePlantModal(
        plantId: plantId,
        initialRating: initialRating,
        initialComment: initialComment,
        onPosted: onPosted,
      ),
    );
  }

  @override
  State<RatePlantModal> createState() => _RatePlantModalState();
}

class _RatePlantModalState extends State<RatePlantModal> {
  late final TextEditingController _commentController =
      TextEditingController(text: widget.initialComment);
  late double _pendingRating = widget.initialRating;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _postReview() async {
    final user = FirebaseAuthService.currentUser;
    if (user?.uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to rate this plant.')),
      );
      return;
    }
    if (_pendingRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tap a star to choose a rating first.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await RatingService.submitRating(
        plantId: widget.plantId,
        uid: user!.uid!,
        rating: _pendingRating,
        comment: _commentController.text.trim(),
        userName: user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : 'Herbal Enthusiast',
      );
      if (!mounted) return;
      widget.onPosted();
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Failed to submit rating: $e');
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save your rating. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Rate this plant',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Center(
            child: RatingWidget(
              rating: _pendingRating,
              starSize: 36,
              onRatingSelected: _isSubmitting
                  ? null
                  : (stars) => setState(() => _pendingRating = stars.toDouble()),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            enabled: !_isSubmitting,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Share your experience with this plant (optional)',
              filled: true,
              fillColor: AppTheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Post Review',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _postReview,
            ),
          ),
        ],
      ),
    );
  }
}
