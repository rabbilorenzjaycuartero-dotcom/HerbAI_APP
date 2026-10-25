import 'package:cloud_firestore/cloud_firestore.dart';

class PlantRatingAggregate {
  final double average;
  final int count;

  const PlantRatingAggregate({required this.average, required this.count});

  static const empty = PlantRatingAggregate(average: 0, count: 0);
}

/// A single user's rating of a plant, with whatever comment they wrote.
/// Used both for "my own rating" (pre-filling PlantRatingSection) and for
/// the public reviews list (PlantReviewsSection) -- `userName`/`updatedAt`
/// only matter for the latter.
class PlantReview {
  final String userName;
  final double rating;
  final String comment;
  final DateTime? updatedAt;

  const PlantReview({
    required this.userName,
    required this.rating,
    required this.comment,
    required this.updatedAt,
  });
}

/// Per-user, per-plant star ratings, stored in Firestore (the only piece of
/// this app's data that's genuinely per-user-generated, unlike the shared
/// herb/symptom data served by the Flask API). One rating per user per
/// plant: `plant_ratings/{plantId}` holds the running total/count so the
/// average can be read without summing every individual rating, and
/// `plant_ratings/{plantId}/userRatings/{uid}` holds that user's own
/// current rating + comment, so it can both be shown back to them and be
/// subtracted out of the running total if they change it later.
class RatingService {
  static final _firestore = FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> _plantDoc(String plantId) =>
      _firestore.collection('plant_ratings').doc(plantId);

  static Future<PlantRatingAggregate> getAggregate(String plantId) async {
    final snap = await _plantDoc(plantId).get();
    if (!snap.exists) return PlantRatingAggregate.empty;
    final data = snap.data()!;
    final count = (data['count'] as num?)?.toInt() ?? 0;
    if (count == 0) return PlantRatingAggregate.empty;
    final total = (data['totalScore'] as num?)?.toDouble() ?? 0;
    return PlantRatingAggregate(average: total / count, count: count);
  }

  static Future<PlantReview?> getUserReview(String plantId, String uid) async {
    final snap = await _plantDoc(plantId).collection('userRatings').doc(uid).get();
    if (!snap.exists) return null;
    final data = snap.data()!;
    return PlantReview(
      userName: data['userName'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      comment: data['comment'] as String? ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Reviews people actually wrote something for -- a bare star tap with no
  /// comment contributes to the average but isn't shown as a "review".
  static Future<List<PlantReview>> getReviews(String plantId) async {
    final snap = await _plantDoc(plantId)
        .collection('userRatings')
        .orderBy('updatedAt', descending: true)
        .get();
    return snap.docs
        .map((doc) {
          final data = doc.data();
          return PlantReview(
            userName: data['userName'] as String? ?? 'Anonymous',
            rating: (data['rating'] as num?)?.toDouble() ?? 0,
            comment: data['comment'] as String? ?? '',
            updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
          );
        })
        .where((review) => review.comment.trim().isNotEmpty)
        .toList();
  }

  /// Submits or updates the given user's rating/comment for a plant,
  /// atomically adjusting the plant's running total/count in the same
  /// transaction so concurrent ratings from other users can't race.
  static Future<void> submitRating({
    required String plantId,
    required String uid,
    required double rating,
    required String comment,
    required String userName,
  }) async {
    final plantRef = _plantDoc(plantId);
    final userRatingRef = plantRef.collection('userRatings').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRatingRef);
      final plantSnap = await transaction.get(plantRef);

      final oldRating = userSnap.exists
          ? (userSnap.data()!['rating'] as num?)?.toDouble()
          : null;
      final currentTotal = plantSnap.exists
          ? (plantSnap.data()!['totalScore'] as num?)?.toDouble() ?? 0
          : 0.0;
      final currentCount = plantSnap.exists
          ? (plantSnap.data()!['count'] as num?)?.toInt() ?? 0
          : 0;

      final newTotal = oldRating == null
          ? currentTotal + rating
          : currentTotal - oldRating + rating;
      final newCount = oldRating == null ? currentCount + 1 : currentCount;

      transaction.set(plantRef, {'totalScore': newTotal, 'count': newCount});
      transaction.set(userRatingRef, {
        'rating': rating,
        'comment': comment,
        'userName': userName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
