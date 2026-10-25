import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/app_constants.dart';
import '../models/plant_model.dart';

class SpellingSuggestion {
  final String typed;
  final String suggestion;

  const SpellingSuggestion({required this.typed, required this.suggestion});

  factory SpellingSuggestion.fromJson(Map<String, dynamic> json) {
    return SpellingSuggestion(
      typed: json['typed'] as String,
      suggestion: json['suggestion'] as String,
    );
  }
}

class SymptomExtraction {
  final List<String> symptomIds;
  final List<SpellingSuggestion> spellingSuggestions;

  const SymptomExtraction({
    required this.symptomIds,
    required this.spellingSuggestions,
  });

  factory SymptomExtraction.fromJson(Map<String, dynamic> json) {
    return SymptomExtraction(
      symptomIds: (json['symptoms'] as List<dynamic>).cast<String>(),
      spellingSuggestions: (json['spellingSuggestions'] as List<dynamic>)
          .map((s) => SpellingSuggestion.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Talks to the Flask API (api_server.py) that wraps the trained
/// herb-relevance model. Follows the same static-method service pattern
/// as FirebaseAuthService/SettingsService/LocalAuthService.
class ApiService {
  // Without a timeout, a request to an unreachable or hung server (as
  // opposed to one that's actively refused, which fails fast) leaves the
  // caller's Future pending indefinitely -- the screen just spins forever
  // with no way out, regardless of how good the device's own internet is.
  static const _requestTimeout = Duration(seconds: 10);

  static Uri _uri(String path) => Uri.parse('${AppConstants.apiBaseUrl}$path');

  /// Retries once, after a short delay, specifically on a timeout -- the
  /// dev-time transport (USB `adb reverse`, multiplexed with the debugger's
  /// own VM service connection) occasionally stalls a single request for no
  /// server-side reason, even though the very next attempt succeeds
  /// immediately. Errors other than a timeout (a real 4xx/5xx, a refused
  /// connection) aren't retried since trying again wouldn't help.
  static Future<T> _withRetry<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on TimeoutException {
      debugPrint('Request timed out, retrying once...');
      await Future.delayed(const Duration(milliseconds: 500));
      return await request();
    }
  }

  static Future<List<Symptom>> fetchSymptoms() {
    return _withRetry(() async {
      final response = await http.get(_uri('/symptoms')).timeout(_requestTimeout);
      if (response.statusCode != 200) {
        throw Exception('Failed to load symptoms (${response.statusCode})');
      }
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((json) => Symptom.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  static Future<List<Plant>> fetchAllPlants() {
    return _withRetry(() async {
      final response = await http.get(_uri('/plants')).timeout(_requestTimeout);
      if (response.statusCode != 200) {
        throw Exception('Failed to load plants (${response.statusCode})');
      }
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((json) => Plant.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  static Future<SymptomExtraction> extractSymptoms(String text) {
    return _withRetry(() async {
      final response = await http
          .post(
            _uri('/extract_symptoms'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(_requestTimeout);
      if (response.statusCode != 200) {
        throw Exception('Failed to extract symptoms (${response.statusCode})');
      }
      return SymptomExtraction.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    });
  }

  /// Returns true/false if the backend's Firebase Admin lookup resolved the
  /// address, or null on any network error or while the backend's Admin SDK
  /// isn't configured yet -- callers should treat null as "don't know" and
  /// never block registration on it, same fail-open stance as the server.
  static Future<bool?> checkEmailExists(String email) async {
    try {
      final response = await http
          .get(_uri('/check-email?email=${Uri.encodeQueryComponent(email)}'))
          .timeout(_requestTimeout);
      if (response.statusCode != 200) {
        return null;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['unknown'] == true) {
        return null;
      }
      return data['exists'] as bool?;
    } catch (e) {
      debugPrint('checkEmailExists failed: $e');
      return null;
    }
  }

  /// Sends a 6-digit email verification code. Caller must supply the
  /// current Firebase ID token (FirebaseAuthService.getIdToken()) so the
  /// backend acts on the real signed-in account.
  static Future<bool> sendVerificationCode(String idToken) async {
    try {
      final response = await http
          .post(
            _uri('/send-verification-code'),
            headers: {'Authorization': 'Bearer $idToken'},
          )
          .timeout(_requestTimeout);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('sendVerificationCode failed: $e');
      return false;
    }
  }

  /// Submits a 6-digit code for verification. Returns null on success, or a
  /// user-facing reason string on failure (wrong/expired code, too many
  /// attempts, network error, etc.).
  static Future<String?> verifyEmailCode(String idToken, String code) async {
    try {
      final response = await http
          .post(
            _uri('/verify-email-code'),
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'code': code}),
          )
          .timeout(_requestTimeout);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['verified'] == true) {
        return null;
      }
      return (data['reason'] as String?) ?? 'Verification failed. Please try again.';
    } catch (e) {
      debugPrint('verifyEmailCode failed: $e');
      return 'Could not reach the server. Please try again.';
    }
  }

  /// Login-lockout bookkeeping (see api_server.py's LOGIN_LOCKOUT_SCHEDULE_NOTE
  /// for the escalating schedule). All three fail open to "not locked" / a
  /// no-op on any network error, so the backend being briefly unreachable
  /// degrades to "no lockout this time" rather than ever blocking sign-in.
  static Future<Map<String, dynamic>> checkLoginLockout(String email) {
    return _postLockout('/login-lockout/status', email);
  }

  static Future<Map<String, dynamic>> recordLoginFailure(String email) {
    return _postLockout('/login-lockout/record-failure', email);
  }

  static Future<void> recordLoginSuccess(String email) async {
    try {
      await http
          .post(
            _uri('/login-lockout/record-success'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(_requestTimeout);
    } catch (e) {
      debugPrint('recordLoginSuccess failed: $e');
    }
  }

  static Future<Map<String, dynamic>> _postLockout(String path, String email) async {
    const notLocked = {'locked': false, 'remainingSeconds': 0};
    try {
      final response = await http
          .post(
            _uri(path),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(_requestTimeout);
      if (response.statusCode != 200) {
        return notLocked;
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Login lockout request to $path failed: $e');
      return notLocked;
    }
  }

  static Future<List<Plant>> fetchRecommendations(
    List<String> symptomIds, {
    int topN = 10,
    List<String> conditions = const [],
  }) {
    return _withRetry(() async {
      final response = await http
          .post(
            _uri('/recommend'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'symptoms': symptomIds,
              'topN': topN,
              'conditions': conditions,
            }),
          )
          .timeout(_requestTimeout);
      if (response.statusCode != 200) {
        throw Exception('Failed to load recommendations (${response.statusCode})');
      }
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((json) => Plant.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }
}
