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

class ChatQuickReply {
  final String label;
  final String action;

  const ChatQuickReply({required this.label, required this.action});

  factory ChatQuickReply.fromJson(Map<String, dynamic> json) => ChatQuickReply(
        label: json['label'] as String,
        action: json['action'] as String,
      );
}

/// One chatbot turn from POST /chat. Herbs always come from the XGBoost
/// model on the server; the reply text is written by Gemini (or a plain
/// template when Gemini is unavailable).
class ChatTurnResult {
  final String reply;
  final List<Plant> herbs;
  final List<ChatQuickReply> quickReplies;
  final Map<String, dynamic> state;
  final bool redFlag;
  final bool limitReached;

  const ChatTurnResult({
    required this.reply,
    this.herbs = const [],
    this.quickReplies = const [],
    this.state = const {},
    this.redFlag = false,
    this.limitReached = false,
  });

  factory ChatTurnResult.fromJson(Map<String, dynamic> json) {
    return ChatTurnResult(
      reply: (json['reply'] as String?) ?? '',
      herbs: ((json['herbs'] as List<dynamic>?) ?? [])
          .map((h) => Plant.fromJson(h as Map<String, dynamic>))
          .toList(),
      quickReplies: ((json['quickReplies'] as List<dynamic>?) ?? [])
          .map((q) => ChatQuickReply.fromJson(q as Map<String, dynamic>))
          .toList(),
      state: (json['state'] as Map<String, dynamic>?) ?? const {},
      redFlag: json['redFlag'] == true,
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

  // /send-verification-code logs in to Gmail SMTP and sends the email before
  // it replies, which can take longer than 10 s.
  static const _sendEmailTimeout = Duration(seconds: 30);

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
      // ~3 MB payload: over a slow uplink it routinely needs longer than
      // the 10s that suits the small endpoints.
      final response = await http.get(_uri('/plants')).timeout(const Duration(seconds: 45));
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
          .timeout(_sendEmailTimeout);
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

  // A chat turn can make two Gemini calls plus the XGBoost ranking.
  static const _chatTimeout = Duration(seconds: 30);

  /// One chatbot turn. Throws on network/server errors so the chat screen
  /// can show a retry; a daily-limit 429 comes back as a normal reply.
  static Future<ChatTurnResult> sendChat({
    required String idToken,
    String message = '',
    String action = '',
    required List<Map<String, String>> history,
    required Map<String, dynamic> state,
    required String sessionId,
    required String language,
  }) async {
    final response = await http
        .post(
          _uri('/chat'),
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'message': message,
            'action': action,
            'history': history,
            'state': state,
            'sessionId': sessionId,
            'language': language,
          }),
        )
        .timeout(_chatTimeout);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 429 && data['reply'] is String) {
      return ChatTurnResult(reply: data['reply'] as String, state: state, limitReached: true);
    }
    if (response.statusCode != 200) {
      throw Exception('Chat failed (${response.statusCode})');
    }
    return ChatTurnResult.fromJson(data);
  }

  /// Records a "Select Your Symptoms" checklist search for the admin usage
  /// reports. Fire-and-forget: never throws and never blocks navigation.
  static Future<void> logChecklistSearch({
    required String idToken,
    required List<String> symptoms,
    required List<String> conditions,
  }) async {
    try {
      await http
          .post(
            _uri('/log-checklist'),
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'symptoms': symptoms, 'conditions': conditions}),
          )
          .timeout(_chatTimeout);
    } catch (e) {
      debugPrint('logChecklistSearch failed: $e');
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
