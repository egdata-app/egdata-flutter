import 'package:langchain/langchain.dart';
import '../api_service.dart';

/// Create get_offer_price tool
Tool createGetOfferPriceTool(ApiService apiService, String country) {
  return Tool.fromFunction<Map<String, dynamic>, Map<String, dynamic>>(
    name: 'get_offer_price',
    description:
        'Get current pricing for a single game with original price, discount price, and discount percentage. Can fetch prices for any country.',
    inputJsonSchema: <String, dynamic>{
      'type': 'object',
      'properties': <String, dynamic>{
        'offerId': <String, dynamic>{
          'type': 'string',
          'description': 'The offer ID',
        },
        'country': <String, dynamic>{
          'type': 'string',
          'description':
              'Two-letter country code (e.g., "US", "ES", "UK", "DE"). Defaults to user\'s country ($country) if not specified.',
        },
      },
      'required': ['offerId'],
    },
    func: (toolInput) async => await getOfferPrice(apiService, country, toolInput),
  );
}

/// Implement get_offer_price
Future<Map<String, dynamic>> getOfferPrice(
  ApiService apiService,
  String defaultCountry,
  Map<String, dynamic> args,
) async {
  try {
    final offerId = args['offerId'] as String;
    final country = (args['country'] as String?) ?? defaultCountry;
    final priceData = await apiService.getOfferPrice(
      offerId,
      country: country,
    );

    if (priceData == null) {
      return {'error': 'Price not found for this offer'};
    }

    final originalPrice = priceData.originalPrice;
    final discountPrice = priceData.discountPrice;
    final discount = priceData.discountPercent ?? 0;

    return {
      'offerId': offerId,
      'originalPrice': '\$${(originalPrice / 100).toStringAsFixed(2)}',
      'discountPrice': discountPrice != originalPrice
          ? '\$${(discountPrice / 100).toStringAsFixed(2)}'
          : null,
      'discount': discount,
      'onSale': discount > 0,
    };
  } catch (e) {
    return {'error': e.toString()};
  }
}
