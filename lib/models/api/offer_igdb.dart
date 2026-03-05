import 'package:json_annotation/json_annotation.dart';

part 'offer_igdb.g.dart';

@JsonSerializable()
class OfferIgdb {
  final int? id;
  @JsonKey(name: '_id')
  final String? internalId;
  final String offerId;
  final int igdbId;
  final String igdbName;
  final String igdbSlug;
  final Cover? cover;
  @JsonKey(name: 'aggregated_rating')
  final double? aggregatedRating;
  @JsonKey(name: 'aggregated_rating_count')
  final int? aggregatedRatingCount;
  final double? rating;
  @JsonKey(name: 'rating_count')
  final int? ratingCount;
  @JsonKey(name: 'total_rating')
  final double? totalRating;
  @JsonKey(name: 'first_release_date')
  final int? firstReleaseDate;
  final String? summary;
  final String? storyline;
  final List<int>? platforms;
  final List<int>? genres;
  final TimeToBeat? timeToBeat;

  OfferIgdb({
    this.id,
    this.internalId,
    required this.offerId,
    required this.igdbId,
    required this.igdbName,
    required this.igdbSlug,
    this.cover,
    this.aggregatedRating,
    this.aggregatedRatingCount,
    this.rating,
    this.ratingCount,
    this.totalRating,
    this.firstReleaseDate,
    this.summary,
    this.storyline,
    this.platforms,
    this.genres,
    this.timeToBeat,
  });

  factory OfferIgdb.fromJson(Map<String, dynamic> json) =>
      _$OfferIgdbFromJson(json);

  Map<String, dynamic> toJson() => _$OfferIgdbToJson(this);
}

@JsonSerializable()
class Cover {
  final int id;
  final String url;
  final int width;
  final int height;
  @JsonKey(name: 'image_id')
  final String imageId;

  Cover({
    required this.id,
    required this.url,
    required this.width,
    required this.height,
    required this.imageId,
  });

  factory Cover.fromJson(Map<String, dynamic> json) => _$CoverFromJson(json);

  Map<String, dynamic> toJson() => _$CoverToJson(this);
}

@JsonSerializable()
class TimeToBeat {
  final int? normally;
  final int? completely;

  TimeToBeat({this.normally, this.completely});

  factory TimeToBeat.fromJson(Map<String, dynamic> json) =>
      _$TimeToBeatFromJson(json);

  Map<String, dynamic> toJson() => _$TimeToBeatToJson(this);

  /// Returns normally time in hours
  double get normallyHours => (normally ?? 0) / 3600.0;

  /// Returns completely time in hours
  double get completelyHours => (completely ?? 0) / 3600.0;
}
