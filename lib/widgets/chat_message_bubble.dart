import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shimmer/shimmer.dart';
import '../main.dart';
import '../models/chat_message.dart';
import 'animated_streaming_text.dart';

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
      case 'get_tags':
        return '🏷️';
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
      case 'get_tags':
        return 'Get Tags';
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

class ChatMessageBubble extends HookWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    // Parse tool calls and answer sections
    final parsedMessage = _parseMessage(message.content);

    // Check if any tools are still executing
    final hasExecutingTools = parsedMessage.toolCalls.any(
      (tool) => tool.status == ToolCallStatus.executing,
    );

    // Manual override state
    final manualExpandOverride = useState<bool?>(null);

    // Determine if should be expanded: auto-expand if executing, or use manual override
    final isExpanded = manualExpandOverride.value ?? hasExecutingTools;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                    child: Text(
                      message.content,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tool call indicators
                      if (parsedMessage.toolCalls.isNotEmpty) ...[
                        _buildToolCallsSection(
                          context,
                          parsedMessage.toolCalls,
                          isExpanded,
                          () {
                            // Toggle manual override
                            manualExpandOverride.value = !isExpanded;
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Answer text
                      if (parsedMessage.displayText.isNotEmpty)
                        AnimatedStreamingText(
                          text: parsedMessage.displayText,
                          textBuilder: _buildFormattedText,
                          isStreaming: message.isStreaming,
                        ),

                      // Streaming indicator
                      if (message.isStreaming &&
                          parsedMessage.displayText.isEmpty &&
                          (parsedMessage.toolCalls.isEmpty ||
                              parsedMessage.toolCalls.every(
                                (t) => t.status != ToolCallStatus.executing,
                              ))) ...[
                        Shimmer.fromColors(
                          baseColor: AppColors.textMuted,
                          highlightColor: AppColors.accent.withValues(
                            alpha: 0.5,
                          ),
                          period: const Duration(milliseconds: 1500),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.borderGlass.withValues(
                                  alpha: 0.5,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 14,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Thinking...',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Timestamp
                      if (!message.isStreaming && !message.isUser) ...[
                        const SizedBox(height: 8),
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
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

  /// Build tool calls section (collapsed or expanded)
  Widget _buildToolCallsSection(
    BuildContext context,
    List<ToolCallIndicator> toolCalls,
    bool isExpanded,
    VoidCallback onToggle,
  ) {
    if (isExpanded) {
      // Expanded view - chips morph into full size
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: toolCalls.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildMorphingToolChip(
                context,
                entry.value,
                isExpanded: true,
              ),
            );
          }).toList(),
        ),
      );
    } else {
      // Collapsed view - chips morph into circles
      return GestureDetector(
        onTap: onToggle,
        child: SizedBox(
          height: 36,
          child: Stack(
            clipBehavior: Clip.none,
            children: toolCalls.asMap().entries.map((entry) {
              final index = entry.key;
              final tool = entry.value;
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                left: index * 24.0,
                top: 0,
                child: _buildMorphingToolChip(context, tool, isExpanded: false),
              );
            }).toList(),
          ),
        ),
      );
    }
  }

  /// Build a morphing tool chip that animates between expanded and collapsed
  Widget _buildMorphingToolChip(
    BuildContext context,
    ToolCallIndicator tool, {
    required bool isExpanded,
  }) {
    Color chipColor;
    Color textColor;
    Color borderColor;

    switch (tool.status) {
      case ToolCallStatus.executing:
        chipColor = AppColors.accent.withValues(alpha: 0.6);
        textColor = AppColors.accent;
        borderColor = AppColors.accent.withValues(alpha: 0.5);
        break;
      case ToolCallStatus.complete:
        chipColor = Colors.green.withValues(alpha: 0.6);
        textColor = Colors.green.shade400;
        borderColor = Colors.green.withValues(alpha: 0.4);
        break;
      case ToolCallStatus.error:
        chipColor = Colors.red.withValues(alpha: 0.6);
        textColor = Colors.red.shade400;
        borderColor = Colors.red.withValues(alpha: 0.4);
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: isExpanded ? null : 36,
      height: isExpanded ? null : 36,
      constraints: isExpanded ? const BoxConstraints(maxWidth: 300) : null,
      padding: isExpanded
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        // Solid background with gradient overlay for depth
        color: AppColors.surface,
        gradient: LinearGradient(
          colors: [
            chipColor,
            chipColor.withValues(alpha: chipColor.a * 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isExpanded ? 16 : 18),
        border: Border.all(color: borderColor, width: isExpanded ? 1 : 2),
        boxShadow: tool.status == ToolCallStatus.executing
            ? [
                BoxShadow(
                  color: textColor.withValues(alpha: isExpanded ? 0.2 : 0.4),
                  blurRadius: isExpanded ? 8 : 10,
                  spreadRadius: isExpanded ? 0 : 1,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon - always visible, centered when collapsed
          if (!isExpanded)
            Expanded(
              child: Center(
                child: Text(tool.icon, style: const TextStyle(fontSize: 14)),
              ),
            )
          else ...[
            // Expanded content
            Text(tool.icon, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                tool.displayName,
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Loading spinner or status
            if (tool.status == ToolCallStatus.executing) ...[
              const SizedBox(width: 10),
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: textColor,
                ),
              ),
            ],

            // Status text
            if (tool.statusText.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                tool.statusText,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Parse message content to extract tool calls and display text
  static ParsedMessage _parseMessage(String content) {
    final toolCallsMap =
        <String, ToolCallIndicator>{}; // Use map to deduplicate by tool name
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
  static TextSpan _buildFormattedText(String text) {
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
          lineSpans.add(
            TextSpan(text: line.substring(currentPos, match.start)),
          );
        }

        // Add formatted text
        if (match.group(1) != null) {
          // Bold text
          lineSpans.add(
            TextSpan(
              text: match.group(1),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        } else if (match.group(2) != null) {
          // Strikethrough text
          lineSpans.add(
            TextSpan(
              text: match.group(2),
              style: const TextStyle(decoration: TextDecoration.lineThrough),
            ),
          );
        }

        currentPos = match.end;
      }

      // Add remaining text
      if (currentPos < line.length) {
        lineSpans.add(TextSpan(text: line.substring(currentPos)));
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
      style: TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.4),
    );
  }

  static String _formatTime(DateTime time) {
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
