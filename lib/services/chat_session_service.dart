import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_session.dart';
import '../models/chat_message.dart';

class ChatSessionService {
  static const String baseUrl = 'https://ai.egdata.app';

  final String userId;
  final http.Client _client;

  ChatSessionService({required this.userId, http.Client? client})
      : _client = client ?? http.Client();

  /// List all chat sessions for the user
  Future<List<ChatSession>> listSessions({
    int limit = 50,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$baseUrl/api/sessions')
        .replace(queryParameters: {
      'userId': userId,
      'limit': limit.toString(),
      'offset': offset.toString(),
    });

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to list sessions: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final sessions = (data['sessions'] as List)
        .map((session) => ChatSession.fromJson(session))
        .toList();

    return sessions;
  }

  /// Create a new chat session
  Future<ChatSession> createSession({String? title}) async {
    final uri = Uri.parse('$baseUrl/api/sessions');

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
        if (title != null) 'title': title,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create session: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    return ChatSession.fromJson(data['session']);
  }

  /// Get chat session details with message history
  Future<({ChatSession session, List<ChatMessage> messages})> getSession(
    String sessionId, {
    bool includeMessages = true,
  }) async {
    final uri = Uri.parse('$baseUrl/api/sessions/$sessionId')
        .replace(queryParameters: {
      'userId': userId,
      'includeMessages': includeMessages.toString(),
    });

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to get session: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final session = ChatSession.fromJson(data['session']);
    final messages = includeMessages
        ? (data['messages'] as List?)
                ?.map((msg) => ChatMessage.fromJson(msg))
                .toList() ??
            []
        : <ChatMessage>[];

    return (session: session, messages: messages);
  }

  /// Rename a chat session
  Future<void> renameSession(String sessionId, String newTitle) async {
    final uri = Uri.parse('$baseUrl/api/sessions/$sessionId');

    final response = await _client.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId,
        'title': newTitle,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to rename session: ${response.statusCode}');
    }
  }

  /// Delete a chat session
  Future<void> deleteSession(String sessionId) async {
    final uri = Uri.parse('$baseUrl/api/sessions/$sessionId')
        .replace(queryParameters: {
      'userId': userId,
    });

    final response = await _client.delete(uri);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete session: ${response.statusCode}');
    }
  }

  /// Dispose of HTTP client resources
  void dispose() {
    _client.close();
  }
}
