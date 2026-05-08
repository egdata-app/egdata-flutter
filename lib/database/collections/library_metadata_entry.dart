import 'package:isar_community/isar.dart';

import '../../models/api/offer.dart';

part 'library_metadata_entry.g.dart';

/// Cached offer metadata for a library item, keyed by Epic catalog item ID.
///
/// Populated by hitting `/items/:id/offer` on egdata-api in bulk so the
/// library can filter / sort by offer-level fields (offerType, tags,
/// releaseDate, price, …) without per-render network calls.
@Collection()
class LibraryMetadataEntry {
  Id id = Isar.autoIncrement;

  /// Epic `catalogItemId` (== Item id). Primary key for lookups.
  @Index(unique: true, replace: true)
  late String catalogItemId;

  /// Resolved BASE_GAME offer id, when one was found.
  String? offerId;
  String? namespace;

  /// Offer-level fields used for filtering & sorting.
  String? offerType; // BASE_GAME, ADD_ON, DLC, EDITION, …
  late List<String> tags;
  late List<String> categories;
  String? developerDisplayName;
  String? publisherDisplayName;
  String? sellerName;

  DateTime? releaseDate;
  DateTime? lastModifiedDate;

  /// Localized current price, in micro-units (e.g. 1999 = $19.99 when
  /// currency is USD). Null when the offer has no price (free or unknown).
  int? currentPriceCents;
  String? currencyCode;
  bool isFree = false;
  bool isOnSale = false;

  /// Box / wide / featured key images, stored as a flat type→url map
  /// (joined with `\n` for Isar). Convenience getter splits it back.
  String? keyImagesPacked;

  /// When this metadata was last fetched from the API.
  late DateTime syncedAt;

  LibraryMetadataEntry();

  @ignore
  Map<String, String> get keyImages {
    final raw = keyImagesPacked;
    if (raw == null || raw.isEmpty) return const {};
    final map = <String, String>{};
    for (final line in raw.split('\n')) {
      final idx = line.indexOf('|');
      if (idx <= 0) continue;
      map[line.substring(0, idx)] = line.substring(idx + 1);
    }
    return map;
  }

  static String _packKeyImages(List<KeyImage> images) {
    return images
        .where((img) => img.url.isNotEmpty && img.type.isNotEmpty)
        .map((img) => '${img.type}|${img.url}')
        .join('\n');
  }

  factory LibraryMetadataEntry.fromOffer({
    required String catalogItemId,
    required Offer offer,
    DateTime? syncedAt,
  }) {
    final price = offer.price?.totalPrice;
    final discount = price?.discountPrice ?? 0;
    return LibraryMetadataEntry()
      ..catalogItemId = catalogItemId
      ..offerId = offer.id
      ..namespace = offer.namespace
      ..offerType = offer.offerType
      ..tags = offer.tags
          .map((t) => t.name)
          .where((name) => name.isNotEmpty)
          .toList(growable: false)
      ..categories = List<String>.from(offer.categories)
      ..developerDisplayName = offer.developerDisplayName
      ..publisherDisplayName = offer.publisherDisplayName
      ..sellerName = offer.seller?.name
      ..releaseDate = offer.releaseDate ?? offer.pcReleaseDate
      ..lastModifiedDate = offer.lastModifiedDate
      ..currentPriceCents = price?.discountPrice
      ..currencyCode = price?.currencyCode
      ..isFree = price != null && discount == 0
      ..isOnSale = price?.isOnSale ?? false
      ..keyImagesPacked = _packKeyImages(offer.keyImages)
      ..syncedAt = syncedAt ?? DateTime.now();
  }

  /// Empty / negative-result placeholder so we don't refetch every render
  /// when an item has no resolvable offer.
  factory LibraryMetadataEntry.empty(String catalogItemId) {
    return LibraryMetadataEntry()
      ..catalogItemId = catalogItemId
      ..tags = const []
      ..categories = const []
      ..syncedAt = DateTime.now();
  }
}
