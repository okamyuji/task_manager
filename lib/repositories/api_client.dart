import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/constants/app_constants.dart';
import '../core/interceptors/auth_interceptor.dart';
import '../models/task.dart';

part 'api_client.g.dart';

/// Dioインスタンスのプロバイダー
@riverpod
Dio dio(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.apiTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.apiTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // 認証インターセプターを追加（最初に追加）
  dio.interceptors.add(AuthInterceptor(dio));

  // ログインターセプターを追加
  dio.interceptors.add(
    LogInterceptor(requestBody: true, responseBody: true, error: true),
  );

  return dio;
}

/// APIクライアントのプロバイダー
@riverpod
ApiClient apiClient(Ref ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
}

/// タスク管理APIクライアント
@RestApi()
abstract class ApiClient {
  factory ApiClient(Dio dio, {String? baseUrl}) = _ApiClient;

  /// タスク一覧を取得
  @GET('/tasks')
  Future<List<Task>> getTasks();

  /// タスクを取得
  @GET('/tasks/{id}')
  Future<Task> getTask(@Path('id') String id);

  /// タスクを作成
  @POST('/tasks')
  Future<Task> createTask(@Body() Task task);

  /// タスクを更新
  @PUT('/tasks/{id}')
  Future<Task> updateTask(@Path('id') String id, @Body() Task task);

  /// タスクを削除
  @DELETE('/tasks/{id}')
  Future<void> deleteTask(@Path('id') String id);

  /// タスクの完了状態を更新
  @PATCH('/tasks/{id}/complete')
  Future<Task> completeTask(@Path('id') String id);

  /// タスクの未完了状態に戻す
  @PATCH('/tasks/{id}/incomplete')
  Future<Task> incompleteTask(@Path('id') String id);

  /// メールアドレスと認証コードでアカウントを認証
  @POST('/auth/verify')
  Future<HttpResponse<dynamic>> verifyEmail(@Body() Map<String, dynamic> body);

  /// 認証コードを再送信
  @POST('/auth/resend-code')
  Future<HttpResponse<dynamic>> resendVerificationCode(
    @Body() Map<String, dynamic> body,
  );
}
