import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/auth_service.dart';

part 'auth_provider.freezed.dart';
part 'auth_provider.g.dart';

/// 認証状態
@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState({
    @Default(false) bool isAuthenticated,
    @Default(false) bool isLoading,
    String? userId,
    String? errorMessage,
  }) = _AuthState;
}

/// 認証状態プロバイダー
@riverpod
class Auth extends _$Auth {
  @override
  Future<AuthState> build() async {
    final authService = ref.watch(authServiceProvider);
    final isAuthenticated = await authService.isAuthenticated();
    final userId = await authService.getUserId();

    return AuthState(isAuthenticated: isAuthenticated, userId: userId);
  }

  /// ログイン
  Future<void> login(String email, String password) async {
    state = AsyncValue.data(
      (state.value ?? const AuthState()).copyWith(isLoading: true),
    );

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.login(email, password);

      state = AsyncValue.data(
        AuthState(
          isAuthenticated: true,
          userId: result['userId'] as String,
          isLoading: false,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(
        AuthState(
          isAuthenticated: false,
          isLoading: false,
          errorMessage: e.toString(),
        ),
      );
      rethrow;
    }
  }

  /// 登録
  Future<void> register(String email, String password, String name) async {
    state = AsyncValue.data(
      (state.value ?? const AuthState()).copyWith(isLoading: true),
    );

    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.register(email, password, name);

      state = AsyncValue.data(
        AuthState(
          isAuthenticated: true,
          userId: result['userId'] as String,
          isLoading: false,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(
        AuthState(
          isAuthenticated: false,
          isLoading: false,
          errorMessage: e.toString(),
        ),
      );
      rethrow;
    }
  }

  /// ログアウト
  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.logout();

    state = const AsyncValue.data(AuthState(isAuthenticated: false));
  }
}
