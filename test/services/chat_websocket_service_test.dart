import 'dart:async';
import 'dart:io';

import 'package:egdata_flutter/services/chat_websocket_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  test(
    'rejected handshake reaches the caller without an unhandled error',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final requests = server.listen((request) {
        request.response.statusCode = HttpStatus.forbidden;
        unawaited(request.response.close());
      });
      final service = ChatWebSocketService(
        connectChannel: (_) => WebSocketChannel.connect(
          Uri.parse('ws://127.0.0.1:${server.port}'),
        ),
      );
      addTearDown(() async {
        service.dispose();
        await requests.cancel();
        await server.close(force: true);
      });

      await expectLater(
        service.connect(userId: 'user', sessionId: 'session'),
        throwsA(isA<WebSocketChannelException>()),
      );
      expect(service.isConnected, isFalse);
    },
  );

  test('waits for readiness and encodes session query parameters', () async {
    final channel = _TestChannel();
    Uri? connectedUri;
    final service = ChatWebSocketService(
      connectChannel: (uri) {
        connectedUri = uri;
        return channel;
      },
    );
    addTearDown(service.dispose);
    final connecting = service.connect(userId: 'a&b', sessionId: 'c=d');
    await Future<void>.delayed(Duration.zero);
    expect(service.isConnected, isFalse);
    await expectLater(
      service.sendMessage(message: 'hello', sessionId: 'c=d'),
      throwsException,
    );

    channel.readyCompleter.complete();
    await connecting;
    expect(service.isConnected, isTrue);
    expect(connectedUri!.queryParameters, {
      'agentId': 'a&b',
      'sessionId': 'c=d',
    });
    await service.sendMessage(message: 'hello', sessionId: 'c=d');
    expect(channel.testSink.messages, hasLength(1));
  });

  test('handles both handshake error channels and can reconnect', () async {
    var channel = _TestChannel();
    final service = ChatWebSocketService(connectChannel: (_) => channel);
    addTearDown(service.dispose);
    final failed = expectLater(
      service.connect(userId: 'user', sessionId: 'session'),
      throwsA(isA<WebSocketChannelException>()),
    );
    await Future<void>.delayed(Duration.zero);
    final error = WebSocketChannelException('Handshake rejected');
    channel.incoming.addError(error);
    channel.readyCompleter.completeError(error);
    await failed;
    expect(service.isConnected, isFalse);
    expect(channel.testSink.closed, isTrue);

    channel = _TestChannel()..readyCompleter.complete();
    await service.connect(userId: 'user', sessionId: 'new-session');
    expect(service.isConnected, isTrue);
  });

  test(
    'dispose during handshake ignores late completion and messages',
    () async {
      final channel = _TestChannel();
      final service = ChatWebSocketService(connectChannel: (_) => channel);
      final connecting = service.connect(userId: 'user', sessionId: 'session');
      await Future<void>.delayed(Duration.zero);
      service.dispose();
      channel.readyCompleter.completeError(WebSocketChannelException('Closed'));
      channel.incoming.add('{"type":"text_delta","text":"late"}');
      await connecting;
      expect(service.isConnected, isFalse);
      expect(channel.testSink.closed, isTrue);
    },
  );

  test('server closure clears readiness and notifies the UI once', () async {
    final channel = _TestChannel()..readyCompleter.complete();
    final service = ChatWebSocketService(connectChannel: (_) => channel);
    addTearDown(service.dispose);
    final events = <ChatEvent>[];
    final subscription = service.events.listen(events.add);
    addTearDown(subscription.cancel);
    await service.connect(userId: 'user', sessionId: 'session');
    await channel.incoming.close();
    await Future<void>.delayed(Duration.zero);
    expect(service.isConnected, isFalse);
    expect(events.whereType<ErrorEvent>(), hasLength(1));
  });
}

class _TestChannel implements WebSocketChannel {
  final readyCompleter = Completer<void>();
  final incoming = StreamController<dynamic>();
  final testSink = _TestSink();

  @override
  Future<void> get ready => readyCompleter.future;
  @override
  Stream<dynamic> get stream => incoming.stream;
  @override
  WebSocketSink get sink => testSink;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestSink implements WebSocketSink {
  bool closed = false;
  final messages = <dynamic>[];
  @override
  void add(dynamic data) => messages.add(data);
  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    closed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
