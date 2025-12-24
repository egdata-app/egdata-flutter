class GameMetadata {
  final String id;
  final String title;
  final String? description;
  final String? developer;
  final String? publisher;
  final List<String> keyImages;

  GameMetadata({
    required this.id,
    required this.title,
    this.description,
    this.developer,
    this.publisher,
    this.keyImages = const [],
  });

  factory GameMetadata.fromJson(Map<String, dynamic> json) {
    List<String> images = [];
    if (json['keyImages'] != null) {
      for (var img in json['keyImages']) {
        if (img['url'] != null) {
          images.add(img['url']);
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
