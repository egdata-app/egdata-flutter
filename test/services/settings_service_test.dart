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
      expect(settings.libraryViewMode, 'grid'); // Default
      expect(settings.libraryFilter, 'all');
      expect(settings.libraryOfferTypeFilter, 'any');
      expect(settings.librarySelectedTag, isNull);
      expect(settings.librarySelectedCategoryName, isNull);
      expect(settings.libraryOnlyOnSale, false);
      expect(settings.libraryOnlyFree, false);
      expect(settings.librarySortBy, 'title');
      expect(settings.librarySortAscending, true);
    });

    test('saveSettings round-trips library filter fields', () async {
      final service = SettingsService();
      final newSettings = AppSettings(
        libraryFilter: 'installed',
        libraryOfferTypeFilter: 'baseGame',
        librarySelectedTag: 'rpg',
        librarySelectedCategoryName: 'My Games',
        libraryOnlyOnSale: true,
        libraryOnlyFree: true,
        librarySortBy: 'releaseDate',
        librarySortAscending: false,
      );

      await service.saveSettings(newSettings);
      final loaded = await service.loadSettings();

      expect(loaded.libraryFilter, 'installed');
      expect(loaded.libraryOfferTypeFilter, 'baseGame');
      expect(loaded.librarySelectedTag, 'rpg');
      expect(loaded.librarySelectedCategoryName, 'My Games');
      expect(loaded.libraryOnlyOnSale, true);
      expect(loaded.libraryOnlyFree, true);
      expect(loaded.librarySortBy, 'releaseDate');
      expect(loaded.librarySortAscending, false);
    });

    test('copyWith can clear nullable library fields', () {
      final settings = AppSettings(
        librarySelectedTag: 'rpg',
        librarySelectedCategoryName: 'My Games',
      );

      final cleared = settings.copyWith(
        librarySelectedTag: null,
        librarySelectedCategoryName: null,
      );

      expect(cleared.librarySelectedTag, isNull);
      expect(cleared.librarySelectedCategoryName, isNull);
    });

    test('copyWith preserves nullable library fields when omitted', () {
      final settings = AppSettings(
        librarySelectedTag: 'rpg',
        librarySelectedCategoryName: 'My Games',
      );

      final updated = settings.copyWith(libraryOnlyOnSale: true);

      expect(updated.librarySelectedTag, 'rpg');
      expect(updated.librarySelectedCategoryName, 'My Games');
      expect(updated.libraryOnlyOnSale, true);
    });

    test('saveSettings persists settings', () async {
      final service = SettingsService();
      final newSettings = AppSettings(
        country: 'ES',
        autoSync: true,
        libraryViewMode: 'list',
      );

      await service.saveSettings(newSettings);

      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('app_settings');
      expect(jsonString, isNotNull);
      expect(jsonString, contains('"country":"ES"'));
      expect(jsonString, contains('"autoSync":true'));
      expect(jsonString, contains('"libraryViewMode":"list"'));
    });

    test('loadSettings returns saved settings', () async {
      final service = SettingsService();
      final newSettings = AppSettings(
        country: 'FR',
        autoSync: true,
        libraryViewMode: 'list',
      );

      await service.saveSettings(newSettings);
      final loadedSettings = await service.loadSettings();

      expect(loadedSettings.country, 'FR');
      expect(loadedSettings.autoSync, true);
      expect(loadedSettings.libraryViewMode, 'list');
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
