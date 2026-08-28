class DeliveryAddress {
  final String id;
  final String label;
  final String fullName;
  final String phone;
  final String addressLine;
  final String city;
  final String state;
  final String postalCode;
  final bool? isDefault;
  final String createdAt;

  const DeliveryAddress({
    required this.id,
    this.label = 'Home',
    this.fullName = '',
    this.phone = '',
    this.addressLine = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
    this.isDefault,
    this.createdAt = '',
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) =>
      DeliveryAddress(
        id: (json['id'] ?? '').toString(),
        label: (json['label'] ?? 'Home').toString(),
        fullName: (json['full_name'] ?? '').toString(),
        phone: (json['phone'] ?? '').toString(),
        addressLine: (json['address_line'] ?? '').toString(),
        city: (json['city'] ?? '').toString(),
        state: (json['state'] ?? '').toString(),
        postalCode: (json['postal_code'] ?? '').toString(),
        isDefault: json['is_default'] as bool?,
        createdAt: (json['created_at'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'full_name': fullName,
        'phone': phone,
        'address_line': addressLine,
        'city': city,
        'state': state,
        'postal_code': postalCode,
      };

  String get summary => '$addressLine, $city $state $postalCode'
      .replaceAll('  ', ' ')
      .trim();
}
