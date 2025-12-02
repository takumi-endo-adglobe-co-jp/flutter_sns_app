class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'SNS';

  // Home Screen
  static const String homeTitle = 'SNS';
  static const String postInputHint = '今何してる？';
  static const String postButton = '投稿';

  // Post Actions
  static const String edit = '編集';
  static const String delete = '削除';
  static const String save = '保存';
  static const String cancel = 'キャンセル';

  // Dialogs
  static const String deleteConfirmTitle = '投稿を削除';
  static const String deleteConfirmMessage = 'この投稿を削除しますか？';
  static const String deleteConfirmButton = '削除';
  static const String cancelButton = 'キャンセル';

  // Validation Messages
  static const String emptyPostError = '投稿内容を入力してください';
  static const String maxLengthError = '512文字以内で入力してください';

  // Error Messages
  static const String fetchPostsError = '投稿の取得に失敗しました';
  static const String createPostError = '投稿の作成に失敗しました';
  static const String updatePostError = '投稿の更新に失敗しました';
  static const String deletePostError = '投稿の削除に失敗しました';
  static const String likePostError = 'いいねの更新に失敗しました';

  // Empty State
  static const String noPostsYet = 'まだ投稿がありません';
  static const String noMorePosts = 'これ以上投稿がありません';

  // Loading
  static const String loading = '読み込み中...';
  static const String loadingMore = '読み込み中...';
}
