import 'package:langchain/langchain.dart';
import '../api_service.dart';

/// Create get_offer_details tool
Tool createGetOfferDetailsTool(ApiService apiService) {
  return Tool.fromFunction<Map<String, dynamic>, Map<String, dynamic>>(
    name: 'get_offer_details',
    description:
        'Get full details for a single game including description, release date, seller, tags, and requirements.',
    inputJsonSchema: <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'offerId': <String, dynamic>{
          'type': 'string',
          'description': 'The offer ID from search results',
        },
      },
      'required': ['offerId'],
    },
    func: (toolInput) async => await getOfferDetails(apiService, toolInput),
  );
}

/// Implement get_offer_details
Future<Map<String, dynamic>> getOfferDetails(
  ApiService apiService,
  Map<String, dynamic> args,
) async {
  try {
    final offerId = args['offerId'] as String;
    final offer = await apiService.getOffer(offerId);

    return {
      'offerId': offer.id,
      'title': offer.title,
      'description': offer.description,
      'releaseDate': offer.releaseDate?.toIso8601String(),
      'developer': offer.seller?.name,
      'tags': offer.tags.map((t) => t.name).toList(),
      'offerType': offer.offerType,
    };
  } catch (e) {
    return {'error': e.toString()};
  }
}
