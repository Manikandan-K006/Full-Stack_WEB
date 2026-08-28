import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/animated_card.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_widget.dart';
import '../../../widgets/feature_navigator.dart';
import '../../../widgets/loading_widget.dart';
import '../models/address.dart';
import '../models/cart.dart';
import '../models/order.dart';
import '../models/restaurant.dart';
import '../services/food_service.dart';
import '../widgets/page_header.dart';
import 'addresses_screen.dart';
import 'orders_screen.dart';

const List<String> _paymentOptions = ['CASH', 'ONLINE', 'CARD', 'UPI'];

class CartScreen extends StatefulWidget {
  final VoidCallback? onCartChanged;

  const CartScreen({super.key, this.onCartChanged});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final FoodService _service = FoodService();

  bool _loading = true;
  String? _error;
  Cart? _cart;
  Restaurant? _restaurant;
  List<DeliveryAddress> _addresses = [];
  String? _addressId;
  String _payment = 'CASH';
  bool _placing = false;
  Order? _placedOrder;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cart = await _service.getCart();
      Restaurant? restaurant;
      if (cart.restaurantId != null) {
        try {
          restaurant = await _service.getRestaurant(cart.restaurantId!);
        } catch (_) {}
      }
      final addresses = await _service.listAddresses();
      if (!mounted) return;
      setState(() {
        _cart = cart;
        _restaurant = restaurant;
        _addresses = addresses;
        if (_addressId == null && addresses.isNotEmpty) {
          _addressId = addresses.first.id;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppDialogs.friendlyError(e);
        _loading = false;
      });
    }
  }

  Future<void> _changeQuantity(CartItem item, int delta) async {
    final next = item.quantity + delta;
    if (next < 0) return;
    try {
      final Cart updated;
      if (next == 0) {
        updated = await _service.removeCartItem(item.foodItemId);
      } else {
        updated = await _service.updateCartItem(item.foodItemId, next);
      }
      if (!mounted) return;
      setState(() => _cart = updated);
      widget.onCartChanged?.call();
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  Future<void> _removeItem(CartItem item) async {
    try {
      final updated = await _service.removeCartItem(item.foodItemId);
      if (!mounted) return;
      setState(() => _cart = updated);
      widget.onCartChanged?.call();
      AppDialogs.showSnack(context, '${item.foodItem.name} removed');
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  Future<void> _addNewAddress() async {
    final address = await showAddressDialog(context);
    if (address == null || !mounted) return;
    try {
      final created = await _service.addAddress(
        label: address.label,
        fullName: address.fullName,
        phone: address.phone,
        addressLine: address.addressLine,
        city: address.city,
        state: address.state,
        postalCode: address.postalCode,
      );
      if (!mounted) return;
      setState(() {
        _addresses = [..._addresses, created];
        _addressId = created.id;
      });
      AppDialogs.showSnack(context, 'Address saved');
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  Future<void> _placeOrder() async {
    final cart = _cart;
    final addressId = _addressId;
    if (cart == null || cart.items.isEmpty) {
      AppDialogs.showSnack(context, 'Your cart is empty', error: true);
      return;
    }
    if (addressId == null) {
      AppDialogs.showSnack(context, 'Please add a delivery address',
          error: true);
      return;
    }
    setState(() => _placing = true);
    try {
      final order = await _service.placeOrder(
        restaurantId: cart.restaurantId ?? '',
        items: [
          for (final item in cart.items)
            {'food_item_id': item.foodItemId, 'quantity': item.quantity},
        ],
        addressId: addressId,
        paymentMethod: _payment,
      );
      if (!mounted) return;
      setState(() {
        _placing = false;
        _placedOrder = order;
        _cart = const Cart();
      });
      widget.onCartChanged?.call();
      AppDialogs.showSnack(context, 'Order placed successfully');
    } catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _placedOrder;
    return Column(
      children: [
        PageHeader(title: 'Your Cart', subtitle: _cartSummary),
        Expanded(
          child: order != null
              ? _OrderSuccessView(
                  order: order,
                  onViewOrders: () => FeatureNavigator.of(context)
                      .pushReplacement(const OrdersScreen()),
                  onBackHome: () => FeatureNavigator.of(context).pop(),
                )
              : _loading
                  ? const LoadingWidget(message: 'Loading cart…')
                  : _error != null
                      ? ErrorWidgetView(message: _error!, onRetry: _load)
                      : _cart == null || _cart!.items.isEmpty
                          ? EmptyState(
                              icon: Icons.shopping_bag_rounded,
                              title: 'Your cart is empty',
                              subtitle:
                                  'Add items from a restaurant menu to get started',
                              action: OutlinedButton.icon(
                                onPressed: () =>
                                    FeatureNavigator.of(context).pop(),
                                icon: const Icon(Icons.restaurant_rounded,
                                    size: 18),
                                label: const Text('Browse restaurants'),
                              ),
                            )
                          : _buildContent(),
        ),
      ],
    );
  }

  String? get _cartSummary {
    final cart = _cart;
    if (cart == null) return null;
    return cart.items.isEmpty
        ? null
        : '${cart.items.length} item${cart.items.length == 1 ? '' : 's'} • ${Formatters.currency(cart.total, exact: true)}';
  }

  Widget _buildContent() {
    final cart = _cart!;
    final restaurant = _restaurant;
    final deliveryFee = restaurant?.deliveryFee ?? 0;
    final total = cart.total + deliveryFee;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final item in cart.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AnimatedCard(
              accentColor: ExperimentPalette.food,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.foodItem.name,
                          style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${Formatters.currency(item.foodItem.price, exact: true)} each',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          Formatters.currency(item.subtotal, exact: true),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: ExperimentPalette.food),
                        ),
                      ],
                    ),
                  ),
                  _CartStepper(
                    quantity: item.quantity,
                    onDecrement: () => _changeQuantity(item, -1),
                    onIncrement: () => _changeQuantity(item, 1),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => _removeItem(item),
                    icon: const Icon(Icons.delete_outline_rounded),
                    color: AppColors.danger,
                    tooltip: 'Remove item',
                  ),
                ],
              ),
            ),
          ),
        if (restaurant != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE6E8F0)),
            ),
            child: Column(
              children: [
                _SummaryRow(
                    label: 'Subtotal',
                    value: Formatters.currency(cart.total, exact: true)),
                const SizedBox(height: 8),
                _SummaryRow(
                    label: 'Delivery fee',
                    value: Formatters.currency(deliveryFee, exact: true)),
                const Divider(height: 22),
                _SummaryRow(
                    label: 'Total',
                    value: Formatters.currency(total, exact: true),
                    bold: true),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE6E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Deliver to',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              const SizedBox(height: 8),
              if (_addresses.isEmpty)
                Row(
                  children: [
                    const Expanded(
                      child: Text('No saved addresses yet',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textMuted)),
                    ),
                    TextButton.icon(
                      onPressed: _addNewAddress,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add address'),
                    ),
                  ],
                )
              else ...[
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _addressId,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(12),
                    items: [
                      for (final address in _addresses)
                        DropdownMenuItem(
                          value: address.id,
                          child: Text(
                            '${address.label} • ${address.summary}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textDark),
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _addressId = value);
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _addNewAddress,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add new address'),
                  ),
                ),
              ],
              const Divider(height: 16),
              const Text('Payment method',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              const SizedBox(height: 4),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _payment,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(12),
                  items: [
                    for (final option in _paymentOptions)
                      DropdownMenuItem(
                        value: option,
                        child: Text(
                          Formatters.enumLabel(option),
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textDark),
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _payment = value);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: ExperimentPalette.food,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _placing || _addresses.isEmpty ? null : _placeOrder,
          child: _placing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.2, color: Colors.white),
                )
              : Text('Place Order • ${Formatters.currency(total, exact: true)}'),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _SummaryRow(
      {required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: bold ? AppColors.textDark : Colors.grey.shade600,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: bold ? 15 : 13.5,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: bold ? AppColors.textDark : AppColors.textDark)),
      ],
    );
  }
}

class _CartStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _CartStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ExperimentPalette.food.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onDecrement,
            icon: const Icon(Icons.remove_rounded),
            iconSize: 17,
            color: ExperimentPalette.food,
            tooltip: 'Decrease quantity',
          ),
          Text('$quantity',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
          IconButton(
            onPressed: onIncrement,
            icon: const Icon(Icons.add_rounded),
            iconSize: 17,
            color: ExperimentPalette.food,
            tooltip: 'Increase quantity',
          ),
        ],
      ),
    );
  }
}

class _OrderSuccessView extends StatelessWidget {
  final Order order;
  final VoidCallback onViewOrders;
  final VoidCallback onBackHome;

  const _OrderSuccessView({
    required this.order,
    required this.onViewOrders,
    required this.onBackHome,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: ExperimentPalette.food.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                size: 46, color: ExperimentPalette.food),
          ),
          const SizedBox(height: 18),
          const Text('Order placed!',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
          const SizedBox(height: 6),
          Text(
            'Order ID: ${order.id}',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            '${order.restaurantName} • ${Formatters.currency(order.total, exact: true)}',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ExperimentPalette.food),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: ExperimentPalette.food,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: onViewOrders,
              icon: const Icon(Icons.receipt_long_rounded, size: 19),
              label: const Text('View My Orders'),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onBackHome,
            icon: const Icon(Icons.home_rounded, size: 18),
            label: const Text('Back to restaurants'),
          ),
        ],
      ),
    );
  }
}
