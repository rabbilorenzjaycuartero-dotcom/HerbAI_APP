import 'package:flutter/foundation.dart';
import '../models/plant_model.dart';
import '../services/api_service.dart';
import '../services/favorites_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';

class PlantProvider with ChangeNotifier {
  List<Plant> _plants = [];
  List<Plant> _favorites = [];
  final List<String> _recentSearches = [];
  bool _isLoading = false;

  List<Plant> get plants => _plants;
  List<Plant> get favorites => _favorites;
  List<String> get recentSearches => _recentSearches;
  bool get isLoading => _isLoading;

  PlantProvider() {
    _loadData();
    // Favorites live in Firestore per-user, so they need (re)loading
    // whenever who's signed in changes -- not just once at startup.
    try {
      FirebaseAuthService.authStateChanges().listen((_) => _loadFavorites());
    } catch (e) {
      debugPrint('Failed to listen to auth changes in PlantProvider: $e');
    }
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _plants = await ApiService.fetchAllPlants();
    } catch (e) {
      debugPrint('Failed to load plants: $e');
      _plants = [];
    }
    _isLoading = false;
    notifyListeners();
    await _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final uid = FirebaseAuthService.currentUser?.uid;
    if (uid == null) {
      _favorites = [];
      notifyListeners();
      return;
    }
    try {
      final ids = await FavoritesService.getFavoritePlantIds(uid);
      _favorites = _plants.where((plant) => ids.contains(plant.id)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load favorites: $e');
    }
  }

  List<Plant> searchPlants(String query) {
    if (query.isEmpty) return <Plant>[];
    return _plants
        .where((plant) =>
            plant.name.toLowerCase().contains(query.toLowerCase()) ||
            plant.scientificName.toLowerCase().contains(query.toLowerCase()) ||
            plant.categories.any((cat) =>
                cat.toLowerCase().contains(query.toLowerCase())))
        .toList();
  }

  Future<void> toggleFavorite(Plant plant) async {
    final isNowFavorite = !_favorites.contains(plant);
    if (isNowFavorite) {
      _favorites.add(plant);
    } else {
      _favorites.remove(plant);
    }
    notifyListeners();

    final notificationsEnabled = await SettingsService.getNotificationsEnabled();
    if (isNowFavorite && notificationsEnabled) {
      NotificationService.scheduleFavoriteRevisitReminder(plant);
    } else {
      NotificationService.cancelFavoriteRevisitReminder(plant);
    }

    final uid = FirebaseAuthService.currentUser?.uid;
    if (uid == null) return;
    try {
      if (isNowFavorite) {
        await FavoritesService.addFavorite(uid, plant.id);
      } else {
        await FavoritesService.removeFavorite(uid, plant.id);
      }
    } catch (e) {
      debugPrint('Failed to sync favorite to Firestore: $e');
    }
  }

  bool isFavorite(Plant plant) {
    return _favorites.contains(plant);
  }

  void addSearch(String search) {
    // Counts toward the Profile screen's lifetime "Searches" stat every
    // time, even a repeat -- unlike the recent-list dedup below, which is
    // only about what's shown, not how many times the user has searched.
    SettingsService.incrementSearchCount();
    if (!_recentSearches.contains(search)) {
      _recentSearches.insert(0, search);
      if (_recentSearches.length > 10) {
        _recentSearches.removeLast();
      }
      notifyListeners();
    }
  }

  void clearRecentSearches() {
    _recentSearches.clear();
    notifyListeners();
  }

  List<Plant> getFeaturedPlants() {
    return List<Plant>.from(_plants.take(3));
  }

  List<Plant> getPopularPlants() {
    final List<Plant> plants = List<Plant>.from(_plants);
    plants.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    return plants;
  }

  List<Plant> getHighestRatedPlants() {
    final List<Plant> plants = List<Plant>.from(_plants);
    plants.sort((a, b) => b.rating.compareTo(a.rating));
    return plants;
  }

  List<Plant> getRecentlyAddedPlants() {
    return List<Plant>.from(_plants.reversed);
  }

  List<Plant> getPlantsByCategory(String category) {
    return _plants
        .where((plant) => plant.categories.contains(category))
        .toList();
  }
}
