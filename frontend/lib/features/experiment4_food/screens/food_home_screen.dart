import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../services/session.dart';
import '../../../widgets/animated_card.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_widget.dart';
import '../../../widgets/feature_navigator.dart';
import '../../../widgets/loading_widget.dart';
import '../models/restaurant.dart';
import '../services/food_service.dart';
import 'addresses_screen.dart';
import 'admin_food_view.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';
import 'restaurant_detail_screen.dart';

class FoodHomeScreen extends StatefulWidget {
  const FoodHomeScreen({super.key});

  @override
  State<FoodHomeScreen> createState() => _FoodHomeScreenState();
}

class _FoodHomeScreenState extends State<FoodHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return const FeatureNavigator(home: _FoodHomeContent());
  }
}

class _FoodHomeContent extends StatefulWidget {
  const _FoodHomeContent();

  @override
  State<_FoodHomeContent> createState() => _FoodHomeContentState();
}

class _FoodHomeContentState extends State<_FoodHomeContent> {
  final FoodService _service = FoodService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  String? _error;
  List<Restaurant> _restaurants = [];
  final List<String> _cuisines = [];
  String? _cuisine;
  String _sort = 'rating';
  String? _search;
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _loadCartCount();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCartCount() async {
    try {
      final cart = await _service.getCart();
      if (!mounted) return;
      setState(() => _cartCount = cart.totalQuantity);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final serverSort =
          (_sort == 'price' || _sort == 'delivery') ? 'rating' : _sort;
      var list = await _service.listRestaurants(
        search: _search,
        cuisine: _cuisine,
        sort: serverSort,
      );
      if (_sort == 'price') {
        list = [...list]..sort((a, b) => a.deliveryFee.compareTo(b.deliveryFee));
      } else if (_sort == 'delivery') {
        list = [...list]
          ..sort((a, b) => a.deliveryEstimate.compareTo(b.deliveryEstimate));
      }
      if (!mounted) return;
      setState(() {
        _restaurants = list;
        for (final r in list) {
          if (r.cuisine.isNotEmpty && !_cuisines.contains(r.cuisine)) {
            _cuisines.add(r.cuisine);
          }
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

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search = value.trim().isEmpty ? null : value.trim();
      _load();
    });
  }

  void _openRestaurant(Restaurant restaurant) {
    FeatureNavigator.of(context).push(RestaurantDetailScreen(
      restaurant: restaurant,
      onCartChanged: _loadCartCount,
    ));
  }

  void _openCart() {
    FeatureNavigator.of(context)
        .push(CartScreen(onCartChanged: _loadCartCount));
  }

  void _openOrders() {
    FeatureNavigator.of(context).push(const OrdersScreen());
  }

  void _openAddresses() {
    FeatureNavigator.of(context).push(const AddressesScreen());
  }

  void _openAdmin() {
    FeatureNavigator.of(context).push(const AdminFoodView());
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final user = session.user;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: ExperimentPalette.food.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.restaurant_rounded,
                    color: ExperimentPalette.food, size: 26),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hungry? Order in.',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                    Text('Fresh meals from restaurants near you',
                        style:
                            TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeaderButton(
                icon: Icons.shopping_bag_rounded,
                label: 'Cart',
                badge: _cartCount,
                onTap: _openCart,
              ),
              _HeaderButton(
                icon: Icons.receipt_long_rounded,
                label: 'My Orders',
                onTap: _openOrders,
              ),
              _HeaderButton(
                icon: Icons.location_on_rounded,
                label: 'Addresses',
                onTap: _openAddresses,
              ),
              if (user != null && user.isAdmin)
                _HeaderButton(
                  icon: Icons.admin_panel_settings_rounded,
                  label: 'Admin Mode',
                  onTap: _openAdmin,
                ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search restaurants, cuisines or cities…',
              prefixIcon:
                  const Icon(Icons.search_rounded, color: ExperimentPalette.food),
              suffixIcon: ListenableBuilder(
                listenable: _searchController,
                builder: (context, _) => _searchController.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _search = null;
                          _load();
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CuisineChip(
                  label: 'All',
                  selected: _cuisine == null,
                  onTap: () {
                    setState(() => _cuisine = null);
                    _load();
                  },
                ),
                for (final cuisine in _cuisines)
                  _CuisineChip(
                    label: cuisine,
                    selected: _cuisine == cuisine,
                    onTap: () {
                      setState(() => _cuisine = cuisine);
                      _load();
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Sort by:',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sort,
                  borderRadius: BorderRadius.circular(12),
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark),
                  items: const [
                    DropdownMenuItem(value: 'rating', child: Text('Top rated')),
                    DropdownMenuItem(value: 'name', child: Text('Name (A–Z)')),
                    DropdownMenuItem(
                        value: 'price', child: Text('Lowest delivery fee')),
                    DropdownMenuItem(
                        value: 'delivery', child: Text('Fastest delivery')),
                  ],
                  onChanged: (value) {
                    if (value == null || value == _sort) return;
                    setState(() => _sort = value);
                    _load();
                  },
                ),
              ),
              const Spacer(),
              Text(
                '${_restaurants.length} restaurant${_restaurants.length == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: LoadingWidget(message: 'Finding restaurants…'),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: ErrorWidgetView(message: _error!, onRetry: _load),
            )
          else if (_restaurants.isEmpty)
            EmptyState(
              icon: Icons.restaurant_menu_rounded,
              title: 'No restaurants found',
              subtitle: 'Try a different search or clear the cuisine filter',
              action: OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _search = null;
                  _cuisine = null;
                  _load();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reset filters'),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = width > 1200
                    ? 4
                    : width > 900
                        ? 3
                        : width > 620
                            ? 2
                            : 1;
                final cardWidth = (width - (columns - 1) * 14) / columns;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    for (final restaurant in _restaurants)
                      SizedBox(
                        width: cardWidth,
                        child: _RestaurantCard(
                          restaurant: restaurant,
                          onTap: () => _openRestaurant(restaurant),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? badge;

  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ExperimentPalette.food.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: ExperimentPalette.food),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ExperimentPalette.food)),
              if (badge != null && badge! > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: ExperimentPalette.food,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$badge',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CuisineChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CuisineChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected
            ? ExperimentPalette.food
            : Colors.white.withValues(alpha: 0.9),
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
                    : const Color(0xFFE2E8F0),
              ),
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

class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;

  const _RestaurantCard({required this.restaurant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      accentColor: ExperimentPalette.food,
      padding: EdgeInsets.zero,
      radius: const BorderRadius.all(Radius.circular(16)),
      hoverElevation: 10,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RestaurantBanner(restaurant: restaurant),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        restaurant.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: ExperimentPalette.food.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: ExperimentPalette.food),
                          const SizedBox(width: 3),
                          Text(
                            restaurant.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: ExperimentPalette.food),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${restaurant.cuisine} • ${restaurant.city}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.delivery_dining_rounded,
                        size: 15, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${Formatters.currency(restaurant.deliveryFee, exact: true)} • ${restaurant.deliveryEstimate} min',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantBanner extends StatelessWidget {
  final Restaurant restaurant;

  const _RestaurantBanner({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: SizedBox(
        height: 110,
        width: double.infinity,
        child: restaurant.imageUrl.isNotEmpty
            ? Image.network(
                restaurant.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _BannerPlaceholder(),
              )
            : const _BannerPlaceholder(),
      ),
    );
  }
}

class _BannerPlaceholder extends StatelessWidget {
  const _BannerPlaceholder();

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
      child: const Icon(Icons.restaurant_rounded, size: 44, color: Colors.white),
    );
  }
}
