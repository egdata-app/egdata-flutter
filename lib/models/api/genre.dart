/// Represents an offer preview within a genre response
class GenreOffer {
  final String id;
  final String title;
  final GenreOfferImage? image;

  GenreOffer({
    required this.id,
    required this.title,
    this.image,
  });

  factory GenreOffer.fromJson(Map<String, dynamic> json) {
    return GenreOffer(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      image: json['image'] != null
          ? GenreOfferImage.fromJson(json['image'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Represents an image in a genre offer
class GenreOfferImage {
  final String type;
  final String url;
  final String? md5;

  GenreOfferImage({
    required this.type,
    required this.url,
    this.md5,
  });

  factory GenreOfferImage.fromJson(Map<String, dynamic> json) {
    return GenreOfferImage(
      type: json['type'] as String? ?? '',
      url: json['url'] as String? ?? '',
      md5: json['md5'] as String?,
    );
  }
}

/// Represents genre metadata
class GenreInfo {
  final String id;
  final String name;
  final String status;
  final int referenceCount;

  GenreInfo({
    required this.id,
    required this.name,
    required this.status,
    required this.referenceCount,
  });

  factory GenreInfo.fromJson(Map<String, dynamic> json) {
    return GenreInfo(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      referenceCount: json['referenceCount'] as int? ?? 0,
    );
  }
}

/// Represents a genre with its associated offers
class GenreWithOffers {
  final GenreInfo genre;
  final List<GenreOffer> offers;

  GenreWithOffers({
    required this.genre,
    required this.offers,
  });

  factory GenreWithOffers.fromJson(Map<String, dynamic> json) {
    final offersJson = json['offers'] as List<dynamic>? ?? [];
    return GenreWithOffers(
      genre: GenreInfo.fromJson(json['genre'] as Map<String, dynamic>),
      offers: offersJson
          .map((e) => GenreOffer.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
