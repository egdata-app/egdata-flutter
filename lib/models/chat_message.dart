import 'referenced_offer.dart';

class ChatMessage {
  final String id;
  final String sessionId;
  final String role; // "user" or "assistant"
  final String content;
  final DateTime timestamp;
  final bool isStreaming;
  final List<ReferencedOffer>? referencedOffers;

  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
    this.referencedOffers,
  });

  /// Helper to check if message is from user
  bool get isUser => role == 'user';

  ChatMessage copyWith({
    String? id,
    String? sessionId,
    String? role,
    String? content,
    DateTime? timestamp,
    bool? isStreaming,
    List<ReferencedOffer>? referencedOffers,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      referencedOffers: referencedOffers ?? this.referencedOffers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'role': role,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isStreaming': isStreaming,
      'referencedOffers':
          referencedOffers?.map((offer) => offer.toJson()).toList(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      sessionId: json['sessionId'] ?? '',
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
          : DateTime.now(),
      isStreaming: json['isStreaming'] ?? false,
      referencedOffers: json['referencedOffers'] != null
          ? (json['referencedOffers'] as List<dynamic>)
              .map((offerJson) => ReferencedOffer.fromJson(offerJson))
              .toList()
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
