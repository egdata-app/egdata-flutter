class OfferPolls {
  final String? id;
  final Map<String, dynamic>? data;

  OfferPolls({
    this.id,
    this.data,
  });

  factory OfferPolls.fromJson(Map<String, dynamic> json) {
    return OfferPolls(
      id: json['_id'] as String?,
      data: json,
    );
  }

  Map<String, dynamic> toJson() {
    return data ?? {};
  }
}
