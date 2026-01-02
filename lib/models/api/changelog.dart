/// Represents a paginated changelog response from the EGData API
class ChangelogResponse {
  final List<ChangelogItem> elements;
  final int page;
  final int limit;
  final int totalCount;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;

  ChangelogResponse({
    required this.elements,
    required this.page,
    required this.limit,
    required this.totalCount,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  factory ChangelogResponse.fromJson(Map<String, dynamic> json) {
    return ChangelogResponse(
      elements: (json['elements'] as List<dynamic>?)
          ?.map((e) => ChangelogItem.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      page: (json['page'] as int?) ?? 1,
      limit: (json['limit'] as int?) ?? 10,
      totalCount: (json['totalCount'] as int?) ?? 0,
      totalPages: (json['totalPages'] as int?) ?? 0,
      hasNextPage: (json['hasNextPage'] as bool?) ?? false,
      hasPreviousPage: (json['hasPreviousPage'] as bool?) ?? false,
    );
  }
}

class ChangelogItem {
  final String id;
  final DateTime timestamp;
  final ChangelogMetadata metadata;

  ChangelogItem({
    required this.id,
    required this.timestamp,
    required this.metadata,
  });

  factory ChangelogItem.fromJson(Map<String, dynamic> json) {
    return ChangelogItem(
      id: (json['_id'] as String?) ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      metadata: json['metadata'] != null
          ? ChangelogMetadata.fromJson(json['metadata'] as Map<String, dynamic>)
          : ChangelogMetadata(contextType: '', contextId: '', changes: []),
    );
  }

  /// Get formatted date (e.g., "Jan 2, 2026")
  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[timestamp.month - 1]} ${timestamp.day}, ${timestamp.year}';
  }

  /// Get relative time (e.g., "2 days ago")
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}

class ChangelogMetadata {
  final String contextType;
  final String contextId;
  final List<Change> changes;

  ChangelogMetadata({
    required this.contextType,
    required this.contextId,
    required this.changes,
  });

  factory ChangelogMetadata.fromJson(Map<String, dynamic> json) {
    return ChangelogMetadata(
      contextType: (json['contextType'] as String?) ?? '',
      contextId: (json['contextId'] as String?) ?? '',
      changes: (json['changes'] as List<dynamic>?)
          ?.map((e) => Change.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class Change {
  final String changeType;
  final String field;
  final dynamic oldValue;
  final dynamic newValue;

  Change({
    required this.changeType,
    required this.field,
    this.oldValue,
    this.newValue,
  });

  factory Change.fromJson(Map<String, dynamic> json) {
    return Change(
      changeType: (json['changeType'] as String?) ?? 'update',
      field: (json['field'] as String?) ?? '',
      oldValue: json['oldValue'],
      newValue: json['newValue'],
    );
  }

  /// Get display label for the field
  String get fieldLabel {
    // Convert camelCase to Title Case
    final words = field.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    ).trim();
    return words.isEmpty ? field : words[0].toUpperCase() + words.substring(1);
  }

  /// Get color for the change type badge
  int get changeTypeColor {
    switch (changeType) {
      case 'insert':
        return 0xFF10B981; // Green
      case 'delete':
        return 0xFFEF4444; // Red
      case 'update':
      default:
        return 0xFF3B82F6; // Blue
    }
  }

  /// Get background color for the change type badge (with opacity)
  int get changeTypeBgColor {
    switch (changeType) {
      case 'insert':
        return 0x3310B981; // Green with 20% opacity
      case 'delete':
        return 0x33EF4444; // Red with 20% opacity
      case 'update':
      default:
        return 0x333B82F6; // Blue with 20% opacity
    }
  }

  /// Get display label for change type
  String get changeTypeLabel {
    switch (changeType) {
      case 'insert':
        return 'Added';
      case 'delete':
        return 'Removed';
      case 'update':
      default:
        return 'Updated';
    }
  }

  /// Get formatted change text (without field label)
  String get changeText {
    if (changeType == 'insert') {
      return _formatValue(newValue);
    } else if (changeType == 'delete') {
      return _formatValue(oldValue);
    } else {
      // Update
      final oldStr = _formatValue(oldValue);
      final newStr = _formatValue(newValue);

      if (oldStr.isEmpty && newStr.isEmpty) {
        return '';
      } else if (oldStr.isEmpty) {
        return newStr;
      } else if (newStr.isEmpty) {
        return oldStr;
      } else {
        return '$oldStr → $newStr';
      }
    }
  }

  /// Get formatted display string (deprecated, use fieldLabel + changeText separately for better styling)
  String get displayString {
    final text = changeText;
    return text.isEmpty ? fieldLabel : '$fieldLabel: $text';
  }

  String _formatValue(dynamic value) {
    if (value == null) return '';

    // Handle dates
    if (field.toLowerCase().contains('date') && value is String) {
      try {
        final date = DateTime.parse(value);
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return '${months[date.month - 1]} ${date.day}, ${date.year}';
      } catch (_) {
        return value;
      }
    }

    // Handle prices (cents to dollars)
    if (field.toLowerCase().contains('price') && value is int) {
      return '\$${(value / 100).toStringAsFixed(2)}';
    }

    // Handle file sizes (bytes)
    if ((field.toLowerCase().contains('size') || field.toLowerCase().contains('bytes')) && value is int) {
      if (value < 1024) return '$value B';
      if (value < 1024 * 1024) return '${(value / 1024).toStringAsFixed(1)} KB';
      if (value < 1024 * 1024 * 1024) return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
      return '${(value / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }

    // Handle images/keyImages
    if (field.toLowerCase().contains('image') && value is Map) {
      final type = value['type'] as String?;
      return type ?? 'Image';
    }

    // Handle tags
    if (field.toLowerCase().contains('tag') && value is Map) {
      final name = value['name'] as String?;
      return name ?? value.toString();
    }

    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is List) return '${value.length} items';
    if (value is Map) return value['name']?.toString() ?? value.toString();
    return value.toString();
  }
}
