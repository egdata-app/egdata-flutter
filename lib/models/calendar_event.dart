enum CalendarEventType {
  freeGame,
  release,
  sale,
  followedUpdate,
}

class CalendarEvent {
  final String id;
  final CalendarEventType type;
  final String title;
  final String? subtitle;
  final String? offerId;
  final String? thumbnailUrl;
  final DateTime startDate;
  final DateTime? endDate;
  final Map<String, dynamic>? metadata;

  const CalendarEvent({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.offerId,
    this.thumbnailUrl,
    required this.startDate,
    this.endDate,
    this.metadata,
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && (endDate == null || now.isBefore(endDate!));
  }

  bool get isUpcoming => DateTime.now().isBefore(startDate);

  bool get hasEnded => endDate != null && DateTime.now().isAfter(endDate!);

  CalendarEvent copyWith({
    String? id,
    CalendarEventType? type,
    String? title,
    String? subtitle,
    String? offerId,
    String? thumbnailUrl,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? metadata,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      offerId: offerId ?? this.offerId,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'subtitle': subtitle,
      'offerId': offerId,
      'thumbnailUrl': thumbnailUrl,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] ?? '',
      type: CalendarEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CalendarEventType.freeGame,
      ),
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      offerId: json['offerId'],
      thumbnailUrl: json['thumbnailUrl'],
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      metadata: json['metadata'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CalendarEvent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
