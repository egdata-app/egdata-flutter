/// Represents an offer from the EGData API
class Offer {
  final String id;
  final String namespace;
  final String title;
  final String description;
  final String? longDescription;
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
  final Map<String, CustomAttribute> customAttributes;
  final List<String> categories;
  final String developerDisplayName;
  final String publisherDisplayName;
  final DateTime? releaseDate;
  final DateTime? pcReleaseDate;
  final DateTime viewableDate;
  final List<String>? countriesBlacklist;
  final List<String>? countriesWhitelist;
  final String refundType;
  final OfferPrice? price;

  Offer({
    required this.id,
    required this.namespace,
    required this.title,
    required this.description,
    this.longDescription,
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
    required this.customAttributes,
    required this.categories,
    required this.developerDisplayName,
    required this.publisherDisplayName,
    this.releaseDate,
    this.pcReleaseDate,
    required this.viewableDate,
    this.countriesBlacklist,
    this.countriesWhitelist,
    required this.refundType,
    this.price,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json['id'] as String,
      namespace: json['namespace'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      longDescription: json['longDescription'] as String?,
      offerType: json['offerType'] as String,
      effectiveDate: DateTime.parse(json['effectiveDate'] as String),
      creationDate: DateTime.parse(json['creationDate'] as String),
      lastModifiedDate: DateTime.parse(json['lastModifiedDate'] as String),
      isCodeRedemptionOnly: json['isCodeRedemptionOnly'] as bool,
      keyImages: (json['keyImages'] as List<dynamic>)
          .map((e) => KeyImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      seller: Seller.fromJson(json['seller'] as Map<String, dynamic>),
      productSlug: json['productSlug'] as String?,
      urlSlug: json['urlSlug'] as String,
      url: json['url'] as String?,
      tags: (json['tags'] as List<dynamic>)
          .map((e) => Tag.fromJson(e as Map<String, dynamic>))
          .toList(),
      items: (json['items'] as List<dynamic>)
          .map((e) => OfferItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      customAttributes: _parseCustomAttributes(json['customAttributes']),
      categories: (json['categories'] as List<dynamic>).cast<String>(),
      developerDisplayName: json['developerDisplayName'] as String,
      publisherDisplayName: json['publisherDisplayName'] as String,
      releaseDate: json['releaseDate'] != null
          ? DateTime.parse(json['releaseDate'] as String)
          : null,
      pcReleaseDate: json['pcReleaseDate'] != null
          ? DateTime.parse(json['pcReleaseDate'] as String)
          : null,
      viewableDate: DateTime.parse(json['viewableDate'] as String),
      countriesBlacklist: (json['countriesBlacklist'] as List<dynamic>?)?.cast<String>(),
      countriesWhitelist: (json['countriesWhitelist'] as List<dynamic>?)?.cast<String>(),
      refundType: json['refundType'] as String,
      price: json['price'] != null
          ? OfferPrice.fromJson(json['price'] as Map<String, dynamic>)
          : null,
    );
  }

  static Map<String, CustomAttribute> _parseCustomAttributes(dynamic attrs) {
    if (attrs == null) return {};

    if (attrs is Map<String, dynamic>) {
      return attrs.map((key, value) => MapEntry(
        key,
        CustomAttribute.fromJson(value as Map<String, dynamic>),
      ));
    }

    return {};
  }
}

class KeyImage {
  final String type;
  final String url;
  final String? md5;

  KeyImage({
    required this.type,
    required this.url,
    this.md5,
  });

  factory KeyImage.fromJson(Map<String, dynamic> json) {
    return KeyImage(
      type: json['type'] as String,
      url: json['url'] as String,
      md5: json['md5'] as String?,
    );
  }
}

class Seller {
  final String id;
  final String name;

  Seller({
    required this.id,
    required this.name,
  });

  factory Seller.fromJson(Map<String, dynamic> json) {
    return Seller(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

class Tag {
  final String id;
  final String name;

  Tag({
    required this.id,
    required this.name,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

class OfferItem {
  final String id;
  final String namespace;

  OfferItem({
    required this.id,
    required this.namespace,
  });

  factory OfferItem.fromJson(Map<String, dynamic> json) {
    return OfferItem(
      id: json['id'] as String,
      namespace: json['namespace'] as String,
    );
  }
}

class CustomAttribute {
  final String type;
  final String value;

  CustomAttribute({
    required this.type,
    required this.value,
  });

  factory CustomAttribute.fromJson(Map<String, dynamic> json) {
    return CustomAttribute(
      type: json['type'] as String,
      value: json['value'] as String,
    );
  }
}

class OfferPrice {
  final TotalPrice totalPrice;

  OfferPrice({required this.totalPrice});

  factory OfferPrice.fromJson(Map<String, dynamic> json) {
    return OfferPrice(
      totalPrice: TotalPrice.fromJson(json['totalPrice'] as Map<String, dynamic>),
    );
  }
}

class TotalPrice {
  final int originalPrice;
  final int discountPrice;
  final String currencyCode;

  TotalPrice({
    required this.originalPrice,
    required this.discountPrice,
    required this.currencyCode,
  });

  factory TotalPrice.fromJson(Map<String, dynamic> json) {
    return TotalPrice(
      originalPrice: json['originalPrice'] as int,
      discountPrice: json['discountPrice'] as int,
      currencyCode: json['currencyCode'] as String,
    );
  }

  int? get discountPercent {
    if (originalPrice <= 0) return null;
    return ((1 - (discountPrice / originalPrice)) * 100).round();
  }

  bool get isOnSale => discountPrice < originalPrice;
}
