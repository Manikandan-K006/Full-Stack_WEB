import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/post.dart';
import '../services/blog_service.dart';
import '../../../services/session.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_widget.dart';
import '../../../widgets/feature_navigator.dart';
import '../../../widgets/loading_widget.dart';
import '../widgets/composer_card.dart';
import '../widgets/feed_post_card.dart';
import 'user_profile_screen.dart';

class BlogHomeScreen extends StatefulWidget {
  const BlogHomeScreen({super.key});

  @override
  State<BlogHomeScreen> createState() => _BlogHomeScreenState();
}

class _BlogHomeScreenState extends State<BlogHomeScreen> {
  static const int _pageSize = 20;

  List<Post> _posts = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;

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
      final posts = await BlogService.feed(skip: 0, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _hasMore = posts.length == _pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : 'Failed to load your feed.';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final more = await BlogService.feed(skip: _posts.length, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _posts = [..._posts, ...more];
        _hasMore = more.length == _pageSize;
      });
    } catch (e) {
      if (mounted) {
        AppDialogs.showSnack(
          context,
          e is ApiException ? e.message : 'Failed to load more posts.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<bool> _createPost(String content) async {
    try {
      final post = await BlogService.createPost(content);
      if (!mounted) return true;
      setState(() => _posts = [post, ..._posts]);
      AppDialogs.showSnack(context, 'Post published');
      return true;
    } catch (e) {
      if (mounted) {
        AppDialogs.showSnack(
          context,
          e is ApiException ? e.message : 'Failed to publish your post.',
          error: true,
        );
      }
      return false;
    }
  }

  Future<void> _toggleLike(Post post) async {
    try {
      final result =
          post.likedByMe ? await BlogService.unlikePost(post.id) : await BlogService.likePost(post.id);
      if (!mounted) return;
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        setState(() => _posts[index] = post.copyWith(
              likedByMe: result.liked,
              likesCount: result.likesCount,
            ));
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showSnack(
          context,
          e is ApiException ? e.message : 'Failed to update like.',
          error: true,
        );
      }
    }
  }

  Future<void> _editPost(Post post, String newContent) async {
    try {
      final updated = await BlogService.updatePost(post.id, newContent);
      if (!mounted) return;
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) setState(() => _posts[index] = updated);
      AppDialogs.showSnack(context, 'Post updated');
    } catch (e) {
      if (mounted) {
        AppDialogs.showSnack(
          context,
          e is ApiException ? e.message : 'Failed to update post.',
          error: true,
        );
      }
    }
  }

  Future<void> _deletePost(Post post) async {
    try {
      await BlogService.deletePost(post.id);
      if (!mounted) return;
      setState(() => _posts.removeWhere((p) => p.id == post.id));
      AppDialogs.showSnack(context, 'Post deleted');
    } catch (e) {
      if (mounted) {
        AppDialogs.showSnack(
          context,
          e is ApiException ? e.message : 'Failed to delete post.',
          error: true,
        );
      }
    }
  }

  void _openMyProfile() {
    final user = context.read<Session>().user;
    if (user == null) return;
    FeatureNavigator.of(context).push(UserProfileScreen(userId: user.id));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingWidget(message: 'Loading your feed…');
    if (_error != null) return ErrorWidgetView(message: _error!, onRetry: _load);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Micro Blogging',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Posts from people you follow',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _openMyProfile,
                style: OutlinedButton.styleFrom(
                  foregroundColor: ExperimentPalette.blog,
                  side: BorderSide(color: ExperimentPalette.blog.withValues(alpha: 0.6)),
                ),
                icon: const Icon(Icons.person_rounded, size: 17),
                label: const Text('My Profile'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ComposerCard(onSubmit: _createPost),
          const SizedBox(height: 24),
          if (_posts.isEmpty)
            const EmptyState(
              icon: Icons.forum_outlined,
              title: 'No posts yet',
              subtitle: 'Follow people to see their posts here. Start by opening a profile.',
            )
          else ...[
            for (final post in _posts)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: FeedPostCard(
                  post: post,
                  onToggleLike: _toggleLike,
                  onEdit: _editPost,
                  onDelete: _deletePost,
                ),
              ),
            if (_hasMore)
              Center(
                child: OutlinedButton.icon(
                  onPressed: _loadingMore ? null : _loadMore,
                  icon: _loadingMore
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.expand_more_rounded),
                  label: Text(_loadingMore ? 'Loading…' : 'Load more'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
