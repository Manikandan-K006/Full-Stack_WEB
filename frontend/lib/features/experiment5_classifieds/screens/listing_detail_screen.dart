import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../services/session.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/error_widget.dart';
import '../../../widgets/feature_navigator.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/status_chip.dart';
import '../models/listing.dart';
import '../services/classified_service.dart';
import 'listing_form_dialog.dart';

class ListingDetailScreen extends StatefulWidget {
  final String listingId;
  final bool initiallyFavorited;
  final VoidCallback? onChanged;

  const ListingDetailScreen({
    super.key,
    required this.listingId,
    this.initiallyFavorited = false,
    this.onChanged,
  });

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  bool _loading = true;
  String? _error;
  Listing? _listing;
  bool _favorited = false;
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    _favorited = widget.initiallyFavorited;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final listing = await ClassifiedService.getListing(widget.listingId);
      if (!mounted) return;
      setState(() {
        _listing = listing;
        _imageIndex = 0;
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

  bool get _isOwner {
    final userId = context.read<Session>().user?.id;
    return userId != null && _listing?.sellerId == userId;
  }

  List<String> get _validImages {
    final out = <String>[];
    for (final image in _listing?.images ?? const <String>[]) {
      final uri = Uri.tryParse(image);
      if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
        out.add(image);
      }
    }
    return out;
  }

  Future<void> _toggleFavorite() async {
    try {
      final favorited = await ClassifiedService.toggleFavorite(_listing!.id);
      if (!mounted) return;
      setState(() => _favorited = favorited);
      widget.onChanged?.call();
    } on Exception catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  Future<void> _openContactDialog() async {
    final sent = await showDialog<bool>(
      context: context,
      builder: (_) => _ContactDialog(
        listingId: _listing!.id,
        listingTitle: _listing!.title,
      ),
    );
    if (sent == true && mounted) {
      AppDialogs.showSnack(context, 'Message sent to the seller');
    }
  }

  Future<void> _openEdit() async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => ListingFormDialog(initial: _listing),
    );
    if (updated == true && mounted) {
      AppDialogs.showSnack(context, 'Listing updated');
      widget.onChanged?.call();
      _load();
    }
  }

  Future<void> _markSold() async {
    try {
      final updated = await ClassifiedService.markSold(_listing!.id);
      if (!mounted) return;
      setState(() => _listing = updated);
      widget.onChanged?.call();
      AppDialogs.showSnack(context, 'Listing marked as sold');
    } on Exception catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  Future<void> _delete() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete listing?',
      message: 'This will permanently remove "${_listing!.title}" and its favorites.',
      confirmLabel: 'Delete',
    );
    if (!confirmed) return;
    try {
      await ClassifiedService.deleteListing(_listing!.id);
      if (!mounted) return;
      AppDialogs.showSnack(context, 'Listing deleted');
      widget.onChanged?.call();
      _pop();
    } on Exception catch (e) {
      if (!mounted) return;
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          _BackHeader(title: 'Listing Details', onBack: _pop),
          Expanded(
            child: _loading
                ? const LoadingWidget(message: 'Loading listing…')
                : _error != null
                    ? ErrorWidgetView(message: _error!, onRetry: _load)
                    : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final listing = _listing!;
    final images = _validImages;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (images.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 260,
                    child: Image.network(
                      images[_imageIndex.clamp(0, images.length - 1).toInt()],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    ),
                  ),
                ),
                if (images.length > 1) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 56,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => InkWell(
                        onTap: () => setState(() => _imageIndex = i),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 72,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              width: 2,
                              color: _imageIndex == i
                                  ? ExperimentPalette.classifieds
                                  : Colors.transparent,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              images[i],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _imagePlaceholder(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(width: double.infinity, height: 200, child: _imagePlaceholder()),
            ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  listing.title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark, height: 1.3),
                ),
              ),
              if (!_isOwner)
                IconButton(
                  tooltip: _favorited ? 'Remove from favorites' : 'Add to favorites',
                  onPressed: _toggleFavorite,
                  icon: Icon(
                    _favorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _favorited ? AppColors.danger : AppColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.currency(listing.price),
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800, color: ExperimentPalette.classifieds),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(Formatters.enumLabel(listing.category), AppColors.primary),
              _chip(Formatters.enumLabel(listing.condition), ExperimentPalette.classifieds),
              StatusChip(status: listing.status),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.place_outlined, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(listing.location,
                  style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700)),
              const Spacer(),
              Icon(Icons.schedule_rounded, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(Formatters.relativeTime(listing.createdAt),
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFE6E8F0)),
          const SizedBox(height: 18),
          const Text('Description',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 8),
          Text(
            listing.description,
            style: TextStyle(fontSize: 14, height: 1.55, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFE6E8F0)),
          const SizedBox(height: 18),
          _buildSeller(listing),
          const SizedBox(height: 20),
          _buildActions(listing),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSeller(Listing listing) {
    final seller = listing.seller;
    final name = seller?['name']?.toString() ?? listing.sellerName ?? 'Unknown';
    final email = seller?['email']?.toString();
    final bio = seller?['bio']?.toString() ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: ExperimentPalette.classifieds.withValues(alpha: 0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: ExperimentPalette.classifieds, fontWeight: FontWeight.w700, fontSize: 17),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Seller',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey, letterSpacing: 0.8)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                if (email != null && email.isNotEmpty)
                  Text(email, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(Listing listing) {
    if (_isOwner) {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          OutlinedButton.icon(
            onPressed: _openEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit'),
          ),
          if (listing.isAvailable)
            FilledButton.icon(
              onPressed: _markSold,
              style: FilledButton.styleFrom(backgroundColor: ExperimentPalette.classifieds),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Mark as Sold'),
            ),
          OutlinedButton.icon(
            onPressed: _delete,
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _openContactDialog,
            style: FilledButton.styleFrom(
                backgroundColor: ExperimentPalette.classifieds,
                padding: const EdgeInsets.symmetric(vertical: 13)),
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: const Text('Contact Seller'),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _imagePlaceholder() {
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
      child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 48),
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

class _ContactDialog extends StatefulWidget {
  final String listingId;
  final String listingTitle;
  const _ContactDialog({required this.listingId, required this.listingTitle});

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ClassifiedService.contactSeller(
        widget.listingId,
        name: _nameController.text.trim(),
        message: _messageController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppDialogs.showSnack(context, AppDialogs.friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.chat_outlined, color: ExperimentPalette.classifieds),
      title: const Text('Contact Seller'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ask about "${widget.listingTitle}"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameController,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Your name'),
                  validator: (v) =>
                      Validators.required(v, 'Name') ?? Validators.minLength(v, 2, 'Name'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _messageController,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: const InputDecoration(labelText: 'Message'),
                  validator: (v) =>
                      Validators.required(v, 'Message') ?? Validators.minLength(v, 2, 'Message'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: ExperimentPalette.classifieds),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Send'),
        ),
      ],
    );
  }
}