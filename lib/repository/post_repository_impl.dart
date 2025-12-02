import '../constant/app_sizes.dart';
import '../infrastructure/supabase_api_client.dart';
import '../model/post.dart';
import 'post_repository.dart';

class PostRepositoryImpl implements PostRepository {
  PostRepositoryImpl(this._apiClient);

  final SupabaseApiClient _apiClient;

  @override
  Future<List<Post>> fetchPosts({
    required int page,
    required int pageSize,
  }) async {
    final offset = page * pageSize;
    final response = await _apiClient.fetchPosts(
      offset: offset,
      limit: pageSize,
    );

    return response.map((json) => Post.fromJson(json)).toList();
  }

  @override
  Future<Post> createPost({
    required String content,
  }) async {
    // Validate content
    _validateContent(content);

    final response = await _apiClient.createPost(content: content);
    return Post.fromJson(response);
  }

  @override
  Future<Post> updatePost({
    required String postId,
    required String content,
  }) async {
    // Validate content
    _validateContent(content);

    final response = await _apiClient.updatePost(
      postId: postId,
      content: content,
    );
    return Post.fromJson(response);
  }

  @override
  Future<void> deletePost({
    required String postId,
  }) async {
    await _apiClient.deletePost(postId: postId);
  }

  @override
  Future<Post> toggleLike({
    required String postId,
    required bool isLiked,
    required int currentLikesCount,
  }) async {
    // Calculate new likes count
    final newCount = isLiked ? currentLikesCount + 1 : currentLikesCount - 1;

    // Ensure count doesn't go below 0
    final validatedCount = newCount < 0 ? 0 : newCount;

    final response = await _apiClient.updateLikesCount(
      postId: postId,
      newCount: validatedCount,
    );
    return Post.fromJson(response);
  }

  /// Validate post content
  /// Throws ArgumentError if content is invalid
  void _validateContent(String content) {
    if (content.trim().isEmpty) {
      throw ArgumentError('投稿内容を入力してください');
    }

    if (content.length > AppSizes.postMaxLength) {
      throw ArgumentError('512文字以内で入力してください');
    }
  }
}
