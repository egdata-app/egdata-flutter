import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../main.dart';
import '../database/database_service.dart';
import '../models/chat_message.dart';
import '../models/settings.dart';
import '../services/ai_chat_service.dart';
import '../services/api_service.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_suggested_prompts.dart';

class MobileChatPage extends HookWidget {
  final AppSettings settings;
  final DatabaseService db;

  const MobileChatPage({
    super.key,
    required this.settings,
    required this.db,
  });

  Future<List<ChatMessage>> _loadChatHistory() async {
    final entries = await db.getAllChatMessages();
    return entries.map((entry) {
      List<Offer>? gameResults;
      if (entry.gameResultsJson != null) {
        try {
          final List<dynamic> resultsList = jsonDecode(entry.gameResultsJson!);
          gameResults =
              resultsList.map((e) => Offer.fromJson(e)).toList();
        } catch (e) {
          // Failed to parse game results, continue without them
        }
      }

      return ChatMessage(
        id: entry.messageId,
        content: entry.content,
        isUser: entry.isUser,
        timestamp: entry.timestamp,
        gameResults: gameResults,
      );
    }).toList();
  }

  /// Strip tool call tags from content for cleaner database storage
  String _stripToolTags(String content) {
    return content.replaceAll(
      RegExp(r'<tool:[^>]+>', multiLine: true),
      '',
    ).trim();
  }

  Future<void> _saveChatMessage(ChatMessage message) async {
    final entry = ChatMessageEntry()
      ..messageId = message.id
      ..content = _stripToolTags(message.content)  // Clean content for DB
      ..isUser = message.isUser
      ..timestamp = message.timestamp
      ..gameResultsJson = message.gameResultsJsonString;

    await db.saveChatMessage(entry);
  }

  @override
  Widget build(BuildContext context) {
    // Chat service
    final chatService = useMemoized(
      () => AIChatService(
        apiService: ApiService(),
        country: settings.country,
      ),
      [settings.country],
    );

    // Initialize chat service on mount
    useEffect(() {
      chatService.initialize();
      return chatService.dispose;
    }, [chatService]);

    // Chat messages state
    final messages = useState<List<ChatMessage>>([]);
    final isLoading = useState(true);
    final isSending = useState(false);
    final streamingMessageId = useState<String?>(null);

    // Text input controller
    final textController = useTextEditingController();
    final scrollController = useScrollController();

    // Load chat history on mount
    useEffect(() {
      void loadHistory() async {
        try {
          final history = await _loadChatHistory();
          messages.value = history;
        } catch (e) {
          debugPrint('Error loading chat history: $e');
        } finally {
          isLoading.value = false;
        }
      }

      loadHistory();
      return null;
    }, []);

    // Scroll to bottom when new messages arrive
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
      return null;
    }, [messages.value.length]);

    // Send message function
    Future<void> sendMessage(String text) async {
      if (text.trim().isEmpty || isSending.value) return;

      final messageText = text.trim();
      textController.clear();
      isSending.value = true;

      // Create user message
      final now = DateTime.now();
      final userMessage = ChatMessage(
        id: 'user_${now.millisecondsSinceEpoch}',
        content: messageText,
        isUser: true,
        timestamp: now,
      );

      // Add user message to UI and save to DB
      messages.value = [...messages.value, userMessage];
      await _saveChatMessage(userMessage);

      // Create AI message placeholder for streaming
      final aiMessageId = 'ai_${now.millisecondsSinceEpoch}';
      streamingMessageId.value = aiMessageId;
      final aiMessage = ChatMessage(
        id: aiMessageId,
        content: '',
        isUser: false,
        timestamp: DateTime.now(),
        isStreaming: true,
      );
      messages.value = [...messages.value, aiMessage];

      // Send message to AI and handle streaming response
      try {
        final responseStream = chatService.sendMessage(messageText);
        final buffer = StringBuffer();

        await for (final chunk in responseStream) {
          buffer.write(chunk);

          // Update the AI message with accumulated content
          final updatedMessages = messages.value.map((m) {
            if (m.id == aiMessageId) {
              return m.copyWith(
                content: buffer.toString(),
                isStreaming: true,
              );
            }
            return m;
          }).toList();

          messages.value = updatedMessages;
        }

        // Finalize AI message
        final finalMessage = ChatMessage(
          id: aiMessageId,
          content: buffer.toString(),
          isUser: false,
          timestamp: DateTime.now(),
          isStreaming: false,
        );

        final finalMessages = messages.value.map((m) {
          if (m.id == aiMessageId) {
            return finalMessage;
          }
          return m;
        }).toList();

        messages.value = finalMessages;

        // Save final AI message to DB
        await _saveChatMessage(finalMessage);
      } catch (e) {
        debugPrint('Error sending message: $e');

        // Update message with error
        final errorMessage = ChatMessage(
          id: aiMessageId,
          content:
              'Sorry, I encountered an error. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
          isStreaming: false,
        );

        final errorMessages = messages.value.map((m) {
          if (m.id == aiMessageId) {
            return errorMessage;
          }
          return m;
        }).toList();

        messages.value = errorMessages;
        await _saveChatMessage(errorMessage);
      } finally {
        isSending.value = false;
        streamingMessageId.value = null;
      }
    }

    // Handle suggested prompt tap
    void handlePromptTap(String prompt) {
      textController.text = prompt;
      sendMessage(prompt);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 24),
            const SizedBox(width: 8),
            Text(
              'AI Chat',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          // Clear chat button
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: AppColors.textMuted),
            tooltip: 'Clear chat history',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: Text('Clear chat history?', style: TextStyle(color: AppColors.textPrimary)),
                  content: Text(
                    'This will delete all your chat messages.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Clear', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await db.deleteChatHistory();
                chatService.clearChat();
                messages.value = [];
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: isLoading.value
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  )
                : messages.value.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 64,
                              color: AppColors.textMuted.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Start a conversation',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ask me about games, prices, or sales!',
                              style: TextStyle(
                                color: AppColors.textMuted.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: messages.value.length,
                        itemBuilder: (context, index) {
                          final message = messages.value[index];
                          return ChatMessageBubble(message: message);
                        },
                      ),
          ),

          // Suggested prompts (show when no messages)
          if (messages.value.isEmpty && !isLoading.value)
            ChatSuggestedPrompts(onPromptTapped: handlePromptTap),

          // Input field
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.borderGlass, width: 1),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Text input
                    Expanded(
                      child: TextField(
                        controller: textController,
                        enabled: !isSending.value,
                        style: TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Ask about games...',
                          hintStyle: TextStyle(color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: AppColors.borderGlass),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: AppColors.borderGlass),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: AppColors.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => sendMessage(textController.text),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Send button
                    Container(
                      decoration: BoxDecoration(
                        color: isSending.value
                            ? AppColors.textMuted.withValues(alpha: 0.3)
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: IconButton(
                        icon: Icon(
                          isSending.value
                              ? Icons.hourglass_empty_rounded
                              : Icons.send_rounded,
                          color: Colors.white,
                        ),
                        onPressed: isSending.value
                            ? null
                            : () => sendMessage(textController.text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
