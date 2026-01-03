import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import '../models/chat_session.dart';
import '../models/settings.dart';
import '../services/chat_session_service.dart';
import '../database/database_service.dart';
import 'mobile_chat_page.dart';

class MobileChatSessionsPage extends HookWidget {
  final AppSettings settings;
  final ChatSessionService chatService;

  const MobileChatSessionsPage({
    super.key,
    required this.settings,
    required this.chatService,
  });

  @override
  Widget build(BuildContext context) {
    final sessions = useState<List<ChatSession>>([]);
    final isLoading = useState(true);
    final error = useState<String?>(null);

    // Load sessions on mount
    useEffect(() {
      Future<void> loadSessions() async {
        try {
          isLoading.value = true;
          error.value = null;
          final loadedSessions = await chatService.listSessions();
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
          error.value = e.toString();
        } finally {
          isLoading.value = false;
        }
      }

      loadSessions();
      return null;
    }, []);

    Future<void> createNewChat() async {
      try {
        final newSession = await chatService.createSession();
        sessions.value = [newSession, ...sessions.value];

        // Navigate to the new chat
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MobileChatPage(
                settings: settings,
                chatService: chatService,
                session: newSession,
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
            const SnackBar(content: Text('Chat deleted')),
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
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('AI Chat'),
        backgroundColor: const Color(0xFF141414),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: createNewChat,
            tooltip: 'New Chat',
          ),
        ],
      ),
      body: isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : error.value != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${error.value}',
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          isLoading.value = true;
                          error.value = null;
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : sessions.value.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.white24,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No chats yet',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Start a new conversation',
                            style: TextStyle(color: Colors.white38),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: createNewChat,
                            icon: const Icon(Icons.add),
                            label: const Text('New Chat'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00D4FF),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sessions.value.length,
                      itemBuilder: (context, index) {
                        final session = sessions.value[index];
                        return _ChatSessionCard(
                          session: session,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => MobileChatPage(
                                  settings: settings,
                                  chatService: chatService,
                                  session: session,
                                  onSessionUpdated: () async {
                                    final updatedSessions = await chatService.listSessions();
                                    sessions.value = updatedSessions;
                                  },
                                ),
                              ),
                            );
                          },
                          onDelete: () => deleteSession(session),
                        );
                      },
                    ),
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
    return Card(
      color: const Color(0xFF141414),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF1F1F1F)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFF00D4FF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${session.messageCount} messages',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                        const Text(
                          ' • ',
                          style: TextStyle(color: Colors.white38),
                        ),
                        Text(
                          _formatDate(session.lastMessageAt),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.white54,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF1F1F1F),
                      title: const Text(
                        'Delete Chat',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'Are you sure you want to delete this chat? This action cannot be undone.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onDelete();
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
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
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}
