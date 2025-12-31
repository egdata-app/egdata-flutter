import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../main.dart';

class CustomTitleBar extends StatefulWidget {
  final VoidCallback onClose;
  final String title;

  const CustomTitleBar({
    super.key,
    required this.onClose,
    this.title = 'EGData Client',
  });

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    _checkMaximized();
  }

  Future<void> _checkMaximized() async {
    if (Platform.isWindows || Platform.isMacOS) {
      final maximized = await windowManager.isMaximized();
      if (mounted) {
        setState(() => _isMaximized = maximized);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          // Draggable area with double-tap to maximize
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) => windowManager.startDragging(),
              onDoubleTap: _toggleMaximize,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  // App icon
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.gamepad_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Title
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Window controls (outside the double-tap area)
          _WindowButton(
            icon: Icons.remove,
            onPressed: () => windowManager.minimize(),
            hoverColor: AppColors.surfaceHover,
          ),
          _WindowButton(
            icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
            iconSize: _isMaximized ? 14 : 16,
            onPressed: _toggleMaximize,
            hoverColor: AppColors.surfaceHover,
          ),
          _WindowButton(
            icon: Icons.close,
            onPressed: widget.onClose,
            hoverColor: AppColors.error,
            hoverIconColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Future<void> _toggleMaximize() async {
    if (_isMaximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
    setState(() => _isMaximized = !_isMaximized);
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color hoverColor;
  final Color? hoverIconColor;
  final double iconSize;

  const _WindowButton({
    required this.icon,
    required this.onPressed,
    required this.hoverColor,
    this.hoverIconColor,
    this.iconSize = 16,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 40,
          color: _isHovered ? widget.hoverColor : Colors.transparent,
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: _isHovered && widget.hoverIconColor != null
                ? widget.hoverIconColor
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
