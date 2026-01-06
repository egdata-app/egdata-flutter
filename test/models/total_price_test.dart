import 'package:flutter_test/flutter_test.dart';
import 'package:egdata_flutter/models/api/offer.dart';

void main() {
  group('TotalPrice', () {
    group('discountPercent', () {
      test('calculates 50% discount correctly', () {
        final price = TotalPrice(
          originalPrice: 5999,
          discountPrice: 2999,
          currencyCode: 'USD',
        );
        expect(price.discountPercent, 50);
      });

      test('calculates 25% discount correctly', () {
        final price = TotalPrice(
          originalPrice: 4000,
          discountPrice: 3000,
          currencyCode: 'USD',
        );
        expect(price.discountPercent, 25);
      });

      test('calculates 0% discount when prices are equal', () {
        final price = TotalPrice(
          originalPrice: 5999,
          discountPrice: 5999,
          currencyCode: 'USD',
        );
        expect(price.discountPercent, 0);
      });

      test('calculates 100% discount for free', () {
        final price = TotalPrice(
          originalPrice: 5999,
          discountPrice: 0,
          currencyCode: 'USD',
        );
        expect(price.discountPercent, 100);
      });

      test('returns null when original price is 0 (division by zero)', () {
        final price = TotalPrice(
          originalPrice: 0,
          discountPrice: 0,
          currencyCode: 'USD',
        );
        expect(price.discountPercent, isNull);
      });

      test('returns null when original price is negative', () {
        final price = TotalPrice(
          originalPrice: -100,
          discountPrice: 50,
          currencyCode: 'USD',
        );
        expect(price.discountPercent, isNull);
      });

      test('rounds discount percentage correctly', () {
        final price = TotalPrice(
          originalPrice: 3000,
          discountPrice: 1999,
          currencyCode: 'USD',
        );
        // 1 - (1999/3000) = 0.3337 -> 33%
        expect(price.discountPercent, 33);
      });

      test('rounds up when appropriate', () {
        final price = TotalPrice(
          originalPrice: 1000,
          discountPrice: 666,
          currencyCode: 'USD',
        );
        // 1 - (666/1000) = 0.334 -> 33%
        expect(price.discountPercent, 33);
      });
    });

    group('isOnSale', () {
      test('returns true when discount price is less than original', () {
        final price = TotalPrice(
          originalPrice: 5999,
          discountPrice: 2999,
          currencyCode: 'USD',
        );
        expect(price.isOnSale, isTrue);
      });

      test('returns false when prices are equal', () {
        final price = TotalPrice(
          originalPrice: 5999,
          discountPrice: 5999,
          currencyCode: 'USD',
        );
        expect(price.isOnSale, isFalse);
      });

      test('returns false when discount price is higher (edge case)', () {
        final price = TotalPrice(
          originalPrice: 2999,
          discountPrice: 5999,
          currencyCode: 'USD',
        );
        expect(price.isOnSale, isFalse);
      });

      test('returns true for free games (100% off)', () {
        final price = TotalPrice(
          originalPrice: 5999,
          discountPrice: 0,
          currencyCode: 'USD',
        );
        expect(price.isOnSale, isTrue);
      });

      test('returns false for originally free games', () {
        final price = TotalPrice(
          originalPrice: 0,
          discountPrice: 0,
          currencyCode: 'USD',
        );
        expect(price.isOnSale, isFalse);
      });
    });

    group('fromJson', () {
      test('parses complete JSON', () {
        final json = {
          'originalPrice': 5999,
          'discountPrice': 2999,
          'currencyCode': 'EUR',
        };
        final price = TotalPrice.fromJson(json);
        expect(price.originalPrice, 5999);
        expect(price.discountPrice, 2999);
        expect(price.currencyCode, 'EUR');
      });

      test('handles missing fields with defaults', () {
        final json = <String, dynamic>{};
        final price = TotalPrice.fromJson(json);
        expect(price.originalPrice, 0);
        expect(price.discountPrice, 0);
        expect(price.currencyCode, 'USD');
      });

      test('handles null values with defaults', () {
        final json = {
          'originalPrice': null,
          'discountPrice': null,
          'currencyCode': null,
        };
        final price = TotalPrice.fromJson(json);
        expect(price.originalPrice, 0);
        expect(price.discountPrice, 0);
        expect(price.currencyCode, 'USD');
      });
    });
  });
}
