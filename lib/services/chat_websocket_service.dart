import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/referenced_offer.dart';

/// Events that can be received from the WebSocket
enum ChatEventType {
  toolProgress,
  textDelta,
  complete,
  error,
  referencedOffers,
}

/// Base event class
abstract class ChatEvent {
  final ChatEventType type;
  const ChatEvent(this.type);
}

/// Tool progress event
class ToolProgressEvent extends ChatEvent {
  final String toolName;
  final String? status;

  const ToolProgressEvent({
    required this.toolName,
    this.status,
  }) : super(ChatEventType.toolProgress);
}

/// Text delta event (streaming text chunk)
class TextDeltaEvent extends ChatEvent {
  final String delta;

  const TextDeltaEvent(this.delta) : super(ChatEventType.textDelta);
}

/// Complete event (message finished)
class CompleteEvent extends ChatEvent {
  final String? messageId;

  const CompleteEvent({this.messageId}) : super(ChatEventType.complete);
}

/// Error event
class ErrorEvent extends ChatEvent {
  final String message;

  const ErrorEvent(this.message) : super(ChatEventType.error);
}

/// Referenced offers event (game offers mentioned in the AI response)
class ReferencedOffersEvent extends ChatEvent {
  final List<ReferencedOffer> offers;

  const ReferencedOffersEvent(this.offers)
      : super(ChatEventType.referencedOffers);
}

class ChatWebSocketService {
  static const String wsBaseUrl = 'wss://ai.egdata.app';

  WebSocketChannel? _channel;
  final StreamController<ChatEvent> _eventController =
      StreamController<ChatEvent>.broadcast();

  bool get isConnected => _channel != null;

  /// Stream of chat events (tool_progress, text_delta, complete, error)
  Stream<ChatEvent> get events => _eventController.stream;

  /// Connect to the WebSocket for a specific session
  Future<void> connect({
    required String userId,
    required String sessionId,
  }) async {
    // Close existing connection if any
    await disconnect();

    try {
      final uri = Uri.parse('$wsBaseUrl/?agentId=$userId&sessionId=$sessionId');
      debugPrint('[WebSocket] Connecting to: $uri');
      _channel = WebSocketChannel.connect(uri);

      // Listen to incoming messages
      _channel!.stream.listen(
        (message) {
          debugPrint('[WebSocket] Received message: $message');
          try {
            final data = json.decode(message);
            debugPrint('[WebSocket] Parsed data: $data');
            final event = _parseEvent(data);
            if (event != null) {
              debugPrint('[WebSocket] Event: ${event.type}');
              _eventController.add(event);
            } else {
              debugPrint('[WebSocket] Unknown event type, ignoring');
            }
          } catch (e) {
            debugPrint('[WebSocket] Parse error: $e');
            _eventController.add(ErrorEvent('Failed to parse message: $e'));
          }
        },
        onError: (error) {
          debugPrint('[WebSocket] Error: $error');
          _eventController.add(ErrorEvent('WebSocket error: $error'));
        },
        onDone: () {
          debugPrint('[WebSocket] Connection closed');
          // Connection closed
          _channel = null;
        },
      );
      debugPrint('[WebSocket] Connected successfully');
    } catch (e) {
      debugPrint('[WebSocket] Connection failed: $e');
      _eventController.add(ErrorEvent('Failed to connect: $e'));
      rethrow;
    }
  }

  /// Send a chat message
  Future<void> sendMessage({
    required String message,
    required String sessionId,
  }) async {
    if (_channel == null) {
      debugPrint('[WebSocket] Cannot send: not connected');
      throw Exception('WebSocket not connected');
    }

    final payload = json.encode({
      'type': 'chat',
      'message': message,
      'sessionId': sessionId,
    });

    debugPrint('[WebSocket] Sending message: $payload');
    _channel!.sink.add(payload);
  }

  /// Disconnect from the WebSocket
  Future<void> disconnect() async {
    debugPrint('[WebSocket] Disconnecting...');
    await _channel?.sink.close();
    _channel = null;
    debugPrint('[WebSocket] Disconnected');
  }

  /// Parse incoming event data
  ChatEvent? _parseEvent(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    debugPrint('[WebSocket] Parsing event type: $type');

    switch (type) {
      case 'tool_progress':
        // API sends 'tool' not 'toolName'
        final toolName = data['tool'] ?? data['toolName'] ?? 'unknown';
        final status = data['status'];
        final message = data['message'];
        debugPrint('[WebSocket] Tool progress: $toolName ($status) - $message');
        return ToolProgressEvent(
          toolName: toolName,
          status: status,
        );

      case 'text_delta':
        // API sends 'text' not 'delta'
        final delta = data['text'] ?? data['delta'] ?? '';
        debugPrint('[WebSocket] Text delta: ${delta.length} chars');
        return TextDeltaEvent(delta);

      case 'complete':
        final messageId = data['messageId'];
        debugPrint('[WebSocket] Complete: messageId=$messageId');
        return CompleteEvent(messageId: messageId);

      case 'error':
        final message = data['message'] ?? 'Unknown error';
        debugPrint('[WebSocket] Error: $message');
        return ErrorEvent(message);

      case 'referenced_offers':
        final offersData = data['offers'] as List<dynamic>? ?? [];
        final offers = offersData
            .map((offerJson) => ReferencedOffer.fromJson(offerJson))
            .toList();
        debugPrint('[WebSocket] Referenced offers: ${offers.length} offers');
        return ReferencedOffersEvent(offers);

      default:
        debugPrint('[WebSocket] Unknown event type: $type');
        return null; // Unknown event type
    }
  }

  /// Dispose of resources
  void dispose() {
    disconnect();
    _eventController.close();
  }
}
