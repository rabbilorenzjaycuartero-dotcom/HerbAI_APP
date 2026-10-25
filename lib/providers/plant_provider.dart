import 'package:flutter/foundation.dart';
import '../models/plant_model.dart';
import '../core/mock_data.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';

class PlantProvider with ChangeNotifier {
  List<Plant> _plants = [];
  List<Plant> _favorites = [];
  List<String> _recentSearches = [];
  bool _isLoading = false;

  List<Plant> get plants => _plants;
  List<Plant> get favorites => _favorites;
  List<String> get recentSearches => _recentSearches;
  bool get isLoading => _isLoading;

  PlantProvider() {
    _loadData();
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
    // Recent-searches seed list is just demo UI content, unrelated to herb
    // data, so it still comes from mock_data.dart.
    _recentSearches = MockData.getRecentSearches();

    _isLoading = false;
    notifyListeners();
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

  void toggleFavorite(Plant plant) {
    if (_favorites.contains(plant)) {
      _favorites.remove(plant);
    } else {
      _favorites.add(plant);
    }
    notifyListeners();
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
