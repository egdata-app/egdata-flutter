import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import '../main.dart';
import '../models/chat_session.dart';
import '../models/settings.dart';
import '../services/api_service.dart';
import '../services/chat_session_service.dart';
import '../services/follow_service.dart';
import '../services/push_service.dart';
import '../database/database_service.dart';
import 'mobile_chat_page.dart';

class MobileChatSessionsPage extends HookWidget {
  final AppSettings settings;
  final ApiService apiService;
  final ChatSessionService chatService;
  final FollowService followService;
  final PushService? pushService;

  const MobileChatSessionsPage({
    super.key,
    required this.settings,
    required this.apiService,
    required this.chatService,
    required this.followService,
    this.pushService,
  });

  @override
  Widget build(BuildContext context) {
    final sessions = useState<List<ChatSession>>([]);
    final isLoading = useState(true);
    final error = useState<String?>(null);

    // Track if widget is still mounted using a ref
    final mountedRef = useRef(true);
    useEffect(() {
      mountedRef.value = true;
      return () => mountedRef.value = false;
    }, []);

    // Load sessions on mount
    useEffect(() {
      Future<void> loadSessions() async {
        try {
          isLoading.value = true;
          error.value = null;
          final loadedSessions = await chatService.listSessions();

          // Check if still mounted before updating state
          if (!mountedRef.value) return;

          sessions.value = loadedSessions;

          // Also sync to local database (update or insert)
          final db = await DatabaseService.getInstance();
          for (final session in loadedSessions) {
            // Check if session already exists
            final existingSession = await db.getChatSessionById(session.id);
            final entry = existingSession ?? ChatSessionEntry();
            entry.sessionId = session.id;
            entry.title = session.title;
            entry.createdAt = session.createdAt;
            entry.lastMessageAt = session.lastMessageAt;
            entry.messageCount = session.messageCount;
            await db.saveChatSession(entry);
          }
        } catch (e) {
          if (!mountedRef.value) return;
          error.value = e.toString();
        } finally {
          if (mountedRef.value) {
            isLoading.value = false;
          }
        }
      }

      loadSessions();
      return null;
    }, []);

    Future<void> createNewChat({String? initialMessage}) async {
      try {
        final newSession = await chatService.createSession();
        sessions.value = [newSession, ...sessions.value];

        // Navigate to the new chat
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MobileChatPage(
                settings: settings,
                apiService: apiService,
                chatService: chatService,
                session: newSession,
                followService: followService,
                pushService: pushService,
                initialMessage: initialMessage,
                onSessionUpdated: () async {
                  // Refresh sessions list
                  final updatedSessions = await chatService.listSessions();
                  sessions.value = updatedSessions;
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create chat: $e')),
          );
        }
      }
    }

    Future<void> deleteSession(ChatSession session) async {
      try {
        await chatService.deleteSession(session.id);
        sessions.value = sessions.value.where((s) => s.id != session.id).toList();

        // Also delete from local database
        final db = await DatabaseService.getInstance();
        await db.deleteChatSession(session.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Chat deleted'),
              backgroundColor: AppColors.surface,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete chat: $e')),
          );
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Custom gradient header
          _buildHeader(context, createNewChat),
          // Content
          Expanded(
            child: isLoading.value
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : error.value != null
                    ? _buildErrorState(error.value!)
                    : sessions.value.isEmpty
                        ? _buildEmptyState(createNewChat)
                        : _buildSessionsList(
                            context,
                            sessions.value,
                            deleteSession,
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Future<void> Function({String? initialMessage}) onNewChat) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.primary.withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Row(
            children: [
              // Icon with glassmorphic background
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  IconsaxPlusBold.messages_2,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Chat',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your Epic Games companion',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // New chat button
              GestureDetector(
                onTap: () => onNewChat(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    IconsaxPlusBold.add,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Future<void> Function({String? initialMessage}) onNewChat) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with gradient background
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    AppColors.primary.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                IconsaxPlusBold.message_text,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Start Your First Chat',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask me anything about Epic Games,\nrecommendations, prices, and more',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Suggested prompts
            const Text(
              'Try asking:',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _buildPromptChip('Show me RPGs under \$20', () => onNewChat(initialMessage: 'Show me RPGs under \$20')),
            const SizedBox(height: 8),
            _buildPromptChip('What games are on sale?', () => onNewChat(initialMessage: 'What games are on sale?')),
            const SizedBox(height: 8),
            _buildPromptChip('Best co-op games', () => onNewChat(initialMessage: 'Best co-op games')),
            const SizedBox(height: 32),
            // Primary CTA
            GestureDetector(
              onTap: () => onNewChat(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      IconsaxPlusBold.add_circle,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Start New Chat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptChip(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              IconsaxPlusBold.message_question,
              size: 16,
              color: AppColors.primary.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                IconsaxPlusBold.danger,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Something went wrong',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsList(
    BuildContext context,
    List<ChatSession> sessions,
    Function(ChatSession) onDelete,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _ChatSessionCard(
          session: session,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MobileChatPage(
                  settings: settings,
                  apiService: apiService,
                  chatService: chatService,
                  session: session,
                  followService: followService,
                  pushService: pushService,
                  onSessionUpdated: () async {
                    final updatedSessions = await chatService.listSessions();
                    sessions = updatedSessions;
                  },
                ),
              ),
            );
          },
          onDelete: () => onDelete(session),
        );
      },
    );
  }
}

class _ChatSessionCard extends StatelessWidget {
  final ChatSession session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ChatSessionCard({
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.borderLight,
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surfaceGlass,
                  Colors.transparent,
                ],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Cyan accent indicator
                      Container(
                        width: 4,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withValues(alpha: 0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Chat icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          IconsaxPlusBold.message_text_1,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  IconsaxPlusBold.message,
                                  size: 12,
                                  color: AppColors.textMuted.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${session.messageCount}',
                                  style: TextStyle(
                                    color: AppColors.textMuted.withValues(alpha: 0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  IconsaxPlusBold.clock,
                                  size: 12,
                                  color: AppColors.textMuted.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(session.lastMessageAt),
                                  style: TextStyle(
                                    color: AppColors.textMuted.withValues(alpha: 0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Delete button
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => _buildDeleteDialog(context),
                          );
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.borderLight,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            IconsaxPlusBold.trash,
                            size: 16,
                            color: AppColors.textMuted.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteDialog(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      title: const Row(
        children: [
          Icon(
            IconsaxPlusBold.danger,
            color: AppColors.error,
            size: 24,
          ),
          SizedBox(width: 12),
          Text(
            'Delete Chat',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: const Text(
        'Are you sure you want to delete this chat? This action cannot be undone.',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDelete();
          },
          child: const Text(
            'Delete',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}
