class Listing {
  static const List<String> categories = [
    'ELECTRONICS',
    'MOBILES',
    'LAPTOPS',
    'VEHICLES',
    'FURNITURE',
    'BOOKS',
    'CLOTHING',
    'HOME_APPLIANCES',
    'OTHERS',
  ];

  static const List<String> conditions = ['NEW', 'LIKE_NEW', 'GOOD', 'FAIR'];

  static const List<String> statuses = ['AVAILABLE', 'SOLD', 'REMOVED'];

  final String id;
  final String title;
  final String description;
  final num price;
  final String category;
  final String condition;
  final String location;
  final List<String> images;
  final String status;
  final String? sellerId;
  final String? sellerName;
  final Map<String, dynamic>? seller;
  final String? createdAt;
  final String? updatedAt;
  final String? favoritedAt;

  const Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.location,
    required this.images,
    required this.status,
    this.sellerId,
    this.sellerName,
    this.seller,
    this.createdAt,
    this.updatedAt,
    this.favoritedAt,
  });

  bool get isAvailable => status.toUpperCase() == 'AVAILABLE';

  factory Listing.fromJson(Map<String, dynamic> json) => Listing(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        price: json['price'] ?? 0,
        category: (json['category'] ?? 'OTHERS').toString(),
        condition: (json['condition'] ?? 'GOOD').toString(),
        location: (json['location'] ?? '').toString(),
        images: (json['images'] is List)
            ? json['images'].whereType<String>().toList()
            : const <String>[],
        status: (json['status'] ?? 'AVAILABLE').toString(),
        sellerId: json['seller_id']?.toString(),
        sellerName: json['seller_name']?.toString(),
        seller: json['seller'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(json['seller'] as Map)
            : null,
        createdAt: json['created_at']?.toString(),
        updatedAt: json['updated_at']?.toString(),
        favoritedAt: json['favorited_at']?.toString(),
      );
}