import 'package:freezed_annotation/freezed_annotation.dart';
import 'post.dart';

part 'post_list_state.freezed.dart';

@freezed
class PostListState with _$PostListState {
  const factory PostListState({
    @Default([]) List<Post> posts,
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default(true) bool hasMore,
    @Default(0) int currentPage,
    String? error,
  }) = _PostListState;
}
