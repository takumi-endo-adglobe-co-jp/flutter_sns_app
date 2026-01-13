# Flutter SNS アプリ 成果物ドキュメント

## 目次
1. [Supabase作成SQL](#1-supabase作成sql)
2. [設計理由](#2-設計理由)
3. [必要パッケージ一覧](#3-必要パッケージ一覧)
4. [Supabase接続設定手順](#4-supabase接続設定手順)
5. [Flutter WebビルドおよびVercelデプロイ手順](#5-flutter-webビルドおよびvercelデプロイ手順)

---

## 1. Supabase作成SQL

以下のSQLをSupabaseのSQL Editorで実行してください。

```sql
-- Create posts table
CREATE TABLE posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content TEXT NOT NULL CHECK (char_length(content) > 0 AND char_length(content) <= 512),
  likes_count INTEGER NOT NULL DEFAULT 0 CHECK (likes_count >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index for efficient ordering
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);

-- Auto-update updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_posts_updated_at
  BEFORE UPDATE ON posts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Enable RLS and allow all operations (no auth)
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all operations on posts" ON posts
  FOR ALL
  USING (true)
  WITH CHECK (true);
```

### データベーススキーマ説明

**posts テーブル**
- `id`: UUID型の主キー（自動生成）
- `content`: 投稿内容（1-512文字の制約付き）
- `likes_count`: いいね数（0以上の制約付き）
- `created_at`: 作成日時（自動設定）
- `updated_at`: 更新日時（自動更新）

**インデックス**
- `idx_posts_created_at`: created_atの降順インデックス（新しい投稿を高速に取得）

**トリガー**
- `update_posts_updated_at`: UPDATE時にupdated_atを自動更新

**RLS（Row Level Security）**
- すべての操作を許可（認証なしのため）

---

## 2. 設計理由

### 2.1 アーキテクチャ概要

本アプリケーションは、**Flutter + Supabase**を使用したTwitter風SNSアプリです。単一画面構成で、投稿の作成・表示・編集・削除・いいね機能を提供します。

### 2.2 主要な設計決定

#### (1) 状態管理: StatefulWidget + setState

**決定内容**: 複雑な状態管理ライブラリを使用せず、Flutterの標準的な`StatefulWidget`と`setState`を採用。

**理由**:
- 単一画面アプリケーションのため、グローバルな状態管理が不要
- すべての状態が`HomeScreen`内で完結し、状態の流れが明確
- 学習コストが低く、メンテナンスが容易
- 既存のカウンターデモと同じパターンを踏襲

#### (2) いいね管理: SharedPreferences

**決定内容**: いいね状態をローカルストレージ（SharedPreferences）で管理。

**理由**:
- 認証機能がないため、サーバー側でユーザーごとのいいねを管理できない
- ブラウザのlocalStorageに相当する永続化が必要
- アプリ再起動後もいいね状態を保持
- 実装がシンプルで信頼性が高い

**トレードオフ**:
- デバイス/ブラウザが異なると状態が同期されない
- ローカルデータをクリアするといいね状態がリセットされる
- → デモアプリとしては許容範囲

#### (3) 無限スクロール: ScrollController + offset-based pagination

**決定内容**: `ScrollController`で90%スクロール時に次の10件を取得。

**理由**:
- Flutterの標準的なパターンで実装が簡単
- ユーザー体験が良好（スムーズなスクロール）
- Supabaseの`.range()`と相性が良い

**代替案との比較**:
- カーソルベースページネーション: より厳密だが実装が複雑
- → 単純なオフセット方式で十分

#### (4) リアルタイム更新: Supabase Realtime

**決定内容**: PostgresChangeEventを使用して、INSERT/UPDATE/DELETEをリアルタイム反映。

**理由**:
- 複数のクライアント間で投稿の同期が可能
- ユーザー体験が向上（自動更新）
- Supabaseの強力な機能を活用
- 既存のカウンターデモで実績あり

#### (5) プロジェクト構造: レイヤー分離

**決定内容**:
```
lib/
├── models/          # データモデル
├── services/        # ビジネスロジック層
├── screens/         # UI画面
└── widgets/         # 再利用可能なコンポーネント
```

**理由**:
- 関心の分離（Separation of Concerns）
- テスタビリティの向上
- 保守性・拡張性の向上
- Flutterのベストプラクティスに準拠

#### (6) エラーハンドリング: SnackBar

**決定内容**: エラーメッセージをSnackBarで非侵襲的に表示。

**理由**:
- ユーザーの操作をブロックしない
- 一時的なメッセージに適している
- Flutterの標準的なパターン

#### (7) 楽観的UI更新

**決定内容**: いいね機能では即座にUIを更新し、エラー時はロールバック。

**理由**:
- ユーザー体験の向上（即座のフィードバック）
- ネットワーク遅延の隠蔽
- エラー時のロールバック機能で整合性を保証

### 2.3 セキュリティ考慮事項

**認証なしの設計**:
- 本アプリは認証機能を持たないデモアプリ
- RLSは有効だが、すべての操作を許可
- 本番環境では認証とRLSの適切な設定が必要

**データ検証**:
- クライアント側: 1-512文字のバリデーション
- サーバー側: PostgreSQLのCHECK制約で二重チェック

### 2.4 パフォーマンス最適化

1. **ListView.builder**: 可視範囲のみレンダリング
2. **インデックス**: created_atにインデックスを設定
3. **ページネーション**: 一度に10件ずつ取得
4. **楽観的更新**: ネットワーク待機時間の削減

---

## 3. 必要パッケージ一覧

### dependencies（本番用）

```yaml
dependencies:
  flutter:
    sdk: flutter

  # UI
  cupertino_icons: ^1.0.8

  # Backend
  supabase_flutter: ^2.9.3

  # ローカルストレージ
  shared_preferences: ^2.2.2

  # 環境変数
  flutter_dotenv: ^5.2.1

  # 国際化（日付フォーマット）
  intl: ^0.19.0
```

### dev_dependencies（開発用）

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter

  # Linter
  flutter_lints: ^5.0.0
```

### パッケージの役割

| パッケージ | 役割 |
|-----------|------|
| `supabase_flutter` | Supabaseクライアント、リアルタイム機能 |
| `shared_preferences` | いいね状態の永続化 |
| `flutter_dotenv` | 環境変数の読み込み（.envファイル） |
| `intl` | 日本語の日付フォーマット |
| `cupertino_icons` | iOSスタイルのアイコン |
| `flutter_lints` | コード品質チェック |

---

## 4. Supabase接続設定手順

### 4.1 Supabaseプロジェクトの作成

1. [Supabase](https://supabase.com/)にアクセスし、アカウントを作成
2. 「New Project」をクリック
3. プロジェクト名、データベースパスワードを設定
4. リージョンを選択（日本の場合は「Northeast Asia (Tokyo)」推奨）
5. プロジェクトが作成されるまで待機（約2分）

### 4.2 データベースのセットアップ

1. Supabaseダッシュボードで「SQL Editor」を開く
2. 「New Query」をクリック
3. [1. Supabase作成SQL](#1-supabase作成sql)のSQLをコピー&ペースト
4. 「Run」をクリックして実行
5. 「Table Editor」で`posts`テーブルが作成されたことを確認

### 4.3 API認証情報の取得

1. Supabaseダッシュボードで「Settings」→「API」を開く
2. 以下の情報をコピー:
   - **Project URL** (例: `https://xxxxx.supabase.co`)
   - **anon public key** (例: `eyJhbGc...`)

### 4.4 Flutterプロジェクトの設定

1. プロジェクトルートに`.env`ファイルを作成:

```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
```

2. `.env`ファイルに実際の値を設定（上記4.3で取得した値）

3. `.gitignore`に`.env`が含まれていることを確認（機密情報の保護）

```gitignore
# 既に含まれているはず
.env
```

### 4.5 接続テスト

1. 依存関係をインストール:

```bash
flutter pub get
```

2. アプリを起動:

```bash
flutter run -d chrome
```

3. 動作確認:
   - アプリが起動すること
   - 投稿を作成できること
   - リアルタイム更新が動作すること

---

## 5. Flutter WebビルドおよびVercelデプロイ手順

### 5.1 Flutter Webビルド

#### 前提条件

- Flutter SDKがインストール済み
- Webサポートが有効（`flutter config --enable-web`）

#### ビルド手順

1. **プロジェクトのクリーン**

```bash
flutter clean
```

2. **Webビルドの実行**

```bash
flutter build web --release
```

3. **ビルド成果物の確認**

ビルドが成功すると、`build/web/`ディレクトリに以下のファイルが生成されます:
- `index.html`
- `flutter.js`
- `main.dart.js`
- その他のアセット

### 5.2 環境変数の設定（重要）

Flutter Webでは`.env`ファイルがビルドに含まれますが、Vercelでは環境変数を別途設定することを推奨します。

#### オプション1: `.env`ファイルをビルドに含める（簡易）

**注意**: この方法では`.env`がクライアント側に露出するため、本番環境では推奨されません。

1. `.env`ファイルがプロジェクトルートに存在することを確認
2. `pubspec.yaml`で`.env`がassetsに含まれていることを確認:

```yaml
flutter:
  assets:
    - .env
```

3. ビルド実行:

```bash
flutter build web --release
```

#### オプション2: 環境変数をVercelで管理（推奨）

1. `.env`の値をVercelの環境変数に設定（後述）
2. ビルド時に環境変数を注入する設定を追加

### 5.3 Vercelへのデプロイ

#### 方法A: Vercel CLIを使用

1. **Vercel CLIのインストール**

```bash
npm install -g vercel
```

2. **Vercelにログイン**

```bash
vercel login
```

3. **プロジェクトのデプロイ**

```bash
cd build/web
vercel --prod
```

4. プロンプトに従って設定:
   - プロジェクト名を入力
   - デプロイ設定を確認

#### 方法B: GitHub連携（推奨）

1. **GitHubリポジトリの作成**

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/yourusername/flutter-sns-app.git
git push -u origin main
```

2. **Vercelでプロジェクトをインポート**

- [Vercel](https://vercel.com/)にアクセス
- 「New Project」をクリック
- GitHubリポジトリを選択
- 「Import」をクリック

3. **ビルド設定**

Vercelの設定画面で以下を設定:

**Framework Preset**: Other

**Build Command**:
```bash
flutter build web --release
```

**Output Directory**:
```
build/web
```

**Install Command**:
```bash
if cd flutter; then git pull && cd ..; else git clone https://github.com/flutter/flutter.git; fi && flutter/bin/flutter doctor && flutter/bin/flutter pub get
```

4. **環境変数の設定**

Vercelの「Settings」→「Environment Variables」で以下を追加:

| Name | Value |
|------|-------|
| `SUPABASE_URL` | `https://xxxxx.supabase.co` |
| `SUPABASE_ANON_KEY` | `eyJhbGc...` |

5. **デプロイ実行**

「Deploy」をクリックしてデプロイを開始。

### 5.4 デプロイ後の確認

1. Vercelが提供するURLにアクセス（例: `https://your-app.vercel.app`）
2. 以下を確認:
   - アプリが正常に表示される
   - 投稿の作成・編集・削除が動作する
   - いいね機能が動作する
   - リアルタイム更新が動作する

### 5.5 カスタムドメインの設定（オプション）

1. Vercelダッシュボードで「Settings」→「Domains」を開く
2. カスタムドメインを追加
3. DNS設定を更新（Vercelの指示に従う）
4. SSL証明書が自動的に発行される

### 5.6 トラブルシューティング

#### 問題1: 「.env file not found」エラー

**解決策**:
- Vercelの環境変数が正しく設定されているか確認
- ビルド時に`.env`が含まれているか確認

#### 問題2: Supabaseに接続できない

**解決策**:
- ブラウザのコンソールでエラーを確認
- SUPABASE_URLとSUPABASE_ANON_KEYが正しいか確認
- SupabaseのRLS設定を確認（allow-allポリシーが設定されているか）

#### 問題3: リアルタイム更新が動作しない

**解決策**:
- Supabaseダッシュボードで「Database」→「Replication」を確認
- `posts`テーブルのReplicationが有効になっているか確認
- ブラウザがWebSocketをサポートしているか確認

#### 問題4: ビルドが失敗する

**解決策**:
```bash
flutter clean
flutter pub get
flutter build web --release --verbose
```

詳細なエラーログを確認し、依存関係の問題を解決。

---

## 付録A: プロジェクト構造

```
flutter_sns_app/
├── lib/
│   ├── main.dart                    # エントリーポイント
│   ├── models/
│   │   └── post.dart                # Postデータモデル
│   ├── services/
│   │   ├── supabase_service.dart    # Supabase CRUD操作
│   │   └── like_storage_service.dart # いいね永続化
│   ├── screens/
│   │   └── home_screen.dart         # メイン画面
│   └── widgets/
│       ├── post_card.dart           # 投稿表示カード
│       ├── edit_post_card.dart      # 編集モードカード
│       └── post_input.dart          # 新規投稿入力
├── web/                             # Web固有ファイル
├── pubspec.yaml                     # 依存関係定義
├── .env                             # 環境変数（Git管理外）
└── .gitignore                       # Git除外設定
```

---

## 付録B: 主要機能の実装詳細

### 投稿表示（無限スクロール）

- `ScrollController`で90%スクロール時に`_loadMorePosts()`を呼び出し
- 10件ずつページネーション（offset-based）
- `ListView.builder`で効率的にレンダリング

### 投稿作成

- `PostInput`ウィジェットで入力
- 1-512文字のクライアント側バリデーション
- `SupabaseService.createPost()`でINSERT
- リアルタイムイベントで自動的にリストに追加

### 投稿編集

- `_editingPostId`で編集中の投稿を管理
- `EditPostCard`ウィジェットでインライン編集
- 保存時に`SupabaseService.updatePost()`でUPDATE
- キャンセル時は`_editingPostId`をnullに設定

### 投稿削除

- 確認ダイアログ（AlertDialog）を表示
- 確認後に`SupabaseService.deletePost()`でDELETE
- リアルタイムイベントで自動的にリストから削除

### いいね機能

- `LikeStorageService`でローカル状態を管理
- 楽観的UI更新（即座にUIを更新）
- `SupabaseService.incrementLikes()`/`decrementLikes()`でDBを更新
- エラー時はロールバック

### リアルタイム更新

- `subscribeToPostChanges()`でPostgresChangeEventを購読
- INSERT: リストの先頭に追加
- UPDATE: 該当投稿を更新
- DELETE: 該当投稿を削除

---

## 付録C: テストチェックリスト

### 基本機能テスト
- [ ] アプリ起動時に投稿一覧が表示される
- [ ] 新規投稿を作成できる
- [ ] 投稿が新しい順に表示される
- [ ] 投稿を編集できる
- [ ] 編集をキャンセルできる
- [ ] 投稿を削除できる（確認ダイアログ付き）
- [ ] いいねボタンが動作する（トグル）

### バリデーションテスト
- [ ] 0文字の投稿は作成できない
- [ ] 512文字の投稿は作成できる
- [ ] 513文字以上は入力できない
- [ ] 編集で0文字にするとエラーが表示される

### 無限スクロールテスト
- [ ] 下にスクロールすると次の10件が読み込まれる
- [ ] すべての投稿を表示した後、追加読み込みが停止する

### リアルタイムテスト
- [ ] 2つのウィンドウで開き、一方で投稿すると他方にも表示される
- [ ] 一方で編集すると他方にも反映される
- [ ] 一方で削除すると他方からも削除される

### 永続化テスト
- [ ] いいねを付けてページをリロードしても状態が保持される

### エラーハンドリングテスト
- [ ] ネットワークエラー時に適切なメッセージが表示される

---

## まとめ

本ドキュメントでは、Flutter + Supabaseを使用したSNSアプリの実装に関するすべての情報を提供しました。

- **Supabase SQL**: postsテーブルの作成とRLS設定
- **設計理由**: 各技術選択の根拠と トレードオフ
- **パッケージ**: 必要な依存関係とその役割
- **接続設定**: Supabaseプロジェクトのセットアップ手順
- **デプロイ**: Flutter WebビルドとVercelへのデプロイ方法

このアプリは単一画面のシンプルな構成ですが、リアルタイム更新、無限スクロール、楽観的UI更新など、現代的なWebアプリケーションのパターンを実装しています。

今後の拡張としては、認証機能の追加、画像アップロード、コメント機能、検索機能などが考えられます。
