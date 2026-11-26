import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/plant_model.dart';
import '../services/api_service.dart';
import '../services/firebase_auth_service.dart';

enum ChatRole { user, bot }

class ChatMessage {
  final ChatRole role;
  final String text;
  final List<Plant> herbs;
  final List<ChatQuickReply> quickReplies;
  final bool isError;
  final bool redFlag;

  const ChatMessage({
    required this.role,
    required this.text,
    this.herbs = const [],
    this.quickReplies = const [],
    this.isError = false,
    this.redFlag = false,
  });
}

/// State for the symptom chatbot screen. The conversation state that
/// matters for recommendations (collected symptoms, conditions, stage) is
/// kept by the server's /chat response and sent back each turn.
class ChatProvider with ChangeNotifier {
  final List<ChatMessage> _messages = [];
  Map<String, dynamic> _state = {};
  String _sessionId = _newSessionId();
  bool _isSending = false;
  String? _lastText;
  String? _lastAction;
  String? _lastActionLabel;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;
  bool get isEmpty => _messages.isEmpty;

  List<String> get collectedSymptoms =>
      ((_state['symptoms'] as List<dynamic>?) ?? []).cast<String>();
  List<String> get collectedConditions =>
      ((_state['conditions'] as List<dynamic>?) ?? []).cast<String>();

  static String _newSessionId() =>
      '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1 << 32)}';

  String? _ownerUid;

  /// Shows the greeting on first open. A different signed-in account on
  /// the same phone never sees the previous user's conversation.
  void start(String greeting) {
    final uid = FirebaseAuthService.currentUser?.uid;
    if (uid != _ownerUid) {
      _ownerUid = uid;
      _messages.clear();
      _state = {};
      _sessionId = _newSessionId();
    }
    if (_messages.isNotEmpty) return;
    _messages.add(ChatMessage(role: ChatRole.bot, text: greeting));
    notifyListeners();
  }

  void reset(String greeting) {
    _messages.clear();
    _state = {};
    _sessionId = _newSessionId();
    start(greeting);
  }

  Future<void> sendText(String text, {required String language, required String errorText}) {
    _lastText = text;
    _lastAction = null;
    return _send(display: text, message: text, language: language, errorText: errorText);
  }

  Future<void> sendAction(ChatQuickReply reply, {required String language, required String errorText}) {
    _lastText = null;
    _lastAction = reply.action;
    _lastActionLabel = reply.label;
    return _send(display: reply.label, action: reply.action, language: language, errorText: errorText);
  }

  /// Re-sends the last user turn after a network error.
  Future<void> retry({required String language, required String errorText}) {
    if (_messages.isNotEmpty && _messages.last.isError) _messages.removeLast();
    if (_messages.isNotEmpty && _messages.last.role == ChatRole.user) _messages.removeLast();
    if (_lastText != null) {
      return sendText(_lastText!, language: language, errorText: errorText);
    }
    if (_lastAction != null) {
      return sendAction(
        ChatQuickReply(label: _lastActionLabel ?? _lastAction!, action: _lastAction!),
        language: language,
        errorText: errorText,
      );
    }
    return Future.value();
  }

  Future<void> _send({
    required String display,
    String message = '',
    String action = '',
    required String language,
    required String errorText,
  }) async {
    if (_isSending) return;
    final history = _messages
        .where((m) => !m.isError)
        .map((m) => {'role': m.role == ChatRole.user ? 'user' : 'bot', 'text': m.text})
        .toList();
    _messages.add(ChatMessage(role: ChatRole.user, text: display));
    _isSending = true;
    notifyListeners();

    try {
      final token = await FirebaseAuthService.getIdToken();
      if (token == null) throw Exception('Not signed in');
      final result = await ApiService.sendChat(
        idToken: token,
        message: message,
        action: action,
        history: history.length > 10 ? history.sublist(history.length - 10) : history,
        state: _state,
        sessionId: _sessionId,
        language: language,
      );
      if (!result.limitReached) _state = result.state;
      _messages.add(ChatMessage(
        role: ChatRole.bot,
        text: result.reply,
        herbs: result.herbs,
        quickReplies: result.quickReplies,
        redFlag: result.redFlag,
      ));
    } catch (e) {
      debugPrint('Chat turn failed: $e');
      _messages.add(ChatMessage(role: ChatRole.bot, text: errorText, isError: true));
    }
    _isSending = false;
    notifyListeners();
  }
}
