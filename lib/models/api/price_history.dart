/// Represents a price history entry from the EGData API
class PriceHistoryEntry {
  final String id;
  final String country;
  final String region;
  final String namespace;
  final String offerId;
  final PriceHistoryPrice price;
  final List<AppliedRule> appliedRules;
  final DateTime updatedAt;

  PriceHistoryEntry({
    required this.id,
    required this.country,
    required this.region,
    required this.namespace,
    required this.offerId,
    required this.price,
    required this.appliedRules,
    required this.updatedAt,
  });

  factory PriceHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PriceHistoryEntry(
      id: (json['_id'] as String?) ?? '',
      country: (json['country'] as String?) ?? '',
      region: (json['region'] as String?) ?? '',
      namespace: (json['namespace'] as String?) ?? '',
      offerId: (json['offerId'] as String?) ?? '',
      price: PriceHistoryPrice.fromJson(
        (json['price'] as Map<String, dynamic>?) ?? {},
      ),
      appliedRules: (json['appliedRules'] as List<dynamic>?)
              ?.map((e) => AppliedRule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'country': country,
      'region': region,
      'namespace': namespace,
      'offerId': offerId,
      'price': price.toJson(),
      'appliedRules': appliedRules.map((e) => e.toJson()).toList(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Represents price information in a price history entry
class PriceHistoryPrice {
  final String currencyCode;
  final int discount;
  final int discountPrice;
  final int originalPrice;
  final String basePayoutCurrencyCode;
  final int basePayoutPrice;
  final double payoutCurrencyExchangeRate;

  PriceHistoryPrice({
    required this.currencyCode,
    required this.discount,
    required this.discountPrice,
    required this.originalPrice,
    required this.basePayoutCurrencyCode,
    required this.basePayoutPrice,
    required this.payoutCurrencyExchangeRate,
  });

  factory PriceHistoryPrice.fromJson(Map<String, dynamic> json) {
    return PriceHistoryPrice(
      currencyCode: (json['currencyCode'] as String?) ?? '',
      discount: (json['discount'] as num?)?.toInt() ?? 0,
      discountPrice: (json['discountPrice'] as num?)?.toInt() ?? 0,
      originalPrice: (json['originalPrice'] as num?)?.toInt() ?? 0,
      basePayoutCurrencyCode:
          (json['basePayoutCurrencyCode'] as String?) ?? 'USD',
      basePayoutPrice: (json['basePayoutPrice'] as num?)?.toInt() ?? 0,
      payoutCurrencyExchangeRate:
          (json['payoutCurrencyExchangeRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currencyCode': currencyCode,
      'discount': discount,
      'discountPrice': discountPrice,
      'originalPrice': originalPrice,
      'basePayoutCurrencyCode': basePayoutCurrencyCode,
      'basePayoutPrice': basePayoutPrice,
      'payoutCurrencyExchangeRate': payoutCurrencyExchangeRate,
    };
  }
}

/// Represents an applied rule (promotion) in a price history entry
class AppliedRule {
  final String id;
  final String name;
  final String promotionStatus;
  final DateTime? startDate;
  final DateTime? endDate;
  final DiscountSetting? discountSetting;
  final List<String> regionIds;

  AppliedRule({
    required this.id,
    required this.name,
    required this.promotionStatus,
    this.startDate,
    this.endDate,
    this.discountSetting,
    required this.regionIds,
  });

  factory AppliedRule.fromJson(Map<String, dynamic> json) {
    return AppliedRule(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      promotionStatus: (json['promotionStatus'] as String?) ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      discountSetting: json['discountSetting'] != null
          ? DiscountSetting.fromJson(
              json['discountSetting'] as Map<String, dynamic>,
            )
          : null,
      regionIds: (json['regionIds'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'promotionStatus': promotionStatus,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'discountSetting': discountSetting?.toJson(),
      'regionIds': regionIds,
    };
  }
}

/// Represents discount settings for an applied rule
class DiscountSetting {
  final String discountType;
  final int discountPercentage;

  DiscountSetting({
    required this.discountType,
    required this.discountPercentage,
  });

  factory DiscountSetting.fromJson(Map<String, dynamic> json) {
    return DiscountSetting(
      discountType: (json['discountType'] as String?) ?? '',
      discountPercentage: (json['discountPercentage'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'discountType': discountType,
      'discountPercentage': discountPercentage,
    };
  }
}
