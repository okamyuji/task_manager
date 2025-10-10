# Task Manager

Flutter + Riverpod + Golang REST APIによるタスク管理アプリケーション

## 目次

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
- **対応プラットフォーム**: iOS 12.0+, Android 5.0+ (API 21+), Web, macOS 10.14+
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

### オプションA: Docker Compose（推奨）

#### 前提条件

- Docker Engine 20.10以上
- Docker Compose v2.0以上

#### 起動手順

```bash
# 環境変数ファイルを作成
cp env.example .env

# .envファイルを編集（本番環境用の値を設定）
# JWT_SECRET: 強力なランダム文字列に変更
# ALLOWED_ORIGINS: 許可するドメインを指定（開発環境では*でOK）

# Dockerコンテナを起動
docker compose up -d

# ログを確認
docker compose logs -f
```

#### サービスURL

- **APIサーバー**: `http://localhost:8080`
- **MailHog WebUI**: `http://localhost:8025`（メール確認用）

#### コンテナ管理

```bash
# 停止（データは保持）
docker compose stop

# 停止 + コンテナ削除（データは保持）
docker compose down

# 停止 + 全データ削除
docker compose down -v
```

#### データの永続化

以下のディレクトリにデータが保存されます：

- `./data/` - SQLiteデータベース
- `./server/uploads/` - アップロード画像

#### トラブルシューティング

**ポート競合の場合:**

`compose.yaml`を編集してポートを変更：

```yaml
services:
  api:
    ports:
      - "8081:8080"  # ホスト側ポート変更
```

**ビルドエラーの場合:**

```bash
docker compose build --no-cache
docker compose up -d
```

**データベースリセット:**

```bash
docker compose down
rm -f data/tasks.db*
docker compose up -d
```

### オプションB: ローカル実行

#### 1. サーバー起動

```bash
# サーバーディレクトリに移動
cd server

# 依存関係インストール
go mod tidy

# サーバー起動（ポート8080）
go run .
```

**注意**: ローカル実行時はメール認証機能が動作しません（MailHogが必要）。

### 2. Flutter アプリ設定

`lib/core/constants/app_constants.dart`を編集する

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

#### 共通手順（iOS/Android共通）

```bash
# 依存関係インストール
flutter pub get

# コード生成
flutter pub run build_runner build --delete-conflicting-outputs
```

#### iOS/iOSシミュレーターで起動

```bash
# iOSシミュレーター一覧確認
xcrun simctl list devices available

# アプリ起動（デフォルトデバイス）
flutter run

# 特定のシミュレーター指定
flutter run -d "iPhone 15 Pro"
```

**注意**: API接続は自動的に`http://192.168.0.16:8080`に設定されます。

#### Androidエミュレーターで起動

```bash
# エミュレーター起動（Android Studio経由推奨）
# または: emulator -avd <AVD名>

# アプリ起動（デフォルトエミュレーター）
flutter run

# 特定のエミュレーター指定
flutter run -d <device-id>
```

**注意**: API接続は自動的に`http://10.0.2.2:8080`に設定されます（エミュレーターからホストマシンのlocalhostにアクセス）。

#### Android実機で起動

```bash
# USB接続してデバッグモードを有効化

# 実機が認識されているか確認
flutter devices

# 環境変数でAPIホストを指定して起動
flutter run --dart-define=API_HOST=192.168.0.16
```

**前提条件:**

- PCとAndroid実機が**同じWi-Fiネットワーク**に接続されている
- PCのファイアウォールで**ポート8080**が開放されている
- サーバーが`0.0.0.0:8080`でリッスンしている（`localhost`ではなく）

**ファイアウォール設定（macOS）:**

```bash
# ポート8080を開放（一時的）
# システム設定 > ネットワーク > ファイアウォール > オプション
# で "Go APIサーバー" の着信接続を許可

# または: pfctlで設定
sudo pfctl -f /etc/pf.conf
```

#### デバイス確認

```bash
# 接続中のデバイス一覧
flutter devices

# 出力例:
# iPhone 15 Pro (simulator)      • iOS 17.2
# Pixel 7 (mobile)               • android-arm64
# macOS (desktop)                • darwin-arm64
```

#### API接続先の動作確認

アプリのログインエラーが発生する場合、以下で接続をテスト：

```bash
# Android実機から（PCのターミナルで）
adb shell
curl http://192.168.0.16:8080/health

# Androidエミュレーターから
adb shell
curl http://10.0.2.2:8080/health
```

### 4. Android APKビルドとインストール

開発中のアプリをAPKファイルとしてビルドし、実機にインストールする方法です。

#### 基本的なビルドとインストール

```bash
# 1. リリースAPKをビルド
flutter build apk --release

# 2. USB接続したAndroidデバイスにインストール
adb install build/app/outputs/flutter-apk/app-release.apk

# または、ワンライナーで実行
flutter build apk --release && adb install build/app/outputs/flutter-apk/app-release.apk
```

#### API_HOSTを指定してビルド（実機用）

実機でAPIサーバーに接続する場合、ビルド時にPCのIPアドレスを指定：

```bash
# 1. PCのIPアドレスを確認
ifconfig | grep "inet " | grep -v 127.0.0.1
# 例: inet 192.168.0.16

# 2. API_HOSTを指定してビルド
flutter build apk --release --dart-define=API_HOST=192.168.0.16

# 3. インストール（既存アプリを上書き）
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

#### Split APK（サイズ最適化）

ABIごとに分割ビルドすることで、APKサイズを50%削減できます：

```bash
# ABIごとに分割ビルド
flutter build apk --split-per-abi --release --dart-define=API_HOST=192.168.0.16

# 生成されるAPK:
# app-arm64-v8a-release.apk     (約15-20MB、最新端末向け)
# app-armeabi-v7a-release.apk   (約15-20MB、古い端末向け)
# app-x86_64-release.apk        (エミュレーター向け)

# デバイスに合ったAPKをインストール（ほとんどの最新端末はarm64-v8a）
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

#### デバッグAPKのビルド

開発中の動作確認用（ホットリロード不可）：

```bash
# デバッグAPKをビルド
flutter build apk --debug

# インストール
adb install build/app/outputs/flutter-apk/app-debug.apk
```

#### 複数デバイスが接続されている場合

```bash
# 接続デバイス一覧確認
adb devices

# 出力例:
# List of devices attached
# emulator-5554       device
# R58M123ABCD         device

# 特定デバイスを指定してインストール
adb -s R58M123ABCD install -r build/app/outputs/flutter-apk/app-release.apk
```

#### APKインストール後の動作確認

```bash
# アプリを起動
adb shell am start -n com.example.task_manager/.MainActivity

# アプリのログを確認
adb logcat | grep flutter

# API接続テスト（アプリ内から）
adb shell
curl http://192.168.0.16:8080/health
```

#### トラブルシューティング

**既存アプリとの競合エラー:**

```bash
# エラー: INSTALL_FAILED_UPDATE_INCOMPATIBLE
# 解決: 既存アプリを削除してからインストール
adb uninstall com.example.task_manager
adb install build/app/outputs/flutter-apk/app-release.apk
```

**容量不足エラー:**

```bash
# エラー: INSTALL_FAILED_INSUFFICIENT_STORAGE
# 解決: デバイスの空き容量を確認
adb shell df -h
```

**デバイスが認識されない:**

```bash
# adbサーバー再起動
adb kill-server
adb start-server
adb devices

# USBデバッグが有効か確認
# Android端末: 設定 > 開発者向けオプション > USBデバッグ
```

#### ビルドサイズ比較

| ビルドタイプ | APKサイズ | 用途 |
|------------|---------|------|
| `--debug` | 約40-50MB | 開発・デバッグ用 |
| `--release` | 約20-30MB | 本番・配布用 |
| `--split-per-abi` | 約15-20MB/ABI | サイズ最適化版 |

#### 実機テスト推奨ワークフロー

```bash
# 1. Docker Composeでサーバー起動
docker compose up -d

# 2. PCのIPアドレス確認
ifconfig | grep "inet " | grep -v 127.0.0.1

# 3. ファイアウォールでポート8080を開放（macOS）
# システム設定 > ネットワーク > ファイアウォール > オプション

# 4. API_HOSTを指定してビルド
flutter build apk --release --dart-define=API_HOST=192.168.0.16

# 5. APKをインストール
adb install -r build/app/outputs/flutter-apk/app-release.apk

# 6. アプリを起動して接続テスト
adb shell am start -n com.example.task_manager/.MainActivity
```

### 5. ユーザー登録とログイン

#### 新規ユーザー登録（メール認証あり）

1. アプリで「新規登録」をタップ
2. 名前、メールアドレス、パスワードを入力
   - パスワードは8文字以上、英数字を含む必要があります
3. 登録ボタンをクリック
4. メール認証画面が表示されます
5. MailHog WebUI (`http://localhost:8025`) で認証コードを確認
6. 6桁の認証コードを入力
7. 認証完了後、ログイン画面に戻る
8. メールアドレスとパスワードでログイン

#### テストユーザー（既に認証済み）

```text
Email: test@example.com
Password: password123
```

このユーザーは初期データとして既に認証済みです。

---

## サーバーAPI仕様

### 認証エンドポイント

#### ユーザー登録（メール認証フロー）

**ステップ1: ユーザー登録:**

```http
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "StrongPass123",
  "name": "ユーザー名"
}
```

レスポンス（未認証状態）:

```json
{
  "message": "User created. Please check your email for verification code.",
  "userId": "uuid",
  "email": "user@example.com"
}
```

**ステップ2: メール認証:**

```http
POST /auth/verify
Content-Type: application/json

{
  "email": "user@example.com",
  "code": "123456"
}
```

レスポンス:

```json
{
  "message": "Verification successful",
  "userId": "uuid"
}
```

**ステップ3: ログイン:**

認証完了後、通常のログインが可能になります。

#### 認証コード再送信

```http
POST /auth/resend-code
Content-Type: application/json

{
  "email": "user@example.com"
}
```

レスポンス:

```json
{
  "message": "Verification code sent"
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

すべてのタスクエンドポイントには`Authorization`ヘッダーが必要です

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

**注意**: 最新版では`app_constants.dart`がプラットフォーム自動判定するため、基本的に手動変更は不要です。

#### Android エミュレータからの接続エラー

- 症状: `SocketException: Failed to connect`

    - 解決策1: 自動設定の確認

    デフォルトで`http://10.0.2.2:8080`に自動設定されます。以下で確認：

    ```bash
    # アプリのログ確認
    flutter run --verbose | grep apiBaseUrl
    ```

    - 解決策2: サーバーが起動しているか確認

    ```bash
    # エミュレーター内から接続テスト
    adb shell
    curl http://10.0.2.2:8080/health
    ```

    エラーが出る場合:

    - Docker Composeでサーバーが起動しているか確認: `docker compose ps`
    - ローカル実行の場合、`0.0.0.0:8080`でリッスンしているか確認

    - 解決策3: エミュレーターのネットワークリセット

    ```bash
    # エミュレーター再起動
    adb reboot

    # または: 完全再起動
    # Android Studio > AVD Manager > エミュレーター削除 → 再作成
    ```

#### Android実機からの接続エラー

**症状**: `SocketException: Network is unreachable`

**チェックリスト:**

1. **同じWi-Fiネットワークに接続しているか確認**

    ```bash
    # PCのIPアドレス確認
    ifconfig | grep "inet "
    # 例: inet 192.168.0.16
    
    # Android実機のIPアドレス確認
    # 設定 > ネットワークとインターネット > Wi-Fi > 詳細
    # 例: 192.168.0.42 → 同じサブネット（192.168.0.x）であること
    ```

2. **ファイアウォールでポート8080を開放**

    **macOS:**

    ```bash
    # システム設定 > ネットワーク > ファイアウォール > オプション
    # "Go APIサーバー" または "Docker" の着信接続を許可
    
    # または: 一時的に無効化（テスト用のみ）
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off
    ```

    **Windows:**

    ```powershell
    # PowerShellで実行（管理者権限）
    netsh advfirewall firewall add rule name="Go API" dir=in action=allow protocol=TCP localport=8080
    ```

3. **サーバーが0.0.0.0でリッスンしているか確認**

    Docker Composeの場合は自動的に`0.0.0.0:8080`でリッスンします。

    ローカル実行の場合、`server/main.go`を確認：

    ```go
    http.ListenAndServe("0.0.0.0:8080", mux) // ✓ 正しい
    // http.ListenAndServe("localhost:8080", mux) // ✗ 実機から接続不可
    ```

4. **実機からAPIホストを指定して起動**

    ```bash
    # PCのIPアドレスを環境変数で指定
    flutter run --dart-define=API_HOST=192.168.0.16
    ```

5. **接続テスト**

    ```bash
    # Android実機のブラウザで以下にアクセス
    http://192.168.0.16:8080/health
    
    # または: adb経由でテスト
    adb shell
    curl http://192.168.0.16:8080/health
    ```

#### Android特有のHTTPエラー

**症状**: `Cleartext HTTP traffic not permitted`

**原因**: Android 9以降、デフォルトでHTTPSのみ許可されています。

**解決策**: `AndroidManifest.xml`に以下が設定されているか確認（最新版では自動設定済み）：

```xml
<application
    android:usesCleartextTraffic="true">
```

#### Androidパーミッションエラー

**症状**: 画像アップロードやカメラが動作しない

**解決策**: `AndroidManifest.xml`に以下が設定されているか確認（最新版では自動設定済み）：

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

#### iOS Simulatorからの接続

デフォルトで`http://192.168.0.16:8080`に自動設定されます。

接続できない場合:

```bash
# シミュレーターからPCのlocalhostにアクセス
# （PCのローカルIPで接続）
curl http://192.168.0.16:8080/health
```

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

このスクリプトは以下を自動テストします

- ユーザー登録
- ログイン
- タスク一覧取得
- タスク作成・更新・削除
- タスク完了・未完了
- トークンリフレッシュ

---

## セキュリティに関する注意

### 実装済みセキュリティ機能 ✅

このプロジェクトには以下のセキュリティ機能が実装されています：

1. ✅ **パスワードのハッシュ化（bcrypt）**
   - bcrypt（コスト係数12）によるパスワードハッシュ化
   - `golang.org/x/crypto/bcrypt`使用

2. ✅ **JWT秘密鍵の環境変数化**
   - `JWT_SECRET`環境変数から読み込み
   - デフォルト値は開発環境用のみ

3. ✅ **レート制限の実装**
   - 認証エンドポイント: 5 req/min per IP
   - タスクAPI: 60 req/min per user
   - アップロード: 10 req/min per user
   - Token Bucketアルゴリズム使用

4. ✅ **SQLite3データベース**
   - インメモリからSQLite3に移行
   - マイグレーション管理（golang-migrate）
   - トランザクション対応

5. ✅ **入力バリデーション強化**
   - メールフォーマット検証（正規表現）
   - パスワード強度検証（8文字以上、英数字含む）
   - タスクデータバリデーション

6. ✅ **本番対応CORS設定**
   - `ALLOWED_ORIGINS`環境変数によるホワイトリスト
   - `Access-Control-Allow-Credentials`対応
   - 開発環境では`*`許可

7. ✅ **メール認証システム**
   - ユーザー登録時の6桁認証コード送信
   - 認証コード有効期限（15分）
   - 認証コード再送信機能

8. ✅ **ログとモニタリング（slog実装済み）**

9. ✅ **JWT認証とユーザー認可（実装済み）**
   - アクセストークン（15分）
   - リフレッシュトークン（7日）
   - ユーザーごとのリソースアクセス制御

10. ✅ **prepared statementによるSQLインジェクション対策**

### 本番環境で追加対応が必要な項目 ⚠️

1. ❗ **HTTPSの使用**
   - Leapcellなどのホスティングサービスで対応
   - または Nginx/Caddy でリバースプロキシ

2. ❗ **本番用SMTPサーバー**
   - 現在はMailHog（開発用）
   - SendGrid、AWS SES、Gmail SMTP等に切り替え

3. ❗ **定期的なバックアップ**
   - SQLiteデータベースの定期バックアップ
   - アップロード画像のバックアップ

### 実装済みのセキュリティ機能

#### クライアント側（Flutter）

- **JWTトークンの安全な削除**: ログアウト時に`FlutterSecureStorage`から全てのトークン（access/refresh/userId）を削除
- **自動トークンリフレッシュ**: `AuthInterceptor`が401エラーを検知して自動的にトークンをリフレッシュ
- **セキュアストレージ**: `flutter_secure_storage`による暗号化保存

```dart
// lib/services/auth_service.dart
Future<void> logout() async {
  await _storage.delete(key: _accessTokenKey);
  await _storage.delete(key: _refreshTokenKey);
  await _storage.delete(key: _userIdKey);
}
```

#### サーバー側（Go）

- **ユーザー認可**: 全タスク操作で所有者チェックを実施
- **JWT検証**: `authMiddleware`でトークンを検証し、ユーザーIDをコンテキストに設定
- **リソースアクセス制御**: ユーザーは自分のタスクのみにアクセス可能

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

- 全6テスト成功
- 静的解析エラーなし

---

## 本番環境への展開

### 環境変数の設定

本番環境では以下を**必ず**設定してください：

```env
# 強力なランダム文字列（256ビット推奨）
JWT_SECRET=your-super-secret-production-key-here

# 許可するドメインを明示的に指定（カンマ区切り）
ALLOWED_ORIGINS=https://yourdomain.com,https://app.yourdomain.com

# 本番用SMTPサーバー
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
MAIL_FROM=noreply@yourdomain.com

# デバッグモードはOFF
DEBUG=false
```

### SMTPサーバーの切り替え

本番環境ではMailHogの代わりに実際のSMTPサーバーを使用：

**推奨サービス:**

- SendGrid
- AWS SES
- Gmail SMTP（テスト用）
- Mailgun

### HTTPSの有効化

#### オプション1: Leapcell等のホスティングサービス

自動的にHTTPSが有効化されます。

#### オプション2: Nginx リバースプロキシ

```yaml
# compose.yaml に追加
services:
  nginx:
    image: nginx:alpine
    ports:
      - "443:443"
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - api
```

### データベースのバックアップ

定期的にバックアップを実施：

```bash
# データベースバックアップ
docker compose exec api sqlite3 /app/data/tasks.db ".backup /app/data/backup.db"

# ホストにコピー
docker compose cp api:/app/data/backup.db ./backups/tasks_$(date +%Y%m%d).db

# cronで自動化（例: 毎日2時）
0 2 * * * cd /path/to/task_manager && docker compose exec api sqlite3 /app/data/tasks.db ".backup /app/data/backup.db"
```

### よくある質問

- Q: MailHogで送信されたメールが見つからない

A: MailHog WebUI (`http://localhost:8025`) にアクセスして確認してください。メールはメモリに保存されるため、コンテナを再起動すると消えます。

- Q: データベースの場所は？

A: `./data/tasks.db` に保存されています。SQLiteブラウザで直接開くことも可能です。

- Q: レート制限を変更したい

A: `server/middleware/rate_limiter.go` の `InitRateLimiters` 関数を編集して再ビルドしてください。

---

## 今後の拡張

### Phase 2: データベーススケーリング

- PostgreSQL / MySQL移行
- レプリケーション
- コネクションプーリング最適化

### Phase 3: キャッシング

- Redis統合
- クエリ結果キャッシュ
- セッション管理

### Phase 4: 高度な機能

- WebSocket（リアルタイム更新）
- GraphQL API
- バックグラウンドジョブ処理
- プッシュ通知

### Phase 5: 運用機能

- ログローテーション
- メトリクス収集（Prometheus）
- アラート設定
- 自動バックアップ

---

## ライセンス

MIT License

---

## サポート

問題が発生した場合は、以下を確認してください

1. Goのバージョン（1.25.0以上）
2. Flutterのバージョン（3.24.0以上）
3. ポートの競合（8080番ポート）
4. ネットワーク設定（ファイアウォール）
5. アクセストークンの有効期限
