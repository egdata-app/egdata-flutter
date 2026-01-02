import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Animated text widget that smoothly batches and animates text chunks as they stream
class AnimatedStreamingText extends HookWidget {
  final String text;
  final TextSpan Function(String) textBuilder;
  final bool isStreaming;

  const AnimatedStreamingText({
    super.key,
    required this.text,
    required this.textBuilder,
    this.isStreaming = true,
  });

  @override
  Widget build(BuildContext context) {
    // Displayed text that animates in batches
    final displayedText = useState('');
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 250),
    );

    // Batch text updates to avoid animating every single character
    useEffect(() {
      if (!isStreaming) {
        // Streaming complete, show all text immediately
        displayedText.value = text;
        return null;
      }

      Timer? debounceTimer;

      // Batch updates: only animate every 100ms
      if (text != displayedText.value) {
        debounceTimer = Timer(const Duration(milliseconds: 100), () {
          if (text != displayedText.value) {
            displayedText.value = text;
            animationController.forward(from: 0.0);
          }
        });
      }

      return () => debounceTimer?.cancel();
    }, [text, isStreaming]);

    if (!isStreaming || text.isEmpty) {
      // No animation for non-streaming or empty text
      return RichText(text: textBuilder(text));
    }

    final animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: 0.4 + (animation.value * 0.6), // Fade from 0.4 to 1.0
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 3),
            child: RichText(text: textBuilder(displayedText.value)),
          ),
        );
      },
    );
  }
}
