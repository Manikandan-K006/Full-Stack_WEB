import '../../../core/network/api_client.dart';
import '../models/address.dart';
import '../models/cart.dart';
import '../models/food_item.dart';
import '../models/order.dart';
import '../models/restaurant.dart';

class RestaurantMenu {
  final Restaurant restaurant;
  final List<FoodItem> items;

  const RestaurantMenu({required this.restaurant, required this.items});

  factory RestaurantMenu.fromJson(Map<String, dynamic> json) => RestaurantMenu(
        restaurant: Restaurant.fromJson(
            (json['restaurant'] as Map<String, dynamic>?) ?? const {}),
        items: ((json['items'] as List?) ?? const [])
            .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class FoodService {
  final ApiClient _api = ApiClient.instance;

  Future<List<Restaurant>> listRestaurants({
    String? search,
    String? cuisine,
    String? city,
    double? minRating,
    String sort = 'name',
  }) async {
    final data = await _api.get('/api/restaurants', query: {
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (cuisine != null && cuisine.isNotEmpty) 'cuisine': cuisine,
      if (city != null && city.isNotEmpty) 'city': city,
      if (minRating != null) 'min_rating': minRating,
      'sort': sort,
    });
    return (data as List)
        .map((e) => Restaurant.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Restaurant> getRestaurant(String restaurantId) async {
    final data = await _api.get('/api/restaurants/$restaurantId');
    return Restaurant.fromJson(data as Map<String, dynamic>);
  }

  Future<RestaurantMenu> getMenu(String restaurantId,
      {String? category}) async {
    final data = await _api.get('/api/restaurants/$restaurantId/menu', query: {
      if (category != null && category.isNotEmpty) 'category': category,
    });
    return RestaurantMenu.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> listReviews(String restaurantId) async {
    final data = await _api.get('/api/restaurants/$restaurantId/reviews');
    return (data as List)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<Cart> getCart() async =>
      Cart.fromJson(await _api.get('/api/cart') as Map<String, dynamic>);

  Future<Cart> addToCart({
    required String restaurantId,
    required String foodItemId,
    int quantity = 1,
  }) async {
    final data = await _api.post('/api/cart', body: {
      'restaurant_id': restaurantId,
      'food_item_id': foodItemId,
      'quantity': quantity,
    });
    return Cart.fromJson(data as Map<String, dynamic>);
  }

  Future<Cart> updateCartItem(String foodItemId, int quantity) async {
    final data = await _api
        .put('/api/cart/$foodItemId', body: {'quantity': quantity});
    return Cart.fromJson(data as Map<String, dynamic>);
  }

  Future<Cart> removeCartItem(String foodItemId) async {
    final data = await _api.delete('/api/cart/$foodItemId');
    return Cart.fromJson(data as Map<String, dynamic>);
  }

  Future<List<DeliveryAddress>> listAddresses() async {
    final data = await _api.get('/api/addresses');
    return (data as List)
        .map((e) => DeliveryAddress.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DeliveryAddress> addAddress({
    required String label,
    required String fullName,
    required String phone,
    required String addressLine,
    required String city,
    required String state,
    required String postalCode,
  }) async {
    final data = await _api.post('/api/addresses', body: {
      'label': label,
      'full_name': fullName,
      'phone': phone,
      'address_line': addressLine,
      'city': city,
      'state': state,
      'postal_code': postalCode,
    });
    return DeliveryAddress.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteAddress(String addressId) async {
    await _api.delete('/api/addresses/$addressId');
  }

  Future<Order> placeOrder({
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    required String addressId,
    required String paymentMethod,
  }) async {
    final data = await _api.post('/api/orders', body: {
      'restaurant_id': restaurantId,
      'items': items,
      'address_id': addressId,
      'payment_method': paymentMethod,
    });
    return Order.fromJson(data as Map<String, dynamic>);
  }

  Future<List<Order>> listOrders() async {
    final data = await _api.get('/api/orders');
    return (data as List)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Order> getOrder(String orderId) async {
    final data = await _api.get('/api/orders/$orderId');
    return Order.fromJson(data as Map<String, dynamic>);
  }

  Future<Restaurant> createRestaurant({
    required String name,
    required String cuisine,
    required String city,
    required String address,
    String phone = '',
    String description = '',
    String imageUrl = '',
    int deliveryEstimate = 30,
    double deliveryFee = 0,
  }) async {
    final data = await _api.post('/api/admin/restaurants', body: {
      'name': name,
      'cuisine': cuisine,
      'city': city,
      'address': address,
      'phone': phone,
      'description': description,
      'image_url': imageUrl,
      'delivery_estimate': deliveryEstimate,
      'delivery_fee': deliveryFee,
    });
    return Restaurant.fromJson(data as Map<String, dynamic>);
  }

  Future<Restaurant> updateRestaurant(
    String restaurantId, {
    required String name,
    required String cuisine,
    required String city,
    required String address,
    String phone = '',
    String description = '',
    String imageUrl = '',
    int deliveryEstimate = 30,
    double deliveryFee = 0,
  }) async {
    final data = await _api.put('/api/admin/restaurants/$restaurantId', body: {
      'name': name,
      'cuisine': cuisine,
      'city': city,
      'address': address,
      'phone': phone,
      'description': description,
      'image_url': imageUrl,
      'delivery_estimate': deliveryEstimate,
      'delivery_fee': deliveryFee,
    });
    return Restaurant.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteRestaurant(String restaurantId) async {
    await _api.delete('/api/admin/restaurants/$restaurantId');
  }

  Future<FoodItem> createFoodItem({
    required String restaurantId,
    required String name,
    String description = '',
    required double price,
    required String category,
    String imageUrl = '',
    bool isVegetarian = false,
    bool isAvailable = true,
  }) async {
    final data = await _api.post(
        '/api/admin/restaurants/$restaurantId/food',
        body: {
          'restaurant_id': restaurantId,
          'name': name,
          'description': description,
          'price': price,
          'category': category,
          'image_url': imageUrl,
          'is_vegetarian': isVegetarian,
          'is_available': isAvailable,
        });
    return FoodItem.fromJson(data as Map<String, dynamic>);
  }

  Future<FoodItem> updateFoodItem(
    String foodItemId, {
    required String restaurantId,
    required String name,
    String description = '',
    required double price,
    required String category,
    String imageUrl = '',
    bool isVegetarian = false,
    bool isAvailable = true,
  }) async {
    final data = await _api.put(
        '/api/admin/restaurants/food/$foodItemId',
        body: {
          'restaurant_id': restaurantId,
          'name': name,
          'description': description,
          'price': price,
          'category': category,
          'image_url': imageUrl,
          'is_vegetarian': isVegetarian,
          'is_available': isAvailable,
        });
    return FoodItem.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteFoodItem(String foodItemId) async {
    await _api.delete('/api/admin/restaurants/food/$foodItemId');
  }
}
