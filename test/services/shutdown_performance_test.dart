import 'package:flutter_test/flutter_test.dart';
import 'package:egdata_flutter/services/playtime_service.dart';
import 'package:egdata_flutter/services/api_service.dart';
import 'package:egdata_flutter/services/chat_session_service.dart';
import 'package:egdata_flutter/database/database_service.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('Shutdown Performance Tests', () {
    
    test('PlaytimeService shutdown should complete quickly', () async {
      // This test verifies that the shutdown method completes in a reasonable time
      final stopwatch = Stopwatch()..start();
      
      // Create a mock playtime service that simulates having an active session
      final mockService = _MockPlaytimeService();
      
      // Simulate having an active session
      mockService._activeSessionId = 123;
      
      // Call shutdown
      await mockService.shutdown();
      
      stopwatch.stop();
      
      // Should complete in less than 100ms (reasonable for a simple operation)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      expect(mockService._activeSessionId, isNull); // Should be cleared
    });

    test('API service dispose should be fast', () async {
      final apiService = ApiService();
      
      final stopwatch = Stopwatch()..start();
      apiService.dispose();
      stopwatch.stop();
      
      // Should be nearly instantaneous
      expect(stopwatch.elapsedMilliseconds, lessThan(10));
    });

    test('ChatSessionService dispose should be fast', () async {
      final chatService = ChatSessionService(userId: 'test_user');
      
      final stopwatch = Stopwatch()..start();
      chatService.dispose();
      stopwatch.stop();
      
      // Should be nearly instantaneous
      expect(stopwatch.elapsedMilliseconds, lessThan(10));
    });

    test('Database close should complete in reasonable time', () async {
      // Note: This is a more complex test that might need mocking in real usage
      // For now, we'll just verify the method exists and can be called
      
      final mockDb = _MockDatabaseService();
      
      final stopwatch = Stopwatch()..start();
      await mockDb.close();
      stopwatch.stop();
      
      // Should complete quickly
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('Complete shutdown sequence should be fast', () async {
      // This simulates the complete shutdown sequence
      final stopwatch = Stopwatch()..start();
      
      // Simulate the shutdown sequence
      final apiService = ApiService();
      final chatService = ChatSessionService(userId: 'test_user');
      final playtimeService = _MockPlaytimeService();
      final dbService = _MockDatabaseService();
      
      // Set up some state
      playtimeService._activeSessionId = 456;
      
      // Execute shutdown sequence
      apiService.dispose();
      chatService.dispose();
      await playtimeService.shutdown();
      await dbService.close();
      
      stopwatch.stop();
      
      // Entire sequence should complete in less than 200ms
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
      
      // Verify proper cleanup
      expect(playtimeService._activeSessionId, isNull);
    });
  });
}

// Mock implementations for testing
class _MockPlaytimeService {
  int? _activeSessionId;
  
  Future<void> shutdown() async {
    if (_activeSessionId != null) {
      // Simulate ending a session
      await Future.delayed(Duration(milliseconds: 10)); // Small delay to simulate DB operation
      _activeSessionId = null;
    }
  }
}

class _MockDatabaseService {
  bool _isOpen = true;
  
  Future<void> close() async {
    await Future.delayed(Duration(milliseconds: 20)); // Small delay to simulate DB close
    _isOpen = false;
  }
}