import 'package:isar/isar.dart';

part 'followed_game_entry.g.dart';

@Collection()
class FollowedGameEntry {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String offerId;

  late String title;
  String? namespace;
  String? thumbnailUrl;
  late DateTime followedAt;

  // Cached sale info from last sync
  double? currentPrice;
  double? originalPrice;
  int? discountPercent;
  String? priceCurrency;
  bool notifiedSale = false;

  // Last known changelog tracking
  DateTime? lastChangelogCheck;
  String? lastChangelogId;

  FollowedGameEntry();

  bool get isOnSale => discountPercent != null && discountPercent! > 0;

  String get formattedDiscount => isOnSale ? '-$discountPercent%' : '';

  String get formattedCurrentPrice {
    if (currentPrice == null) return '';
    final price = currentPrice! / 100;
    return '${priceCurrency ?? '\$'}${price.toStringAsFixed(2)}';
  }

  String get formattedOriginalPrice {
    if (originalPrice == null) return '';
    final price = originalPrice! / 100;
    return '${priceCurrency ?? '\$'}${price.toStringAsFixed(2)}';
  }
}
