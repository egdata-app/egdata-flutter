import 'package:flutter_test/flutter_test.dart';
import 'package:egdata_flutter/services/search_service.dart';

void main() {
  group('SearchResult', () {
    group('isOnSale', () {
      test('returns true when discount price is less than original', () {
        final result = SearchResult(
          id: 'test',
          title: 'Test Game',
          originalPrice: 5999,
          discountPrice: 2999,
        );
        expect(result.isOnSale, isTrue);
      });

      test('returns false when prices are equal', () {
        final result = SearchResult(
          id: 'test',
          title: 'Test Game',
          originalPrice: 5999,
          discountPrice: 5999,
        );
        expect(result.isOnSale, isFalse);
      });

      test('returns false when discount price is null', () {
        final result = SearchResult(
          id: 'test',
          title: 'Test Game',
          originalPrice: 5999,
          discountPrice: null,
        );
        expect(result.isOnSale, isFalse);
      });

      test('returns false when original price is null', () {
        final result = SearchResult(
          id: 'test',
          title: 'Test Game',
          originalPrice: null,
          discountPrice: 2999,
        );
        expect(result.isOnSale, isFalse);
      });

      test('returns false when both prices are null', () {
        final result = SearchResult(
          id: 'test',
          title: 'Test Game',
          originalPrice: null,
          discountPrice: null,
        );
        expect(result.isOnSale, isFalse);
      });
    });

    group('discountPercent', () {
      test('calculates 50% discount', () {
        final result = SearchResult(
          id: 'test',
          title: 'Test Game',
          originalPrice: 6000,
          discountPrice: 3000,
        );
        expect(result.discountPercent, 50);
      });

      test('calculates 75% discount', () {
        final result = SearchResult(
          id: 'test',
          title: 'Test Game',
          originalPrice: 4000,
          discountPrice: 1000,
        );
        expect(result.discountPercent, 75);
      });

      test('returns 0 when not on sale', () {
        final result = SearchResult(
          id: 'test',
          title: 'Test Game',
          originalPrice: 5999,
          discountPrice: 5999,
        );
        expect(result.discountPercent, 0);
      });

      test('returns 0 when original price is 0', () {
        final result = SearchResult(
          id: 'test',
          title: 'Test Game',
          originalPrice: 0,
          discountPrice: 0,
        );
        expect(result.discountPercent, 0);
      });

      test('returns 0 when prices are null', () {
        final result = SearchResult(
          id: 'test',
          title: 'Test Game',
          originalPrice: null,
          discountPrice: null,
        );
        expect(result.discountPercent, 0);
      });

      test('calculates 100% for free (was paid)', () {
        final result = SearchResult(
          id: 'test',
          title: 'Test Game',
          originalPrice: 5999,
          discountPrice: 0,
        );
        expect(result.discountPercent, 100);
      });
    });

    group('formattedPrice', () {
      test('returns Free when discount price is 0', () {
        final result = SearchResult(
          id: 'test',
          title: 'Test Game',
          originalPrice: 5999,
          discountPrice: 0,
        );
        expect(result.formattedPrice, 'Free');
      });

      test('returns Free when discount price is null', () {
        final result = SearchResult(
          id: 'test',
          title: 'Test Game',
          originalPrice: 5999,
          discountPrice: null,
        );
        expect(result.formattedPrice, 'Free');
      });
    });

    group('formattedOriginalPrice', () {
      test('returns Free when original price is 0', () {
        final result = SearchResult(
          id: 'test',
          title: 'Test Game',
          originalPrice: 0,
          discountPrice: 0,
        );
        expect(result.formattedOriginalPrice, 'Free');
      });

      test('returns Free when original price is null', () {
        final result = SearchResult(
          id: 'test',
          title: 'Test Game',
          originalPrice: null,
          discountPrice: null,
        );
        expect(result.formattedOriginalPrice, 'Free');
      });
    });

    group('fromJson', () {
      test('parses basic JSON', () {
        final json = {
          'id': 'game-123',
          'title': 'Test Game',
          'namespace': 'epic',
        };
        final result = SearchResult.fromJson(json);
        expect(result.id, 'game-123');
        expect(result.title, 'Test Game');
        expect(result.namespace, 'epic');
      });

      test('parses price data', () {
        final json = {
          'id': 'game-123',
          'title': 'Test Game',
          'price': {
            'totalPrice': {
              'originalPrice': 5999,
              'discountPrice': 2999,
              'currencyCode': 'USD',
            }
          },
        };
        final result = SearchResult.fromJson(json);
        expect(result.originalPrice, 5999);
        expect(result.discountPrice, 2999);
        expect(result.currencyCode, 'USD');
      });

      test('selects OfferImageWide as first priority thumbnail', () {
        final json = {
          'id': 'game-123',
          'title': 'Test Game',
          'keyImages': [
            {'type': 'Thumbnail', 'url': 'https://example.com/thumb.jpg'},
            {'type': 'OfferImageWide', 'url': 'https://example.com/wide.jpg'},
            {'type': 'DieselGameBoxTall', 'url': 'https://example.com/tall.jpg'},
          ],
        };
        final result = SearchResult.fromJson(json);
        expect(result.thumbnailUrl, 'https://example.com/wide.jpg');
      });

      test('selects DieselStoreFrontWide as second priority', () {
        final json = {
          'id': 'game-123',
          'title': 'Test Game',
          'keyImages': [
            {'type': 'Thumbnail', 'url': 'https://example.com/thumb.jpg'},
            {'type': 'DieselStoreFrontWide', 'url': 'https://example.com/store.jpg'},
            {'type': 'DieselGameBoxTall', 'url': 'https://example.com/tall.jpg'},
          ],
        };
        final result = SearchResult.fromJson(json);
        expect(result.thumbnailUrl, 'https://example.com/store.jpg');
      });

      test('selects DieselGameBoxTall as third priority', () {
        final json = {
          'id': 'game-123',
          'title': 'Test Game',
          'keyImages': [
            {'type': 'Thumbnail', 'url': 'https://example.com/thumb.jpg'},
            {'type': 'DieselGameBoxTall', 'url': 'https://example.com/tall.jpg'},
          ],
        };
        final result = SearchResult.fromJson(json);
        expect(result.thumbnailUrl, 'https://example.com/tall.jpg');
      });

      test('falls back to Thumbnail', () {
        final json = {
          'id': 'game-123',
          'title': 'Test Game',
          'keyImages': [
            {'type': 'Thumbnail', 'url': 'https://example.com/thumb.jpg'},
            {'type': 'SomeOtherType', 'url': 'https://example.com/other.jpg'},
          ],
        };
        final result = SearchResult.fromJson(json);
        expect(result.thumbnailUrl, 'https://example.com/thumb.jpg');
      });

      test('falls back to first image when no priority match', () {
        final json = {
          'id': 'game-123',
          'title': 'Test Game',
          'keyImages': [
            {'type': 'SomeType', 'url': 'https://example.com/some.jpg'},
            {'type': 'AnotherType', 'url': 'https://example.com/another.jpg'},
          ],
        };
        final result = SearchResult.fromJson(json);
        expect(result.thumbnailUrl, 'https://example.com/some.jpg');
      });

      test('handles empty keyImages', () {
        final json = {
          'id': 'game-123',
          'title': 'Test Game',
          'keyImages': [],
        };
        final result = SearchResult.fromJson(json);
        expect(result.thumbnailUrl, isNull);
      });

      test('handles missing keyImages', () {
        final json = {
          'id': 'game-123',
          'title': 'Test Game',
        };
        final result = SearchResult.fromJson(json);
        expect(result.thumbnailUrl, isNull);
      });

      test('handles missing price data', () {
        final json = {
          'id': 'game-123',
          'title': 'Test Game',
        };
        final result = SearchResult.fromJson(json);
        expect(result.originalPrice, isNull);
        expect(result.discountPrice, isNull);
        expect(result.currencyCode, isNull);
      });
    });
  });
}
