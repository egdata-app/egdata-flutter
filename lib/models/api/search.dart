import 'offer.dart';

/// Offer types supported by the search API
enum SearchOfferType {
  baseGame('BASE_GAME'),
  dlc('DLC'),
  addon('ADD_ON'),
  subscription('SUBSCRIPTION'),
  bundle('BUNDLE'),
  demo('DEMO'),
  edition('Edition'),
  season('SEASON'),
  pass('PASS'),
  inGameItem('INGAMEITEM'),
  inGameCurrency('INGAME_CURRENCY'),
  lootbox('LOOTBOX'),
  subscriptionBundle('SUBSCRIPTION_BUNDLE'),
  experience('EXPERIENCE'),
  digitalExtra('DIGITAL_EXTRA'),
  consumable('CONSUMABLE'),
  unknown('UNKNOWN');

  const SearchOfferType(this.value);
  final String value;

  /// Display name for UI
  String get displayName {
    switch (this) {
      case SearchOfferType.baseGame:
        return 'Base Game';
      case SearchOfferType.dlc:
        return 'DLC';
      case SearchOfferType.addon:
        return 'Add-On';
      case SearchOfferType.subscription:
        return 'Subscription';
      case SearchOfferType.bundle:
        return 'Bundle';
      case SearchOfferType.demo:
        return 'Demo';
      case SearchOfferType.edition:
        return 'Edition';
      case SearchOfferType.season:
        return 'Season';
      case SearchOfferType.pass:
        return 'Pass';
      case SearchOfferType.inGameItem:
        return 'In-Game Item';
      case SearchOfferType.inGameCurrency:
        return 'In-Game Currency';
      case SearchOfferType.lootbox:
        return 'Lootbox';
      case SearchOfferType.subscriptionBundle:
        return 'Subscription Bundle';
      case SearchOfferType.experience:
        return 'Experience';
      case SearchOfferType.digitalExtra:
        return 'Digital Extra';
      case SearchOfferType.consumable:
        return 'Consumable';
      case SearchOfferType.unknown:
        return 'Unknown';
    }
  }
}

/// Sort options for search results
enum SearchSortBy {
  releaseDate('releaseDate'),
  lastModifiedDate('lastModifiedDate'),
  effectiveDate('effectiveDate'),
  creationDate('creationDate'),
  viewableDate('viewableDate'),
  pcReleaseDate('pcReleaseDate'),
  upcoming('upcoming'),
  price('price'),
  discount('discount'),
  discountPercent('discountPercent'),
  giveawayDate('giveawayDate'),
  title('title'),
  offerType('offerType');

  const SearchSortBy(this.value);
  final String value;

  /// Display name for UI
  String get displayName {
    switch (this) {
      case SearchSortBy.releaseDate:
        return 'Release Date';
      case SearchSortBy.lastModifiedDate:
        return 'Last Modified';
      case SearchSortBy.effectiveDate:
        return 'Effective Date';
      case SearchSortBy.creationDate:
        return 'Creation Date';
      case SearchSortBy.viewableDate:
        return 'Viewable Date';
      case SearchSortBy.pcReleaseDate:
        return 'PC Release Date';
      case SearchSortBy.upcoming:
        return 'Upcoming';
      case SearchSortBy.price:
        return 'Price';
      case SearchSortBy.discount:
        return 'Discount';
      case SearchSortBy.discountPercent:
        return 'Discount %';
      case SearchSortBy.giveawayDate:
        return 'Giveaway Date';
      case SearchSortBy.title:
        return 'Title';
      case SearchSortBy.offerType:
        return 'Offer Type';
    }
  }
}

/// Sort direction for search results
enum SearchSortDir {
  asc('asc'),
  desc('desc');

  const SearchSortDir(this.value);
  final String value;
}

/// Price range filter for search
class PriceRange {
  final int? min;
  final int? max;

  const PriceRange({this.min, this.max});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (min != null) map['min'] = min;
    if (max != null) map['max'] = max;
    return map;
  }
}

/// Request body for the search API
class SearchRequest {
  final String? title;
  final SearchOfferType? offerType;
  final List<String>? tags;
  final List<String>? customAttributes;
  final String? seller;
  final SearchSortBy? sortBy;
  final SearchSortDir? sortDir;
  final int? limit;
  final int? page;
  final String? refundType;
  final bool? isCodeRedemptionOnly;
  final PriceRange? price;
  final bool? onSale;
  final List<String>? categories;
  final String? developerDisplayName;
  final String? publisherDisplayName;
  final bool? excludeBlockchain;
  final bool? pastGiveaways;
  final bool? isLowestPriceEver;

  const SearchRequest({
    this.title,
    this.offerType,
    this.tags,
    this.customAttributes,
    this.seller,
    this.sortBy,
    this.sortDir,
    this.limit,
    this.page,
    this.refundType,
    this.isCodeRedemptionOnly,
    this.price,
    this.onSale,
    this.categories,
    this.developerDisplayName,
    this.publisherDisplayName,
    this.excludeBlockchain,
    this.pastGiveaways,
    this.isLowestPriceEver,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};

    if (title != null) map['title'] = title;
    if (offerType != null) map['offerType'] = offerType!.value;
    if (tags != null) map['tags'] = tags;
    if (customAttributes != null) map['customAttributes'] = customAttributes;
    if (seller != null) map['seller'] = seller;
    if (sortBy != null) map['sortBy'] = sortBy!.value;
    if (sortDir != null) map['sortDir'] = sortDir!.value;
    if (limit != null) map['limit'] = limit;
    if (page != null) map['page'] = page;
    if (refundType != null) map['refundType'] = refundType;
    if (isCodeRedemptionOnly != null) {
      map['isCodeRedemptionOnly'] = isCodeRedemptionOnly;
    }
    if (price != null) map['price'] = price!.toJson();
    if (onSale != null) map['onSale'] = onSale;
    if (categories != null) map['categories'] = categories;
    if (developerDisplayName != null) {
      map['developerDisplayName'] = developerDisplayName;
    }
    if (publisherDisplayName != null) {
      map['publisherDisplayName'] = publisherDisplayName;
    }
    if (excludeBlockchain != null) map['excludeBlockchain'] = excludeBlockchain;
    if (pastGiveaways != null) map['pastGiveaways'] = pastGiveaways;
    if (isLowestPriceEver != null) map['isLowestPrice'] = isLowestPriceEver;

    return map;
  }
}

/// Aggregation bucket item
class AggregationBucket {
  final String key;
  final int docCount;

  AggregationBucket({
    required this.key,
    required this.docCount,
  });

  factory AggregationBucket.fromJson(Map<String, dynamic> json) {
    return AggregationBucket(
      key: json['key'] as String,
      docCount: json['doc_count'] as int,
    );
  }
}

/// Aggregation with buckets
class Aggregation {
  final List<AggregationBucket> buckets;

  Aggregation({required this.buckets});

  factory Aggregation.fromJson(Map<String, dynamic> json) {
    return Aggregation(
      buckets: (json['buckets'] as List<dynamic>)
          .map((e) => AggregationBucket.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Price statistics from aggregations
class PriceStats {
  final double? min;
  final double? max;
  final double? avg;
  final double? sum;
  final int? count;

  PriceStats({
    this.min,
    this.max,
    this.avg,
    this.sum,
    this.count,
  });

  factory PriceStats.fromJson(Map<String, dynamic> json) {
    return PriceStats(
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      avg: (json['avg'] as num?)?.toDouble(),
      sum: (json['sum'] as num?)?.toDouble(),
      count: json['count'] as int?,
    );
  }
}

/// Search aggregations
class SearchAggregations {
  final Aggregation? offerType;
  final Aggregation? tags;
  final Aggregation? developer;
  final Aggregation? publisher;
  final Aggregation? seller;
  final PriceStats? priceStats;

  SearchAggregations({
    this.offerType,
    this.tags,
    this.developer,
    this.publisher,
    this.seller,
    this.priceStats,
  });

  factory SearchAggregations.fromJson(Map<String, dynamic> json) {
    return SearchAggregations(
      offerType: json['offerType'] != null
          ? Aggregation.fromJson(json['offerType'] as Map<String, dynamic>)
          : null,
      tags: json['tags'] != null
          ? Aggregation.fromJson(json['tags'] as Map<String, dynamic>)
          : null,
      developer: json['developer'] != null
          ? Aggregation.fromJson(json['developer'] as Map<String, dynamic>)
          : null,
      publisher: json['publisher'] != null
          ? Aggregation.fromJson(json['publisher'] as Map<String, dynamic>)
          : null,
      seller: json['seller'] != null
          ? Aggregation.fromJson(json['seller'] as Map<String, dynamic>)
          : null,
      priceStats: json['price_stats'] != null
          ? PriceStats.fromJson(json['price_stats'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Search response metadata
class SearchMeta {
  final int ms;
  final bool timedOut;
  final bool cached;

  SearchMeta({
    required this.ms,
    required this.timedOut,
    required this.cached,
  });

  factory SearchMeta.fromJson(Map<String, dynamic> json) {
    return SearchMeta(
      ms: json['ms'] as int,
      timedOut: json['timed_out'] as bool,
      cached: json['cached'] as bool,
    );
  }
}

/// Response from the search API
class SearchResponse {
  final int total;
  final List<Offer> offers;
  final int page;
  final int limit;
  final SearchAggregations? aggregations;
  final SearchMeta? meta;

  SearchResponse({
    required this.total,
    required this.offers,
    required this.page,
    required this.limit,
    this.aggregations,
    this.meta,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      total: json['total'] as int,
      offers: (json['offers'] as List<dynamic>)
          .map((e) => Offer.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int,
      limit: json['limit'] as int,
      aggregations: json['aggregations'] != null
          ? SearchAggregations.fromJson(
              json['aggregations'] as Map<String, dynamic>)
          : null,
      meta: json['meta'] != null
          ? SearchMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
    );
  }
}
