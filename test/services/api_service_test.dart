import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:egdata_flutter/services/api_service.dart';

void main() {
  group('ApiService', () {
    const baseUrl = 'https://api.egdata.app';

    test('getFreeGames returns list of FreeGame on 200', () async {
      final mockResponse = [
        {
          'id': 'game1',
          'title': 'Free Game 1',
          'namespace': 'ns1',
          'description': 'Desc 1',
          'effectiveDate': '2023-01-01T00:00:00.000Z',
          'creationDate': '2023-01-01T00:00:00.000Z',
          'lastModifiedDate': '2023-01-01T00:00:00.000Z',
          'offerType': 'BASE_GAME',
          'expiryDate': null,
          'viewableDate': '2023-01-01T00:00:00.000Z',
          'status': 'ACTIVE',
          'isCodeRedemptionOnly': false,
          'keyImages': [],
          'seller': {'id': 's1', 'name': 'Seller 1'},
          'productSlug': 'slug1',
          'urlSlug': 'url1',
          'items': [],
          'customAttributes': [],
          'categories': [],
          'tags': [],
          'catalogNs': {'mappings': []},
          'offerMappings': [],
          'price': {'totalPrice': {'discountPrice': 0, 'originalPrice': 100}},
          'promotions': {
            'promotionalOffers': [
              {
                'promotionalOffers': [
                  {
                    'startDate': '2023-01-01T00:00:00.000Z',
                    'endDate': '2023-01-08T00:00:00.000Z',
                    'discountSetting': {'discountType': 'PERCENTAGE', 'discountPercentage': 0}
                  }
                ]
              }
            ],
            'upcomingPromotionalOffers': []
          }
        }
      ];

      final client = MockClient((request) async {
        expect(request.url.toString(), '$baseUrl/free-games');
        expect(request.method, 'GET');
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final apiService = ApiService(client: client);
      final freeGames = await apiService.getFreeGames();

      expect(freeGames, isA<List<FreeGame>>());
      expect(freeGames.length, 1);
      expect(freeGames.first.title, 'Free Game 1');
    });

    test('getOffer returns Offer on 200', () async {
      final mockResponse = {
        'id': 'offer1',
        'title': 'Awesome Game',
        'namespace': 'ns1',
        'description': 'Description',
        'effectiveDate': '2023-01-01T00:00:00.000Z',
        'offerType': 'BASE_GAME',
        'keyImages': [],
        'seller': {'id': 's1', 'name': 'Seller 1'},
        'productSlug': 'slug1',
        'urlSlug': 'url1',
        'items': [],
        'customAttributes': [],
        'categories': [],
        'tags': [],
        'catalogNs': {'mappings': []},
        'offerMappings': [],
        'price': {'totalPrice': {'discountPrice': 100, 'originalPrice': 100}},
      };

      final client = MockClient((request) async {
        expect(request.url.toString(), '$baseUrl/offers/offer1');
        expect(request.method, 'GET');
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final apiService = ApiService(client: client);
      final offer = await apiService.getOffer('offer1');

      expect(offer, isA<Offer>());
      expect(offer.title, 'Awesome Game');
    });

    test('getOffer throws ApiException on 404', () async {
      final client = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: client);

      expect(
        () => apiService.getOffer('unknown'),
        throwsA(isA<ApiException>()),
      );
    });

    test('getOfferPrice returns TotalPrice on 200', () async {
      final mockResponse = {
        'price': {
            'currencyCode': 'USD',
            'discountPrice': 1000,
            'originalPrice': 2000,
            'fmtPrice': {
                'originalPrice': '\$20.00',
                'discountPrice': '\$10.00',
                'intermediatePrice': '\$10.00'
            }
        }
      };

      final client = MockClient((request) async {
        expect(request.url.toString(), '$baseUrl/offers/offer1/price?country=US');
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final apiService = ApiService(client: client);
      final price = await apiService.getOfferPrice('offer1');

      expect(price, isA<TotalPrice>());
      expect(price?.currencyCode, 'USD');
      expect(price?.discountPrice, 1000);
    });

    test('getOfferPrice returns null on 404', () async {
      final client = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: client);
      final price = await apiService.getOfferPrice('offer1');

      expect(price, isNull);
    });

    test('handles SocketException (Network Error)', () async {
      final client = MockClient((request) async {
        throw const SocketException('No internet');
      });

      final apiService = ApiService(client: client);

      expect(
        () => apiService.getFreeGames(),
        throwsA(predicate((e) => e is ApiException && e.message.contains('Network error'))),
      );
    });
  });
}
