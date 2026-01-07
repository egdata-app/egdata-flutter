import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:egdata_flutter/services/game_process_api_service.dart';
import 'package:egdata_flutter/services/api_service.dart';
import 'package:egdata_flutter/models/api/item.dart';

class MockApiService extends ApiService {
  MockApiService() : super(client: MockClient((_) async => http.Response('{}', 200)));

  Item? mockItem;

  @override
  Future<Item> getItem(String catalogItemId) async {
    if (mockItem != null) return mockItem!;
    throw ApiException('Mock Error');
  }
}

void main() {
  group('GameProcessApiService', () {
    test('fetchProcessNames returns process names from Item', () async {
      final mockApi = MockApiService();
      mockApi.mockItem = Item(
        id: 'item1',
        namespace: 'ns',
        customAttributes: [
          ItemCustomAttribute(key: 'ProcessNames', value: 'game.exe, launcher.exe'),
        ],
        keyImages: [],
      );

      final service = GameProcessApiService(api: mockApi);
      final names = await service.fetchProcessNames('item1');

      expect(names, contains('game.exe'));
      expect(names, contains('launcher.exe'));
    });

    test('fetchProcessNames returns empty list on error', () async {
      final mockApi = MockApiService();
      // mockItem is null, will throw ApiException

      final service = GameProcessApiService(api: mockApi);
      final names = await service.fetchProcessNames('item1');

      expect(names, isEmpty);
    });
  });
}
