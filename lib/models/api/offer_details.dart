/// Features response from /offers/:id/features
class OfferFeatures {
  final String launcher;
  final List<String> features;
  final List<String> epicFeatures;

  OfferFeatures({
    required this.launcher,
    required this.features,
    required this.epicFeatures,
  });

  factory OfferFeatures.fromJson(Map<String, dynamic> json) {
    return OfferFeatures(
      launcher: (json['launcher'] as String?) ?? '',
      features: (json['features'] as List<dynamic>?)?.cast<String>() ?? [],
      epicFeatures:
          (json['epicFeatures'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

/// Achievement from /offers/:id/achievements
class Achievement {
  final String name;
  final String flavorText;
  final bool hidden;
  final String unlockedDisplayName;
  final String unlockedDescription;
  final String unlockedIconLink;
  final String lockedDisplayName;
  final String lockedDescription;
  final String lockedIconLink;
  final int xp;
  final double completedPercent;

  Achievement({
    required this.name,
    required this.flavorText,
    required this.hidden,
    required this.unlockedDisplayName,
    required this.unlockedDescription,
    required this.unlockedIconLink,
    required this.lockedDisplayName,
    required this.lockedDescription,
    required this.lockedIconLink,
    required this.xp,
    required this.completedPercent,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      name: (json['name'] as String?) ?? '',
      flavorText: (json['flavorText'] as String?) ?? '',
      hidden: (json['hidden'] as bool?) ?? false,
      unlockedDisplayName: (json['unlockedDisplayName'] as String?) ?? '',
      unlockedDescription: (json['unlockedDescription'] as String?) ?? '',
      unlockedIconLink: (json['unlockedIconLink'] as String?) ?? '',
      lockedDisplayName: (json['lockedDisplayName'] as String?) ?? '',
      lockedDescription: (json['lockedDescription'] as String?) ?? '',
      lockedIconLink: (json['lockedIconLink'] as String?) ?? '',
      xp: (json['xp'] as int?) ?? 0,
      completedPercent: (json['completedPercent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Achievement set from /offers/:id/achievements
class AchievementSet {
  final String productId;
  final String achievementSetId;
  final bool isBase;
  final List<Achievement> achievements;

  AchievementSet({
    required this.productId,
    required this.achievementSetId,
    required this.isBase,
    required this.achievements,
  });

  factory AchievementSet.fromJson(Map<String, dynamic> json) {
    return AchievementSet(
      productId: (json['productId'] as String?) ?? '',
      achievementSetId: (json['achievementSetId'] as String?) ?? '',
      isBase: (json['isBase'] as bool?) ?? false,
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((e) => Achievement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Detailed time from /offers/:id/hltb
class HltbDetailedTime {
  final String type;
  final String average;
  final String median;
  final String rushed;
  final String leisure;

  HltbDetailedTime({
    required this.type,
    required this.average,
    required this.median,
    required this.rushed,
    required this.leisure,
  });

  factory HltbDetailedTime.fromJson(Map<String, dynamic> json) {
    return HltbDetailedTime(
      type: (json['type'] as String?) ?? '',
      average: (json['average'] as String?) ?? '',
      median: (json['median'] as String?) ?? '',
      rushed: (json['rushed'] as String?) ?? '',
      leisure: (json['leisure'] as String?) ?? '',
    );
  }
}

/// Game time from /offers/:id/hltb
class HltbGameTime {
  final String category;
  final String time;

  HltbGameTime({
    required this.category,
    required this.time,
  });

  factory HltbGameTime.fromJson(Map<String, dynamic> json) {
    return HltbGameTime(
      category: (json['category'] as String?) ?? '',
      time: (json['time'] as String?) ?? '',
    );
  }
}

/// HLTB response from /offers/:id/hltb
class OfferHltb {
  final String hltbId;
  final List<HltbDetailedTime> detailedTimes;
  final List<HltbGameTime> gameTimes;

  OfferHltb({
    required this.hltbId,
    required this.detailedTimes,
    required this.gameTimes,
  });

  factory OfferHltb.fromJson(Map<String, dynamic> json) {
    return OfferHltb(
      hltbId: (json['hltbId'] as String?) ?? '',
      detailedTimes: (json['detailedTimes'] as List<dynamic>?)
              ?.map((e) => HltbDetailedTime.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      gameTimes: (json['gameTimes'] as List<dynamic>?)
              ?.map((e) => HltbGameTime.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Media image from /offers/:id/media
class MediaImage {
  final String src;

  MediaImage({required this.src});

  factory MediaImage.fromJson(Map<String, dynamic> json) {
    return MediaImage(
      src: (json['src'] as String?) ?? '',
    );
  }
}

/// Media video output from /offers/:id/media
class MediaVideoOutput {
  final int? duration;
  final String url;
  final int? width;
  final int? height;
  final String key;
  final String contentType;

  MediaVideoOutput({
    this.duration,
    required this.url,
    this.width,
    this.height,
    required this.key,
    required this.contentType,
  });

  factory MediaVideoOutput.fromJson(Map<String, dynamic> json) {
    return MediaVideoOutput(
      duration: json['duration'] as int?,
      url: (json['url'] as String?) ?? '',
      width: json['width'] as int?,
      height: json['height'] as int?,
      key: (json['key'] as String?) ?? '',
      contentType: (json['contentType'] as String?) ?? '',
    );
  }
}

/// Media video from /offers/:id/media
class MediaVideo {
  final List<MediaVideoOutput> outputs;

  MediaVideo({required this.outputs});

  factory MediaVideo.fromJson(Map<String, dynamic> json) {
    return MediaVideo(
      outputs: (json['outputs'] as List<dynamic>?)
              ?.map((e) => MediaVideoOutput.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Get the best quality video URL (mp4, highest resolution)
  String? get bestVideoUrl {
    final mp4Outputs = outputs
        .where((o) =>
            o.contentType.contains('video/mp4') &&
            o.width != null &&
            o.height != null)
        .toList();
    if (mp4Outputs.isEmpty) return null;
    mp4Outputs.sort((a, b) => (b.width ?? 0).compareTo(a.width ?? 0));
    return mp4Outputs.first.url;
  }

  /// Get thumbnail URL
  String? get thumbnailUrl {
    final thumbnails =
        outputs.where((o) => o.contentType.contains('image')).toList();
    return thumbnails.isNotEmpty ? thumbnails.first.url : null;
  }
}

/// Media response from /offers/:id/media
class OfferMedia {
  final String namespace;
  final List<MediaImage> images;
  final List<MediaVideo> videos;

  OfferMedia({
    required this.namespace,
    required this.images,
    required this.videos,
  });

  factory OfferMedia.fromJson(Map<String, dynamic> json) {
    return OfferMedia(
      namespace: (json['namespace'] as String?) ?? '',
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => MediaImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      videos: (json['videos'] as List<dynamic>?)
              ?.map((e) => MediaVideo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
