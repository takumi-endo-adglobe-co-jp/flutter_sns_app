import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseApiClient {
  SupabaseApiClient(this._client);

  final SupabaseClient _client;

  /// Fetch posts with pagination
  /// Returns a list of posts ordered by created_at descending
  Future<List<Map<String, dynamic>>> fetchPosts({
    required int offset,
    required int limit,
  }) async {
    final response = await _client
        .from('posts')
        .select()
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Create a new post
  /// Returns the created post
  Future<Map<String, dynamic>> createPost({
    required String content,
  }) async {
    final response = await _client
        .from('posts')
        .insert({
          'content': content,
        })
        .select()
        .single();

    return response;
  }

  /// Update an existing post
  /// Returns the updated post
  Future<Map<String, dynamic>> updatePost({
    required String postId,
    required String content,
  }) async {
    final response = await _client
        .from('posts')
        .update({
          'content': content,
        })
        .eq('id', postId)
        .select()
        .single();

    return response;
  }

  /// Delete a post
  Future<void> deletePost({
    required String postId,
  }) async {
    await _client.from('posts').delete().eq('id', postId);
  }

  /// Update likes count
  /// Returns the updated post
  Future<Map<String, dynamic>> updateLikesCount({
    required String postId,
    required int newCount,
  }) async {
    final response = await _client
        .from('posts')
        .update({
          'likes_count': newCount,
        })
        .eq('id', postId)
        .select()
        .single();

    return response;
  }
}
