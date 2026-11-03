import 'package:cloud_firestore/cloud_firestore.dart';

/// Per-user favorited plant IDs, stored in Firestore under
/// `users/{uid}/favorites/{plantId}` -- mirrors RatingService's per-user
/// data pattern. Only the plant id is stored server-side; PlantProvider
/// resolves ids back to full Plant objects against the already-fetched
/// plant list.
class FavoritesService {
  static final _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _favoritesCollection(String uid) =>
      _firestore.collection('users').doc(uid).collection('favorites');

  static Future<List<String>> getFavoritePlantIds(String uid) async {
    final snap = await _favoritesCollection(uid).get();
    return snap.docs.map((doc) => doc.id).toList();
  }

  static Future<void> addFavorite(String uid, String plantId) {
    return _favoritesCollection(uid).doc(plantId).set({
      'plantId': plantId,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> removeFavorite(String uid, String plantId) {
    return _favoritesCollection(uid).doc(plantId).delete();
  }
}
