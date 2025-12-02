import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../model/post_list_state.dart';
import '../provider/repository_provider.dart';

part 'home_view_model.g.dart';

@riverpod
class HomeViewModel extends _$HomeViewModel {
  static const int _pageSize = 10;

  @override
  FutureOr<PostListState> build() async {
    // Initialize with loading state and fetch first page
    return await _fetchInitialPosts();
  }

  /// Fetch initial posts (first page)
  Future<PostListState> _fetchInitialPosts() async {
    try {
      final repository = ref.read(postRepositoryProvider);
      final posts = await repository.fetchPosts(
        page: 0,
        pageSize: _pageSize,
      );

      return PostListState(
        posts: posts,
        isLoading: false,
        isLoadingMore: false,
        hasMore: posts.length >= _pageSize,
        currentPage: 0,
        error: null,
      );
    } catch (e) {
      return PostListState(
        posts: [],
        isLoading: false,
        isLoadingMore: false,
        hasMore: false,
        currentPage: 0,
        error: '投稿の取得に失敗しました',
      );
    }
  }

  /// Refresh posts (pull-to-refresh)
  Future<void> refreshPosts() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await _fetchInitialPosts();
    });
  }

  /// Fetch more posts for infinite scroll
  Future<void> fetchMorePosts() async {
    final currentState = state.value;
    if (currentState == null ||
        currentState.isLoadingMore ||
        !currentState.hasMore) {
      return;
    }

    // Set loading more flag
    state = AsyncValue.data(
      currentState.copyWith(isLoadingMore: true),
    );

    try {
      final repository = ref.read(postRepositoryProvider);
      final nextPage = currentState.currentPage + 1;
      final newPosts = await repository.fetchPosts(
        page: nextPage,
        pageSize: _pageSize,
      );

      state = AsyncValue.data(
        currentState.copyWith(
          posts: [...currentState.posts, ...newPosts],
          currentPage: nextPage,
          hasMore: newPosts.length >= _pageSize,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(
        currentState.copyWith(
          isLoadingMore: false,
          error: '投稿の取得に失敗しました',
        ),
      );
    }
  }

  /// Create a new post
  Future<void> createPost(String content) async {
    try {
      final repository = ref.read(postRepositoryProvider);
      await repository.createPost(content: content);

      // Refresh the post list after creation
      await refreshPosts();
    } catch (e) {
      final currentState = state.value;
      if (currentState != null) {
        state = AsyncValue.data(
          currentState.copyWith(error: '投稿の作成に失敗しました'),
        );
      }
      rethrow;
    }
  }

  /// Update an existing post
  Future<void> updatePost(String postId, String content) async {
    try {
      final repository = ref.read(postRepositoryProvider);
      final updatedPost = await repository.updatePost(
        postId: postId,
        content: content,
      );

      // Update the post in the list
      final currentState = state.value;
      if (currentState != null) {
        final updatedPosts = currentState.posts.map((post) {
          return post.id == postId ? updatedPost : post;
        }).toList();

        state = AsyncValue.data(
          currentState.copyWith(posts: updatedPosts),
        );
      }
    } catch (e) {
      final currentState = state.value;
      if (currentState != null) {
        state = AsyncValue.data(
          currentState.copyWith(error: '投稿の更新に失敗しました'),
        );
      }
      rethrow;
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    try {
      final repository = ref.read(postRepositoryProvider);
      await repository.deletePost(postId: postId);

      // Remove the post from the list
      final currentState = state.value;
      if (currentState != null) {
        final updatedPosts =
            currentState.posts.where((post) => post.id != postId).toList();

        state = AsyncValue.data(
          currentState.copyWith(posts: updatedPosts),
        );
      }
    } catch (e) {
      final currentState = state.value;
      if (currentState != null) {
        state = AsyncValue.data(
          currentState.copyWith(error: '投稿の削除に失敗しました'),
        );
      }
      rethrow;
    }
  }

  /// Toggle like on a post
  Future<void> toggleLike(
    String postId,
    bool isCurrentlyLiked,
    int currentCount,
  ) async {
    try {
      final repository = ref.read(postRepositoryProvider);
      final updatedPost = await repository.toggleLike(
        postId: postId,
        isLiked: isCurrentlyLiked,
        currentLikesCount: currentCount,
      );

      // Update the post in the list
      final currentState = state.value;
      if (currentState != null) {
        final updatedPosts = currentState.posts.map((post) {
          return post.id == postId ? updatedPost : post;
        }).toList();

        state = AsyncValue.data(
          currentState.copyWith(posts: updatedPosts),
        );
      }
    } catch (e) {
      final currentState = state.value;
      if (currentState != null) {
        state = AsyncValue.data(
          currentState.copyWith(error: 'いいねの更新に失敗しました'),
        );
      }
      // Don't rethrow for likes - we want it to fail silently
    }
  }
}
