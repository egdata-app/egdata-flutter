class KeyImage {
  final String type;
  final String url;

  const KeyImage({required this.type, required this.url});

  factory KeyImage.fromJson(Map<String, dynamic> json) {
    return KeyImage(
      type: json['type'] ?? '',
      url: json['url'] ?? '',
    );
  }
}

class GameMetadata {
  final String id;
  final String title;
  final String? description;
  final String? developer;
  final String? publisher;
  final List<KeyImage> keyImages;

  GameMetadata({
    required this.id,
    required this.title,
    this.description,
    this.developer,
    this.publisher,
    this.keyImages = const [],
  });

  /// Get horizontal box art (DieselGameBox)
  String? get dieselGameBox => _getImageByType('DieselGameBox');

  /// Get vertical/tall box art (DieselGameBoxTall)
  String? get dieselGameBoxTall => _getImageByType('DieselGameBoxTall');

  String? _getImageByType(String type) {
    for (final img in keyImages) {
      if (img.type == type) return img.url;
    }
    return null;
  }

  /// Get first available image URL (fallback)
  String? get firstImageUrl => keyImages.isNotEmpty ? keyImages.first.url : null;

  factory GameMetadata.fromJson(Map<String, dynamic> json) {
    List<KeyImage> images = [];
    if (json['keyImages'] != null) {
      for (var img in json['keyImages']) {
        if (img['url'] != null) {
          images.add(KeyImage.fromJson(img));
        }
      }
    }

    return GameMetadata(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      developer: json['developer'],
      publisher: json['publisher'],
      keyImages: images,
    );
  }
}
