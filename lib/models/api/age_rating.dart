class AgeRatings {
  final Map<String, AgeRating> ratings;

  AgeRatings({required this.ratings});

  factory AgeRatings.fromJson(Map<String, dynamic> json) {
    final ratings = <String, AgeRating>{};
    json.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        ratings[key] = AgeRating.fromJson(value);
      }
    });
    return AgeRatings(ratings: ratings);
  }

  Map<String, dynamic> toJson() {
    return ratings.map((key, value) => MapEntry(key, value.toJson()));
  }

  /// Get rating for a specific system (e.g., "ESRB", "PEGI", "USK")
  AgeRating? getRating(String system) => ratings[system];

  /// Get all available rating systems
  List<String> get systems => ratings.keys.toList();

  /// Check if ratings are available
  bool get hasRatings => ratings.isNotEmpty;
}

class AgeRating {
  final String? ratingSystem;
  final int? ageControl;
  final String? gameRating;
  final String? ratingImage;
  final String? rectangularRatingImage;
  final String? title;
  final String? descriptor;
  final List<int>? descriptorIds;
  final List<dynamic>? elementIds;
  final bool? isTrad;
  final bool? isIARC;

  AgeRating({
    this.ratingSystem,
    this.ageControl,
    this.gameRating,
    this.ratingImage,
    this.rectangularRatingImage,
    this.title,
    this.descriptor,
    this.descriptorIds,
    this.elementIds,
    this.isTrad,
    this.isIARC,
  });

  factory AgeRating.fromJson(Map<String, dynamic> json) {
    return AgeRating(
      ratingSystem: json['ratingSystem'] as String?,
      ageControl: json['ageControl'] as int?,
      gameRating: json['gameRating'] as String?,
      ratingImage: json['ratingImage'] as String?,
      rectangularRatingImage: json['rectangularRatingImage'] as String?,
      title: json['title'] as String?,
      descriptor: json['descriptor'] as String?,
      descriptorIds: (json['descriptorIds'] as List<dynamic>?)?.cast<int>(),
      elementIds: json['elementIds'] as List<dynamic>?,
      isTrad: json['isTrad'] as bool?,
      isIARC: json['isIARC'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ratingSystem': ratingSystem,
      'ageControl': ageControl,
      'gameRating': gameRating,
      'ratingImage': ratingImage,
      'rectangularRatingImage': rectangularRatingImage,
      'title': title,
      'descriptor': descriptor,
      'descriptorIds': descriptorIds,
      'elementIds': elementIds,
      'isTrad': isTrad,
      'isIARC': isIARC,
    };
  }

  /// Get display name for the rating system
  String get systemDisplayName {
    if (ratingSystem == null) return 'Unknown';

    switch (ratingSystem!.toUpperCase()) {
      case 'ESRB':
        return 'ESRB (North America)';
      case 'PEGI':
        return 'PEGI (Europe)';
      case 'USK':
        return 'USK (Germany)';
      case 'GRAC':
        return 'GRAC (South Korea)';
      case 'CERO':
        return 'CERO (Japan)';
      case 'ACB':
        return 'ACB (Australia)';
      case 'CLASSIND':
        return 'ClassInd (Brazil)';
      default:
        return ratingSystem!;
    }
  }

  /// Get short display for compact views
  String get compactDisplay {
    return gameRating ?? title ?? 'No Rating';
  }

  /// Get age display (e.g., "Ages 10+")
  String? get ageDisplay {
    if (ageControl == null) return null;
    if (ageControl == 0) return 'All Ages';
    return 'Ages $ageControl+';
  }
}
