/// Represents a region from the EGData API
class Region {
  final String code;
  final String currencyCode;
  final String description;
  final List<String> countries;

  Region({
    required this.code,
    required this.currencyCode,
    required this.description,
    required this.countries,
  });

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      code: (json['code'] as String?) ?? '',
      currencyCode: (json['currencyCode'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      countries: (json['countries'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'currencyCode': currencyCode,
      'description': description,
      'countries': countries,
    };
  }
}
