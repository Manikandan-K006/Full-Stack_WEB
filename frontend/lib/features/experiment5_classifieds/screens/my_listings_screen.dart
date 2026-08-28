import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/animated_card.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_widget.dart';
import '../../../widgets/feature_navigator.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/status_chip.dart';
import '../models/listing.dart';
import '../services/classified_service.dart';
import 'listing_detail_screen.dart';
import 'listing_form_dialog.dart';

class MyListingsScreen extends StatefulWidget {
  final VoidCallback? onChanged;
  const MyListingsScreen({super.key, this.onChanged});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  bool _loading = true;
  String? _error;
  List<Listing> _items = const [];

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
      final items = await ClassifiedService.myListings();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  void _openDetail(Listing listing) {
    FeatureNavigator.of(context).push(ListingDetailScreen(
      listingId: listing.id,
      onChanged: _load,
    ));
  }

  Future<void> _openCreate() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const ListingFormDialog(),
    );
    if (created == true && mounted) {
      AppDialogs.showSnack(context, 'Listing created successfully');
      widget.onChanged?.call();
      _load();
    }
  }

  Future<void> _openEdit(Listing listing) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => ListingFormDialog(initial: listing),
    );
    if (updated == true && mounted) {
      AppDialogs.showSnack(context, 'Listing updated');
      widget.onChanged?.call();
      _load();
    }
  }

  Future<void> _markSold(Listing listing) async {
    try {
      await ClassifiedService.markSold(listing.id);
      if (!mounted) return;
      AppDialogs.showSnack(context, 'Listing marked as sold');
      widget.onChanged?.call();
      _load();
    } on Exception catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  Future<void> _delete(Listing listing) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete listing?',
      message: 'This will permanently remove "${listing.title}".',
      confirmLabel: 'Delete',
    );
    if (!confirmed) return;
    try {
      await ClassifiedService.deleteListing(listing.id);
      if (!mounted) return;
      AppDialogs.showSnack(context, 'Listing deleted');
      widget.onChanged?.call();
      _load();
    } on Exception catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          _BackHeader(title: 'My Listings', onBack: _pop),
          Expanded(
            child: _loading
                ? const LoadingWidget(message: 'Loading your listings…')
                : _error != null
                    ? ErrorWidgetView(message: _error!, onRetry: _load)
                    : _items.isEmpty
                        ? EmptyState(
                            icon: Icons.storefront_rounded,
                            title: 'No listings yet',
                            subtitle: 'Sell your first item and it will appear here',
                            action: FilledButton.icon(
                              onPressed: _openCreate,
                              style: FilledButton.styleFrom(
                                  backgroundColor: ExperimentPalette.classifieds),
                              icon: const Icon(Icons.add),
                              label: const Text('Sell an Item'),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) => _buildTile(_items[i]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(Listing listing) {
    return AnimatedCard(
      accentColor: ExperimentPalette.classifieds,
      onTap: () => _openDetail(listing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 74,
              height: 74,
              child: _thumb(listing),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.currency(listing.price),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: ExperimentPalette.classifieds),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    StatusChip(status: listing.status),
                    const SizedBox(width: 8),
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
          Column(
            children: [
              if (listing.isAvailable)
                IconButton(
                  tooltip: 'Mark as sold',
                  onPressed: () => _markSold(listing),
                  icon: const Icon(Icons.check_circle_outline_rounded,
                      color: ExperimentPalette.classifieds),
                ),
              IconButton(
                tooltip: 'Edit',
                onPressed: () => _openEdit(listing),
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: () => _delete(listing),
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _thumb(Listing listing) {
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA7F3D0), Color(0xFF059669)],
        ),
      ),
      child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 26),
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