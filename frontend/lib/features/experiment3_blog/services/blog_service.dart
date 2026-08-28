import '../../../core/network/api_client.dart';
import '../models/post.dart';

class LikeResult {
  final bool liked;
  final int likesCount;

  const LikeResult({required this.liked, required this.likesCount});
}

class BlogService {
  static const String _postsPath = '/api/posts';
  static const String _usersPath = '/api/users';

  static Future<List<Post>> feed({int skip = 0, int limit = 30}) async {
    final data =
        await ApiClient.instance.get('$_postsPath/feed', query: {'skip': skip, 'limit': limit});
    return _parsePosts(data);
  }

  static Future<Post> createPost(String content) async {
    final data = await ApiClient.instance.post(_postsPath, body: {'content': content});
    return Post.fromJson(data as Map<String, dynamic>);
  }

  static Future<Post> updatePost(String postId, String content) async {
    final data = await ApiClient.instance.put('$_postsPath/$postId', body: {'content': content});
    return Post.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> deletePost(String postId) async {
    await ApiClient.instance.delete('$_postsPath/$postId');
  }

  static Future<LikeResult> likePost(String postId) async {
    final data = await ApiClient.instance.post('$_postsPath/$postId/like');
    return _parseLike(data);
  }

  static Future<LikeResult> unlikePost(String postId) async {
    final data = await ApiClient.instance.delete('$_postsPath/$postId/like');
    return _parseLike(data);
  }

  static Future<List<Post>> fetchUserPosts(String userId) async {
    final data = await ApiClient.instance.get('$_postsPath/user/$userId');
    return _parsePosts(data);
  }

  static Future<BlogUser> fetchUser(String userId) async {
    final data = await ApiClient.instance.get('$_usersPath/$userId');
    return BlogUser.fromJson(data as Map<String, dynamic>);
  }

  static Future<BlogUser> updateMe({String? name, String? bio}) async {
    final data = await ApiClient.instance.put('$_usersPath/me', body: {'name': name, 'bio': bio});
    return BlogUser.fromJson(data as Map<String, dynamic>);
  }

  static Future<List<BlogUser>> searchUsers(String query) async {
    final data = await ApiClient.instance.get('$_usersPath/search', query: {'q': query});
    return _parseUsers(data);
  }

  static Future<List<BlogUser>> fetchFollowers(String userId) async {
    final data = await ApiClient.instance.get('$_usersPath/$userId/followers');
    return _parseUsers(data);
  }

  static Future<List<BlogUser>> fetchFollowing(String userId) async {
    final data = await ApiClient.instance.get('$_usersPath/$userId/following');
    return _parseUsers(data);
  }

  static Future<bool> followUser(String userId) async {
    final data = await ApiClient.instance.post('$_usersPath/$userId/follow');
    return (data as Map<String, dynamic>)['following'] == true;
  }

  static Future<bool> unfollowUser(String userId) async {
    final data = await ApiClient.instance.delete('$_usersPath/$userId/follow');
    return (data as Map<String, dynamic>)['following'] == true;
  }

  static List<Post> _parsePosts(dynamic data) {
    if (data is! List) return [];
    return data.whereType<Map<String, dynamic>>().map(Post.fromJson).toList();
  }

  static List<BlogUser> _parseUsers(dynamic data) {
    if (data is! List) return [];
    return data.whereType<Map<String, dynamic>>().map(BlogUser.fromJson).toList();
  }

  static LikeResult _parseLike(dynamic data) {
    final map = (data as Map<String, dynamic>?) ?? const {};
    return LikeResult(
      liked: map['liked'] == true,
      likesCount: int.tryParse('${map['likes_count']}') ?? 0,
    );
  }
}
