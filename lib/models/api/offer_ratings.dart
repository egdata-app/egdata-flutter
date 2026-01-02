class OfferRatings {
  final String? id;
  final int? criticAverage;
  final String? criticRating;
  final int? recommendPercentage;
  final List<Review>? reviews;
  final String? url;

  OfferRatings({
    this.id,
    this.criticAverage,
    this.criticRating,
    this.recommendPercentage,
    this.reviews,
    this.url,
  });

  factory OfferRatings.fromJson(Map<String, dynamic> json) {
    return OfferRatings(
      id: json['_id'] as String?,
      criticAverage: json['criticAverage'] as int?,
      criticRating: json['criticRating'] as String?,
      recommendPercentage: json['recommendPercentage'] as int?,
      reviews: json['reviews'] != null
          ? (json['reviews'] as List)
              .map((r) => Review.fromJson(r as Map<String, dynamic>))
              .toList()
          : null,
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'criticAverage': criticAverage,
      'criticRating': criticRating,
      'recommendPercentage': recommendPercentage,
      'reviews': reviews?.map((r) => r.toJson()).toList(),
      'url': url,
    };
  }
}

class Review {
  final String? author;
  final String? body;
  final String? outlet;
  final ReviewScore? score;
  final String? url;

  Review({
    this.author,
    this.body,
    this.outlet,
    this.score,
    this.url,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      author: json['author'] as String?,
      body: json['body'] as String?,
      outlet: json['outlet'] as String?,
      score: json['score'] != null
          ? ReviewScore.fromJson(json['score'] as Map<String, dynamic>)
          : null,
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'author': author,
      'body': body,
      'outlet': outlet,
      'score': score?.toJson(),
      'url': url,
    };
  }
}

class ReviewScore {
  final double? earnedScore;
  final double? totalScore;
  final String? score; // For qualitative scores like "Recommended"

  ReviewScore({
    this.earnedScore,
    this.totalScore,
    this.score,
  });

  factory ReviewScore.fromJson(Map<String, dynamic> json) {
    return ReviewScore(
      earnedScore: (json['earnedScore'] as num?)?.toDouble(),
      totalScore: (json['totalScore'] as num?)?.toDouble(),
      score: json['score'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'earnedScore': earnedScore,
      'totalScore': totalScore,
      'score': score,
    };
  }

  /// Get formatted score string (e.g., "89/100" or "Recommended")
  String get formatted {
    if (score != null) return score!;
    if (earnedScore != null && totalScore != null) {
      if (totalScore == 10) {
        return earnedScore!.toStringAsFixed(1);
      }
      return '${earnedScore!.toInt()}/${totalScore!.toInt()}';
    }
    return '';
  }
}

