# Task Manager

Flutter + Riverpod + Golang REST APIによるタスク管理アプリケーション

**サーバーサイド（Golang REST API）**: <https://github.com/okamyuji/task-manager-server>

## 目次

- [プロジェクト構成](#プロジェクト構成)
- [技術スタック](#技術スタック)
- [クイックスタート](#クイックスタート)
- [アーキテクチャ](#アーキテクチャ)
  - [ネットワークリトライ機能](#ネットワークリトライ機能)
- [トラブルシューティング](#トラブルシューティング)

---

## プロジェクト構成

```shell
task_manager/
├── lib/                     # Flutter アプリケーション
│   ├── main.dart
│   ├── models/              # データモデル (Freezed)
│   ├── providers/           # 状態管理 (Riverpod)
│   ├── repositories/        # データ層
│   ├── services/            # ビジネスロジック
│   ├── screens/             # UI画面
│   └── widgets/             # 再利用可能ウィジェット
│
└── test/                    # テストコード
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

サーバーサイドは別リポジトリで管理しています: <https://github.com/okamyuji/task-manager-server>

---

## クイックスタート

### 1. 依存関係のインストール

```bash
# Flutter SDKのインストール確認
flutter --version

# プロジェクトの依存関係を取得
flutter pub get

# コード生成を実行
dart run build_runner build --delete-conflicting-outputs
```

### 2. API接続先の設定

アプリは自動的にプラットフォームに応じたAPI接続先を設定します：

| プラットフォーム | デフォルトURL | 説明 |
|--------------|-------------|-----|
| Android エミュレーター | `http://10.0.2.2:8080` | ホストマシンの`localhost`へのアクセス |
| iOS シミュレーター | `http://192.168.0.16:8080` | ローカルネットワークIP |
| Android 実機 | `http://192.168.0.16:8080` | ローカルネットワークIP |
| Web / Desktop | `http://localhost:8080` | ローカルホスト |

#### API_HOSTのカスタマイズ

Android実機やiOS実機で動作させる場合、ビルド時に`API_HOST`を指定できます：

```bash
# PCのIPアドレスを確認
ifconfig | grep "inet " | grep -v 127.0.0.1
# 例: inet 192.168.0.16

# API_HOSTを指定してビルド
flutter run --dart-define=API_HOST=192.168.0.16
```

### 3. アプリの起動

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

# アプリ起動
flutter run
```

**注意**: API接続は自動的に`http://10.0.2.2:8080`に設定されます。

#### Android実機で起動

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

実機でAPIサーバーに接続する場合、ビルド時にPCのIPアドレスを指定してください。

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

#### 複数デバイスがある場合

```bash
# デバイス一覧を表示
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
```

### 5. iOSセットアップ

iOSアプリでカメラや写真ライブラリを使用するため、必要な権限設定が追加されています。

#### Info.plistの権限設定

`ios/Runner/Info.plist`に以下の権限説明が設定されています。

```xml
<key>NSCameraUsageDescription</key>
<string>タスクに画像を添付するためにカメラを使用します</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>タスクに画像を添付するためにフォトライブラリにアクセスします</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>撮影した画像をフォトライブラリに保存します</string>
```

#### 権限の説明

| 権限キー | 用途 | 必要なタイミング |
|---------|------|----------------|
| `NSCameraUsageDescription` | カメラでの撮影 | 「カメラ」ボタンをタップ時 |
| `NSPhotoLibraryUsageDescription` | 写真の選択 | 「ギャラリー」ボタンをタップ時 |
| `NSPhotoLibraryAddUsageDescription` | 写真の保存 | カメラで撮影後に保存する場合 |

#### iOSシミュレーターでの実行

```bash
# シミュレーター一覧確認
xcrun simctl list devices available

# アプリ起動（デフォルトデバイス）
flutter run

# 特定のシミュレーター指定
flutter run -d "iPhone 15 Pro"
```

**注意事項:**

- シミュレーターではカメラ機能は動作しません（写真ライブラリからの選択のみ可能）
- 実機でテストする場合は、Apple Developerアカウントと適切なプロビジョニングプロファイルが必要です

#### iOS実機でのテスト

```bash
# 接続されているiOSデバイスを確認
flutter devices

# 実機にインストールして実行
flutter run -d <device-id>

# リリースビルド（署名が必要）
flutter build ios --release
```

#### CocoaPodsの更新

依存関係の問題が発生した場合：

```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
flutter clean
flutter pub get
```

---

## アーキテクチャ

### プロジェクト構造

```shell
lib/
├── main.dart                         # アプリケーションエントリーポイント
├── app.dart                          # MaterialApp設定
├── core/                             # コア機能
│   ├── constants/
│   │   └── app_constants.dart        # API URL等の定数
│   ├── theme/
│   │   └── app_theme.dart            # テーマ設定
│   ├── utils/
│   │   ├── logger.dart               # ログユーティリティ
│   │   └── date_formatter.dart       # 日付フォーマット
│   └── interceptors/
│       └── retry_interceptor.dart    # HTTPリトライ処理
├── models/                           # データモデル
│   ├── task.dart                     # Task (freezed)
│   ├── task_hive.dart                # HiveAdapter
│   └── *.g.dart / *.freezed.dart    # 自動生成ファイル
├── providers/                        # 状態管理
│   ├── auth_provider.dart            # 認証状態
│   ├── task_provider.dart            # タスク状態
│   └── image_upload_provider.dart    # 画像アップロード状態
├── repositories/                     # データアクセス層
│   └── api_client.dart               # Retrofit APIクライアント
├── services/                         # ビジネスロジック
│   ├── auth_service.dart             # 認証サービス
│   └── image_cache_service.dart      # 画像キャッシュ
├── screens/                          # 画面
│   ├── home_screen.dart              # ホーム画面
│   ├── login_screen.dart             # ログイン
│   ├── register_screen.dart          # ユーザー登録
│   ├── verification_screen.dart      # メール認証
│   ├── task_list_screen.dart         # タスク一覧
│   ├── add_task_screen.dart          # タスク追加
│   ├── edit_task_screen.dart         # タスク編集
│   ├── task_detail_screen.dart       # タスク詳細
│   ├── image_picker_screen.dart      # 画像選択
│   └── filter_bottom_sheet.dart      # フィルタ
└── widgets/                          # 再利用可能ウィジェット
    ├── task_card.dart                # タスクカード
    ├── animated_task_card.dart       # アニメーション付きカード
    ├── swipeable_task_card.dart      # スワイプ可能カード
    ├── cached_image.dart             # キャッシュ付き画像
    ├── completion_particles.dart     # 完了エフェクト
    └── error_banner.dart             # エラー表示
```

### 状態管理 (Riverpod)

#### 主要プロバイダー

```dart
// 認証状態
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>

// タスク一覧
final taskProvider = StateNotifierProvider<TaskNotifier, AsyncValue<List<Task>>>

// 画像アップロード
final imageUploadProvider = StateNotifierProvider<ImageUploadNotifier, ImageUploadState>
```

### ネットワークリトライ機能

アプリケーションには自動的にネットワークエラーをリトライする仕組みが組み込まれています。

#### RetryInterceptor の仕様

**対象エラー:**

- 接続エラー（`DioExceptionType.connectionError`）
- タイムアウト（`DioExceptionType.connectionTimeout`, `DioExceptionType.sendTimeout`, `DioExceptionType.receiveTimeout`）
- HTTP 5xxエラー（サーバーエラー）

**リトライしないエラー:**

- HTTP 4xxエラー（クライアントエラー: 400, 401, 403, 404など）
- キャンセルされたリクエスト

**リトライ戦略:**

- **最大リトライ回数**: 3回（初回含めて最大4回の試行）
- **バックオフ戦略**: 指数関数的増加
  - 1回目: 1秒待機
  - 2回目: 2秒待機
  - 3回目: 4秒待機

**実装:**

```dart
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration initialDelay;

  RetryInterceptor({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_shouldRetry(err) && _getRetryCount(err) < maxRetries) {
      final delay = _calculateDelay(_getRetryCount(err));
      await Future.delayed(delay);
      return _retry(err, handler);
    }
    handler.next(err);
  }
}
```

**使用例:**

```dart
// Dioインスタンスに自動的に組み込まれています
final dio = Dio()
  ..interceptors.add(RetryInterceptor());

// APIクライアント経由で使用
final apiClient = ApiClient(dio);
```

**ログ出力例:**

```text
[RetryInterceptor] リトライ 1/3 (GET /tasks) 1秒後に再試行
[RetryInterceptor] リトライ 2/3 (GET /tasks) 2秒後に再試行
[RetryInterceptor] リトライ 3/3 (GET /tasks) 4秒後に再試行
[RetryInterceptor] 最大リトライ回数に達しました (GET /tasks)
```

**カスタマイズ:**

```dart
// リトライ回数と初期遅延をカスタマイズ
final dio = Dio()
  ..interceptors.add(RetryInterceptor(
    maxRetries: 5,
    initialDelay: Duration(milliseconds: 500),
  ));
```

---

## トラブルシューティング

### Flutter関連

#### 依存関係エラー

```bash
# パッケージキャッシュをクリア
flutter pub cache clean
flutter clean
flutter pub get
```

#### コード生成エラー

```bash
# 既存の生成ファイルを削除して再生成
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
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

  デフォルトで`http://10.0.2.2:8080`に自動設定されます。以下で確認してください。

  ```dart
  // lib/core/constants/app_constants.dart
  static String get baseUrl => 'http://10.0.2.2:8080';
  ```

  - 解決策2: サーバーが起動しているか確認

  ```bash
  curl http://localhost:8080/health
  ```

  - 解決策3: Androidエミュレーターから接続テスト

  ```bash
  adb shell
  curl http://10.0.2.2:8080/health
  ```

#### Android実機からの接続エラー

- 症状: `SocketException: OS Error: Connection refused`
  - 解決策1: PCとAndroid実機が同じWi-Fiに接続されているか確認
  - 解決策2: PCのIPアドレスを確認し、`API_HOST`で指定してビルド

  ```bash
  # PCのIPアドレスを確認
  ifconfig | grep "inet " | grep -v 127.0.0.1
  # 例: inet 192.168.0.16

  # API_HOSTを指定してビルド
  flutter run --dart-define=API_HOST=192.168.0.16
  ```

  - 解決策3: ファイアウォールでポート8080が開放されているか確認

  ```bash
  # macOSの場合
  # システム設定 > ネットワーク > ファイアウォール > オプション
  # で "Go APIサーバー" の着信接続を許可
  ```

  - 解決策4: サーバーが`0.0.0.0`でリッスンしているか確認

  `localhost`ではなく`0.0.0.0`でリッスンする必要があります。

#### iOS Simulatorからの接続

デフォルトで`http://192.168.0.16:8080`に自動設定されます。

接続できない場合:

```bash
# シミュレーターからPCのlocalhostにアクセス
# （PCのローカルIPで接続）
curl http://192.168.0.16:8080/health
```

### 認証関連エラー

#### トークンの有効期限切れ

アクセストークンの有効期限は15分です。期限切れの場合は`POST /auth/refresh`でトークンを更新してください。

アプリ側では自動的にリフレッシュトークンを使用してトークンを更新します。

#### ログインできない

- 解決策1: メール認証が完了しているか確認
- 解決策2: パスワードが正しいか確認（最低8文字、英数字を含む）
- 解決策3: サーバーログを確認

### 画像関連エラー

#### 画像がアップロードできない

- 解決策1: カメラ/写真ライブラリの権限が許可されているか確認
  - iOS: 設定 > プライバシーとセキュリティ > カメラ/写真
  - Android: 設定 > アプリ > Task Manager > 権限
- 解決策2: 画像サイズが大きすぎないか確認（推奨: 10MB以下）
- 解決策3: ネットワーク接続を確認

#### 画像が表示されない

- 解決策1: ネットワーク接続を確認
- 解決策2: キャッシュをクリア

```bash
# アプリデータをクリア
# iOS: アプリを長押し → 削除 → 再インストール
# Android: 設定 > アプリ > Task Manager > ストレージ > データを削除
```

---

## ライセンス

MIT License

---

## サポート

問題が発生した場合は、以下を確認してください

1. Flutter SDKのバージョン（3.24.0以上）
2. サーバーが起動しているか
3. ネットワーク接続とAPI URL設定
4. 認証トークンの有効期限
5. プラットフォーム固有の権限設定

サーバーサイドの問題については、こちらを参照してください: <https://github.com/okamyuji/task-manager-server>
