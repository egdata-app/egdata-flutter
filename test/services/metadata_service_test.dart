import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:egdata_flutter/services/metadata_service.dart';
import 'package:egdata_flutter/services/api_service.dart';
import 'package:egdata_flutter/models/game_metadata.dart' as metadata;

class MockApiService extends ApiService {
  MockApiService() : super(client: MockClient((_) async => http.Response('{}', 200)));

  int getItemCallCount = 0;
  Item? mockItem;
  bool shouldThrow = false;

  @override
  Future<Item> getItem(String catalogItemId) async {
    getItemCallCount++;
    if (shouldThrow) {
      throw ApiException('Mock Error');
    }
    return mockItem ?? Item(
      id: catalogItemId,
      namespace: 'ns',
      customAttributes: [],
      keyImages: [],
    );
  }
}

void main() {
  group('MetadataService', () {
    late MockApiService mockApi;
    late MetadataService service;

    setUp(() {
      mockApi = MockApiService();
      service = MetadataService(api: mockApi);
    });

    test('fetchMetadata calls API and returns metadata', () async {
      mockApi.mockItem = Item(
        id: 'item1',
        namespace: 'ns1',
        title: 'Game 1',
        description: 'Desc',
        developer: 'Dev',
        publisher: 'Pub',
        customAttributes: [],
        keyImages: [ItemKeyImage(type: 'Thumbnail', url: 'http://img.com')],
      );

      final result = await service.fetchMetadata('item1');

      expect(result, isNotNull);
      expect(result!.title, 'Game 1');
      expect(result.developer, 'Dev');
      expect(result.keyImages.first.url, 'http://img.com');
      expect(mockApi.getItemCallCount, 1);
    });

    test('fetchMetadata returns cached result on second call', () async {
      mockApi.mockItem = Item(
        id: 'item1',
        namespace: 'ns1',
        customAttributes: [],
        keyImages: [],
      );

      await service.fetchMetadata('item1');
      await service.fetchMetadata('item1');

      expect(mockApi.getItemCallCount, 1);
    });

    test('fetchMetadata returns null on error', () async {
      mockApi.shouldThrow = true;

      final result = await service.fetchMetadata('item1');

      expect(result, isNull);
    });

    test('clearCache clears the cache', () async {
      mockApi.mockItem = Item(
        id: 'item1',
        namespace: 'ns1',
        customAttributes: [],
        keyImages: [],
      );

      await service.fetchMetadata('item1'); // Call 1
      service.clearCache();
      await service.fetchMetadata('item1'); // Call 2

      expect(mockApi.getItemCallCount, 2);
    });
  });
}
