import 'package:dio/dio.dart';

/// ネットワークエラー時に自動的にリトライするインターセプター
///
/// 一時的なネットワーク問題（タイムアウト、接続エラーなど）が発生した場合、
/// 指定された回数まで自動的にリクエストを再試行します。
class RetryInterceptor extends Interceptor {
  /// 最大リトライ回数
  final int maxRetries;

  /// リトライ間の待機時間
  final Duration retryDelay;

  /// バックオフ戦略を使用するか（リトライごとに待機時間を増やす）
  final bool useExponentialBackoff;

  RetryInterceptor({
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.useExponentialBackoff = true,
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final extra = err.requestOptions.extra;
    final retries = extra['retries'] ?? 0;

    // リトライ可能かチェック
    if (retries < maxRetries && _shouldRetry(err)) {
      // バックオフ戦略による待機時間の計算
      final delay = useExponentialBackoff
          ? retryDelay * (retries + 1)
          : retryDelay;

      await Future.delayed(delay);

      // リトライカウントを更新
      err.requestOptions.extra['retries'] = retries + 1;

      try {
        // 元のリクエストを再実行
        // 注: このインターセプターを追加したDioインスタンスを使用する必要がある
        final response = await Dio().fetch(err.requestOptions);
        return handler.resolve(response);
      } on DioException catch (e) {
        // リトライも失敗した場合、エラーハンドラーへ渡す
        return super.onError(e, handler);
      } catch (e) {
        // 予期しないエラーの場合、元のエラーを返す
        return handler.next(err);
      }
    }

    // リトライ不可またはリトライ上限に達した場合
    handler.next(err);
  }

  /// リトライすべきエラーかどうかを判定
  ///
  /// 以下の場合にリトライを行います：
  /// - 接続タイムアウト
  /// - 受信タイムアウト
  /// - 接続エラー（ネットワーク不通など）
  /// - 送信タイムアウト
  ///
  /// 以下の場合はリトライしません：
  /// - 認証エラー（401, 403）
  /// - クライアントエラー（400, 404など）
  /// - サーバーエラー（5xx）でもビジネスロジックエラー
  bool _shouldRetry(DioException err) {
    // タイムアウトやネットワークエラーの場合のみリトライ
    final shouldRetryByType =
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError;

    // HTTPステータスコードによる判定
    // 502, 503, 504 のような一時的なサーバーエラーはリトライ
    final statusCode = err.response?.statusCode;
    final shouldRetryByStatus =
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504 ||
        statusCode == 408; // Request Timeout

    return shouldRetryByType || shouldRetryByStatus;
  }
}
