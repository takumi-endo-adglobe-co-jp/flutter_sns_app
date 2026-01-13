import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  Future<List<Post>> fetchPosts({required int offset, required int limit}) async {
    final response = await _client
        .from('posts')
        .select()
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((json) => Post.fromJson(json)).toList();
  }

  Future<Post> createPost(String content) async {
    final response = await _client
        .from('posts')
        .insert({'content': content})
        .select()
        .single();

    return Post.fromJson(response);
  }

  Future<Post> updatePost(String id, String content) async {
    final response = await _client
        .from('posts')
        .update({'content': content})
        .eq('id', id)
        .select()
        .single();

    return Post.fromJson(response);
  }

  Future<void> deletePost(String id) async {
    await _client.from('posts').delete().eq('id', id);
  }

  Future<void> incrementLikes(String id) async {
    final post = await _client
        .from('posts')
        .select('likes_count')
        .eq('id', id)
        .single();

    final currentLikes = post['likes_count'] as int;
    await _client
        .from('posts')
        .update({'likes_count': currentLikes + 1})
        .eq('id', id);
  }

  Future<void> decrementLikes(String id) async {
    final post = await _client
        .from('posts')
        .select('likes_count')
        .eq('id', id)
        .single();

    final currentLikes = post['likes_count'] as int;
    if (currentLikes > 0) {
      await _client
          .from('posts')
          .update({'likes_count': currentLikes - 1})
          .eq('id', id);
    }
  }

  RealtimeChannel subscribeToPostChanges({
    required void Function(Map<String, dynamic>) onInsert,
    required void Function(Map<String, dynamic>) onUpdate,
    required void Function(Map<String, dynamic>) onDelete,
  }) {
    return _client.channel('posts_channel').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'posts',
      callback: (payload) {
        if (payload.eventType == PostgresChangeEvent.insert) {
          onInsert(payload.newRecord);
        } else if (payload.eventType == PostgresChangeEvent.update) {
          onUpdate(payload.newRecord);
        } else if (payload.eventType == PostgresChangeEvent.delete) {
          onDelete(payload.oldRecord);
        }
      },
    ).subscribe();
  }
}
