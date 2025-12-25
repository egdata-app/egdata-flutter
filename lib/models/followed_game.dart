class FollowedGame {
  final String offerId;
  final String title;
  final String? namespace;
  final String? thumbnailUrl;
  final DateTime followedAt;

  const FollowedGame({
    required this.offerId,
    required this.title,
    this.namespace,
    this.thumbnailUrl,
    required this.followedAt,
  });

  FollowedGame copyWith({
    String? offerId,
    String? title,
    String? namespace,
    String? thumbnailUrl,
    DateTime? followedAt,
  }) {
    return FollowedGame(
      offerId: offerId ?? this.offerId,
      title: title ?? this.title,
      namespace: namespace ?? this.namespace,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      followedAt: followedAt ?? this.followedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offerId': offerId,
      'title': title,
      'namespace': namespace,
      'thumbnailUrl': thumbnailUrl,
      'followedAt': followedAt.toIso8601String(),
    };
  }

  factory FollowedGame.fromJson(Map<String, dynamic> json) {
    return FollowedGame(
      offerId: json['offerId'] ?? '',
      title: json['title'] ?? '',
      namespace: json['namespace'],
      thumbnailUrl: json['thumbnailUrl'],
      followedAt: json['followedAt'] != null
          ? DateTime.parse(json['followedAt'])
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FollowedGame && other.offerId == offerId;
  }

  @override
  int get hashCode => offerId.hashCode;
}
