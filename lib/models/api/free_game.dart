import 'offer.dart';

/// Represents a free game offer from the EGData API
class FreeGame {
  final String id;
  final String namespace;
  final String title;
  final String description;
  final String offerType;
  final DateTime effectiveDate;
  final DateTime creationDate;
  final DateTime lastModifiedDate;
  final bool isCodeRedemptionOnly;
  final List<KeyImage> keyImages;
  final Seller seller;
  final String? productSlug;
  final String urlSlug;
  final String? url;
  final List<Tag> tags;
  final List<OfferItem> items;
  final List<String> categories;
  final String developerDisplayName;
  final String publisherDisplayName;
  final DateTime? releaseDate;
  final DateTime? pcReleaseDate;
  final DateTime viewableDate;
  final List<String>? countriesBlacklist;
  final String refundType;
  final Giveaway? giveaway;
  final FreeGamePrice? price;

  FreeGame({
    required this.id,
    required this.namespace,
    required this.title,
    required this.description,
    required this.offerType,
    required this.effectiveDate,
    required this.creationDate,
    required this.lastModifiedDate,
    required this.isCodeRedemptionOnly,
    required this.keyImages,
    required this.seller,
    this.productSlug,
    required this.urlSlug,
    this.url,
    required this.tags,
    required this.items,
    required this.categories,
    required this.developerDisplayName,
    required this.publisherDisplayName,
    this.releaseDate,
    this.pcReleaseDate,
    required this.viewableDate,
    this.countriesBlacklist,
    required this.refundType,
    this.giveaway,
    this.price,
  });

  factory FreeGame.fromJson(Map<String, dynamic> json) {
    return FreeGame(
      id: json['id'] as String,
      namespace: json['namespace'] as String,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      offerType: (json['offerType'] as String?) ?? 'UNKNOWN',
      effectiveDate: DateTime.parse(json['effectiveDate'] as String),
      creationDate: DateTime.parse(json['creationDate'] as String),
      lastModifiedDate: DateTime.parse(json['lastModifiedDate'] as String),
      isCodeRedemptionOnly: (json['isCodeRedemptionOnly'] as bool?) ?? false,
      keyImages: (json['keyImages'] as List<dynamic>?)
          ?.map((e) => KeyImage.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      seller: Seller.fromJson(json['seller'] as Map<String, dynamic>),
      productSlug: json['productSlug'] as String?,
      urlSlug: (json['urlSlug'] as String?) ?? '',
      url: json['url'] as String?,
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => Tag.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => OfferItem.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      categories: (json['categories'] as List<dynamic>?)?.cast<String>() ?? [],
      developerDisplayName: (json['developerDisplayName'] as String?) ?? '',
      publisherDisplayName: (json['publisherDisplayName'] as String?) ?? '',
      releaseDate: json['releaseDate'] != null
          ? DateTime.parse(json['releaseDate'] as String)
          : null,
      pcReleaseDate: json['pcReleaseDate'] != null
          ? DateTime.parse(json['pcReleaseDate'] as String)
          : null,
      viewableDate: DateTime.parse(json['viewableDate'] as String),
      countriesBlacklist: (json['countriesBlacklist'] as List<dynamic>?)?.cast<String>(),
      refundType: (json['refundType'] as String?) ?? 'NON_REFUNDABLE',
      giveaway: json['giveaway'] != null
          ? Giveaway.fromJson(json['giveaway'] as Map<String, dynamic>)
          : null,
      price: json['price'] != null
          ? FreeGamePrice.fromJson(json['price'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Giveaway {
  final DateTime startDate;
  final DateTime endDate;
  final String? title;

  Giveaway({
    required this.startDate,
    required this.endDate,
    this.title,
  });

  factory Giveaway.fromJson(Map<String, dynamic> json) {
    return Giveaway(
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      title: json['title'] as String?,
    );
  }
}

class FreeGamePrice {
  final String currencyCode;
  final int originalPrice;
  final int discountPrice;

  FreeGamePrice({
    required this.currencyCode,
    required this.originalPrice,
    required this.discountPrice,
  });

  factory FreeGamePrice.fromJson(Map<String, dynamic> json) {
    return FreeGamePrice(
      currencyCode: (json['currencyCode'] as String?) ?? 'USD',
      originalPrice: (json['originalPrice'] as int?) ?? 0,
      discountPrice: (json['discountPrice'] as int?) ?? 0,
    );
  }
}
