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
}
