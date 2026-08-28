import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/post.dart';
import '../services/blog_service.dart';
import '../../../services/session.dart';
import '../../../widgets/animated_card.dart';
import '../../../widgets/app_dialogs.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_widget.dart';
import '../../../widgets/feature_navigator.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/stat_card.dart';
import '../widgets/edit_profile_dialog.dart';
import '../widgets/feed_post_card.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  static const int _tabPosts = 0;
  static const int _tabFollowers = 1;
  static const int _tabFollowing = 2;

  BlogUser? _profile;
  bool _loading = true;
  bool _followBusy = false;
  String? _error;
  int _tab = _tabPosts;

  List<Post> _posts = [];
  List<BlogUser> _followers = [];
  List<BlogUser> _following = [];
  bool _followersLoaded = false;
  bool _followersLoading = false;
  bool _followingLoaded = false;
  bool _followingLoading = false;
  String? _followersError;
  String? _followingError;

  bool get _isOwnProfile {
    final user = context.read<Session>().user;
    return user != null && user.id == widget.userId;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        BlogService.fetchUser(widget.userId),
        BlogService.fetchUserPosts(widget.userId),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as BlogUser;
        _posts = results[1] as List<Post>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is ApiException ? e.message : 'Failed to load profile.';
      });
    }
  }

  void _selectTab(int tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
    if (tab == _tabFollowers && !_followersLoaded && !_followersLoading) {
      _loadFollowers();
    } else if (tab == _tabFollowing && !_followingLoaded && !_followingLoading) {
      _loadFollowing();
    }
  }

  Future<void> _loadFollowers() async {
    setState(() {
      _followersLoading = true;
      _followersError = null;
    });
    try {
      final users = await BlogService.fetchFollowers(widget.userId);
      if (!mounted) return;
      setState(() {
        _followers = users;
        _followersLoaded = true;
        _followersLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _followersLoading = false;
        _followersError = e is ApiException ? e.message : 'Failed to load followers.';
      });
    }
  }

  Future<void> _loadFollowing() async {
    setState(() {
      _followingLoading = true;
      _followingError = null;
    });
    try {
      final users = await BlogService.fetchFollowing(widget.userId);
      if (!mounted) return;
      setState(() {
        _following = users;
        _followingLoaded = true;
        _followingLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _followingLoading = false;
        _followingError = e is ApiException ? e.message : 'Failed to load following.';
      });
    }
  }

  Future<void> _toggleFollow() async {
    final profile = _profile;
    if (profile == null || _followBusy || _isOwnProfile) return;
    setState(() => _followBusy = true);
    try {
      if (profile.followedByMe) {
        await BlogService.unfollowUser(profile.id);
        if (!mounted) return;
        setState(() => _profile = profile.copyWith(
              followedByMe: false,
              followersCount: profile.followersCount > 0 ? profile.followersCount - 1 : 0,
            ));
        AppDialogs.showSnack(context, 'Unfollowed ${profile.name}');
      } else {
        await BlogService.followUser(profile.id);
        if (!mounted) return;
        setState(() => _profile = profile.copyWith(
              followedByMe: true,
              followersCount: profile.followersCount + 1,
            ));
        AppDialogs.showSnack(context, 'Following ${profile.name}');
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showSnack(
          context,
          e is ApiException ? e.message : 'Failed to update follow status.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  Future<void> _toggleFollowForUser(BlogUser user) async {
    try {
      if (user.followedByMe) {
        await BlogService.unfollowUser(user.id);
      } else {
        await BlogService.followUser(user.id);
      }
      if (!mounted) return;
      setState(() {
        _followers = _flipFollow(_followers, user.id);
        _following = _flipFollow(_following, user.id);
      });
    } catch (e) {
      if (mounted) {
        AppDialogs.showSnack(
          context,
          e is ApiException ? e.message : 'Failed to update follow status.',
          error: true,
        );
      }
    }
  }

  List<BlogUser> _flipFollow(List<BlogUser> list, String userId) {
    return [
      for (final u in list)
        if (u.id == userId) u.copyWith(followedByMe: !u.followedByMe) else u,
    ];
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

  Future<void> _editProfile() async {
    final profile = _profile;
    if (profile == null) return;
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => EditProfileDialog(initialName: profile.name, initialBio: profile.bio),
    );
    if (result == null || !mounted) return;
    final name = result['name'] ?? profile.name;
    final bio = result['bio'] ?? profile.bio;
    try {
      await context.read<Session>().updateProfile(name: name, bio: bio);
      if (!mounted) return;
      setState(() => _profile = _profile!.copyWith(name: name, bio: bio));
      AppDialogs.showSnack(context, 'Profile updated');
    } catch (e) {
      if (mounted) {
        AppDialogs.showSnack(
          context,
          e is ApiException ? e.message : 'Failed to update profile.',
          error: true,
        );
      }
    }
  }

  Widget _buildHeader(BlogUser profile) {
    final isOwn = _isOwnProfile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ExperimentPalette.blog.withValues(alpha: 0.85),
                    ExperimentPalette.blog.withValues(alpha: 0.4),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: () => FeatureNavigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back',
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Transform.translate(
            offset: const Offset(0, -36),
            child: CircleAvatar(
              radius: 38,
              backgroundColor: ExperimentPalette.blog,
              child: Text(
                profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.name,
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
              if (profile.bio.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  profile.bio,
                  style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Posts',
                      value: profile.postsCount.toDouble(),
                      icon: Icons.article_rounded,
                      color: ExperimentPalette.blog,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: 'Followers',
                      value: profile.followersCount.toDouble(),
                      icon: Icons.group_outlined,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StatCard(
                      label: 'Following',
                      value: profile.followingCount.toDouble(),
                      icon: Icons.people_alt_outlined,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (isOwn)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _editProfile,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ExperimentPalette.blog,
                      side: BorderSide(color: ExperimentPalette.blog.withValues(alpha: 0.6)),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 17),
                    label: const Text('Edit Profile'),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _followBusy ? null : _toggleFollow,
                    style: FilledButton.styleFrom(
                      backgroundColor: profile.followedByMe ? Colors.grey.shade300 : ExperimentPalette.blog,
                      foregroundColor: profile.followedByMe ? Colors.black87 : Colors.white,
                    ),
                    icon: _followBusy
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            profile.followedByMe
                                ? Icons.check_rounded
                                : Icons.person_add_alt_1_rounded,
                            size: 17,
                          ),
                    label: Text(profile.followedByMe ? 'Following' : 'Follow'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          _TabChip(
            label: 'Posts',
            icon: Icons.article_outlined,
            selected: _tab == _tabPosts,
            onTap: () => _selectTab(_tabPosts),
          ),
          const SizedBox(width: 10),
          _TabChip(
            label: 'Followers',
            icon: Icons.group_outlined,
            selected: _tab == _tabFollowers,
            onTap: () => _selectTab(_tabFollowers),
          ),
          const SizedBox(width: 10),
          _TabChip(
            label: 'Following',
            icon: Icons.people_outline,
            selected: _tab == _tabFollowing,
            onTap: () => _selectTab(_tabFollowing),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_posts.isEmpty) {
      return const SliverToBoxAdapter(
        child: EmptyState(
          icon: Icons.forum_outlined,
          title: 'No posts yet',
          subtitle: 'Nothing has been posted yet.',
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: FeedPostCard(post: _posts[index], onToggleLike: _toggleLike),
        ),
      ),
    );
  }

  Widget _buildUserList({
    required bool loading,
    required String? error,
    required List<BlogUser> users,
    required String emptyTitle,
    required IconData emptyIcon,
    required VoidCallback onRetry,
  }) {
    if (loading) {
      return const SliverToBoxAdapter(child: LoadingWidget(message: 'Loading…'));
    }
    if (error != null) {
      return SliverToBoxAdapter(child: ErrorWidgetView(message: error, onRetry: onRetry));
    }
    if (users.isEmpty) {
      return SliverToBoxAdapter(child: EmptyState(icon: emptyIcon, title: emptyTitle));
    }
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList.builder(
        itemCount: users.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _UserTile(user: users[index], onToggleFollow: _toggleFollowForUser),
        ),
      ),
    );
  }

  List<Widget> _buildTabContent() {
    switch (_tab) {
      case _tabFollowers:
        return [
          _buildUserList(
            loading: _followersLoading,
            error: _followersError,
            users: _followers,
            emptyTitle: 'No followers yet',
            emptyIcon: Icons.person_search_outlined,
            onRetry: _loadFollowers,
          ),
        ];
      case _tabFollowing:
        return [
          _buildUserList(
            loading: _followingLoading,
            error: _followingError,
            users: _following,
            emptyTitle: 'Not following anyone yet',
            emptyIcon: Icons.people_outline,
            onRetry: _loadFollowing,
          ),
        ];
      default:
        return [_buildPostsTab()];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingWidget(message: 'Loading profile…');
    if (_error != null) return ErrorWidgetView(message: _error!, onRetry: _loadProfile);
    final profile = _profile!;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(profile)),
        SliverToBoxAdapter(child: _buildTabs()),
        ..._buildTabContent(),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? ExperimentPalette.blog : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? ExperimentPalette.blog : const Color(0xFFE6E8F0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: selected ? Colors.white : Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final BlogUser user;
  final Future<void> Function(BlogUser user) onToggleFollow;

  const _UserTile({required this.user, required this.onToggleFollow});

  @override
  Widget build(BuildContext context) {
    final isSelf = context.read<Session>().user?.id == user.id;
    return AnimatedCard(
      accentColor: ExperimentPalette.blog,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => FeatureNavigator.of(context).push(UserProfileScreen(userId: user.id)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: ExperimentPalette.blog.withValues(alpha: 0.14),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(color: ExperimentPalette.blog, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textDark),
                ),
                if (user.bio.isNotEmpty)
                  Text(
                    user.bio,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (!isSelf)
            user.followedByMe
                ? OutlinedButton(
                    onPressed: () => onToggleFollow(user),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: const Text('Following'),
                  )
                : FilledButton(
                    onPressed: () => onToggleFollow(user),
                    style: FilledButton.styleFrom(
                      backgroundColor: ExperimentPalette.blog,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: const Text('Follow'),
                  ),
        ],
      ),
    );
  }
}
