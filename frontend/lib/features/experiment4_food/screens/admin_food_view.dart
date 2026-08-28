import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../services/session.dart';
import '../../../widgets/animated_card.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_widget.dart';
import '../../../widgets/loading_widget.dart';
import '../models/food_item.dart';
import '../models/restaurant.dart';
import '../services/food_service.dart';
import '../widgets/page_header.dart';

class AdminFoodView extends StatefulWidget {
  const AdminFoodView({super.key});

  @override
  State<AdminFoodView> createState() => _AdminFoodViewState();
}

class _AdminFoodViewState extends State<AdminFoodView> {
  final FoodService _service = FoodService();
  int _tabIndex = 0;

  bool _loading = true;
  String? _error;
  List<Restaurant> _restaurants = [];
  List<FoodItem> _foodItems = [];
  String? _selectedRestaurantId;

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
      final restaurants = await _service.listRestaurants();
      var selected = _selectedRestaurantId;
      if (selected == null ||
          !restaurants.any((r) => r.id == selected)) {
        selected = restaurants.isNotEmpty ? restaurants.first.id : null;
      }
      final List<FoodItem> items;
      if (selected != null) {
        final menu = await _service.getMenu(selected);
        items = menu.items;
      } else {
        items = const [];
      }
      if (!mounted) return;
      setState(() {
        _restaurants = restaurants;
        _foodItems = items;
        _selectedRestaurantId = selected;
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

  Future<void> _loadFood() async {
    final selected = _selectedRestaurantId;
    if (selected == null) return;
    try {
      final menu = await _service.getMenu(selected);
      if (!mounted) return;
      setState(() => _foodItems = menu.items);
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  void _manageMenu(Restaurant restaurant) {
    setState(() {
      _selectedRestaurantId = restaurant.id;
      _foodItems = [];
    });
    _loadFood();
    setState(() => _tabIndex = 1);
  }

  void _selectRestaurant(String? id) {
    if (id == null) return;
    setState(() {
      _selectedRestaurantId = id;
      _foodItems = [];
    });
    _loadFood();
  }

  Future<void> _addRestaurant() async {
    final data = await _restaurantForm(context, existing: null);
    if (data == null || !mounted) return;
    try {
      await _service.createRestaurant(
        name: data['name']!,
        cuisine: data['cuisine']!,
        city: data['city']!,
        address: data['address']!,
        phone: data['phone']!,
        description: data['description']!,
        imageUrl: data['imageUrl']!,
        deliveryEstimate: data['deliveryEstimate'] as int,
        deliveryFee: data['deliveryFee'] as double,
      );
      if (!mounted) return;
      AppDialogs.showSnack(context, 'Restaurant created');
      _load();
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  Future<void> _editRestaurant(Restaurant restaurant) async {
    final data = await _restaurantForm(context, existing: restaurant);
    if (data == null || !mounted) return;
    try {
      await _service.updateRestaurant(
        restaurant.id,
        name: data['name']!,
        cuisine: data['cuisine']!,
        city: data['city']!,
        address: data['address']!,
        phone: data['phone']!,
        description: data['description']!,
        imageUrl: data['imageUrl']!,
        deliveryEstimate: data['deliveryEstimate'] as int,
        deliveryFee: data['deliveryFee'] as double,
      );
      if (!mounted) return;
      AppDialogs.showSnack(context, 'Restaurant updated');
      _load();
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  Future<void> _deleteRestaurant(Restaurant restaurant) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete restaurant?',
      message:
          'Delete "${restaurant.name}" and its menu? This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !mounted) return;
    try {
      await _service.deleteRestaurant(restaurant.id);
      if (!mounted) return;
      AppDialogs.showSnack(context, 'Restaurant deleted');
      _load();
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  Future<void> _addFoodItem() async {
    final selected = _selectedRestaurantId;
    if (selected == null) {
      AppDialogs.showSnack(context, 'Select a restaurant first', error: true);
      return;
    }
    final data = await _foodItemForm(context, restaurants: _restaurants,
        initialRestaurantId: selected, existing: null);
    if (data == null || !mounted) return;
    try {
      await _service.createFoodItem(
        restaurantId: data['restaurantId']!,
        name: data['name']!,
        description: data['description']!,
        price: data['price'] as double,
        category: data['category']!,
        imageUrl: data['imageUrl']!,
        isVegetarian: data['isVegetarian'] as bool,
        isAvailable: data['isAvailable'] as bool,
      );
      if (!mounted) return;
      AppDialogs.showSnack(context, 'Food item created');
      if (data['restaurantId'] != selected) {
        setState(() => _selectedRestaurantId = data['restaurantId']);
      }
      _loadFood();
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  Future<void> _editFoodItem(FoodItem item) async {
    final data = await _foodItemForm(
        context, restaurants: _restaurants,
        initialRestaurantId: item.restaurantId, existing: item);
    if (data == null || !mounted) return;
    try {
      await _service.updateFoodItem(
        item.id,
        restaurantId: data['restaurantId']!,
        name: data['name']!,
        description: data['description']!,
        price: data['price'] as double,
        category: data['category']!,
        imageUrl: data['imageUrl']!,
        isVegetarian: data['isVegetarian'] as bool,
        isAvailable: data['isAvailable'] as bool,
      );
      if (!mounted) return;
      AppDialogs.showSnack(context, 'Food item updated');
      if (data['restaurantId'] != item.restaurantId) {
        setState(() => _selectedRestaurantId = data['restaurantId']);
      }
      _loadFood();
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  Future<void> _deleteFoodItem(FoodItem item) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete food item?',
      message: 'Delete "${item.name}" from the menu? This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !mounted) return;
    try {
      await _service.deleteFoodItem(item.id);
      if (!mounted) return;
      AppDialogs.showSnack(context, 'Food item deleted');
      _loadFood();
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  Future<void> _toggleAvailability(FoodItem item, bool available) async {
    try {
      await _service.updateFoodItem(
        item.id,
        restaurantId: item.restaurantId,
        name: item.name,
        description: item.description,
        price: item.price,
        category: item.category,
        imageUrl: item.imageUrl,
        isVegetarian: item.isVegetarian,
        isAvailable: available,
      );
      if (!mounted) return;
      AppDialogs.showSnack(
          context, available ? 'Item marked available' : 'Item marked unavailable');
      _loadFood();
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<Session>().user;
    if (user == null || !user.isAdmin) {
      return const EmptyState(
        icon: Icons.admin_panel_settings_outlined,
        title: 'Admin access required',
        subtitle:
            'Sign in with an admin account to manage restaurants and menus',
      );
    }
    return Column(
        children: [
          const PageHeader(title: 'Admin • Food Delivery'),
          Material(
            color: Colors.white,
            child: TabBar(
              labelColor: ExperimentPalette.food,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: ExperimentPalette.food,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Restaurants', height: 48),
                Tab(text: 'Menu', height: 48),
              ],
              onTap: (i) => setState(() => _tabIndex = i),
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingWidget(message: 'Loading admin data…')
                : _error != null
                    ? ErrorWidgetView(message: _error!, onRetry: _load)
                    : IndexedStack(
                        index: _tabIndex,
                        children: [
                          _buildRestaurantsTab(),
                          _buildMenuTab(),
                        ],
                      ),
          ),
        ],
    );
  }

  Widget _buildRestaurantsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: ExperimentPalette.food),
            onPressed: _addRestaurant,
            icon: const Icon(Icons.add_rounded, size: 19),
            label: const Text('Add Restaurant'),
          ),
        ),
        const SizedBox(height: 14),
        if (_restaurants.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: EmptyState(
                icon: Icons.restaurant_rounded,
                title: 'No restaurants yet',
                subtitle: 'Add your first restaurant to get started'),
          )
        else
          for (final restaurant in _restaurants)
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
                            restaurant.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${restaurant.cuisine} • ${restaurant.city}',
                            style: TextStyle(
                                fontSize: 12.5, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 15, color: ExperimentPalette.food),
                              const SizedBox(width: 3),
                              Text(
                                '${restaurant.rating.toStringAsFixed(1)} (${restaurant.ratingCount})',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: ExperimentPalette.food),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ExperimentPalette.food,
                        side: BorderSide(
                            color: ExperimentPalette.food.withValues(alpha: 0.6)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                      onPressed: () => _manageMenu(restaurant),
                      child: const Text('Menu'),
                    ),
                    IconButton(
                      onPressed: () => _editRestaurant(restaurant),
                      icon: const Icon(Icons.edit_outlined),
                      color: AppColors.textDark,
                      tooltip: 'Edit restaurant',
                    ),
                    IconButton(
                      onPressed: () => _deleteRestaurant(restaurant),
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: AppColors.danger,
                      tooltip: 'Delete restaurant',
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildMenuTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(_selectedRestaurantId),
          initialValue: _selectedRestaurantId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Restaurant'),
          items: [
            for (final restaurant in _restaurants)
              DropdownMenuItem(
                value: restaurant.id,
                child: Text(restaurant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13.5, color: AppColors.textDark)),
              ),
          ],
          onChanged: _selectRestaurant,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: ExperimentPalette.food),
            onPressed: _selectedRestaurantId == null ? null : _addFoodItem,
            icon: const Icon(Icons.add_rounded, size: 19),
            label: const Text('Add Food Item'),
          ),
        ),
        const SizedBox(height: 14),
        if (_selectedRestaurantId == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: EmptyState(
                icon: Icons.restaurant_menu_rounded,
                title: 'Select a restaurant',
                subtitle: 'Pick a restaurant above to view its menu'),
          )
        else if (_foodItems.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: EmptyState(
                icon: Icons.no_food_rounded,
                title: 'No items in this menu',
                subtitle: 'Add food items to this restaurant'),
          )
        else
          for (final item in _foodItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AnimatedCard(
                accentColor: ExperimentPalette.food,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    _AdminVegDot(isVegetarian: item.isVegetarian),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: item.isAvailable
                                    ? AppColors.textDark
                                    : Colors.grey.shade400),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.category,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.currency(item.price, exact: true),
                            style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: ExperimentPalette.food),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Available',
                            style: TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textMuted)),
                        Switch(
                          value: item.isAvailable,
                          activeTrackColor: ExperimentPalette.food,
                          onChanged: (value) =>
                              _toggleAvailability(item, value),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => _editFoodItem(item),
                      icon: const Icon(Icons.edit_outlined),
                      color: AppColors.textDark,
                      tooltip: 'Edit item',
                    ),
                    IconButton(
                      onPressed: () => _deleteFoodItem(item),
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: AppColors.danger,
                      tooltip: 'Delete item',
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _AdminVegDot extends StatelessWidget {
  final bool isVegetarian;

  const _AdminVegDot({required this.isVegetarian});

  @override
  Widget build(BuildContext context) {
    final color =
        isVegetarian ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return Container(
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
    );
  }
}

Future<Map<String, dynamic>?> _restaurantForm(
  BuildContext context, {
  required Restaurant? existing,
}) async {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController(text: existing?.name ?? '');
  final cuisine = TextEditingController(text: existing?.cuisine ?? '');
  final city = TextEditingController(text: existing?.city ?? '');
  final address = TextEditingController(text: existing?.address ?? '');
  final phone = TextEditingController(text: existing?.phone ?? '');
  final description = TextEditingController(text: existing?.description ?? '');
  final imageUrl = TextEditingController(text: existing?.imageUrl ?? '');
  final estimate = TextEditingController(
      text: existing?.deliveryEstimate.toString() ?? '30');
  final fee = TextEditingController(
      text: existing != null
          ? (existing.deliveryFee == existing.deliveryFee.roundToDouble()
              ? existing.deliveryFee.toInt().toString()
              : existing.deliveryFee.toString())
          : '0');

  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(existing == null ? 'Add restaurant' : 'Edit restaurant',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => Validators.required(v, 'Name'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: cuisine,
                      decoration: const InputDecoration(labelText: 'Cuisine'),
                      validator: (v) => Validators.required(v, 'Cuisine'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: city,
                      decoration: const InputDecoration(labelText: 'City'),
                      validator: (v) => Validators.required(v, 'City'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: address,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: (v) => Validators.required(v, 'Address'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        return Validators.phone(v);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: estimate,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Delivery estimate (min)'),
                      validator: (v) => Validators.positiveNumber(v, 'Estimate'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: fee,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Delivery fee (₹)'),
                validator: (v) => Validators.positiveNumber(v, 'Delivery fee'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: imageUrl,
                keyboardType: TextInputType.url,
                decoration:
                    const InputDecoration(labelText: 'Image URL (optional)'),
                validator: (v) => Validators.url(v, 'Image URL'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: description,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'Description (optional)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: ExperimentPalette.food),
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(context, true);
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );

  final controllers = [
    name, cuisine, city, address, phone, description, imageUrl, estimate, fee,
  ];
  final result = saved == true
      ? {
          'name': name.text.trim(),
          'cuisine': cuisine.text.trim(),
          'city': city.text.trim(),
          'address': address.text.trim(),
          'phone': phone.text.trim(),
          'description': description.text.trim(),
          'imageUrl': imageUrl.text.trim(),
          'deliveryEstimate': int.tryParse(estimate.text.trim()) ?? 30,
          'deliveryFee': double.tryParse(fee.text.trim()) ?? 0,
        }
      : null;
  for (final c in controllers) {
    c.dispose();
  }
  return result;
}

Future<Map<String, dynamic>?> _foodItemForm(
  BuildContext context, {
  required List<Restaurant> restaurants,
  required String initialRestaurantId,
  required FoodItem? existing,
}) async {
  final formKey = GlobalKey<FormState>();
  var restaurantId = existing?.restaurantId ?? initialRestaurantId;
  final name = TextEditingController(text: existing?.name ?? '');
  final description = TextEditingController(text: existing?.description ?? '');
  final price = TextEditingController(
      text: existing != null
          ? (existing.price == existing.price.roundToDouble()
              ? existing.price.toInt().toString()
              : existing.price.toString())
          : '');
  final category = TextEditingController(text: existing?.category ?? '');
  final imageUrl = TextEditingController(text: existing?.imageUrl ?? '');
  var isVegetarian = existing?.isVegetarian ?? false;
  var isAvailable = existing?.isAvailable ?? true;

  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'Add food item' : 'Edit food item',
            style:
                const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: restaurantId,
                  isExpanded: true,
                  decoration:
                      const InputDecoration(labelText: 'Restaurant'),
                  items: [
                    for (final restaurant in restaurants)
                      DropdownMenuItem(
                        value: restaurant.id,
                        child: Text(restaurant.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13.5, color: AppColors.textDark)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) restaurantId = value;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => Validators.required(v, 'Name'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: price,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration:
                            const InputDecoration(labelText: 'Price (₹)'),
                        validator: (v) {
                          final base = Validators.positiveNumber(v, 'Price');
                          if (base != null) return base;
                          final parsed = double.tryParse(v!.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Price must be greater than zero';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: category,
                        decoration:
                            const InputDecoration(labelText: 'Category'),
                        validator: (v) => Validators.required(v, 'Category'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: imageUrl,
                  keyboardType: TextInputType.url,
                  decoration:
                      const InputDecoration(labelText: 'Image URL (optional)'),
                  validator: (v) => Validators.url(v, 'Image URL'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: description,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'Description (optional)'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Vegetarian',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  value: isVegetarian,
                  activeTrackColor: const Color(0xFF16A34A),
                  onChanged: (value) =>
                      setDialogState(() => isVegetarian = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Available',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  value: isAvailable,
                  activeTrackColor: ExperimentPalette.food,
                  onChanged: (value) =>
                      setDialogState(() => isAvailable = value),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: ExperimentPalette.food),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );

  final controllers = [name, description, price, category, imageUrl];
  final result = saved == true
      ? {
          'restaurantId': restaurantId,
          'name': name.text.trim(),
          'description': description.text.trim(),
          'price': double.tryParse(price.text.trim()) ?? 0,
          'category': category.text.trim(),
          'imageUrl': imageUrl.text.trim(),
          'isVegetarian': isVegetarian,
          'isAvailable': isAvailable,
        }
      : null;
  for (final c in controllers) {
    c.dispose();
  }
  return result;
}
