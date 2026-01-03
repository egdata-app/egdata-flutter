class ReferencedOffer {
  final String id;
  final String title;
  final String? price;
  final String? originalPrice;
  final int? discountPercentage;
  final String? thumbnail;
  final String? offerType;
  final int? releaseDate;
  final String? seller;

  const ReferencedOffer({
    required this.id,
    required this.title,
    this.price,
    this.originalPrice,
    this.discountPercentage,
    this.thumbnail,
    this.offerType,
    this.releaseDate,
    this.seller,
  });

  factory ReferencedOffer.fromJson(Map<String, dynamic> json) {
    return ReferencedOffer(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      price: json['price'],
      originalPrice: json['originalPrice'],
      discountPercentage: json['discountPercentage'],
      thumbnail: json['thumbnail'],
      offerType: json['offerType'],
      releaseDate: json['releaseDate'],
      seller: json['seller'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'originalPrice': originalPrice,
      'discountPercentage': discountPercentage,
      'thumbnail': thumbnail,
      'offerType': offerType,
      'releaseDate': releaseDate,
      'seller': seller,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReferencedOffer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
