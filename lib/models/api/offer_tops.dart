class OfferTops {
  final Map<String, int> positions;

  OfferTops({required this.positions});

  factory OfferTops.fromJson(Map<String, dynamic> json) {
    final positions = <String, int>{};
    json.forEach((key, value) {
      if (value is int) {
        positions[key] = value;
      }
    });
    return OfferTops(positions: positions);
  }

  Map<String, dynamic> toJson() {
    return positions;
  }

  /// Get top rankings in display order (smaller numbers = better ranking)
  /// Filters out position 0 which means the game disappeared from that ranking
  List<MapEntry<String, int>> get sortedRankings {
    final entries = positions.entries
        .where((entry) => entry.value > 0) // Exclude position 0 (disappeared)
        .toList();
    entries.sort((a, b) => a.value.compareTo(b.value));
    return entries;
  }

  /// Check if this offer is in any top rankings
  /// Position 0 means disappeared, so only count positions > 0
  bool get hasRankings => positions.values.any((position) => position > 0);

  /// Get human-readable collection name
  String getCollectionName(String collectionId) {
    switch (collectionId) {
      case 'top-player-reviewed':
        return 'Top Player Reviewed';
      case 'top-wishlisted':
        return 'Most Wishlisted';
      case 'top-sellers':
        return 'Top Sellers';
      case 'top-rated':
        return 'Top Rated';
      case 'top-new-releases':
        return 'Top New Releases';
      case 'top-discounts':
        return 'Best Discounts';
      default:
        // Convert kebab-case to Title Case
        return collectionId
            .split('-')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  /// Get formatted ranking text (e.g., "#5 in Top Sellers")
  /// Position is 1-indexed (1 = first place, 2 = second place, etc.)
  /// Position 0 means the game disappeared from that ranking
  String formatRanking(String collectionId, int position) {
    if (position <= 0) {
      return 'Not ranked in ${getCollectionName(collectionId)}';
    }
    return '#$position in ${getCollectionName(collectionId)}';
  }
}
