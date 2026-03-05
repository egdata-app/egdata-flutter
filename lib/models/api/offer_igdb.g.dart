// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer_igdb.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfferIgdb _$OfferIgdbFromJson(Map<String, dynamic> json) => OfferIgdb(
  id: (json['id'] as num?)?.toInt(),
  internalId: json['_id'] as String?,
  offerId: json['offerId'] as String,
  igdbId: (json['igdbId'] as num).toInt(),
  igdbName: json['igdbName'] as String,
  igdbSlug: json['igdbSlug'] as String,
  cover: json['cover'] == null
      ? null
      : Cover.fromJson(json['cover'] as Map<String, dynamic>),
  aggregatedRating: (json['aggregated_rating'] as num?)?.toDouble(),
  aggregatedRatingCount: (json['aggregated_rating_count'] as num?)?.toInt(),
  rating: (json['rating'] as num?)?.toDouble(),
  ratingCount: (json['rating_count'] as num?)?.toInt(),
  totalRating: (json['total_rating'] as num?)?.toDouble(),
  firstReleaseDate: (json['first_release_date'] as num?)?.toInt(),
  summary: json['summary'] as String?,
  storyline: json['storyline'] as String?,
  platforms: (json['platforms'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  genres: (json['genres'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  timeToBeat: json['timeToBeat'] == null
      ? null
      : TimeToBeat.fromJson(json['timeToBeat'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OfferIgdbToJson(OfferIgdb instance) => <String, dynamic>{
  'id': instance.id,
  '_id': instance.internalId,
  'offerId': instance.offerId,
  'igdbId': instance.igdbId,
  'igdbName': instance.igdbName,
  'igdbSlug': instance.igdbSlug,
  'cover': instance.cover,
  'aggregated_rating': instance.aggregatedRating,
  'aggregated_rating_count': instance.aggregatedRatingCount,
  'rating': instance.rating,
  'rating_count': instance.ratingCount,
  'total_rating': instance.totalRating,
  'first_release_date': instance.firstReleaseDate,
  'summary': instance.summary,
  'storyline': instance.storyline,
  'platforms': instance.platforms,
  'genres': instance.genres,
  'timeToBeat': instance.timeToBeat,
};

Cover _$CoverFromJson(Map<String, dynamic> json) => Cover(
  id: (json['id'] as num).toInt(),
  url: json['url'] as String,
  width: (json['width'] as num).toInt(),
  height: (json['height'] as num).toInt(),
  imageId: json['image_id'] as String,
);

Map<String, dynamic> _$CoverToJson(Cover instance) => <String, dynamic>{
  'id': instance.id,
  'url': instance.url,
  'width': instance.width,
  'height': instance.height,
  'image_id': instance.imageId,
};

TimeToBeat _$TimeToBeatFromJson(Map<String, dynamic> json) => TimeToBeat(
  normally: (json['normally'] as num?)?.toInt(),
  completely: (json['completely'] as num?)?.toInt(),
);

Map<String, dynamic> _$TimeToBeatToJson(TimeToBeat instance) =>
    <String, dynamic>{
      'normally': instance.normally,
      'completely': instance.completely,
    };
