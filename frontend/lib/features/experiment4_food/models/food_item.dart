class FoodItem {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final bool isVegetarian;
  final bool isAvailable;

  const FoodItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.description = '',
    this.price = 0,
    this.category = '',
    this.imageUrl = '',
    this.isVegetarian = false,
    this.isAvailable = true,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        id: (json['id'] ?? '').toString(),
        restaurantId: (json['restaurant_id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        price: (json['price'] as num?)?.toDouble() ?? 0,
        category: (json['category'] ?? '').toString(),
        imageUrl: (json['image_url'] ?? '').toString(),
        isVegetarian: (json['is_vegetarian'] ?? false) == true,
        isAvailable: (json['is_available'] ?? true) != false,
      );

  Map<String, dynamic> toJson() => {
        'restaurant_id': restaurantId,
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'image_url': imageUrl,
        'is_vegetarian': isVegetarian,
        'is_available': isAvailable,
      };
}
