class Restaurant {
  final String id;
  final String name;
  final String cuisine;
  final String city;
  final String address;
  final String phone;
  final String description;
  final String imageUrl;
  final int deliveryEstimate;
  final double deliveryFee;
  final double rating;
  final int ratingCount;

  const Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.city,
    this.address = '',
    this.phone = '',
    this.description = '',
    this.imageUrl = '',
    this.deliveryEstimate = 30,
    this.deliveryFee = 0,
    this.rating = 0,
    this.ratingCount = 0,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        cuisine: (json['cuisine'] ?? '').toString(),
        city: (json['city'] ?? '').toString(),
        address: (json['address'] ?? '').toString(),
        phone: (json['phone'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        imageUrl: (json['image_url'] ?? '').toString(),
        deliveryEstimate: (json['delivery_estimate'] as num?)?.toInt() ?? 30,
        deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'cuisine': cuisine,
        'city': city,
        'address': address,
        'phone': phone,
        'description': description,
        'image_url': imageUrl,
        'delivery_estimate': deliveryEstimate,
        'delivery_fee': deliveryFee,
      };
}
