import 'food_item.dart';

class CartItem {
  final String foodItemId;
  final int quantity;
  final FoodItem foodItem;
  final double subtotal;
  final String? restaurantId;

  const CartItem({
    required this.foodItemId,
    required this.quantity,
    required this.foodItem,
    required this.subtotal,
    this.restaurantId,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        foodItemId: (json['food_item_id'] ?? '').toString(),
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        foodItem: FoodItem.fromJson(
            (json['food_item'] as Map<String, dynamic>?) ?? const {}),
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        restaurantId: (json['restaurant_id'] as String?)?.toString(),
      );
}

class Cart {
  final String? restaurantId;
  final List<CartItem> items;
  final double total;

  const Cart({
    this.restaurantId,
    this.items = const [],
    this.total = 0,
  });

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
        restaurantId: (json['restaurant_id'] as String?)?.toString(),
        items: ((json['items'] as List?) ?? const [])
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: (json['total'] as num?)?.toDouble() ?? 0,
      );

  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);
}
