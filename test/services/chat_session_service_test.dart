import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:egdata_flutter/services/chat_session_service.dart';
import 'package:egdata_flutter/models/chat_session.dart';

void main() {
  group('ChatSessionService', () {
    const userId = 'user123';
    const baseUrl = 'https://ai.egdata.app/api';

    test('listSessions returns list of ChatSession', () async {
      final mockResponse = {
        'sessions': [
          {
            'id': 'session1',
            'title': 'Session 1',
            'createdAt': 1672531200000,
            'lastMessageAt': 1672531200000,
            'messageCount': 5
          }
        ]
      };

      final client = MockClient((request) async {
        expect(request.url.path, '/api/sessions');
        expect(request.url.queryParameters['userId'], userId);
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final service = ChatSessionService(userId: userId, client: client);
      final sessions = await service.listSessions();

      expect(sessions, isA<List<ChatSession>>());
      expect(sessions.length, 1);
      expect(sessions.first.title, 'Session 1');
    });

    test('createSession returns new ChatSession', () async {
      final mockResponse = {
        'session': {
          'id': 'session2',
          'title': 'New Session',
          'createdAt': 1672531200000,
          'lastMessageAt': 1672531200000,
          'messageCount': 0
        }
      };

      final client = MockClient((request) async {
        expect(request.url.path, '/api/sessions');
        expect(request.method, 'POST');
        final body = jsonDecode(request.body);
        expect(body['userId'], userId);
        expect(body['title'], 'New Session');
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final service = ChatSessionService(userId: userId, client: client);
      final session = await service.createSession(title: 'New Session');

      expect(session, isA<ChatSession>());
      expect(session.id, 'session2');
      expect(session.title, 'New Session');
    });

    test('deleteSession sends correct request', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/sessions/session1');
        expect(request.method, 'DELETE');
        expect(request.url.queryParameters['userId'], userId);
        return http.Response('', 204);
      });

      final service = ChatSessionService(userId: userId, client: client);
      await service.deleteSession('session1');
    });
  });
}
