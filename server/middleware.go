package main

import (
	"encoding/json"
	"log/slog"
	"net/http"
	"strings"
	"time"
)

// loggingMiddleware リクエスト/レスポンスをログに記録するミドルウェア
func loggingMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		// レスポンスラッパーでステータスコードをキャプチャ
		wrapped := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}

		// リクエスト開始ログ
		logger.Debug("リクエスト開始",
			"method", r.Method,
			"path", r.URL.Path,
			"remote_addr", r.RemoteAddr,
			"user_agent", r.UserAgent(),
		)

		next(wrapped, r)

		duration := time.Since(start)

		// リクエスト完了ログ
		logLevel := slog.LevelInfo
		if wrapped.statusCode >= 500 {
			logLevel = slog.LevelError
		} else if wrapped.statusCode >= 400 {
			logLevel = slog.LevelWarn
		}

		logger.Log(r.Context(), logLevel, "リクエスト完了",
			"method", r.Method,
			"path", r.URL.Path,
			"status", wrapped.statusCode,
			"duration_ms", duration.Milliseconds(),
			"remote_addr", r.RemoteAddr,
		)
	}
}

// responseWriter ステータスコードをキャプチャするためのラッパー
type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

// corsMiddleware CORSヘッダーを追加するミドルウェア
func corsMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// CORSヘッダーを設定
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, PATCH, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		w.Header().Set("Access-Control-Max-Age", "3600")

		// プリフライトリクエストの処理
		if r.Method == http.MethodOptions {
			logger.Debug("CORSプリフライトリクエスト",
				"origin", r.Header.Get("Origin"),
				"method", r.Header.Get("Access-Control-Request-Method"),
			)
			w.WriteHeader(http.StatusNoContent)
			return
		}

		next(w, r)
	}
}

// authMiddleware JWT認証を行うミドルウェア
func authMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Authorizationヘッダーからトークンを取得
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			logger.Warn("認証ヘッダーが見つかりません",
				"path", r.URL.Path,
				"remote_addr", r.RemoteAddr,
			)
			respondWithError(w, http.StatusUnauthorized, "Authorization header required")
			return
		}

		// "Bearer "プレフィックスを削除
		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		if tokenString == authHeader {
			logger.Warn("無効な認証形式",
				"path", r.URL.Path,
				"remote_addr", r.RemoteAddr,
			)
			respondWithError(w, http.StatusUnauthorized, "Invalid authorization format")
			return
		}

		// トークン検証
		claims, err := VerifyToken(tokenString)
		if err != nil {
			logger.Warn("トークン検証失敗",
				"error", err,
				"path", r.URL.Path,
				"remote_addr", r.RemoteAddr,
			)
			respondWithError(w, http.StatusUnauthorized, "Invalid or expired token")
			return
		}

		logger.Debug("認証成功",
			"user_id", claims.UserID,
			"email", claims.Email,
			"path", r.URL.Path,
		)

		// クレームをコンテキストに追加（簡易実装のためヘッダーに設定）
		r.Header.Set("X-User-ID", claims.UserID)
		r.Header.Set("X-User-Email", claims.Email)

		next(w, r)
	}
}

// respondWithJSON JSON形式でレスポンスを返す
func respondWithJSON(w http.ResponseWriter, statusCode int, payload interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(payload)
}

// respondWithError エラーレスポンスを返す
func respondWithError(w http.ResponseWriter, statusCode int, message string) {
	respondWithJSON(w, statusCode, ErrorResponse{Message: message})
}
