import 'package:flutter/material.dart';
import '../main.dart';

class ChatSuggestedPrompts extends StatelessWidget {
  final ValueChanged<String> onPromptTapped;

  const ChatSuggestedPrompts({
    super.key,
    required this.onPromptTapped,
  });

  static const List<Map<String, String>> _prompts = [
    {
      'icon': '🎮',
      'text': 'What are the current free games?',
    },
    {
      'icon': '💰',
      'text': 'Show me RPGs under \$20',
    },
    {
      'icon': '🔥',
      'text': 'What\'s on sale this week?',
    },
    {
      'icon': '⭐',
      'text': 'Best indie games right now',
    },
    {
      'icon': '🎯',
      'text': 'Show me multiplayer games',
    },
    {
      'icon': '🏆',
      'text': 'Latest AAA releases',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: _prompts.take(4).map((prompt) {
        return _PromptChip(
          icon: prompt['icon']!,
          text: prompt['text']!,
          onTap: () => onPromptTapped(prompt['text']!),
        );
      }).toList(),
    );
  }
}

class _PromptChip extends StatelessWidget {
  final String icon;
  final String text;
  final VoidCallback onTap;

  const _PromptChip({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.borderGlass.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
