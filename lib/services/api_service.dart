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
  Future<dynamic> _get(String endpoint, {String? apiKey}) async {
    final headers = <String, String>{};
    if (apiKey != null) {
      headers['X-API-Key'] = apiKey;
    }

    final response = await _client.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers.isEmpty ? null : headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw ApiException(
      'GET $endpoint failed',
      response.statusCode,
    );
  }

  /// Generic POST request that returns decoded JSON
  Future<dynamic> _post(String endpoint, Map<String, dynamic> body,
      {Map<String, String>? queryParams, String? apiKey}) async {
    var uri = Uri.parse('$baseUrl$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final headers = {'Content-Type': 'application/json'};
    if (apiKey != null) {
      headers['X-API-Key'] = apiKey;
    }

    final response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );

    // Accept 200 OK and 201 Created
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    throw ApiException(
      'POST $endpoint failed: ${response.body}',
      response.statusCode,
    );
  }

  /// Generic DELETE request that returns decoded JSON
  Future<dynamic> _delete(String endpoint, {String? apiKey}) async {
    final headers = <String, String>{};
    if (apiKey != null) {
      headers['X-API-Key'] = apiKey;
    }

    final response = await _client.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers.isEmpty ? null : headers,
    );

    // Accept 200 OK and 204 No Content
    if (response.statusCode == 200 || response.statusCode == 204) {
      if (response.body.isEmpty) {
        return {'message': 'Success'};
      }
      return jsonDecode(response.body);
    }

    throw ApiException(
      'DELETE $endpoint failed: ${response.body}',
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

  /// Searches for offers with various filters
  ///
  /// [request] - Search parameters including title, filters, pagination, etc.
  /// [country] - Country code for price localization (defaults to "US")
  Future<SearchResponse> search(SearchRequest request,
      {String country = 'US'}) async {
    final data = await _post(
      '/search/v2/search',
      request.toJson(),
      queryParams: {'country': country},
    ) as Map<String, dynamic>;
    return SearchResponse.fromJson(data);
  }

  /// Fetches list of available country codes
  Future<List<String>> getCountries() async {
    final data = await _get('/countries') as List<dynamic>;
    return data.cast<String>();
  }

  // ============================================
  // Push Notification Endpoints
  // ============================================

  /// Gets the VAPID public key for web push
  Future<String> getVapidPublicKey() async {
    final data = await _get('/push/vapid-public-key') as Map<String, dynamic>;
    return data['publicKey'] as String;
  }

  /// Subscribes to push notifications
  /// Returns subscription ID and message
  Future<PushSubscribeResponse> subscribeToPush({
    required String apiKey,
    required String endpoint,
    required String p256dh,
    required String auth,
  }) async {
    final data = await _post(
      '/push/subscribe',
      {
        'endpoint': endpoint,
        'keys': {
          'p256dh': p256dh,
          'auth': auth,
        },
      },
      apiKey: apiKey,
    ) as Map<String, dynamic>;
    return PushSubscribeResponse.fromJson(data);
  }

  /// Gets current subscription status
  Future<PushSubscriptionStatus> getPushSubscriptionStatus({
    required String apiKey,
  }) async {
    final data = await _get('/push/subscribe', apiKey: apiKey) as Map<String, dynamic>;
    return PushSubscriptionStatus.fromJson(data);
  }

  /// Unsubscribes from push notifications
  Future<void> unsubscribeFromPush({
    required String apiKey,
    required String subscriptionId,
  }) async {
    await _delete('/push/unsubscribe/$subscriptionId', apiKey: apiKey);
  }

  /// Subscribes to specific topics
  Future<PushTopicResponse> subscribeToTopics({
    required String apiKey,
    required String subscriptionId,
    required List<String> topics,
  }) async {
    final data = await _post(
      '/push/topics/subscribe',
      {
        'subscriptionId': subscriptionId,
        'topics': topics,
      },
      apiKey: apiKey,
    ) as Map<String, dynamic>;
    return PushTopicResponse.fromJson(data);
  }

  /// Unsubscribes from specific topics
  Future<PushTopicResponse> unsubscribeFromTopics({
    required String apiKey,
    required String subscriptionId,
    required List<String> topics,
  }) async {
    final data = await _post(
      '/push/topics/unsubscribe',
      {
        'subscriptionId': subscriptionId,
        'topics': topics,
      },
      apiKey: apiKey,
    ) as Map<String, dynamic>;
    return PushTopicResponse.fromJson(data);
  }

  /// Gets all subscriptions for the current user
  Future<List<PushSubscriptionInfo>> getPushSubscriptions({
    required String apiKey,
  }) async {
    final data = await _get('/push/subscriptions', apiKey: apiKey) as Map<String, dynamic>;
    final subscriptions = data['subscriptions'] as List<dynamic>;
    return subscriptions
        .map((e) => PushSubscriptionInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Disposes the HTTP client
  void dispose() {
    _client.close();
  }
}

// Push notification response models

class PushSubscribeResponse {
  final String id;
  final String message;

  PushSubscribeResponse({required this.id, required this.message});

  factory PushSubscribeResponse.fromJson(Map<String, dynamic> json) {
    return PushSubscribeResponse(
      id: json['id'] as String,
      message: json['message'] as String,
    );
  }
}

class PushSubscriptionStatus {
  final bool isSubscribed;
  final int subscriptionCount;
  final List<PushSubscriptionInfo> subscriptions;

  PushSubscriptionStatus({
    required this.isSubscribed,
    required this.subscriptionCount,
    required this.subscriptions,
  });

  factory PushSubscriptionStatus.fromJson(Map<String, dynamic> json) {
    final subscriptions = json['subscriptions'] as List<dynamic>? ?? [];
    return PushSubscriptionStatus(
      isSubscribed: json['isSubscribed'] as bool? ?? false,
      subscriptionCount: json['subscriptionCount'] as int? ?? 0,
      subscriptions: subscriptions
          .map((e) => PushSubscriptionInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PushSubscriptionInfo {
  final String id;
  final String endpoint;
  final List<String> topics;
  final DateTime createdAt;

  PushSubscriptionInfo({
    required this.id,
    required this.endpoint,
    required this.topics,
    required this.createdAt,
  });

  factory PushSubscriptionInfo.fromJson(Map<String, dynamic> json) {
    final topics = json['topics'] as List<dynamic>? ?? [];
    return PushSubscriptionInfo(
      id: json['id'] as String? ?? json['_id'] as String,
      endpoint: json['endpoint'] as String,
      topics: topics.cast<String>(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}

class PushTopicResponse {
  final String message;
  final List<String> topics;

  PushTopicResponse({required this.message, required this.topics});

  factory PushTopicResponse.fromJson(Map<String, dynamic> json) {
    final topics = json['topics'] as List<dynamic>? ?? [];
    return PushTopicResponse(
      message: json['message'] as String,
      topics: topics.cast<String>(),
    );
  }
}
