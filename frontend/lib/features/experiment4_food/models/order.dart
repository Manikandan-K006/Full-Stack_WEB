class OrderItem {
  final String foodItemId;
  final String name;
  final double price;
  final int quantity;
  final double subtotal;

  const OrderItem({
    required this.foodItemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        foodItemId: (json['food_item_id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        price: (json['price'] as num?)?.toDouble() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      );
}

class OrderAddress {
  final String label;
  final String fullName;
  final String phone;
  final String addressLine;
  final String city;
  final String state;
  final String postalCode;

  const OrderAddress({
    this.label = '',
    this.fullName = '',
    this.phone = '',
    this.addressLine = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
  });

  factory OrderAddress.fromJson(Map<String, dynamic> json) => OrderAddress(
        label: (json['label'] ?? '').toString(),
        fullName: (json['full_name'] ?? '').toString(),
        phone: (json['phone'] ?? '').toString(),
        addressLine: (json['address_line'] ?? '').toString(),
        city: (json['city'] ?? '').toString(),
        state: (json['state'] ?? '').toString(),
        postalCode: (json['postal_code'] ?? '').toString(),
      );

  String get summary =>
      '$addressLine, $city $state $postalCode'.replaceAll('  ', ' ').trim();
}

class StatusHistoryEvent {
  final String status;
  final String at;
  final String note;

  const StatusHistoryEvent({
    required this.status,
    this.at = '',
    this.note = '',
  });

  factory StatusHistoryEvent.fromJson(Map<String, dynamic> json) =>
      StatusHistoryEvent(
        status: (json['status'] ?? '').toString(),
        at: (json['at'] ?? '').toString(),
        note: (json['note'] ?? '').toString(),
      );
}

class Order {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final OrderAddress address;
  final String paymentMethod;
  final String status;
  final List<StatusHistoryEvent> statusHistory;
  final String createdAt;

  const Order({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    this.items = const [],
    this.subtotal = 0,
    this.deliveryFee = 0,
    this.total = 0,
    this.address = const OrderAddress(),
    this.paymentMethod = '',
    this.status = '',
    this.statusHistory = const [],
    this.createdAt = '',
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: (json['id'] ?? '').toString(),
        restaurantId: (json['restaurant_id'] ?? '').toString(),
        restaurantName: (json['restaurant_name'] ?? '').toString(),
        items: ((json['items'] as List?) ?? const [])
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num?)?.toDouble() ?? 0,
        address: OrderAddress.fromJson(
            (json['address'] as Map<String, dynamic>?) ?? const {}),
        paymentMethod: (json['payment_method'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        statusHistory: ((json['status_history'] as List?) ?? const [])
            .map((e) =>
                StatusHistoryEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: (json['created_at'] ?? '').toString(),
      );
}
