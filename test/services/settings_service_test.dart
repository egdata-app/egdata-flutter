import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:egdata_flutter/services/settings_service.dart';
import 'package:egdata_flutter/models/settings.dart';

void main() {
  group('SettingsService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loadSettings returns default settings when empty', () async {
      final service = SettingsService();
      final settings = await service.loadSettings();
      
      expect(settings.country, 'US'); // Default
      expect(settings.autoSync, false); // Default
    });

    test('saveSettings persists settings', () async {
      final service = SettingsService();
      final newSettings = AppSettings(country: 'ES', autoSync: true);
      
      await service.saveSettings(newSettings);

      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('app_settings');
      expect(jsonString, isNotNull);
      expect(jsonString, contains('"country":"ES"'));
      expect(jsonString, contains('"autoSync":true'));
    });

    test('loadSettings returns saved settings', () async {
      final service = SettingsService();
      final newSettings = AppSettings(country: 'FR', autoSync: true);
      
      await service.saveSettings(newSettings);
      final loadedSettings = await service.loadSettings();

      expect(loadedSettings.country, 'FR');
      expect(loadedSettings.autoSync, true);
    });

    test('loadSettings handles corrupted json', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_settings', '{ corrupted json ');

      final service = SettingsService();
      final settings = await service.loadSettings();

      // Should return defaults
      expect(settings.country, 'US');
    });
  });
}
