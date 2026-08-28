import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../models/post.dart';
import '../screens/user_profile_screen.dart';
import '../../../services/session.dart';
import '../../../widgets/animated_card.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/feature_navigator.dart';

class FeedPostCard extends StatefulWidget {
  final Post post;
  final Future<void> Function(Post post) onToggleLike;
  final Future<void> Function(Post post, String newContent)? onEdit;
  final Future<void> Function(Post post)? onDelete;

  const FeedPostCard({
    super.key,
    required this.post,
    required this.onToggleLike,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard> {
  bool? _optimisticLiked;
  int? _optimisticCount;

  Post get _post => widget.post;

  bool get _liked => _optimisticLiked ?? _post.likedByMe;

  int get _likesCount => _optimisticCount ?? _post.likesCount;

  bool get _isOwn {
    final sessionUser = context.read<Session>().user;
    return sessionUser != null && sessionUser.id == _post.author.id;
  }

  void _openProfile() {
    FeatureNavigator.of(context).push(UserProfileScreen(userId: _post.author.id));
  }

  Future<void> _toggleLike() async {
    setState(() {
      _optimisticLiked = !_liked;
      _optimisticCount = math.max(0, _likesCount + (_optimisticLiked! ? 1 : -1));
    });
    try {
      await widget.onToggleLike(_post);
    } finally {
      if (mounted) {
        setState(() {
          _optimisticLiked = null;
          _optimisticCount = null;
        });
      }
    }
  }

  Future<void> _showEditDialog() async {
    final controller = TextEditingController(text: _post.content);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit post'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 5,
          maxLength: AppConstants.postMaxLength,
          decoration: InputDecoration(
            hintText: 'Update your post…',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ExperimentPalette.blog),
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty || result == _post.content) return;
    await widget.onEdit?.call(_post, result);
  }

  Future<void> _confirmDelete() async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Delete post?',
      message: 'This post will be permanently removed from your feed.',
      confirmLabel: 'Delete',
    );
    if (ok) await widget.onDelete?.call(_post);
  }

  @override
  Widget build(BuildContext context) {
    final time = Formatters.relativeTime(_post.createdAt);
    return AnimatedCard(
      accentColor: ExperimentPalette.blog,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: _openProfile,
                borderRadius: BorderRadius.circular(20),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: ExperimentPalette.blog.withValues(alpha: 0.14),
                  child: Text(
                    _post.author.name.isNotEmpty ? _post.author.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: ExperimentPalette.blog,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: _openProfile,
                      borderRadius: BorderRadius.circular(6),
                      child: Text(
                        _post.author.name,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      time.isEmpty ? '—' : time,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              if (_isOwn && widget.onEdit != null)
                IconButton(
                  tooltip: 'Edit post',
                  onPressed: _showEditDialog,
                  icon: Icon(Icons.edit_outlined, size: 19, color: Colors.grey.shade600),
                ),
              if (_isOwn && widget.onDelete != null)
                IconButton(
                  tooltip: 'Delete post',
                  onPressed: _confirmDelete,
                  icon: Icon(Icons.delete_outline_rounded, size: 19, color: Colors.grey.shade600),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _post.content,
            style: const TextStyle(fontSize: 14.5, height: 1.5, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _toggleLike,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                    child: Icon(
                      _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      key: ValueKey(_liked),
                      size: 20,
                      color: _liked ? const Color(0xFFE11D48) : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                    child: Text(
                      '$_likesCount',
                      key: ValueKey(_likesCount),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _liked ? const Color(0xFFE11D48) : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Likes',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
