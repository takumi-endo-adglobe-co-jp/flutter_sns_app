import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../component/loading_indicator.dart';
import '../component/post_card.dart';
import '../component/post_input_field.dart';
import '../constant/app_colors.dart';
import '../constant/app_strings.dart';
import '../view_model/home_view_model.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      // User scrolled to 90% of the list
      final state = ref.read(homeViewModelProvider).value;
      if (state != null && !state.isLoadingMore && state.hasMore) {
        ref.read(homeViewModelProvider.notifier).fetchMorePosts();
      }
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(homeViewModelProvider.notifier).refreshPosts();
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(homeViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.homeTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: asyncState.when(
        loading: () => const LoadingIndicator(),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                error.toString(),
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _onRefresh,
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
        data: (state) {
          // Show error snackbar if there's an error
          if (state.error != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error!)),
              );
            });
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: Column(
              children: [
                // Post input field at the top
                const PostInputField(),

                // Posts list
                Expanded(
                  child: state.posts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.article_outlined,
                                size: 64,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppStrings.noPostsYet,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: state.posts.length +
                              (state.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= state.posts.length) {
                              // Show loading indicator at the bottom
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final post = state.posts[index];
                            return PostCard(
                              key: ValueKey(post.id),
                              post: post,
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
