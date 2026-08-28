class BlogUser {
  final String id;
  final String name;
  final String email;
  final String bio;
  final bool followedByMe;
  final int followersCount;
  final int followingCount;
  final int postsCount;

  const BlogUser({
    required this.id,
    required this.name,
    this.email = '',
    this.bio = '',
    this.followedByMe = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
  });

  factory BlogUser.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'];
    final hasStats = stats is Map<String, dynamic>;
    return BlogUser(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
      followedByMe: json['followed_by_me'] == true,
      followersCount: hasStats ? int.tryParse('${stats['followers']}') ?? 0 : 0,
      followingCount: hasStats ? int.tryParse('${stats['following']}') ?? 0 : 0,
      postsCount: hasStats ? int.tryParse('${stats['posts']}') ?? 0 : 0,
    );
  }

  BlogUser copyWith({
    String? name,
    String? bio,
    bool? followedByMe,
    int? followersCount,
    int? followingCount,
    int? postsCount,
  }) =>
      BlogUser(
        id: id,
        name: name ?? this.name,
        email: email,
        bio: bio ?? this.bio,
        followedByMe: followedByMe ?? this.followedByMe,
        followersCount: followersCount ?? this.followersCount,
        followingCount: followingCount ?? this.followingCount,
        postsCount: postsCount ?? this.postsCount,
      );
}

class Post {
  final String id;
  final BlogUser author;
  final String content;
  final int likesCount;
  final bool likedByMe;
  final String? createdAt;
  final String? updatedAt;

  const Post({
    required this.id,
    required this.author,
    required this.content,
    required this.likesCount,
    required this.likedByMe,
    this.createdAt,
    this.updatedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final authorJson = json['author'];
    return Post(
      id: (json['id'] ?? '').toString(),
      author: authorJson is Map<String, dynamic>
          ? BlogUser.fromJson(authorJson)
          : BlogUser(id: (json['author_id'] ?? '').toString(), name: 'Unknown'),
      content: (json['content'] ?? '').toString(),
      likesCount: int.tryParse('${json['likes_count']}') ?? 0,
      likedByMe: json['liked_by_me'] == true,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Post copyWith({String? content, int? likesCount, bool? likedByMe}) => Post(
        id: id,
        author: author,
        content: content ?? this.content,
        likesCount: likesCount ?? this.likesCount,
        likedByMe: likedByMe ?? this.likedByMe,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
