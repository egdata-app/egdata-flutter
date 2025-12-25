class SearchResult {
  final String id;
  final String title;
  final String? namespace;
  final String? thumbnailUrl;
  final String? developer;
  final String? publisher;
  final int? priceValue;
  final String? priceCurrency;
  final int? discountPrice;
  final bool isFree;
  final String? offerType;
  final DateTime? releaseDate;

  const SearchResult({
    required this.id,
    required this.title,
    this.namespace,
    this.thumbnailUrl,
    this.developer,
    this.publisher,
    this.priceValue,
    this.priceCurrency,
    this.discountPrice,
    this.isFree = false,
    this.offerType,
    this.releaseDate,
  });

  String? get formattedPrice {
    if (isFree) return 'Free';
    if (priceValue == null) return null;
    final price = priceValue! / 100;
    return '\$${price.toStringAsFixed(2)}';
  }

  String? get formattedDiscountPrice {
    if (discountPrice == null) return null;
    final price = discountPrice! / 100;
    return '\$${price.toStringAsFixed(2)}';
  }

  bool get hasDiscount => discountPrice != null && discountPrice! < (priceValue ?? 0);

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    // Extract thumbnail URL from keyImages
    String? thumbnailUrl;
    if (json['keyImages'] != null) {
      final keyImages = json['keyImages'] as List<dynamic>;
      // Prefer DieselGameBoxTall, then DieselGameBox, then first available
      for (final img in keyImages) {
        if (img['type'] == 'DieselGameBoxTall') {
          thumbnailUrl = img['url'];
          break;
        }
      }
      if (thumbnailUrl == null) {
        for (final img in keyImages) {
          if (img['type'] == 'DieselGameBox') {
            thumbnailUrl = img['url'];
            break;
          }
        }
      }
      if (thumbnailUrl == null && keyImages.isNotEmpty) {
        thumbnailUrl = keyImages.first['url'];
      }
    }

    // Extract price info
    int? priceValue;
    String? priceCurrency;
    int? discountPrice;
    bool isFree = false;

    if (json['price'] != null) {
      final price = json['price'];
      if (price['price'] != null) {
        final priceData = price['price'];
        priceValue = priceData['originalPrice'];
        discountPrice = priceData['discountPrice'];
        priceCurrency = priceData['currencyCode'];
        isFree = (discountPrice ?? priceValue ?? 0) == 0;
      }
    }

    // Parse release date
    DateTime? releaseDate;
    if (json['releaseDate'] != null) {
      try {
        releaseDate = DateTime.parse(json['releaseDate']);
      } catch (_) {}
    }

    return SearchResult(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      namespace: json['namespace'],
      thumbnailUrl: thumbnailUrl,
      developer: json['developerDisplayName'] ?? json['developer'],
      publisher: json['publisherDisplayName'] ?? json['publisher'],
      priceValue: priceValue,
      priceCurrency: priceCurrency,
      discountPrice: discountPrice,
      isFree: isFree,
      offerType: json['offerType'],
      releaseDate: releaseDate,
    );
  }
}
