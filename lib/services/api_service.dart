import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api/api.dart';

export '../models/api/api.dart';

/// Exception thrown when an API request fails
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (status: $statusCode)' : ''}';
}

/// Centralized API service for api.egdata.app endpoints
class ApiService {
  static const String baseUrl = 'https://api.egdata.app';

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Generic GET request that returns decoded JSON
  Future<dynamic> _get(String endpoint) async {
    final response = await _client.get(Uri.parse('$baseUrl$endpoint'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw ApiException(
      'GET $endpoint failed',
      response.statusCode,
    );
  }

  /// Fetches all currently free games
  Future<List<FreeGame>> getFreeGames() async {
    final data = await _get('/free-games') as List<dynamic>;
    return data
        .map((e) => FreeGame.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches offer details including price information
  Future<Offer> getOffer(String offerId) async {
    final data = await _get('/offers/$offerId') as Map<String, dynamic>;
    return Offer.fromJson(data);
  }

  /// Fetches changelog/update history for an offer
  Future<ChangelogResponse> getOfferChangelog(String offerId, {int limit = 5}) async {
    final data = await _get('/offers/$offerId/changelog?limit=$limit') as Map<String, dynamic>;
    return ChangelogResponse.fromJson(data);
  }

  /// Fetches item metadata
  Future<Item> getItem(String catalogItemId) async {
    final data = await _get('/items/$catalogItemId') as Map<String, dynamic>;
    return Item.fromJson(data);
  }

  /// Disposes the HTTP client
  void dispose() {
    _client.close();
  }
}
