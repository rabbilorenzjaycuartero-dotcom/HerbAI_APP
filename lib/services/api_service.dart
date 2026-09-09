import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_constants.dart';
import '../models/plant_model.dart';

/// Talks to the Flask API (api_server.py) that wraps the trained
/// herb-relevance model. Follows the same static-method service pattern
/// as FirebaseAuthService/SettingsService/LocalAuthService.
class ApiService {
  static Uri _uri(String path) => Uri.parse('${AppConstants.apiBaseUrl}$path');

  static Future<List<Symptom>> fetchSymptoms() async {
    final response = await http.get(_uri('/symptoms'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load symptoms (${response.statusCode})');
    }
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => Symptom.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Plant>> fetchAllPlants() async {
    final response = await http.get(_uri('/plants'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load plants (${response.statusCode})');
    }
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => Plant.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Plant>> fetchRecommendations(
    List<String> symptomIds, {
    int topN = 10,
  }) async {
    final response = await http.post(
      _uri('/recommend'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'symptoms': symptomIds, 'topN': topN}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load recommendations (${response.statusCode})');
    }
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => Plant.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
