/// Represents an item from the EGData API
class Item {
  final String id;
  final String namespace;
  final String? title;
  final String? description;
  final String? developer;
  final String? publisher;
  final List<ItemCustomAttribute> customAttributes;
  final List<ItemKeyImage> keyImages;

  Item({
    required this.id,
    required this.namespace,
    this.title,
    this.description,
    this.developer,
    this.publisher,
    required this.customAttributes,
    required this.keyImages,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      namespace: json['namespace'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      developer: json['developer'] as String?,
      publisher: json['publisher'] as String?,
      customAttributes: (json['customAttributes'] as List<dynamic>?)
              ?.map((e) => ItemCustomAttribute.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      keyImages: (json['keyImages'] as List<dynamic>?)
              ?.map((e) => ItemKeyImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Extracts process names from customAttributes
  /// Looks for ProcessNames, MainWindowProcessName, and BackgroundProcessNames
  List<String> get processNames {
    final names = <String>{};

    for (final attr in customAttributes) {
      if (attr.key == 'ProcessNames' ||
          attr.key == 'MainWindowProcessName' ||
          attr.key == 'BackgroundProcessNames') {
        if (attr.value.isNotEmpty) {
          names.addAll(attr.value.split(',').map((s) => s.trim()));
        }
      }
    }

    return names.toList();
  }
}

class ItemCustomAttribute {
  final String key;
  final String value;

  ItemCustomAttribute({
    required this.key,
    required this.value,
  });

  factory ItemCustomAttribute.fromJson(Map<String, dynamic> json) {
    return ItemCustomAttribute(
      key: json['key'] as String,
      value: json['value'] as String? ?? '',
    );
  }
}

class ItemKeyImage {
  final String type;
  final String url;

  ItemKeyImage({
    required this.type,
    required this.url,
  });

  factory ItemKeyImage.fromJson(Map<String, dynamic> json) {
    return ItemKeyImage(
      type: json['type'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }
}
