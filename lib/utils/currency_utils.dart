import 'package:intl/intl.dart';

/// Currency formatting utilities for price display
class CurrencyUtils {
  /// Currencies that use full price values (no division by 100)
  /// These currencies don't use minor units (cents)
  static const _currenciesWithFullPrice = {'JPY', 'KRW'};

  /// Calculates the display price from API cents value
  static double calculatePrice(int priceInCents, String currencyCode) {
    if (_currenciesWithFullPrice.contains(currencyCode.toUpperCase())) {
      return priceInCents.toDouble();
    }
    return priceInCents / 100;
  }

  /// Formats a price with the appropriate currency symbol and formatting
  /// Uses Intl.NumberFormat for proper locale-aware formatting
  static String formatPrice(int priceInCents, String currencyCode) {
    final code = currencyCode.toUpperCase();
    final price = calculatePrice(priceInCents, code);

    // Use simpleCurrency which automatically handles symbol and decimal places
    final formatter = NumberFormat.simpleCurrency(name: code);
    return formatter.format(price);
  }
}
