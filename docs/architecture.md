# architecture.md - アーキテクチャ設計書

## アーキテクチャ概要

本プロジェクトは **MVVM (Model-View-ViewModel)** アーキテクチャを採用しています。
状態管理には **Riverpod** を使用し、各レイヤーの責務を明確に分離することで、保守性・テスタビリティの高いコードベースを実現しています。

## ディレクトリ構成

```
lib/
├── component/          # 再利用可能なUIコンポーネント
├── constant/           # 定数定義
├── core/              # アプリケーションコア機能
├── infrastructure/    # 外部システムとの通信層
├── model/             # データモデル・UIステート
├── provider/          # Riverpodプロバイダー定義
├── repository/        # ビジネスロジック層
├── router/            # 画面遷移管理
├── ui_core/           # UI共通機能
├── view/              # 画面UI
├── view_model/        # UIステート管理・データ変換
├── app.dart           # アプリケーションルート
├── importer.dart      # 一括エクスポート
└── main.dart          # エントリーポイント
```

## 各レイヤーの役割と責務

### 1. View (UI層)

**役割**: ユーザーインターフェースの表示

**責務**:
- UIの構築と描画
- ユーザー入力の受付
- ViewModelのメソッド呼び出し
- UIステートの監視と表示の更新

**制約**:
- ビジネスロジックを含めない
- 直接Repositoryを呼び出さない
- データの加工処理を行わない
- 自身のContextのみを扱う

**依存関係**:
- ViewModel → 状態取得・メソッド呼び出し
- Component → UI部品の利用
- Router → 画面遷移の実行

**実装例**:
```dart
class HomeView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(homeViewModelProvider);

    return Scaffold(
      body: uiState.when(
        loading: () => CircularProgressIndicator(),
        success: (data) => ListView(...),
        error: (error) => ErrorWidget(error),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(homeViewModelProvider.notifier).fetchData();
        },
      ),
    );
  }
}
```

---

### 2. ViewModel (プレゼンテーション層)

**役割**: UIステートの管理とデータ変換

**責務**:
- UIステートの保持・更新
- Repositoryから取得したデータの加工
- ユーザーアクションのハンドリング
- エラーハンドリング

**制約**:
- UI構築に関する処理を含めない
- 直接Infrastructureを呼び出さない
- ビジネスロジックを含めない(Repositoryに委譲)

**依存関係**:
- Repository → データ取得・更新
- Model → UIステートの型定義

**実装例**:
```dart
@riverpod
class HomeViewModel extends _$HomeViewModel {
  @override
  FutureOr<HomeUiState> build() async {
    return await _fetchInitialData();
  }

  Future<void> fetchData() async {
    state = const AsyncValue.loading();

    final repository = ref.read(postRepositoryProvider);
    state = await AsyncValue.guard(() async {
      final posts = await repository.fetchPosts();
      return HomeUiState.success(posts: posts);
    });
  }

  Future<void> createPost(String content) async {
    final repository = ref.read(postRepositoryProvider);
    await repository.createPost(content: content);
    await fetchData(); // 再取得
  }
}
```

---

### 3. Repository (ビジネスロジック層)

**役割**: ビジネスロジックの実装

**責務**:
- データのCRUD操作
- ビジネスルールの実行
- 複数のInfrastructureの組み合わせ
- ドメインモデルの操作

**制約**:
- UIに関する処理を含めない
- 直接Viewを参照しない
- UIステートを扱わない

**依存関係**:
- Infrastructure → データソースへのアクセス
- Model → ドメインモデルの利用

**実装例**:
```dart
// インターフェース
abstract class PostRepository {
  Future<List<Post>> fetchPosts();
  Future<Post> createPost({required String content});
  Future<void> deletePost({required String postId});
}

// 実装クラス
class PostRepositoryImpl implements PostRepository {
  PostRepositoryImpl(this._apiClient);

  final SupabaseApiClient _apiClient;

  @override
  Future<List<Post>> fetchPosts() async {
    final response = await _apiClient.fetchPosts();
    return response.map((json) => Post.fromJson(json)).toList();
  }

  @override
  Future<Post> createPost({required String content}) async {
    final response = await _apiClient.createPost(content: content);
    return Post.fromJson(response);
  }

  @override
  Future<void> deletePost({required String postId}) async {
    await _apiClient.deletePost(postId: postId);
  }
}
```

---

### 4. Infrastructure (データアクセス層)

**役割**: 外部システムとの通信

**責務**:
- API通信の実行
- データベースアクセス
- ローカルストレージ操作
- 外部サービス連携

**制約**:
- ビジネスロジックを含めない
- UIに関する処理を含めない
- データの加工は最小限に

**依存関係**:
- 外部ライブラリ(Supabase, Firebase, etc.)

**実装例**:
```dart
class SupabaseApiClient {
  SupabaseApiClient(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchPosts() async {
    final response = await _client
        .from('posts')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createPost({
    required String content,
  }) async {
    final response = await _client
        .from('posts')
        .insert({'content': content})
        .select()
        .single();
    return response;
  }

  Future<void> deletePost({required String postId}) async {
    await _client.from('posts').delete().eq('id', postId);
  }
}
```

---

### 5. Model (データモデル層)

**役割**: データ構造の定義

**責務**:
- ドメインモデルの定義
- UIステートの定義
- データのバリデーション
- JSON変換

**制約**:
- ビジネスロジックを含めない(純粋なデータ構造)
- Freezedを使用してイミュータブルに

**実装例**:
```dart
// ドメインモデル
@freezed
class Post with _$Post {
  const factory Post({
    required String id,
    required String content,
    required String userId,
    required DateTime createdAt,
  }) = _Post;

  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
}

// UIステート
@freezed
class HomeUiState with _$HomeUiState {
  const factory HomeUiState.loading() = _Loading;
  const factory HomeUiState.success({
    required List<Post> posts,
  }) = _Success;
  const factory HomeUiState.error({
    required String message,
  }) = _Error;
}
```

---

### 6. Provider (依存性注入層)

**役割**: インスタンスの提供と依存関係の管理

**責務**:
- ViewModelの提供
- Repositoryの提供
- Infrastructureの提供
- 依存関係の解決

**実装例**:
```dart
// Infrastructure Provider
@riverpod
SupabaseApiClient supabaseApiClient(SupabaseApiClientRef ref) {
  return SupabaseApiClient(Supabase.instance.client);
}

// Repository Provider
@riverpod
PostRepository postRepository(PostRepositoryRef ref) {
  final apiClient = ref.watch(supabaseApiClientProvider);
  return PostRepositoryImpl(apiClient);
}

// ViewModel Provider (自動生成)
@riverpod
class HomeViewModel extends _$HomeViewModel {
  // ...
}
```

---

### 7. Component (UI部品層)

**役割**: 再利用可能なUIコンポーネント

**責務**:
- 共通UI部品の提供
- UIの一貫性の担保

**制約**:
- ビジネスロジックを含めない
- 状態管理は最小限に(親から受け取る)

**実装例**:
```dart
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.onPressed,
    required this.label,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? CircularProgressIndicator()
          : Text(label),
    );
  }
}
```

---

### 8. Router (画面遷移層)

**役割**: 画面遷移の管理

**責務**:
- 画面遷移ロジックの集約
- ルーティング設定
- 画面間のデータ受け渡し

**制約**:
- ビジネスロジックを含めない
- ViewModelから直接呼び出さない(Viewから呼び出す)

**実装例**:
```dart
class AppRouter {
  static void toHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeView()),
    );
  }

  static void toPostDetail(BuildContext context, {required String postId}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostDetailView(postId: postId),
      ),
    );
  }

  static void back(BuildContext context) {
    Navigator.of(context).pop();
  }
}
```

---

### 9. Constant (定数層)

**役割**: アプリ全体で使用する定数の管理

**責務**:
- 色の定義
- サイズ・マージンの定義
- 文言の定義
- URLの定義
- 設定値の定義

**実装例**:
```dart
// colors.dart
class AppColors {
  static const primary = Color(0xFF2196F3);
  static const secondary = Color(0xFF03DAC6);
  static const error = Color(0xFFB00020);
}

// strings.dart
class AppStrings {
  static const appName = 'SNS App';
  static const homeTitle = 'ホーム';
  static const loginButton = 'ログイン';
}

// dimens.dart
class AppDimens {
  static const paddingSmall = 8.0;
  static const paddingMedium = 16.0;
  static const paddingLarge = 24.0;
}
```

---

### 10. UI Core (UI共通機能層)

**役割**: UI関連の共通ユーティリティ

**責務**:
- フォーマット処理(日付、数値など)
- バリデーション
- 入力値の整形

**実装例**:
```dart
class DateFormatter {
  static String format(DateTime dateTime) {
    return DateFormat('yyyy/MM/dd HH:mm').format(dateTime);
  }
}

class InputValidator {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'メールアドレスを入力してください';
    }
    if (!value.contains('@')) {
      return '正しいメールアドレスを入力してください';
    }
    return null;
  }
}
```

---

### 11. Core (アプリケーションコア層)

**役割**: アプリ全体で使用する基盤機能

**責務**:
- ロガー
- 型変換(Converter)
- エラーハンドリング
- 拡張機能

**実装例**:
```dart
class Logger {
  static void debug(String message) {
    debugPrint('[DEBUG] $message');
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[ERROR] $message');
    if (error != null) debugPrint('Error: $error');
    if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
  }
}

class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();

  @override
  DateTime fromJson(Timestamp timestamp) {
    return timestamp.toDate();
  }

  @override
  Timestamp toJson(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }
}
```

---

## データフロー

```
User Input (View)
    ↓
ViewModel (UIイベント処理)
    ↓
Repository (ビジネスロジック実行)
    ↓
Infrastructure (データ取得/更新)
    ↓
API/DB (外部システム)
    ↓
Infrastructure (レスポンス受信)
    ↓
Repository (ドメインモデル変換)
    ↓
ViewModel (UIステート更新)
    ↓
View (UI再描画)
```

---

## テスト戦略

### Unit Test 対象
- ViewModel: UIステート管理ロジック
- Repository: ビジネスロジック
- Model: データ変換・バリデーション
- UI Core: ユーティリティ関数

### Widget Test 対象
- View: UI表示・ユーザー操作
- Component: 再利用部品

### Integration Test 対象
- エンドツーエンドのユーザーフロー

---

## 命名規則

### ファイル名
- View: `{screen_name}_view.dart`
- ViewModel: `{screen_name}_view_model.dart`
- Repository: `{domain}_repository.dart`
- Model: `{entity_name}.dart`
- Provider: `{entity_name}_provider.dart`

### クラス名
- View: `{ScreenName}View`
- ViewModel: `{ScreenName}ViewModel`
- Repository Interface: `{Domain}Repository`
- Repository Implementation: `{Domain}RepositoryImpl`
- Model: `{EntityName}`
- UIState: `{ScreenName}UiState`

---

## 実装のベストプラクティス

### 1. 単一責任の原則
各クラスは1つの責務のみを持つ

### 2. 依存性の逆転
上位レイヤーは下位レイヤーのインターフェースに依存する

### 3. イミュータブル
Freezedを使用してデータクラスをイミュータブルに保つ

### 4. エラーハンドリング
各レイヤーで適切にエラーをハンドリングし、ユーザーフレンドリーなメッセージを提供

### 5. テスタビリティ
モックを容易にするため、インターフェースを定義する

---

## まとめ

本アーキテクチャは以下の利点を提供します:

- **保守性**: 責務が明確で変更の影響範囲が限定的
- **テスタビリティ**: 各レイヤーを独立してテスト可能
- **スケーラビリティ**: 機能追加が容易
- **可読性**: 一貫した構造で理解しやすい

各レイヤーの役割を理解し、適切に実装することで、高品質なFlutterアプリケーションを構築できます。