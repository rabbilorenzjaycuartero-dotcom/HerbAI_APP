import 'package:flutter/foundation.dart';
import '../models/plant_model.dart';
import '../services/api_service.dart';

enum SortOption {
  bestMatch,
  highestRated,
  alphabetical,
}

class SymptomProvider with ChangeNotifier {
  List<Symptom> _allSymptoms = [];
  bool _isLoadingSymptoms = false;

  Set<String> _selectedSymptomIds = {};
  SortOption _sortOption = SortOption.bestMatch;
  Set<String> _activeFilters = {};

  List<Plant> _recommendedPlants = [];
  bool _isLoadingRecommendations = false;
  String? _recommendationsError;

  SymptomProvider() {
    _loadSymptoms();
  }

  Future<void> _loadSymptoms() async {
    _isLoadingSymptoms = true;
    notifyListeners();
    try {
      _allSymptoms = await ApiService.fetchSymptoms();
    } catch (e) {
      debugPrint('Failed to load symptoms: $e');
      _allSymptoms = [];
    }
    _isLoadingSymptoms = false;
    notifyListeners();
  }

  List<Symptom> get allSymptoms => _allSymptoms;
  bool get isLoadingSymptoms => _isLoadingSymptoms;

  List<Symptom> get selectedSymptoms {
    return _allSymptoms
        .where((symptom) => _selectedSymptomIds.contains(symptom.id))
        .toList();
  }

  SortOption get sortOption => _sortOption;
  Set<String> get activeFilters => _activeFilters;

  bool get hasSelectedSymptoms => _selectedSymptomIds.isNotEmpty;

  bool get isLoadingRecommendations => _isLoadingRecommendations;
  String? get recommendationsError => _recommendationsError;

  bool isSymptomSelected(Symptom symptom) {
    return _selectedSymptomIds.contains(symptom.id);
  }

  void toggleSymptom(Symptom symptom) {
    if (_selectedSymptomIds.contains(symptom.id)) {
      _selectedSymptomIds.remove(symptom.id);
    } else {
      _selectedSymptomIds.add(symptom.id);
    }
    notifyListeners();
  }

  void clearSymptoms() {
    _selectedSymptomIds.clear();
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void toggleFilter(String filter) {
    if (_activeFilters.contains(filter)) {
      _activeFilters.remove(filter);
    } else {
      _activeFilters.add(filter);
    }
    notifyListeners();
  }

  void clearFilters() {
    _activeFilters.clear();
    notifyListeners();
  }

  /// Calls the ML backend for the currently selected symptoms and caches
  /// the ranked results. Call this once when entering the recommendations
  /// screen; sorting/filtering afterwards (getRecommendedPlants) is local
  /// and doesn't re-hit the network.
  Future<void> fetchRecommendations() async {
    if (_selectedSymptomIds.isEmpty) {
      _recommendedPlants = [];
      notifyListeners();
      return;
    }

    _isLoadingRecommendations = true;
    _recommendationsError = null;
    notifyListeners();

    try {
      _recommendedPlants =
          await ApiService.fetchRecommendations(_selectedSymptomIds.toList());
    } catch (e) {
      debugPrint('Failed to fetch recommendations: $e');
      _recommendedPlants = [];
      _recommendationsError = 'Could not reach the server. Please try again.';
    }

    _isLoadingRecommendations = false;
    notifyListeners();
  }

  List<Plant> getRecommendedPlants() {
    List<Plant> plants = List.from(_recommendedPlants);

    if (_activeFilters.isNotEmpty) {
      plants = plants.where((plant) {
        for (var filter in _activeFilters) {
          switch (filter) {
            case 'DOH Recognized':
              if (!plant.isDohRecognized) return false;
              break;
            case 'Commonly Available':
              if (plant.availability != AvailabilityStatus.common) return false;
              break;
            case 'Safe for Children':
              if (plant.safetyInfo.safeForChildren != true) return false;
              break;
            case 'Safe for Elderly':
              if (plant.safetyInfo.safeForElderly != true) return false;
              break;
            case 'Easy to Prepare':
              if (!plant.isEasyToPrepare) return false;
              break;
          }
        }
        return true;
      }).toList();
    }

    switch (_sortOption) {
      case SortOption.bestMatch:
        plants.sort((a, b) =>
            (b.relevanceScore ?? 0).compareTo(a.relevanceScore ?? 0));
        break;
      case SortOption.highestRated:
        plants.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortOption.alphabetical:
        plants.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return plants;
  }
}
