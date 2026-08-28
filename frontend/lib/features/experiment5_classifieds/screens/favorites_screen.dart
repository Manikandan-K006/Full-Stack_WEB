import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/animated_card.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_widget.dart';
import '../../../widgets/feature_navigator.dart';
import '../../../widgets/loading_widget.dart';
import '../models/favorite.dart';
import '../models/listing.dart';
import '../services/classified_service.dart';
import 'listing_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final VoidCallback? onChanged;
  const FavoritesScreen({super.key, this.onChanged});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _loading = true;
  String? _error;
  List<Favorite> _favorites = const [];

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
      final favorites = await ClassifiedService.myFavorites();
      if (!mounted) return;
      setState(() {
        _favorites = favorites;
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

  void _pop() {
    final nav = FeatureNavigator.maybeOf(context);
    if (nav != null) {
      nav.pop();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _remove(Favorite favorite) async {
    try {
      await ClassifiedService.toggleFavorite(favorite.listing.id);
      if (!mounted) return;
      AppDialogs.showSnack(context, 'Removed from favorites');
      widget.onChanged?.call();
      _load();
    } on Exception catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  void _openDetail(Listing listing) {
    FeatureNavigator.of(context).push(ListingDetailScreen(
      listingId: listing.id,
      initiallyFavorited: true,
      onChanged: _load,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final columns = width > 1200 ? 3 : (width > 720 ? 2 : 1);
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          _BackHeader(title: 'Favorites', onBack: _pop),
          Expanded(
            child: _loading
                ? const LoadingWidget(message: 'Loading favorites…')
                : _error != null
                    ? ErrorWidgetView(message: _error!, onRetry: _load)
                    : _favorites.isEmpty
                        ? const EmptyState(
                            icon: Icons.favorite_border_rounded,
                            title: 'No favorites yet',
                            subtitle: 'Tap the heart on any listing to save it here',
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final cardWidth =
                                  (constraints.maxWidth - (columns - 1) * 16) / columns;
                              return SingleChildScrollView(
                                padding: const EdgeInsets.all(20),
                                child: Wrap(
                                  spacing: 16,
                                  runSpacing: 16,
                                  children: [
                                    for (final favorite in _favorites)
                                      SizedBox(
                                        width: cardWidth,
                                        child: _FavoriteCard(
                                          favorite: favorite,
                                          onTap: () => _openDetail(favorite.listing),
                                          onRemove: () => _remove(favorite),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final Favorite favorite;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteCard({
    required this.favorite,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final listing = favorite.listing;
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
                  child: _imageOrPlaceholder(listing),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.92),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onRemove,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(7),
                      child: Icon(Icons.favorite_rounded, size: 19, color: AppColors.danger),
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

  Widget _imageOrPlaceholder(Listing listing) {
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

class _BackHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _BackHeader({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 16.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}