import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/search_result.dart';

class SearchService {
  static const String _baseUrl = 'https://api.egdata.app';

  Future<List<SearchResult>> search(
    String? query, {
    int? limit,
    int? page,
    String? sortBy,
    List<String>? offerTypes,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (query != null && query.isNotEmpty) {
        body['title'] = query;
      }

      if (limit != null) {
        body['limit'] = limit;
      }

      if (page != null) {
        body['page'] = page;
      }

      if (sortBy != null) {
        body['sortBy'] = sortBy;
      }

      if (offerTypes != null && offerTypes.isNotEmpty) {
        body['offerType'] = offerTypes;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/search/v2/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final elements = json['offers'] as List<dynamic>? ?? [];
        return elements
            .map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('[SearchService] Error: $e');
    }

    return [];
  }

  Future<SearchResult?> getOfferDetails(String offerId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/offers/$offerId'));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return SearchResult.fromJson(json);
      }
    } catch (e) {
      // Failed to fetch offer details
    }

    return null;
  }

  Future<String?> getOfferIdForItem(String itemId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/items/$itemId/offer'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        // Return the offer ID from the response
        if (json is Map<String, dynamic>) {
          return json['id'] as String?;
        }
      }
    } catch (e) {
      // Failed to get offer for item
    }

    return null;
  }
}
