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
import '../models/listing.dart';
import '../services/classified_service.dart';
import 'admin_moderation_view.dart';
import 'favorites_screen.dart';
import 'listing_detail_screen.dart';
import 'listing_form_dialog.dart';
import 'messages_screen.dart';
import 'my_listings_screen.dart';

class ClassifiedsHomeScreen extends StatefulWidget {
  const ClassifiedsHomeScreen({super.key});

  @override
  State<ClassifiedsHomeScreen> createState() => _ClassifiedsHomeScreenState();
}

class _ClassifiedsHomeScreenState extends State<ClassifiedsHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return const FeatureNavigator(home: _ClassifiedsBody(), backColor: ExperimentPalette.classifieds);
  }
}

class _ClassifiedsBody extends StatefulWidget {
  const _ClassifiedsBody();

  @override
  State<_ClassifiedsBody> createState() => _ClassifiedsBodyState();
}

class _ClassifiedsBodyState extends State<_ClassifiedsBody> {
  bool _loading = true;
  String? _error;
  List<Listing> _listings = const [];
  final Set<String> _favoriteIds = {};
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  String _category = 'ALL';
  String _condition = 'ALL';
  String _sortKey = 'created_at|desc';

  static const Map<String, String> _sortOptions = {
    'created_at|desc': 'Newest first',
    'price|asc': 'Price: Low to High',
    'price|desc': 'Price: High to Low',
    'title|asc': 'Title: A to Z',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final parts = _sortKey.split('|');
      final listings = await ClassifiedService.listListings(
        search: _searchController.text,
        category: _category,
        condition: _condition,
        minPrice: double.tryParse(_minPriceController.text),
        maxPrice: double.tryParse(_maxPriceController.text),
        sort: parts[0],
        direction: parts[1],
      );
      final favorites = await ClassifiedService.myFavorites();
      if (!mounted) return;
      setState(() {
        _listings = listings;
        _favoriteIds
          ..clear()
          ..addAll(favorites.map((f) => f.listing.id));
        _loading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppDialogs.friendlyError(e);
      });
    }
  }

  Future<void> _openCreate() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const ListingFormDialog(),
    );
    if (created == true) {
      if (!mounted) return;
      AppDialogs.showSnack(context, 'Listing created successfully');
      _load();
    }
  }

  Future<void> _toggleFavorite(Listing listing) async {
    try {
      final favorited = await ClassifiedService.toggleFavorite(listing.id);
      if (!mounted) return;
      setState(() {
        if (favorited) {
          _favoriteIds.add(listing.id);
        } else {
          _favoriteIds.remove(listing.id);
        }
      });
    } on Exception catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingWidget(message: 'Loading listings…');
    if (_error != null) {
      return ErrorWidgetView(message: _error!, onRetry: _load);
    }
    final width = MediaQuery.of(context).size.width;
    final columns = width > 1200 ? 3 : (width > 720 ? 2 : 1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 18),
          _buildFilters(context),
          const SizedBox(height: 14),
          _buildCategoryChips(),
          const SizedBox(height: 16),
          if (_listings.isEmpty)
            EmptyState(
              icon: Icons.storefront_rounded,
              title: 'No listings found',
              subtitle: 'Try different filters or be the first to sell something',
              action: FilledButton.icon(
                onPressed: _openCreate,
                style: FilledButton.styleFrom(backgroundColor: ExperimentPalette.classifieds),
                icon: const Icon(Icons.add),
                label: const Text('Sell an Item'),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth =
                    (constraints.maxWidth - (columns - 1) * 16) / columns;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final listing in _listings)
                      SizedBox(
                        width: cardWidth,
                        child: _ListingCard(
                          listing: listing,
                          favorited: _favoriteIds.contains(listing.id),
                          onTap: () => _openDetail(listing.id),
                          onToggleFavorite: () => _toggleFavorite(listing),
                        ),
                      ),
                  ],
                );
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isAdmin = context.watch<Session>().user?.isAdmin == true;
    final nav = FeatureNavigator.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Classifieds',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textDark),
        ),
        const SizedBox(height: 4),
        Text('Buy and sell used items in your city',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _openCreate,
              style: FilledButton.styleFrom(backgroundColor: ExperimentPalette.classifieds),
              icon: const Icon(Icons.add),
              label: const Text('Sell'),
            ),
            OutlinedButton.icon(
              onPressed: () => nav.push(MyListingsScreen(onChanged: _load)),
              icon: const Icon(Icons.list_alt_rounded),
              label: const Text('My Listings'),
            ),
            OutlinedButton.icon(
              onPressed: () => nav.push(FavoritesScreen(onChanged: _load)),
              icon: const Icon(Icons.favorite_border_rounded),
              label: const Text('Favorites'),
            ),
            OutlinedButton.icon(
              onPressed: () => nav.push(const MessagesScreen()),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Inbox'),
            ),
            if (isAdmin)
              OutlinedButton.icon(
                onPressed: () => nav.push(const AdminModerationView()),
                icon: const Icon(Icons.shield_outlined),
                label: const Text('Moderation'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _load(),
                  decoration: const InputDecoration(
                    isDense: true,
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                    hintText: 'Search listings…',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Search',
                style: IconButton.styleFrom(
                  backgroundColor: ExperimentPalette.classifieds,
                  foregroundColor: Colors.white,
                ),
                onPressed: _load,
                icon: const Icon(Icons.search_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (_) => _load(),
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Min price (₹)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _maxPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (_) => _load(),
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Max price (₹)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _condition,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Condition',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(value: 'ALL', child: Text('All conditions')),
                    for (final c in Listing.conditions)
                      DropdownMenuItem(value: c, child: Text(Formatters.enumLabel(c))),
                  ],
                  onChanged: (v) {
                    setState(() => _condition = v ?? 'ALL');
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _sortKey,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Sort by',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final entry in _sortOptions.entries)
                      DropdownMenuItem(value: entry.key, child: Text(entry.value)),
                  ],
                  onChanged: (v) {
                    setState(() => _sortKey = v ?? _sortKey);
                    _load();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final category in ['ALL', ...Listing.categories])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(category == 'ALL' ? 'All' : Formatters.enumLabel(category)),
                selected: _category == category,
                onSelected: (_) {
                  setState(() => _category = category);
                  _load();
                },
              ),
            ),
        ],
      ),
    );
  }

  void _openDetail(String listingId) {
    final nav = FeatureNavigator.of(context);
    nav.push(ListingDetailScreen(
      listingId: listingId,
      initiallyFavorited: _favoriteIds.contains(listingId),
      onChanged: _load,
    ));
  }
}

class _ListingCard extends StatelessWidget {
  final Listing listing;
  final bool favorited;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _ListingCard({
    required this.listing,
    required this.favorited,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      accentColor: ExperimentPalette.classifieds,
      padding: EdgeInsets.zero,
      radius: const BorderRadius.all(Radius.circular(14)),
      hoverElevation: 10,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: SizedBox(
                  width: double.infinity,
                  height: 150,
                  child: _imageOrPlaceholder(),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.92),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onToggleFavorite,
                    customBorder: const CircleBorder(),
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: Icon(
                        favorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 19,
                        color: favorited ? AppColors.danger : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark, height: 1.3),
                ),
                const SizedBox(height: 6),
                Text(
                  Formatters.currency(listing.price),
                  style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: ExperimentPalette.classifieds),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: ExperimentPalette.classifieds.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        Formatters.enumLabel(listing.condition),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: ExperimentPalette.classifieds),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.place_outlined, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        '${listing.location} · ${Formatters.relativeTime(listing.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                      ),
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

  Widget _imageOrPlaceholder() {
    final first = listing.images.isEmpty ? null : listing.images.first;
    final uri = first == null ? null : Uri.tryParse(first);
    if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
      return Image.network(
        first!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA7F3D0), Color(0xFF059669)],
        ),
      ),
      child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 42),
    );
  }
}