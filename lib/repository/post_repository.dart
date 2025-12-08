import '../model/post.dart';

abstract class PostRepository {
  /// Fetch posts with pagination
  /// Returns a list of posts for the specified page
  Future<List<Post>> fetchPosts({
    required int page,
    required int pageSize,
  });

  /// Create a new post
  /// Validates content before creating
  /// Throws exception if content is invalid
  Future<Post> createPost({
    required String content,
  });

  /// Update an existing post
  /// Validates content before updating
  /// Throws exception if content is invalid
  Future<Post> updatePost({
    required String postId,
    required String content,
  });

  /// Delete a post
  Future<void> deletePost({
    required String postId,
  });

  /// Toggle like on a post
  /// Increments or decrements the likes count
  Future<Post> toggleLike({
    required String postId,
    required bool isLiked,
    required int currentLikesCount,
  });
}
