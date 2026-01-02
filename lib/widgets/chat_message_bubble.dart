import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../main.dart';
import '../models/chat_message.dart';

/// Tool call status indicator
enum ToolCallStatus { executing, complete, error }

/// Represents a single tool call indicator in the chat
class ToolCallIndicator {
  final String toolName;
  final ToolCallStatus status;
  final int? resultCount;
  final Map<String, dynamic>? params;

  ToolCallIndicator({
    required this.toolName,
    required this.status,
    this.resultCount,
    this.params,
  });

  String get icon {
    switch (toolName) {
      case 'search_offers':
        return '🔍';
      case 'get_offer_price':
        return '💰';
      case 'get_free_games':
        return '🎮';
      case 'get_offer_details':
        return '📋';
      case 'get_top_sellers':
      case 'get_top_wishlisted':
        return '⭐';
      case 'get_upcoming_games':
        return '🗓️';
      case 'get_latest_releases':
        return '🆕';
      case 'search_sellers':
        return '🏢';
      default:
        return '🔧';
    }
  }

  String get displayName {
    switch (toolName) {
      case 'search_offers':
        return 'Search Offers';
      case 'get_offer_price':
        return 'Get Pricing';
      case 'get_free_games':
        return 'Free Games';
      case 'get_offer_details':
        return 'Game Details';
      case 'get_top_sellers':
        return 'Top Sellers';
      case 'get_top_wishlisted':
        return 'Most Wishlisted';
      case 'get_upcoming_games':
        return 'Upcoming Games';
      case 'get_latest_releases':
        return 'Latest Releases';
      case 'search_sellers':
        return 'Search Publishers';
      default:
        return toolName;
    }
  }

  String get statusText {
    switch (status) {
      case ToolCallStatus.executing:
        return '';
      case ToolCallStatus.complete:
        if (resultCount != null && resultCount! > 0) {
          return '✓ Found $resultCount ${resultCount == 1 ? "result" : "results"}';
        }
        return '✓ Complete';
      case ToolCallStatus.error:
        return '✗ Error';
    }
  }
}

/// Parsed message with separated display text and tool calls
class ParsedMessage {
  final String displayText;
  final List<ToolCallIndicator> toolCalls;

  ParsedMessage({required this.displayText, required this.toolCalls});
}

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    // Parse tool calls and answer sections
    final parsedMessage = _parseMessage(message.content);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message content (no bubble for AI, bubble for user)
          Flexible(
            child: message.isUser
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tool call indicators
                      if (parsedMessage.toolCalls.isNotEmpty) ...[
                        Wrap(
                          children: parsedMessage.toolCalls
                              .map((tool) => _buildToolCallChip(context, tool))
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Answer text
                      if (parsedMessage.displayText.isNotEmpty)
                        RichText(
                          text: _buildFormattedText(parsedMessage.displayText),
                        ),

                      // Streaming indicator - show when:
                      // 1. No tools and no text yet (initial thinking), OR
                      // 2. Tools are complete but no text yet (waiting for final answer)
                      if (message.isStreaming &&
                          parsedMessage.displayText.isEmpty &&
                          (parsedMessage.toolCalls.isEmpty ||
                              parsedMessage.toolCalls.every(
                                  (t) => t.status != ToolCallStatus.executing))) ...[
                        Shimmer.fromColors(
                          baseColor: AppColors.textMuted,
                          highlightColor: AppColors.accent.withValues(alpha: 0.5),
                          period: const Duration(milliseconds: 1500),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 14,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Thinking...',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Timestamp
                      if (!message.isStreaming && !message.isUser) ...[
                        const SizedBox(height: 6),
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Build a tool call chip widget
  Widget _buildToolCallChip(BuildContext context, ToolCallIndicator tool) {
    Color chipColor;
    Color textColor;

    switch (tool.status) {
      case ToolCallStatus.executing:
        chipColor = AppColors.accent.withValues(alpha: 0.2);
        textColor = AppColors.accent;
        break;
      case ToolCallStatus.complete:
        chipColor = Colors.green.withValues(alpha: 0.2);
        textColor = Colors.green;
        break;
      case ToolCallStatus.error:
        chipColor = Colors.red.withValues(alpha: 0.2);
        textColor = Colors.red;
        break;
    }

    final chipWidget = Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Text(tool.icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),

          // Tool name
          Text(
            tool.displayName,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          // Loading spinner for executing status
          if (tool.status == ToolCallStatus.executing) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: textColor,
              ),
            ),
          ],

          // Status text
          if (tool.statusText.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              tool.statusText,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );

    // Wrap with Tooltip if params exist
    if (tool.params != null && tool.params!.isNotEmpty) {
      return Tooltip(
        message: _formatParams(tool.params!),
        preferBelow: false,
        padding: const EdgeInsets.all(8),
        textStyle: const TextStyle(
          fontSize: 11,
          color: Colors.white,
          fontFamily: 'monospace',
        ),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(6),
        ),
        child: chipWidget,
      );
    }

    return chipWidget;
  }

  /// Format parameters for display
  String _formatParams(Map<String, dynamic> params) {
    final buffer = StringBuffer();
    params.forEach((key, value) {
      buffer.write('$key: ');
      if (value is List) {
        buffer.write('[${value.join(', ')}]');
      } else if (value is Map) {
        buffer.write(jsonEncode(value));
      } else {
        buffer.write(value);
      }
      buffer.write('\n');
    });
    return buffer.toString().trim();
  }

  /// Parse message content to extract tool calls and display text
  ParsedMessage _parseMessage(String content) {
    final toolCallsMap = <String, ToolCallIndicator>{}; // Use map to deduplicate by tool name
    final displayTextBuffer = StringBuffer();

    // Regex: <tool:name:status:count:params> or <tool:name:status:params> or <tool:name:status>
    final toolPattern = RegExp(
      r'<tool:([^:]+):([^:>]+)(?::(\d+))?(?::([^>]+))?>',
      multiLine: true,
    );

    int lastIndex = 0;

    for (final match in toolPattern.allMatches(content)) {
      // Add text before this tag
      displayTextBuffer.write(content.substring(lastIndex, match.start));

      final toolName = match.group(1)!;
      final statusStr = match.group(2)!;
      final countStr = match.group(3);
      final paramsEncoded = match.group(4);

      final status = statusStr == 'executing'
          ? ToolCallStatus.executing
          : statusStr == 'error'
              ? ToolCallStatus.error
              : ToolCallStatus.complete;

      final count = countStr != null ? int.tryParse(countStr) : null;

      // Decode params if present
      Map<String, dynamic>? params;
      if (paramsEncoded != null && paramsEncoded.isNotEmpty) {
        try {
          final decoded = Uri.decodeComponent(paramsEncoded);
          params = jsonDecode(decoded) as Map<String, dynamic>;
        } catch (e) {
          // Ignore parsing errors
        }
      }

      final indicator = ToolCallIndicator(
        toolName: toolName,
        status: status,
        resultCount: count,
        params: params,
      );

      // Only keep the latest status for each tool (complete/error overrides executing)
      final existing = toolCallsMap[toolName];
      if (existing == null ||
          existing.status == ToolCallStatus.executing ||
          status != ToolCallStatus.executing) {
        toolCallsMap[toolName] = indicator;
      }

      lastIndex = match.end;
    }

    // Add remaining text
    displayTextBuffer.write(content.substring(lastIndex));

    return ParsedMessage(
      displayText: displayTextBuffer.toString().trim(),
      toolCalls: toolCallsMap.values.toList(),
    );
  }

  // Simple markdown-to-TextSpan converter
  TextSpan _buildFormattedText(String text) {
    final spans = <InlineSpan>[];
    final lines = text.split('\n');

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];

      // Handle bullet points (but NOT if line starts with ** for bold)
      if ((line.trim().startsWith('•') || line.trim().startsWith('* ')) &&
          !line.trim().startsWith('**')) {
        line = line.replaceFirst(RegExp(r'^\s*[•*]\s*'), '• ');
      }

      // Parse inline formatting
      final lineSpans = <InlineSpan>[];
      var currentPos = 0;

      // Find bold (**text**) and strikethrough (~~text~~)
      final pattern = RegExp(r'\*\*(.+?)\*\*|~~(.+?)~~');
      final matches = pattern.allMatches(line);

      for (final match in matches) {
        // Add text before the match
        if (match.start > currentPos) {
          lineSpans.add(TextSpan(
            text: line.substring(currentPos, match.start),
          ));
        }

        // Add formatted text
        if (match.group(1) != null) {
          // Bold text
          lineSpans.add(TextSpan(
            text: match.group(1),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ));
        } else if (match.group(2) != null) {
          // Strikethrough text
          lineSpans.add(TextSpan(
            text: match.group(2),
            style: const TextStyle(decoration: TextDecoration.lineThrough),
          ));
        }

        currentPos = match.end;
      }

      // Add remaining text
      if (currentPos < line.length) {
        lineSpans.add(TextSpan(
          text: line.substring(currentPos),
        ));
      }

      // Add the line to spans
      spans.addAll(lineSpans);

      // Add newline if not the last line
      if (i < lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return TextSpan(
      children: spans,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        height: 1.4,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
