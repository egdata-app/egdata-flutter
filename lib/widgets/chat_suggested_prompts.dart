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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Suggested prompts',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _prompts.length,
              itemBuilder: (context, index) {
                final prompt = _prompts[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < _prompts.length - 1 ? 8 : 0,
                  ),
                  child: _PromptChip(
                    icon: prompt['icon']!,
                    text: prompt['text']!,
                    onTap: () => onPromptTapped(prompt['text']!),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.borderGlass,
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
    );
  }
}
