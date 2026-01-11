import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../main.dart';
import '../models/chat_session.dart';
import '../models/referenced_offer.dart';
import '../services/chat_session_service.dart';
import '../services/chat_websocket_service.dart';
import '../services/user_service.dart';

/// Result returned when user wants to continue the conversation in full chat
class AskAIContinueResult {
  final ChatSession session;
  final String userMessage;
  final String aiResponse;
  final List<ReferencedOffer> referencedOffers;

  AskAIContinueResult({
    required this.session,
    required this.userMessage,
    required this.aiResponse,
    required this.referencedOffers,
  });
}

class AskAIBottomSheet extends StatefulWidget {
  final String offerTitle;
  final String offerId;
  final String? offerType;
  final ChatSessionService chatService;
  final ValueChanged<AskAIContinueResult>? onContinueInChat;

  const AskAIBottomSheet({
    super.key,
    required this.offerTitle,
    required this.offerId,
    required this.chatService,
    this.offerType,
    this.onContinueInChat,
  });

  @override
  State<AskAIBottomSheet> createState() => _AskAIBottomSheetState();
}

class _AskAIBottomSheetState extends State<AskAIBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  bool _hasText = false;
  bool _isConnecting = false;
  bool _isSending = false;
  bool _hasResponse = false;
  String _aiResponse = '';
  String _userMessage = '';
  String? _currentTool;
  List<ReferencedOffer> _referencedOffers = [];

  ChatWebSocketService? _wsService;
  StreamSubscription<ChatEvent>? _eventSubscription;
  ChatSession? _session;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _eventSubscription?.cancel();
    _wsService?.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  Future<void> _connectAndSend(String message) async {
    setState(() {
      _isConnecting = true;
      _userMessage = message;
    });

    try {
      // Create a new session
      _session = await widget.chatService.createSession(
        title: widget.offerTitle,
      );

      // Get user ID and connect to WebSocket
      final userId = await UserService.getUserId();
      _wsService = ChatWebSocketService();

      await _wsService!.connect(
        userId: userId,
        sessionId: _session!.id,
      );

      setState(() {
        _isConnecting = false;
        _isSending = true;
      });

      // Listen to events
      _eventSubscription = _wsService!.events.listen(_handleEvent);

      // Send the message
      await _wsService!.sendMessage(
        message: message,
        sessionId: _session!.id,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleEvent(ChatEvent event) {
    if (!mounted) return;

    if (event is ToolProgressEvent) {
      setState(() {
        _currentTool = event.toolName;
      });
    } else if (event is TextDeltaEvent) {
      setState(() {
        _aiResponse += event.delta;
        _hasResponse = true;
      });
      // Auto-scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    } else if (event is ReferencedOffersEvent) {
      setState(() {
        _referencedOffers = event.offers;
      });
    } else if (event is CompleteEvent) {
      setState(() {
        _isSending = false;
        _currentTool = null;
      });
    } else if (event is ErrorEvent) {
      setState(() {
        _isSending = false;
        _currentTool = null;
        if (_aiResponse.isEmpty) {
          _aiResponse = 'Sorry, an error occurred: ${event.message}';
          _hasResponse = true;
        }
      });
    }
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    _focusNode.unfocus();
    _controller.clear();

    // Build the message with context about the offer
    final contextMessage =
        'About "${widget.offerTitle}"${widget.offerType != null ? ' (${_formatOfferType(widget.offerType!)})' : ''}: $text';

    _connectAndSend(contextMessage);
  }

  void _submitSuggestion(String text) {
    if (_isSending) return;

    _focusNode.unfocus();

    // Build the message with context about the offer
    final contextMessage =
        'About "${widget.offerTitle}"${widget.offerType != null ? ' (${_formatOfferType(widget.offerType!)})' : ''}: $text';

    _connectAndSend(contextMessage);
  }

  void _continueInChat() {
    if (_session == null || widget.onContinueInChat == null) return;

    Navigator.of(context).pop();
    widget.onContinueInChat!(AskAIContinueResult(
      session: _session!,
      userMessage: _userMessage,
      aiResponse: _aiResponse,
      referencedOffers: _referencedOffers,
    ));
  }

  String _formatOfferType(String type) {
    switch (type) {
      case 'BASE_GAME':
        return 'Base Game';
      case 'DLC':
        return 'DLC';
      case 'ADD_ON':
        return 'Add-On';
      case 'BUNDLE':
        return 'Bundle';
      case 'EDITION':
        return 'Edition';
      case 'DEMO':
        return 'Demo';
      default:
        return type.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: AppColors.borderLight,
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                _buildHeader(),

                // Content area
                if (_hasResponse || _isSending || _isConnecting)
                  Flexible(child: _buildResponseArea())
                else
                  _buildSuggestions(),

                // Input or action buttons
                if (_hasResponse && !_isSending)
                  _buildActionButtons()
                else if (!_hasResponse)
                  _buildInputField(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          // AI icon with gradient
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primaryDark,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ask AI',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  widget.offerTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Tool indicator or close button
          if (_currentTool != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
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
                  const SizedBox(width: 6),
                  Text(
                    _currentTool!,
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
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
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suggestions',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSuggestionChip('Is it worth buying?'),
              _buildSuggestionChip('Similar games?'),
              _buildSuggestionChip('Price history?'),
              _buildSuggestionChip('Reviews?'),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () => _submitSuggestion(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bolt_rounded,
              size: 14,
              color: AppColors.primary.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _focusNode.hasFocus
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !_isSending,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  height: 1.4,
                ),
                decoration: const InputDecoration(
                  hintText: 'Ask anything about this game...',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 16,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(
                    left: 16,
                    right: 12,
                    top: 14,
                    bottom: 14,
                  ),
                ),
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
              ),
            ),
            // Send button
            Padding(
              padding: const EdgeInsets.only(right: 4, bottom: 4),
              child: GestureDetector(
                onTap: _hasText && !_isSending ? _submit : null,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: _hasText && !_isSending
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.accent,
                              AppColors.primary,
                            ],
                          )
                        : null,
                    color: _hasText && !_isSending
                        ? null
                        : AppColors.surface.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: _hasText && !_isSending
                        ? Colors.white
                        : AppColors.textMuted.withValues(alpha: 0.4),
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User message
        if (_userMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      // Show only the question part after the context
                      _userMessage.contains(': ')
                          ? _userMessage.split(': ').skip(1).join(': ')
                          : _userMessage,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // AI response
        Flexible(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primaryDark,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isConnecting)
                        _buildLoadingIndicator('Connecting...')
                      else if (_isSending && _aiResponse.isEmpty)
                        _buildLoadingIndicator('Thinking...')
                      else if (_aiResponse.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: MarkdownBody(
                            data: _aiResponse,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                                height: 1.5,
                              ),
                              strong: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              listBullet: const TextStyle(
                                color: AppColors.primary,
                              ),
                              code: TextStyle(
                                backgroundColor: AppColors.surfaceLight,
                                color: AppColors.accent,
                                fontSize: 13,
                              ),
                              codeblockDecoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            selectable: true,
                          ),
                        ),

                      // Referenced offers
                      if (_referencedOffers.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          '${_referencedOffers.length} game${_referencedOffers.length > 1 ? 's' : ''} mentioned',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _referencedOffers.take(3).map((offer) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.borderLight,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.videogame_asset_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    offer.title.length > 20
                                        ? '${offer.title.substring(0, 20)}...'
                                        : offer.title,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          // Close button
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.borderLight,
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Continue in chat button
          if (widget.onContinueInChat != null)
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _continueInChat,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary,
                        AppColors.primaryDark,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Continue in Chat',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
