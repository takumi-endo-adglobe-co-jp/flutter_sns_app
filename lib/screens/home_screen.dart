import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';
import '../services/supabase_service.dart';
import '../services/like_storage_service.dart';
import '../widgets/post_card.dart';
import '../widgets/edit_post_card.dart';
import '../widgets/post_input.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final SupabaseService _supabaseService;
  late final LikeStorageService _likeStorageService;
  late final ScrollController _scrollController;

  List<Post> _posts = [];
  Set<String> _likedPostIds = {};
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _editingPostId;
  int _currentOffset = 0;
  RealtimeChannel? _realtimeChannel;
  bool _hasMore = true;

  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _supabaseService = SupabaseService(Supabase.instance.client);
    _likeStorageService = LikeStorageService();
    _scrollController = ScrollController();

    _initialize();
  }

  Future<void> _initialize() async {
    await _likeStorageService.init();
    final likedPosts = await _likeStorageService.getLikedPostIds();
    setState(() {
      _likedPostIds = likedPosts;
    });

    await _loadInitialPosts();
    _setupScrollListener();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.9) {
        if (!_isLoadingMore && _hasMore) {
          _loadMorePosts();
        }
      }
    });
  }

  void _setupRealtimeSubscription() {
    _realtimeChannel = _supabaseService.subscribeToPostChanges(
      onInsert: _handleRealtimeInsert,
      onUpdate: _handleRealtimeUpdate,
      onDelete: _handleRealtimeDelete,
    );
  }

  void _handleRealtimeInsert(Map<String, dynamic> record) {
    if (!mounted) return;
    final post = Post.fromJson(record);
    setState(() {
      _posts.insert(0, post);
    });
  }

  void _handleRealtimeUpdate(Map<String, dynamic> record) {
    if (!mounted) return;
    final updatedPost = Post.fromJson(record);
    setState(() {
      final index = _posts.indexWhere((p) => p.id == updatedPost.id);
      if (index != -1) {
        _posts[index] = updatedPost;
      }
    });
  }

  void _handleRealtimeDelete(Map<String, dynamic> record) {
    if (!mounted) return;
    final postId = record['id'] as String;
    setState(() {
      _posts.removeWhere((p) => p.id == postId);
    });
  }

  Future<void> _loadInitialPosts() async {
    try {
      final posts = await _supabaseService.fetchPosts(
        offset: 0,
        limit: _pageSize,
      );

      if (mounted) {
        setState(() {
          _posts = posts;
          _currentOffset = _pageSize;
          _isLoading = false;
          _hasMore = posts.length >= _pageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('投稿の読み込みに失敗しました');
      }
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final newPosts = await _supabaseService.fetchPosts(
        offset: _currentOffset,
        limit: _pageSize,
      );

      if (mounted) {
        setState(() {
          _posts.addAll(newPosts);
          _currentOffset += _pageSize;
          _isLoadingMore = false;
          _hasMore = newPosts.length >= _pageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        _showError('投稿の読み込みに失敗しました');
      }
    }
  }

  Future<void> _handleCreatePost(String content) async {
    try {
      await _supabaseService.createPost(content);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('投稿しました')),
        );
      }
    } on PostgrestException catch (e) {
      _showError('データベースエラー: ${e.message}');
    } catch (e) {
      _showError('投稿の作成に失敗しました');
    }
  }

  Future<void> _handleEditPost(String postId, String content) async {
    try {
      await _supabaseService.updatePost(postId, content);
      if (mounted) {
        setState(() {
          _editingPostId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('投稿を更新しました')),
        );
      }
    } on PostgrestException catch (e) {
      _showError('データベースエラー: ${e.message}');
    } catch (e) {
      _showError('投稿の更新に失敗しました');
    }
  }

  Future<void> _handleDeletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('投稿を削除'),
        content: const Text('この投稿を削除しますか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabaseService.deletePost(postId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('投稿を削除しました')),
          );
        }
      } on PostgrestException catch (e) {
        _showError('データベースエラー: ${e.message}');
      } catch (e) {
        _showError('投稿の削除に失敗しました');
      }
    }
  }

  Future<void> _handleToggleLike(Post post) async {
    final isCurrentlyLiked = _likedPostIds.contains(post.id);
    final newLikedState = !isCurrentlyLiked;

    setState(() {
      if (newLikedState) {
        _likedPostIds.add(post.id);
      } else {
        _likedPostIds.remove(post.id);
      }

      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        _posts[index] = post.copyWith(
          likesCount: newLikedState ? post.likesCount + 1 : post.likesCount - 1,
        );
      }
    });

    try {
      await _likeStorageService.toggleLike(post.id);
      if (newLikedState) {
        await _supabaseService.incrementLikes(post.id);
      } else {
        await _supabaseService.decrementLikes(post.id);
      }
    } catch (e) {
      setState(() {
        if (newLikedState) {
          _likedPostIds.remove(post.id);
        } else {
          _likedPostIds.add(post.id);
        }

        final index = _posts.indexWhere((p) => p.id == post.id);
        if (index != -1) {
          _posts[index] = post.copyWith(
            likesCount:
                newLikedState ? post.likesCount - 1 : post.likesCount + 1,
          );
        }
      });
      _showError('いいねの更新に失敗しました');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('投稿アプリ'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          PostInput(onSubmit: _handleCreatePost),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _posts.isEmpty
                    ? const Center(
                        child: Text(
                          'まだ投稿がありません。\n最初の投稿をしてみましょう!',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _posts.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final post = _posts[index];
                          final isEditing = _editingPostId == post.id;
                          final isLiked = _likedPostIds.contains(post.id);

                          if (isEditing) {
                            return EditPostCard(
                              post: post,
                              onSave: (content) =>
                                  _handleEditPost(post.id, content),
                              onCancel: () {
                                setState(() {
                                  _editingPostId = null;
                                });
                              },
                            );
                          }

                          return PostCard(
                            post: post,
                            isLiked: isLiked,
                            onEdit: () {
                              setState(() {
                                _editingPostId = post.id;
                              });
                            },
                            onDelete: () => _handleDeletePost(post.id),
                            onLike: () => _handleToggleLike(post),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
