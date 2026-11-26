import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/context_extensions.dart';
import '../models/plant_model.dart';
import '../providers/chat_provider.dart';
import '../providers/symptom_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../widgets/custom_appbar.dart';

/// "Describe Your Symptoms" as a chatbot (panel revision). The user chats in
/// English, Bisaya or Tagalog; herbs shown under the bot's replies come from
/// the HerbAI XGBoost model on the server.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ChatProvider>().start(context.trRead('chat_greeting'));
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _language => context.read<ThemeProvider>().selectedLanguage;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText() async {
    final chat = context.read<ChatProvider>();
    final text = _input.text.trim();
    if (text.isEmpty || chat.isSending) return;
    _input.clear();
    _scrollToBottom();
    await chat.sendText(text, language: _language, errorText: context.trRead('chat_error'));
    _scrollToBottom();
  }

  Future<void> _tapQuickReply(ChatQuickReply reply) async {
    final chat = context.read<ChatProvider>();
    if (reply.action == 'show_all') {
      context.read<SymptomProvider>().setSelectionFromChat(
            chat.collectedSymptoms,
            chat.collectedConditions,
          );
      context.push('/recommendations');
      return;
    }
    if (reply.action == 'restart') {
      chat.reset(context.trRead('chat_greeting'));
      return;
    }
    _scrollToBottom();
    await chat.sendAction(reply, language: _language, errorText: context.trRead('chat_error'));
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: context.tr('chat_title'),
        actions: [
          IconButton(
            tooltip: context.tr('chat_new_conversation'),
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<ChatProvider>().reset(context.trRead('chat_greeting')),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<ChatProvider>(
          builder: (context, chat, _) {
            final messages = chat.messages;
            return Column(
              children: [
                _buildNotice(context),
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    itemCount: messages.length + (chat.isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) return _buildTyping();
                      final message = messages[index];
                      final isLast = index == messages.length - 1;
                      return _buildMessage(context, chat, message, isLast);
                    },
                  ),
                ),
                _buildInputBar(context, chat),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotice(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.primary.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.tr('chat_notice'),
              style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(BuildContext context, ChatProvider chat, ChatMessage message, bool isLast) {
    final isUser = message.role == ChatRole.user;
    final bubbleColor = isUser
        ? AppTheme.primary
        : message.redFlag
            ? Colors.red.withValues(alpha: 0.10)
            : AppTheme.surface;
    final textColor = isUser ? Colors.white : AppTheme.textPrimary;

    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                child: Icon(Icons.eco, size: 16, color: AppTheme.primary),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  border: message.redFlag ? Border.all(color: Colors.red.withValues(alpha: 0.5)) : null,
                ),
                child: SelectableText(
                  message.text,
                  style: TextStyle(color: textColor, fontSize: 15, height: 1.4),
                ),
              ),
            ),
          ],
        ),
        if (message.herbs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 34, top: 4),
            child: Column(
              children: [for (final plant in message.herbs) _buildHerbTile(context, plant)],
            ),
          ),
        if (message.isError && isLast)
          Padding(
            padding: const EdgeInsets.only(left: 34, top: 4),
            child: ActionChip(
              avatar: const Icon(Icons.refresh, size: 16),
              label: Text(context.tr('retry')),
              onPressed: chat.isSending
                  ? null
                  : () => chat.retry(language: _language, errorText: context.trRead('chat_error')),
            ),
          ),
        if (isLast && !chat.isSending && message.quickReplies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 34, top: 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final reply in message.quickReplies)
                  ActionChip(
                    label: Text(reply.label),
                    labelStyle: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                    side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.35)),
                    onPressed: () => _tapQuickReply(reply),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildHerbTile(BuildContext context, Plant plant) {
    final warning = plant.conditionWarnings.isNotEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 44,
            height: 44,
            child: plant.imageUrl.isNotEmpty
                ? Image.network(
                    plant.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _herbIcon(),
                  )
                : _herbIcon(),
          ),
        ),
        title: Text(plant.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          warning ? context.tr('chat_has_condition_warning') : plant.scientificName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: warning ? Colors.orange.shade800 : AppTheme.textSecondary),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/plant-details', extra: plant),
      ),
    );
  }

  Widget _herbIcon() => Container(
        color: AppTheme.primary.withValues(alpha: 0.1),
        child: Icon(Icons.eco, color: AppTheme.primary),
      );

  Widget _buildTyping() {
    return Padding(
      padding: const EdgeInsets.only(left: 34, top: 4, bottom: 8),
      child: Row(
        children: [
          const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 10),
          Text(context.tr('chat_typing'), style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, ChatProvider chat) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 4,
              maxLength: 500,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendText(),
              decoration: InputDecoration(
                counterText: '',
                hintText: context.tr('chat_input_hint'),
                filled: true,
                fillColor: AppTheme.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppTheme.primary, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton.filled(
            onPressed: chat.isSending ? null : _sendText,
            icon: const Icon(Icons.send_rounded),
            style: IconButton.styleFrom(backgroundColor: AppTheme.primary),
          ),
        ],
      ),
    );
  }
}
