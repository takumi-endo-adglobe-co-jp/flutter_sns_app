import 'package:shared_preferences/shared_preferences.dart';

class LikeStorageService {
  static const String _likedPostsKey = 'liked_posts';
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<Set<String>> getLikedPostIds() async {
    if (_prefs == null) await init();
    final List<String> likedPosts = _prefs!.getStringList(_likedPostsKey) ?? [];
    return Set<String>.from(likedPosts);
  }

  Future<bool> isLiked(String postId) async {
    final likedPosts = await getLikedPostIds();
    return likedPosts.contains(postId);
  }

  Future<bool> toggleLike(String postId) async {
    if (_prefs == null) await init();
    final likedPosts = await getLikedPostIds();

    bool isNowLiked;
    if (likedPosts.contains(postId)) {
      likedPosts.remove(postId);
      isNowLiked = false;
    } else {
      likedPosts.add(postId);
      isNowLiked = true;
    }

    await _prefs!.setStringList(_likedPostsKey, likedPosts.toList());
    return isNowLiked;
  }
}
