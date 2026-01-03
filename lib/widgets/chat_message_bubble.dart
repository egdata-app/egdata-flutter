import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/chat_message.dart';

class ChatMessageBubble extends HookWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  /// Format timestamp Discord-style (relative time)
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    final timeFormat = DateFormat('h:mm a');

    if (messageDate == today) {
      return 'Today at ${timeFormat.format(timestamp)}';
    } else if (messageDate == yesterday) {
      return 'Yesterday at ${timeFormat.format(timestamp)}';
    } else if (difference.inDays < 7) {
      // Show day of week for last 7 days
      final dayFormat = DateFormat('EEEE');
      return '${dayFormat.format(timestamp)} at ${timeFormat.format(timestamp)}';
    } else if (timestamp.year == now.year) {
      // Same year: "Dec 15 at 4:20 PM"
      final dateFormat = DateFormat('MMM d');
      return '${dateFormat.format(timestamp)} at ${timeFormat.format(timestamp)}';
    } else {
      // Different year: "Dec 15, 2024 at 4:20 PM"
      final dateFormat = DateFormat('MMM d, y');
      return '${dateFormat.format(timestamp)} at ${timeFormat.format(timestamp)}';
    }
  }

  /// Format Discord-style timestamp tags
  String _formatDiscordTimestamp(int timestamp, String format) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    switch (format) {
      case 'R': // Relative time
        if (difference.isNegative) {
          final absDiff = difference.abs();
          if (absDiff.inDays > 0) {
            return '${absDiff.inDays} day${absDiff.inDays > 1 ? 's' : ''} ago';
          } else if (absDiff.inHours > 0) {
            return '${absDiff.inHours} hour${absDiff.inHours > 1 ? 's' : ''} ago';
          } else if (absDiff.inMinutes > 0) {
            return '${absDiff.inMinutes} minute${absDiff.inMinutes > 1 ? 's' : ''} ago';
          } else {
            return 'just now';
          }
        } else {
          if (difference.inDays > 0) {
            return 'in ${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
          } else if (difference.inHours > 0) {
            return 'in ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
          } else if (difference.inMinutes > 0) {
            return 'in ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
          } else {
            return 'in a moment';
          }
        }

      case 'f': // Short date/time
        return DateFormat('MMMM d, y \'at\' h:mm a').format(dateTime);

      case 'F': // Long date/time
        return DateFormat('EEEE, MMMM d, y \'at\' h:mm a').format(dateTime);

      case 't': // Short time
        return DateFormat('h:mm a').format(dateTime);

      case 'T': // Long time
        return DateFormat('h:mm:ss a').format(dateTime);

      case 'd': // Short date
        return DateFormat('MM/dd/y').format(dateTime);

      case 'D': // Long date
        return DateFormat('MMMM d, y').format(dateTime);

      default:
        return DateFormat('MMMM d, y \'at\' h:mm a').format(dateTime);
    }
  }

  /// Clean markdown content (remove thread-title tags, parse Discord timestamps)
  String _cleanContent(String content) {
    // Remove thread-title tags
    var cleaned = content.replaceAll(RegExp(r'<thread-title>.*?</thread-title>'), '');

    // Parse Discord timestamp tags: <t:TIMESTAMP:FORMAT>
    final timestampRegex = RegExp(r'<t:(\d+):([RfFtTdD])>');
    cleaned = cleaned.replaceAllMapped(timestampRegex, (match) {
      final timestamp = int.tryParse(match.group(1) ?? '');
      final format = match.group(2) ?? 'f';

      if (timestamp != null) {
        return _formatDiscordTimestamp(timestamp, format);
      }
      return match.group(0) ?? '';
    });

    return cleaned.trim();
  }

  @override
  Widget build(BuildContext context) {
    final cleanedContent = _cleanContent(message.content);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message content
          Flexible(
            child: message.isUser
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          message.content,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(message.timestamp),
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Answer text with markdown
                      if (cleanedContent.isNotEmpty)
                        MarkdownBody(
                          data: cleanedContent,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              height: 1.6,
                              letterSpacing: 0.2,
                            ),
                            h1: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                            h2: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                            h3: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                            strong: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            em: TextStyle(
                              color: AppColors.textPrimary,
                              fontStyle: FontStyle.italic,
                            ),
                            code: TextStyle(
                              color: AppColors.accent,
                              backgroundColor: AppColors.surface,
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.surface,
                                width: 1,
                              ),
                            ),
                            codeblockPadding: const EdgeInsets.all(12),
                            listBullet: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                            ),
                            tableBorder: TableBorder.all(
                              color: AppColors.surface,
                              width: 1,
                            ),
                            tableHead: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            tableBody: TextStyle(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),

                      // Timestamp for AI messages
                      if (cleanedContent.isNotEmpty && !message.isStreaming)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _formatTimestamp(message.timestamp),
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),

                      // Streaming indicator with icon
                      if (message.isStreaming && cleanedContent.isEmpty)
                        Shimmer.fromColors(
                          baseColor: AppColors.textMuted.withValues(alpha: 0.5),
                          highlightColor:
                              AppColors.textMuted.withValues(alpha: 0.2),
                          period: const Duration(milliseconds: 1200),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 16,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Thinking...',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
