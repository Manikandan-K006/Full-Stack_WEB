import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_widget.dart';
import '../../../widgets/loading_widget.dart';
import '../models/cart.dart';
import '../models/food_item.dart';
import '../models/restaurant.dart';
import '../services/food_service.dart';
import '../widgets/page_header.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Restaurant restaurant;
  final VoidCallback? onCartChanged;

  const RestaurantDetailScreen({
    super.key,
    required this.restaurant,
    this.onCartChanged,
  });

  @override
  State<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final FoodService _service = FoodService();

  bool _loading = true;
  String? _error;
  RestaurantMenu? _menu;
  Cart? _cart;
  String _category = 'All';
  String _vegFilter = 'all';

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
      final results = await Future.wait<Object>([
        _service.getMenu(widget.restaurant.id),
        _service.getCart(),
      ]);
      if (!mounted) return;
      setState(() {
        _menu = results[0] as RestaurantMenu;
        _cart = results[1] as Cart;
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

  int _quantityOf(String foodItemId) {
    final cart = _cart;
    if (cart == null) return 0;
    for (final item in cart.items) {
      if (item.foodItemId == foodItemId) return item.quantity;
    }
    return 0;
  }

  List<String> get _categories {
    final menu = _menu;
    if (menu == null) return const [];
    final set = <String>{for (final item in menu.items) item.category};
    return set.toList()..sort();
  }

  List<FoodItem> get _filteredItems {
    final menu = _menu;
    if (menu == null) return const [];
    return menu.items.where((item) {
      if (_category != 'All' && item.category != _category) return false;
      if (_vegFilter == 'veg' && !item.isVegetarian) return false;
      if (_vegFilter == 'nonVeg' && item.isVegetarian) return false;
      return true;
    }).toList();
  }

  Future<void> _addToCart(FoodItem item) async {
    final cart = _cart;
    if (cart != null &&
        cart.restaurantId != null &&
        cart.restaurantId != widget.restaurant.id &&
        cart.items.isNotEmpty) {
      final replace = await ConfirmDialog.show(
        context,
        title: 'Replace cart?',
        message:
            'Your cart has items from another restaurant. Adding "${item.name}" will replace your current cart.',
        confirmLabel: 'Replace cart',
      );
      if (!replace || !mounted) return;
    }
    try {
      final updated = await _service.addToCart(
        restaurantId: widget.restaurant.id,
        foodItemId: item.id,
      );
      if (!mounted) return;
      setState(() => _cart = updated);
      widget.onCartChanged?.call();
      AppDialogs.showSnack(context, '${item.name} added to cart');
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  Future<void> _changeQuantity(FoodItem item, int delta) async {
    final current = _quantityOf(item.id);
    final next = current + delta;
    if (next < 0) return;
    try {
      final Cart updated;
      if (next == 0) {
        updated = await _service.removeCartItem(item.id);
      } else {
        updated = await _service.updateCartItem(item.id, next);
      }
      if (!mounted) return;
      setState(() => _cart = updated);
      widget.onCartChanged?.call();
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;
    return Column(
      children: [
        PageHeader(
          title: restaurant.name,
          subtitle: '${restaurant.cuisine} • ${restaurant.city}',
        ),
        Expanded(
          child: _loading
              ? const LoadingWidget(message: 'Loading menu…')
              : _error != null
                  ? ErrorWidgetView(message: _error!, onRetry: _load)
                  : _menu == null
                      ? const EmptyState(
                          icon: Icons.restaurant_menu_rounded,
                          title: 'Menu unavailable')
                      : _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final restaurant = widget.restaurant;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: restaurant.imageUrl.isNotEmpty
                  ? Image.network(
                      restaurant.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _DetailBanner(),
                    )
                  : const _DetailBanner(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  restaurant.name,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: ExperimentPalette.food.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 16, color: ExperimentPalette.food),
                    const SizedBox(width: 3),
                    Text(
                      '${restaurant.rating.toStringAsFixed(1)} (${restaurant.ratingCount})',
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: ExperimentPalette.food),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(
                  icon: Icons.location_on_rounded, text: restaurant.city),
              _InfoPill(
                  icon: Icons.schedule_rounded,
                  text: '${restaurant.deliveryEstimate} min'),
              _InfoPill(
                  icon: Icons.delivery_dining_rounded,
                  text: Formatters.currency(restaurant.deliveryFee, exact: true)),
              if (restaurant.phone.isNotEmpty)
                _InfoPill(icon: Icons.phone_rounded, text: restaurant.phone),
            ],
          ),
          if (restaurant.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              restaurant.description,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _category == 'All',
                  onTap: () => setState(() => _category = 'All'),
                ),
                for (final category in _categories)
                  _FilterChip(
                    label: category,
                    selected: _category == category,
                    onTap: () => setState(() => _category = category),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _VegFilterChip(
                label: 'All',
                selected: _vegFilter == 'all',
                onTap: () => setState(() => _vegFilter = 'all'),
              ),
              const SizedBox(width: 8),
              _VegFilterChip(
                label: 'Veg',
                selected: _vegFilter == 'veg',
                onTap: () => setState(() => _vegFilter = 'veg'),
              ),
              const SizedBox(width: 8),
              _VegFilterChip(
                label: 'Non-Veg',
                selected: _vegFilter == 'nonVeg',
                onTap: () => setState(() => _vegFilter = 'nonVeg'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_filteredItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: EmptyState(
                  icon: Icons.no_food_rounded,
                  title: 'No items match',
                  subtitle: 'Try a different filter'),
            )
          else
            for (final item in _filteredItems)
              _MenuItemRow(
                item: item,
                quantity: _quantityOf(item.id),
                onAdd: () => _addToCart(item),
                onQuantityChanged: (delta) => _changeQuantity(item, delta),
              ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _DetailBanner extends StatelessWidget {
  const _DetailBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFED7AA), Color(0xFFF97316)],
        ),
      ),
      child: const Icon(Icons.restaurant_rounded, size: 60, color: Colors.white),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ExperimentPalette.food),
          const SizedBox(width: 5),
          Text(text,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color:
            selected ? ExperimentPalette.food : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: selected
                      ? ExperimentPalette.food
                      : const Color(0xFFE2E8F0)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VegFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _VegFilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textMuted)),
      selected: selected,
      showCheckmark: false,
      selectedColor: ExperimentPalette.food,
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE2E8F0)),
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
      visualDensity: VisualDensity.compact,
      onSelected: (_) => onTap(),
    );
  }
}

class _MenuItemRow extends StatelessWidget {
  final FoodItem item;
  final int quantity;
  final VoidCallback onAdd;
  final ValueChanged<int> onQuantityChanged;

  const _MenuItemRow({
    required this.item,
    required this.quantity,
    required this.onAdd,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final unavailable = !item.isAvailable;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VegDot(isVegetarian: item.isVegetarian),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: unavailable ? Colors.grey.shade400 : AppColors.textDark),
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        color: unavailable ? Colors.grey.shade400 : Colors.grey.shade600),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  Formatters.currency(item.price, exact: true),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: unavailable ? Colors.grey.shade400 : ExperimentPalette.food),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (unavailable)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Unavailable',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted)),
            )
          else if (quantity == 0)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ExperimentPalette.food,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onAdd,
              child: const Text('Add'),
            )
          else
            _QtyStepper(
              quantity: quantity,
              onDecrement: () => onQuantityChanged(-1),
              onIncrement: () => onQuantityChanged(1),
            ),
        ],
      ),
    );
  }
}

class _VegDot extends StatelessWidget {
  final bool isVegetarian;

  const _VegDot({required this.isVegetarian});

  @override
  Widget build(BuildContext context) {
    final color = isVegetarian ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Container(
        width: 15,
        height: 15,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.6),
          borderRadius: BorderRadius.circular(3),
        ),
        padding: const EdgeInsets.all(2),
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QtyStepper({
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
            iconSize: 18,
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
            iconSize: 18,
            color: ExperimentPalette.food,
            tooltip: 'Increase quantity',
          ),
        ],
      ),
    );
  }
}
