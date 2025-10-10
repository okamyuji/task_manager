# Task Manager

Flutter + Riverpod + Golang REST APIによるタスク管理アプリケーション

## 📋 目次

- [プロジェクト構成](#プロジェクト構成)
- [技術スタック](#技術スタック)
- [クイックスタート](#クイックスタート)
- [サーバーAPI仕様](#サーバーapi仕様)
- [アーキテクチャ](#アーキテクチャ)
- [トラブルシューティング](#トラブルシューティング)

---

## プロジェクト構成

```shell
task_manager/
├── lib/                      # Flutter アプリケーション
│   ├── main.dart
│   ├── models/              # データモデル (Freezed)
│   ├── providers/           # 状態管理 (Riverpod)
│   ├── repositories/        # データ層
│   ├── services/            # ビジネスロジック
│   ├── screens/             # UI画面
│   └── widgets/             # 再利用可能ウィジェット
│
├── server/                   # Golang REST APIサーバー
│   ├── main.go              # エントリーポイント
│   ├── models.go            # データモデル
│   ├── jwt.go               # JWT認証
│   ├── middleware.go        # CORS・認証ミドルウェア
│   ├── auth_handler.go      # 認証エンドポイント
│   ├── task_handler.go      # タスク管理エンドポイント
│   ├── upload_handler.go    # 画像アップロード
│   └── uploads/             # アップロード画像保存先
│
└── test/                     # テストコード
```

---

## 技術スタック

### Flutter アプリ

- **Flutter**: 3.24.0+
- **Dart**: 3.5.0+
- **状態管理**: Riverpod 3.0.3
- **HTTP通信**: Dio 5.9.0 + Retrofit 4.7.3
- **ローカルDB**: Hive 2.2.3
- **認証**: JWT + FlutterSecureStorage 9.2.4
- **画像処理**: ImagePicker 1.2.0, CachedNetworkImage 3.4.1

### Golang サーバー

- **Go**: 1.25.0
- **標準ライブラリ**: net/http, encoding/json, crypto/hmac
- **外部依存**: github.com/google/uuid のみ
- **認証**: JWT (HMAC-SHA256)
- **データストア**: インメモリ (開発用)

---

## クイックスタート

### 1. サーバー起動

```bash
# サーバーディレクトリに移動
cd server

# 依存関係インストール
go get github.com/google/uuid
go mod tidy

# サーバー起動（ポート8080）
go run .
```

起動成功時の表示:

```shell
🚀 Task Manager Server 起動しました: http://localhost:8080
📝 利用可能なエンドポイント:
  POST   /auth/login              - ログイン
  POST   /auth/register           - ユーザー登録
  ...
```

### 2. Flutter アプリ設定

`lib/core/constants/app_constants.dart`を編集:

```dart
class AppConstants {
  // ローカル開発
  static const String apiBaseUrl = 'http://localhost:8080';
  
  // iOS Simulator の場合
  // static const String apiBaseUrl = 'http://127.0.0.1:8080';
  
  // Android エミュレータの場合
  // static const String apiBaseUrl = 'http://10.0.2.2:8080';
  
  // 実機テスト（同一ネットワーク）の場合
  // static const String apiBaseUrl = 'http://192.168.x.x:8080';
  
  static const int apiTimeout = 30000;
}
```

### 3. Flutter アプリ起動

```bash
# 依存関係インストール
flutter pub get

# コード生成
flutter pub run build_runner build --delete-conflicting-outputs

# アプリ起動
flutter run
```

### 4. テストユーザーでログイン

```text
Email: test@example.com
Password: password123
```

---

## サーバーAPI仕様

### 認証エンドポイント

#### ユーザー登録

```http
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "name": "ユーザー名"
}
```

レスポンス:

```json
{
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc...",
  "userId": "uuid"
}
```

#### ログイン

```http
POST /auth/login
Content-Type: application/json

{
  "email": "test@example.com",
  "password": "password123"
}
```

#### トークンリフレッシュ

```http
POST /auth/refresh
Content-Type: application/json

{
  "refreshToken": "eyJhbGc..."
}
```

### タスクエンドポイント（要認証）

すべてのタスクエンドポイントには`Authorization`ヘッダーが必要:

```http
Authorization: Bearer {accessToken}
```

- `GET /tasks` - タスク一覧取得
- `POST /tasks` - タスク作成
- `GET /tasks/{id}` - タスク詳細取得
- `PUT /tasks/{id}` - タスク更新
- `DELETE /tasks/{id}` - タスク削除
- `PATCH /tasks/{id}/complete` - タスク完了
- `PATCH /tasks/{id}/incomplete` - タスク未完了

### 画像エンドポイント

```http
POST /upload
Authorization: Bearer {accessToken}
Content-Type: multipart/form-data

image: (binary file, 最大10MB)
```

---

## アーキテクチャ

### システム構成図

```text
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Client App                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │   Auth   │  │  Tasks   │  │  Image   │  │   UI     │   │
│  │ Provider │  │ Provider │  │ Provider │  │ Screens  │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│       ▲              ▲              ▲             ▲          │
│       └──────────────┴──────────────┴─────────────┘          │
│                         HTTP/REST                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Go REST API Server                        │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                   HTTP Router (mux)                  │   │
│  └──────────────────────────────────────────────────────┘   │
│       │                    │                    │            │
│       ▼                    ▼                    ▼            │
│  ┌─────────┐         ┌─────────┐         ┌─────────┐       │
│  │  Auth   │         │  Task   │         │ Upload  │       │
│  │ Handler │         │ Handler │         │ Handler │       │
│  └─────────┘         └─────────┘         └─────────┘       │
│       │                    │                    │            │
│       ▼                    ▼                    ▼            │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                   Middleware Layer                   │   │
│  │  ┌────────────┐              ┌────────────┐         │   │
│  │  │    CORS    │              │    Auth    │         │   │
│  │  │ Middleware │              │ Middleware │         │   │
│  │  └────────────┘              └────────────┘         │   │
│  └──────────────────────────────────────────────────────┘   │
│       │                    │                    │            │
│       ▼                    ▼                    ▼            │
│  ┌─────────┐         ┌─────────┐         ┌─────────┐       │
│  │   JWT   │         │  Task   │         │  File   │       │
│  │ Service │         │  Store  │         │ System  │       │
│  └─────────┘         └─────────┘         └─────────┘       │
│                            │                                 │
│                            ▼                                 │
│                   ┌──────────────────┐                      │
│                   │ In-Memory Store  │                      │
│                   │  (map[string])   │                      │
│                   └──────────────────┘                      │
└─────────────────────────────────────────────────────────────┘
```

### Flutterアプリのレイヤー構成

```text
Presentation Layer (UI)
    ↓ ref.watch/read
Application Layer (Provider/StateNotifier)
    ↓ repository呼び出し
Domain Layer (Models - Freezed)
    ↓ データ変換
Infrastructure Layer (Repository/Service)
    ↓ API/Storage呼び出し
Data Layer (Dio/Hive/SecureStorage)
```

### JWT認証フロー

```text
1. クライアント → POST /auth/login (email, password)
2. サーバー → ユーザー検証
3. サーバー → JWTトークン生成 (HMAC-SHA256)
4. サーバー → クライアント (accessToken: 15分, refreshToken: 7日)
5. クライアント → 以降のリクエストに Authorization: Bearer {token}
6. トークン期限切れ → POST /auth/refresh で更新
```

### データストア

**開発環境（現在の実装）:**

- インメモリストア (`map[string]*Task`)
- サーバー再起動でデータ消失
- 高速・シンプル・外部依存なし

**本番環境への移行:**

- PostgreSQL / MySQL
- Redis（キャッシング）
- マイグレーション管理

---

## トラブルシューティング

### サーバー関連

#### ポートが既に使用されている

```bash
# ポート8080を使用中のプロセスを確認
lsof -i :8080

# プロセスを停止
kill -9 <PID>

# 別のポートで起動
PORT=3000 go run .
```

#### Goモジュールエラー

```bash
# モジュールキャッシュをクリア
go clean -modcache

# 依存関係を再インストール
cd server
rm go.sum
go mod tidy
```

### Flutter アプリ関連

#### コード生成エラー

```bash
# キャッシュクリアと再生成
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

#### Dart Analyzerキャッシュ問題

```bash
# Dartキャッシュクリア
rm -rf .dart_tool/
flutter pub get
# IDEを再起動
```

#### iOS CocoaPodsエラー

```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
```

### 接続エラー

#### Android エミュレータからの接続

`app_constants.dart`:

```dart
static const String apiBaseUrl = 'http://10.0.2.2:8080';
```

#### iOS Simulatorからの接続

```dart
static const String apiBaseUrl = 'http://127.0.0.1:8080';
```

#### 実機からの接続

1. MacのローカルIPを確認:

    ```bash
    ifconfig | grep "inet "
    ```

2. `app_constants.dart`を更新:

    ```dart
    static const String apiBaseUrl = 'http://192.168.x.x:8080';
    ```

3. ファイアウォール設定を確認

### JWT認証エラー

**トークンの有効期限:**

- アクセストークン: 15分
- リフレッシュトークン: 7日

**期限切れの場合:**
`POST /auth/refresh`でトークンを更新してください。

Flutter側では`AuthInterceptor`が自動的に401エラーを検知してトークンをリフレッシュします。

---

## APIテスト

### curlでテスト

```bash
# ログイン
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# タスク一覧取得（要トークン）
curl -X GET http://localhost:8080/tasks \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### テストスクリプトを使用

```bash
cd server
chmod +x test_api.sh
./test_api.sh
```

このスクリプトは以下を自動テスト:

- ✅ ユーザー登録
- ✅ ログイン
- ✅ タスク一覧取得
- ✅ タスク作成・更新・削除
- ✅ タスク完了・未完了
- ✅ トークンリフレッシュ

---

## セキュリティに関する注意

⚠️ このプロジェクトは**開発・学習用**です。本番環境では以下の対応が必要:

1. ❗ パスワードのハッシュ化（bcrypt）
2. ❗ JWT秘密鍵の環境変数化
3. ❗ HTTPSの使用
4. ❗ レート制限の実装
5. ❗ データベースの使用（現在はインメモリ）
6. ❗ 入力バリデーションの強化
7. ✅ ログとモニタリング（slog実装済み）
8. ❗ 適切なCORS設定
9. ✅ JWT認証とユーザー認可（実装済み）

### 実装済みのセキュリティ機能

#### クライアント側（Flutter）

- ✅ **JWTトークンの安全な削除**: ログアウト時に`FlutterSecureStorage`から全てのトークン（access/refresh/userId）を削除
- ✅ **自動トークンリフレッシュ**: `AuthInterceptor`が401エラーを検知して自動的にトークンをリフレッシュ
- ✅ **セキュアストレージ**: `flutter_secure_storage`による暗号化保存

```dart
// lib/services/auth_service.dart
Future<void> logout() async {
  await _storage.delete(key: _accessTokenKey);
  await _storage.delete(key: _refreshTokenKey);
  await _storage.delete(key: _userIdKey);
}
```

#### サーバー側（Go）

- ✅ **ユーザー認可**: 全タスク操作で所有者チェックを実施
- ✅ **JWT検証**: `authMiddleware`でトークンを検証し、ユーザーIDをコンテキストに設定
- ✅ **リソースアクセス制御**: ユーザーは自分のタスクのみにアクセス可能

```go
// server/task_handler.go - 所有者チェックの例
if task.UserID != userID {
    logger.Warn("アクセス権限がありません",
        "task_id", taskID,
        "task_owner", task.UserID,
        "requesting_user", userID,
    )
    respondWithError(w, http.StatusForbidden, "Access denied")
    return
}
```

**保護されているエンドポイント**:

- `GET /tasks` - 自分のタスクのみ取得
- `GET /tasks/{id}` - 自分のタスクのみ取得（403 Forbidden if not owner）
- `POST /tasks` - 自動的に作成者のuserIdを設定
- `PUT /tasks/{id}` - 自分のタスクのみ更新可能
- `DELETE /tasks/{id}` - 自分のタスクのみ削除可能
- `PATCH /tasks/{id}/complete` - 自分のタスクのみ完了可能
- `PATCH /tasks/{id}/incomplete` - 自分のタスクのみ未完了化可能

---

## ログ

サーバーは標準ライブラリの`log/slog`による構造化ログを出力します。

### 通常モード（INFO）

```bash
go run .
```

### デバッグモード

```bash
DEBUG=true go run .
```

### ログ例

```json
{"time":"2025-10-10T11:30:15Z","level":"INFO","msg":"サーバーを起動しました","port":"8080"}
{"time":"2025-10-10T11:30:20Z","level":"INFO","msg":"リクエスト完了","method":"POST","path":"/auth/login","status":200,"duration_ms":45}
{"time":"2025-10-10T11:30:21Z","level":"INFO","msg":"ログイン成功","user_id":"user-1","email":"test@example.com"}
{"time":"2025-10-10T11:30:30Z","level":"WARN","msg":"ログイン失敗: 認証情報が無効","email":"wrong@example.com"}
```

---

## テスト実行

```bash
# Flutterテスト
flutter test

# カバレッジ付きテスト
flutter test --coverage

# 静的解析
flutter analyze
```

**テスト結果:**

- ✅ 16テスト成功
- ✅ 静的解析エラーなし
- ⏭️ 2テストスキップ（統合テストに移行予定）

---

## 今後の拡張

### Phase 2: データベース統合

- PostgreSQL または MySQL
- マイグレーション管理
- トランザクション処理

### Phase 3: キャッシング

- Redis統合
- クエリ結果キャッシュ
- セッション管理

### Phase 4: 高度な機能

- WebSocket（リアルタイム更新）
- GraphQL API
- バックグラウンドジョブ処理
- メール通知

### Phase 5: 運用機能

- ログローテーション
- メトリクス収集（Prometheus）
- アラート設定
- バックアップ・リストア

---

## ライセンス

MIT License

---

## サポート

問題が発生した場合は、以下を確認してください:

1. Goのバージョン（1.25.0以上）
2. Flutterのバージョン（3.24.0以上）
3. ポートの競合（8080番ポート）
4. ネットワーク設定（ファイアウォール）
5. アクセストークンの有効期限
