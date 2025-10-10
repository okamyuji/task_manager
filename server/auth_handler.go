package main

import (
	"encoding/json"
	"net/http"

	"github.com/google/uuid"
)

// AuthHandler 認証関連のハンドラー
type AuthHandler struct{}

// 簡易的なユーザーストア（本番環境ではデータベースを使用）
var users = map[string]*User{
	"test@example.com": {
		ID:       "user-1",
		Email:    "test@example.com",
		Password: "password123", // 本番環境ではハッシュ化すべき
		Name:     "テストユーザー",
	},
}

// HandleLogin ログイン処理
func (h *AuthHandler) HandleLogin(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		logger.Warn("不正なHTTPメソッド", "method", r.Method, "path", r.URL.Path)
		respondWithError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		logger.Warn("リクエストボディのパースエラー", "error", err)
		respondWithError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	logger.Info("ログイン試行", "email", req.Email)

	// ユーザー検証
	user, exists := users[req.Email]
	if !exists || user.Password != req.Password {
		logger.Warn("ログイン失敗: 認証情報が無効", "email", req.Email)
		respondWithError(w, http.StatusUnauthorized, "Invalid email or password")
		return
	}

	// トークン生成
	accessToken, err := GenerateAccessToken(user.ID, user.Email)
	if err != nil {
		logger.Error("アクセストークン生成エラー", "error", err, "user_id", user.ID)
		respondWithError(w, http.StatusInternalServerError, "Failed to generate access token")
		return
	}

	refreshToken, err := GenerateRefreshToken(user.ID, user.Email)
	if err != nil {
		logger.Error("リフレッシュトークン生成エラー", "error", err, "user_id", user.ID)
		respondWithError(w, http.StatusInternalServerError, "Failed to generate refresh token")
		return
	}

	logger.Info("ログイン成功",
		"user_id", user.ID,
		"email", user.Email,
	)

	// レスポンス
	response := AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		UserID:       user.ID,
	}

	respondWithJSON(w, http.StatusOK, response)
}

// HandleRegister ユーザー登録処理
func (h *AuthHandler) HandleRegister(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		logger.Warn("不正なHTTPメソッド", "method", r.Method, "path", r.URL.Path)
		respondWithError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	var req RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		logger.Warn("リクエストボディのパースエラー", "error", err)
		respondWithError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	logger.Info("ユーザー登録試行", "email", req.Email, "name", req.Name)

	// ユーザー重複チェック
	if _, exists := users[req.Email]; exists {
		logger.Warn("ユーザー登録失敗: ユーザーが既に存在", "email", req.Email)
		respondWithError(w, http.StatusConflict, "User already exists")
		return
	}

	// 新規ユーザー作成
	userID := uuid.New().String()
	user := &User{
		ID:       userID,
		Email:    req.Email,
		Password: req.Password, // 本番環境ではハッシュ化すべき
		Name:     req.Name,
	}
	users[req.Email] = user

	logger.Info("新規ユーザー作成完了", "user_id", userID, "email", req.Email)

	// トークン生成
	accessToken, err := GenerateAccessToken(user.ID, user.Email)
	if err != nil {
		logger.Error("アクセストークン生成エラー", "error", err, "user_id", user.ID)
		respondWithError(w, http.StatusInternalServerError, "Failed to generate access token")
		return
	}

	refreshToken, err := GenerateRefreshToken(user.ID, user.Email)
	if err != nil {
		logger.Error("リフレッシュトークン生成エラー", "error", err, "user_id", user.ID)
		respondWithError(w, http.StatusInternalServerError, "Failed to generate refresh token")
		return
	}

	logger.Info("ユーザー登録成功", "user_id", user.ID, "email", user.Email)

	// レスポンス
	response := AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		UserID:       user.ID,
	}

	respondWithJSON(w, http.StatusCreated, response)
}

// HandleRefresh トークンリフレッシュ処理
func (h *AuthHandler) HandleRefresh(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		logger.Warn("不正なHTTPメソッド", "method", r.Method, "path", r.URL.Path)
		respondWithError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	var req RefreshRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		logger.Warn("リクエストボディのパースエラー", "error", err)
		respondWithError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	logger.Debug("トークンリフレッシュ試行")

	// リフレッシュトークン検証
	claims, err := VerifyToken(req.RefreshToken)
	if err != nil {
		logger.Warn("リフレッシュトークン検証失敗", "error", err)
		respondWithError(w, http.StatusUnauthorized, "Invalid or expired refresh token")
		return
	}

	// 新しいアクセストークン生成
	accessToken, err := GenerateAccessToken(claims.UserID, claims.Email)
	if err != nil {
		logger.Error("アクセストークン生成エラー", "error", err, "user_id", claims.UserID)
		respondWithError(w, http.StatusInternalServerError, "Failed to generate access token")
		return
	}

	logger.Info("トークンリフレッシュ成功", "user_id", claims.UserID, "email", claims.Email)

	// レスポンス
	response := RefreshResponse{
		AccessToken: accessToken,
	}

	respondWithJSON(w, http.StatusOK, response)
}
