import 'package:flutter/material.dart';
import '../main.dart';
import '../models/chat_message.dart';

class ChatMessageBubble extends StatefulWidget {
  final ChatMessage message;

  const ChatMessageBubble({
    super.key,
    required this.message,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble>
    with SingleTickerProviderStateMixin {
  bool _isThinkingExpanded = false;
  AnimationController? _shimmerController;
  Animation<double>? _shimmerAnimation;
  DateTime? _thinkingStartTime;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _shimmerController!, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Parse thinking and answer sections
    final parsedMessage = _parseMessage(widget.message.content);

    // Track thinking start time
    if (widget.message.isStreaming &&
        parsedMessage['thinking'] != null &&
        parsedMessage['answer'] == null &&
        _thinkingStartTime == null) {
      _thinkingStartTime = DateTime.now();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: widget.message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message content (no bubble for AI, bubble for user)
          Flexible(
            child: widget.message.isUser
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
                      widget.message.content,
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
                  // Thinking section (collapsible)
                  if (parsedMessage['thinking'] != null) ...[
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isThinkingExpanded = !_isThinkingExpanded;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Apply shimmer only to text when thinking
                                if (widget.message.isStreaming &&
                                    parsedMessage['answer'] == null &&
                                    _shimmerAnimation != null)
                                  AnimatedBuilder(
                                    animation: _shimmerAnimation!,
                                    builder: (context, child) {
                                      return ShaderMask(
                                        blendMode: BlendMode.srcIn,
                                        shaderCallback: (bounds) {
                                          return LinearGradient(
                                            begin: Alignment(
                                                _shimmerAnimation!.value, 0),
                                            end: Alignment(
                                                _shimmerAnimation!.value + 1, 0),
                                            colors: [
                                              AppColors.textMuted,
                                              AppColors.accent,
                                              AppColors.textMuted,
                                            ],
                                            stops: const [0.0, 0.5, 1.0],
                                          ).createShader(bounds);
                                        },
                                        child: Text(
                                          _getThinkingLabel(parsedMessage),
                                          style: TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                else
                                  Text(
                                    _getThinkingLabel(parsedMessage),
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                const SizedBox(width: 4),
                                Icon(
                                  _isThinkingExpanded
                                      ? Icons.expand_less
                                      : Icons.chevron_right,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                              ],
                            ),
                            if (_isThinkingExpanded) ...[
                              const SizedBox(height: 8),
                              RichText(
                                text: TextSpan(
                                  children: _buildFormattedText(
                                    parsedMessage['thinking']!,
                                  ).children,
                                  style: TextStyle(
                                    color: AppColors.textMuted
                                        .withValues(alpha: 0.7),
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Answer section (only show if there's an answer)
                  if (parsedMessage['answer'] != null)
                    RichText(
                      text: _buildFormattedText(parsedMessage['answer']!),
                    ),
                  // Streaming indicator (only show if no thinking section)
                  if (widget.message.isStreaming &&
                      parsedMessage['thinking'] == null) ...[
                    const SizedBox(height: 8),
                    Row(
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
                          'Thinking...',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Timestamp
                  if (!widget.message.isStreaming &&
                      !widget.message.isUser) ...[
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(widget.message.timestamp),
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

  String _getThinkingLabel(Map<String, String?> parsedMessage) {
    final isStreaming =
        widget.message.isStreaming && parsedMessage['answer'] == null;

    if (isStreaming) {
      return 'Thinking';
    } else {
      // Calculate thinking time
      if (_thinkingStartTime != null) {
        final thinkingDuration =
            widget.message.timestamp.difference(_thinkingStartTime!);
        final seconds = thinkingDuration.inSeconds;
        return 'Thought for ${seconds}s';
      }
      return 'Thought';
    }
  }

  Map<String, String?> _parseMessage(String content) {
    // Check if message contains thinking tags
    final thinkingStartIndex = content.indexOf('<thinking>');
    final thinkingEndIndex = content.indexOf('</thinking>');

    if (thinkingStartIndex != -1) {
      String? thinkingContent;
      String? answerContent;

      if (thinkingEndIndex != -1) {
        // Complete thinking section - extract thinking and answer
        thinkingContent = content
            .substring(
              thinkingStartIndex + '<thinking>'.length,
              thinkingEndIndex,
            )
            .trim();

        // Everything after </thinking> is the answer
        answerContent = content
            .substring(thinkingEndIndex + '</thinking>'.length)
            .trim();
      } else {
        // Incomplete thinking section (still streaming)
        thinkingContent = content
            .substring(thinkingStartIndex + '<thinking>'.length)
            .trim();
        answerContent = null;
      }

      return {
        'thinking': thinkingContent.isNotEmpty ? thinkingContent : null,
        'answer': answerContent != null && answerContent.isNotEmpty
            ? answerContent
            : null,
      };
    }

    // No thinking section found - entire content is answer
    return {
      'thinking': null,
      'answer': content,
    };
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
