import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:egdata_flutter/services/user_service.dart';

void main() {
  group('UserService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('getUserId generates new ID if not exists', () async {
      final userId = await UserService.getUserId();
      expect(userId, isNotEmpty);
    });

    test('getUserId returns existing ID', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', 'existing-uuid');

      final userId = await UserService.getUserId();
      expect(userId, 'existing-uuid');
    });

    test('getUserId persists the ID', () async {
      final userId = await UserService.getUserId();
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_id'), userId);
    });

    test('clearUserId removes the ID', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', 'existing-uuid');

      await UserService.clearUserId();
      expect(prefs.getString('user_id'), isNull);
    });
  });
}
