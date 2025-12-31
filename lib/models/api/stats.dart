/// Homepage statistics from /stats/homepage endpoint
class HomepageStats {
  final int offers;
  final int trackedPriceChanges;
  final int activeDiscounts;
  final int giveaways;

  HomepageStats({
    required this.offers,
    required this.trackedPriceChanges,
    required this.activeDiscounts,
    required this.giveaways,
  });

  factory HomepageStats.fromJson(Map<String, dynamic> json) {
    return HomepageStats(
      offers: json['offers'] as int? ?? 0,
      trackedPriceChanges: json['trackedPriceChanges'] as int? ?? 0,
      activeDiscounts: json['activeDiscounts'] as int? ?? 0,
      giveaways: json['giveaways'] as int? ?? 0,
    );
  }
}

/// Total value statistics with currency information
class TotalValue {
  final String currencyCode;
  final int originalPrice;
  final int discountPrice;
  final int discount;
  final int basePayoutPrice;
  final String basePayoutCurrencyCode;
  final double payoutCurrencyExchangeRate;

  TotalValue({
    required this.currencyCode,
    required this.originalPrice,
    required this.discountPrice,
    required this.discount,
    required this.basePayoutPrice,
    required this.basePayoutCurrencyCode,
    required this.payoutCurrencyExchangeRate,
  });

  factory TotalValue.fromJson(Map<String, dynamic> json) {
    return TotalValue(
      currencyCode: json['currencyCode'] as String? ?? 'USD',
      originalPrice: json['originalPrice'] as int? ?? 0,
      discountPrice: json['discountPrice'] as int? ?? 0,
      discount: json['discount'] as int? ?? 0,
      basePayoutPrice: json['basePayoutPrice'] as int? ?? 0,
      basePayoutCurrencyCode: json['basePayoutCurrencyCode'] as String? ?? 'USD',
      payoutCurrencyExchangeRate: (json['payoutCurrencyExchangeRate'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// Returns the original price formatted with currency symbol
  String get formattedOriginalPrice {
    final price = originalPrice / 100;
    return _formatPrice(price, currencyCode);
  }

  /// Returns the discount price formatted with currency symbol
  String get formattedDiscountPrice {
    final price = discountPrice / 100;
    return _formatPrice(price, currencyCode);
  }

  /// Returns the total discount formatted with currency symbol
  String get formattedDiscount {
    final price = discount / 100;
    return _formatPrice(price, currencyCode);
  }

  String _formatPrice(double price, String currency) {
    final symbol = _getCurrencySymbol(currency);
    return '$symbol${price.toStringAsFixed(2)}';
  }

  String _getCurrencySymbol(String code) {
    switch (code) {
      case 'EUR':
        return '\u20AC';
      case 'GBP':
        return '\u00A3';
      case 'USD':
      default:
        return '\$';
    }
  }
}

/// Free games statistics from /free-games/stats endpoint
class FreeGamesStats {
  final TotalValue totalValue;
  final int totalOffers;
  final int totalGiveaways;
  final int repeated;
  final int sellers;

  FreeGamesStats({
    required this.totalValue,
    required this.totalOffers,
    required this.totalGiveaways,
    required this.repeated,
    required this.sellers,
  });

  factory FreeGamesStats.fromJson(Map<String, dynamic> json) {
    return FreeGamesStats(
      totalValue: TotalValue.fromJson(json['totalValue'] as Map<String, dynamic>? ?? {}),
      totalOffers: json['totalOffers'] as int? ?? 0,
      totalGiveaways: json['totalGiveaways'] as int? ?? 0,
      repeated: json['repeated'] as int? ?? 0,
      sellers: json['sellers'] as int? ?? 0,
    );
  }
}
