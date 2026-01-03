import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:uuid/uuid.dart';
import '../main.dart';
import '../database/database_service.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/settings.dart';
import '../services/api_service.dart';
import '../services/chat_session_service.dart';
import '../services/chat_websocket_service.dart';
import '../services/follow_service.dart';
import '../services/push_service.dart';
import '../services/user_service.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_suggested_prompts.dart';

const _uuid = Uuid();

class MobileChatPage extends HookWidget {
  final AppSettings settings;
  final ApiService apiService;
  final ChatSessionService chatService;
  final ChatSession session;
  final FollowService followService;
  final PushService? pushService;
  final VoidCallback? onSessionUpdated;

  const MobileChatPage({
    super.key,
    required this.settings,
    required this.apiService,
    required this.chatService,
    required this.session,
    required this.followService,
    this.pushService,
    this.onSessionUpdated,
  });

  Future<List<ChatMessage>> _loadChatHistory(String sessionId) async {
    final db = await DatabaseService.getInstance();
    final entries = await db.getChatMessagesForSession(sessionId);
    return entries.map((entry) {
      return ChatMessage(
        id: entry.messageId,
        sessionId: entry.sessionId,
        role: entry.role,
        content: entry.content,
        timestamp: entry.timestamp,
      );
    }).toList();
  }

  Future<void> _saveChatMessage(ChatMessage message) async {
    final db = await DatabaseService.getInstance();
    final entry = ChatMessageEntry()
      ..messageId = message.id
      ..sessionId = message.sessionId
      ..role = message.role
      ..content = message.content
      ..timestamp = message.timestamp;

    await db.saveChatMessage(entry);
  }

  @override
  Widget build(BuildContext context) {
    // WebSocket service
    final wsService = useMemoized(() => ChatWebSocketService(), []);

    // Chat messages state
    final messages = useState<List<ChatMessage>>([]);
    final isLoading = useState(true);
    final isSending = useState(false);
    final isConnected = useState(false);
    final streamingMessageId = useState<String?>(null);
    final currentToolName = useState<String?>(null);

    // Text input controller
    final textController = useTextEditingController();
    final scrollController = useScrollController();
    final hasText = useState(false);

    // Listen to text changes to enable/disable send button
    useEffect(() {
      void listener() {
        hasText.value = textController.text.trim().isNotEmpty;
      }

      textController.addListener(listener);
      return () => textController.removeListener(listener);
    }, [textController]);

    // Connect to WebSocket on mount
    useEffect(() {
      StreamSubscription? subscription;

      Future<void> connectAndLoadHistory() async {
        try {
          // Load chat history first
          final history = await _loadChatHistory(session.id);
          messages.value = history;

          // Get persistent user ID and connect to WebSocket
          final userId = await UserService.getUserId();
          await wsService.connect(
            userId: userId,
            sessionId: session.id,
          );
          isConnected.value = true;

          // Listen to WebSocket events
          subscription = wsService.events.listen((event) {
            debugPrint('[Chat] Received event: ${event.runtimeType}');
            if (event is ToolProgressEvent) {
              // Update current tool being executed
              debugPrint('[Chat] Tool progress: ${event.toolName}');
              currentToolName.value = event.toolName;
            } else if (event is TextDeltaEvent) {
              // Append text delta to streaming message
              debugPrint('[Chat] Text delta: ${event.delta.length} chars');
              if (streamingMessageId.value != null) {
                final currentMessages = messages.value;
                final updatedMessages = currentMessages.map((m) {
                  if (m.id == streamingMessageId.value) {
                    return m.copyWith(
                      content: m.content + event.delta,
                    );
                  }
                  return m;
                }).toList();
                messages.value = updatedMessages;

                // Auto-scroll to bottom
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (scrollController.hasClients) {
                    scrollController.animateTo(
                      scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeOut,
                    );
                  }
                });
              }
            } else if (event is ReferencedOffersEvent) {
              // Add referenced offers to the last assistant message
              debugPrint(
                  '[Chat] Referenced offers: ${event.offers.length} offers');
              final currentMessages = messages.value;
              if (currentMessages.isNotEmpty) {
                // Find the last assistant message
                final lastIndex = currentMessages.lastIndexWhere(
                    (m) => m.role == 'assistant');
                if (lastIndex != -1) {
                  final updatedMessages = List<ChatMessage>.from(currentMessages);
                  updatedMessages[lastIndex] = updatedMessages[lastIndex]
                      .copyWith(referencedOffers: event.offers);
                  messages.value = updatedMessages;

                  // Save the updated message to database
                  _saveChatMessage(updatedMessages[lastIndex]);

                  debugPrint(
                      '[Chat] Updated last assistant message with ${event.offers.length} offers');
                }
              }
            } else if (event is CompleteEvent) {
              // Finalize streaming message
              debugPrint('[Chat] Complete event received');
              if (streamingMessageId.value != null) {
                final currentMessages = messages.value;
                final finalMessages = currentMessages.map((m) {
                  if (m.id == streamingMessageId.value) {
                    final finalMessage = m.copyWith(isStreaming: false);
                    _saveChatMessage(finalMessage);
                    return finalMessage;
                  }
                  return m;
                }).toList();
                messages.value = finalMessages;
                streamingMessageId.value = null;
                currentToolName.value = null;
                isSending.value = false;

                // Notify parent to refresh session list
                onSessionUpdated?.call();
              }
            } else if (event is ErrorEvent) {
              // Handle error
              debugPrint('WebSocket error: ${event.message}');
              if (streamingMessageId.value != null) {
                final currentMessages = messages.value;
                final errorMessages = currentMessages.map((m) {
                  if (m.id == streamingMessageId.value) {
                    final errorMessage = m.copyWith(
                      content: 'Sorry, an error occurred: ${event.message}',
                      isStreaming: false,
                    );
                    _saveChatMessage(errorMessage);
                    return errorMessage;
                  }
                  return m;
                }).toList();
                messages.value = errorMessages;
                streamingMessageId.value = null;
                currentToolName.value = null;
                isSending.value = false;
              }
            }
          });
        } catch (e) {
          debugPrint('[Chat] Error connecting to WebSocket: $e');
        } finally {
          isLoading.value = false;
        }
      }

      connectAndLoadHistory();

      return () {
        subscription?.cancel();
        wsService.dispose();
      };
    }, []);

    // Send message function
    Future<void> sendMessage(String text) async {
      if (text.trim().isEmpty || isSending.value || !isConnected.value) return;

      final messageText = text.trim();
      debugPrint('[Chat] Sending message: $messageText');
      textController.clear();
      isSending.value = true;

      // Create user message
      final now = DateTime.now();
      final userMessage = ChatMessage(
        id: _uuid.v4(),
        sessionId: session.id,
        role: 'user',
        content: messageText,
        timestamp: now,
      );

      // Add user message to UI and save to DB
      debugPrint('[Chat] Adding user message to UI');
      messages.value = [...messages.value, userMessage];
      await _saveChatMessage(userMessage);
      debugPrint('[Chat] User message saved to DB');

      // Create AI message placeholder for streaming
      final aiMessageId = _uuid.v4();
      streamingMessageId.value = aiMessageId;
      debugPrint('[Chat] Created AI message placeholder: $aiMessageId');
      final aiMessage = ChatMessage(
        id: aiMessageId,
        sessionId: session.id,
        role: 'assistant',
        content: '',
        timestamp: DateTime.now(),
        isStreaming: true,
      );
      messages.value = [...messages.value, aiMessage];

      // Send message via WebSocket
      try {
        debugPrint('[Chat] Sending via WebSocket...');
        await wsService.sendMessage(
          message: messageText,
          sessionId: session.id,
        );
        debugPrint('[Chat] Message sent via WebSocket');
      } catch (e) {
        debugPrint('[Chat] Error sending message: $e');
        // Update message with error
        final errorMessage = ChatMessage(
          id: aiMessageId,
          sessionId: session.id,
          role: 'assistant',
          content: 'Sorry, I encountered an error. Please try again.',
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
        isSending.value = false;
        streamingMessageId.value = null;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isConnected.value)
              Text(
                'Connecting...',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          if (currentToolName.value != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentToolName.value!,
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Messages area
          Expanded(
            child: isLoading.value
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accent,
                      strokeWidth: 2.5,
                    ),
                  )
                : messages.value.isEmpty
                    ? _buildEmptyState((prompt) {
                        textController.text = prompt;
                        sendMessage(prompt);
                      })
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        itemCount: messages.value.length,
                        itemBuilder: (context, index) {
                          final message = messages.value[index];
                          return ChatMessageBubble(
                            message: message,
                            apiService: apiService,
                            followService: followService,
                            pushService: pushService,
                          );
                        },
                      ),
          ),

          // Modern input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
            ),
            child: SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.surface.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Text input
                    Expanded(
                      child: TextField(
                        controller: textController,
                        enabled: !isSending.value && isConnected.value,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          hintText: isConnected.value
                              ? 'Message...'
                              : 'Connecting...',
                          hintStyle: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.5),
                            fontSize: 16,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.only(
                            left: 20,
                            right: 12,
                            top: 14,
                            bottom: 14,
                          ),
                        ),
                        maxLines: null,
                        minLines: 1,
                        maxLength: null,
                        textInputAction: TextInputAction.newline,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    // Send button
                    Padding(
                      padding: const EdgeInsets.only(right: 4, bottom: 4),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: !isSending.value &&
                                  isConnected.value &&
                                  hasText.value
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.accent,
                                    AppColors.primary,
                                  ],
                                )
                              : null,
                          color: AppColors.surface.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            isSending.value
                                ? Icons.more_horiz_rounded
                                : Icons.arrow_upward_rounded,
                            color: !isSending.value &&
                                    isConnected.value &&
                                    hasText.value
                                ? Colors.white
                                : AppColors.textMuted.withValues(alpha: 0.4),
                            size: 20,
                          ),
                          onPressed: !isSending.value &&
                                  isConnected.value &&
                                  hasText.value
                              ? () => sendMessage(textController.text)
                              : null,
                        ),
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

  /// Build modern empty state
  Widget _buildEmptyState(ValueChanged<String> onPromptTapped) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            Text(
              session.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            // Subtitle
            Text(
              'Ask detailed questions for better answers',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 48),
            // Suggested prompts
            ChatSuggestedPrompts(onPromptTapped: onPromptTapped),
          ],
        ),
      ),
    );
  }
}
