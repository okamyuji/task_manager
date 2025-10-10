package main

import (
	"encoding/json"
	"log/slog"
	"net/http"
	"time"

	"task_manager_server/database/repository"
	"task_manager_server/email"
	"task_manager_server/utils"
	"task_manager_server/validation"
)

// AuthHandler 認証関連のハンドラー（リポジトリ版）
type AuthHandlerNew struct {
	userRepo         repository.UserRepository
	verificationRepo repository.VerificationRepository
	emailService     *email.EmailService
	logger           *slog.Logger
}

// NewAuthHandler 認証ハンドラーを作成
func NewAuthHandler(
	userRepo repository.UserRepository,
	verificationRepo repository.VerificationRepository,
	emailService *email.EmailService,
	logger *slog.Logger,
) *AuthHandlerNew {
	return &AuthHandlerNew{
		userRepo:         userRepo,
		verificationRepo: verificationRepo,
		emailService:     emailService,
		logger:           logger,
	}
}

// HandleLogin ログイン処理
func (h *AuthHandlerNew) HandleLogin(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.logger.Warn("不正なHTTPメソッド", "method", r.Method, "path", r.URL.Path)
		respondWithError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.logger.Warn("リクエストボディのパースエラー", "error", err)
		respondWithError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// バリデーション
	if err := validation.ValidateEmail(req.Email); err != nil {
		h.logger.Warn("バリデーションエラー", "error", err)
		respondWithError(w, http.StatusBadRequest, err.Error())
		return
	}

	h.logger.Info("ログイン試行", "email", req.Email)

	// ユーザー取得
	user, err := h.userRepo.GetByEmail(req.Email)
	if err != nil {
		h.logger.Error("ユーザー取得エラー", "error", err)
		respondWithError(w, http.StatusInternalServerError, "Internal server error")
		return
	}
	if user == nil {
		h.logger.Warn("ログイン失敗: ユーザーが存在しません", "email", req.Email)
		respondWithError(w, http.StatusUnauthorized, "Invalid email or password")
		return
	}

	// パスワード検証
	if err := utils.ComparePassword(user.PasswordHash, req.Password); err != nil {
		h.logger.Warn("ログイン失敗: パスワードが無効", "email", req.Email)
		respondWithError(w, http.StatusUnauthorized, "Invalid email or password")
		return
	}

	// 認証確認
	if !user.IsVerified {
		h.logger.Warn("ログイン失敗: 未認証ユーザー", "email", req.Email, "user_id", user.ID)
		respondWithError(w, http.StatusForbidden, "Email not verified. Please verify your email first.")
		return
	}

	// トークン生成
	accessToken, err := GenerateAccessToken(user.ID, user.Email)
	if err != nil {
		h.logger.Error("アクセストークン生成エラー", "error", err, "user_id", user.ID)
		respondWithError(w, http.StatusInternalServerError, "Failed to generate access token")
		return
	}

	refreshToken, err := GenerateRefreshToken(user.ID, user.Email)
	if err != nil {
		h.logger.Error("リフレッシュトークン生成エラー", "error", err, "user_id", user.ID)
		respondWithError(w, http.StatusInternalServerError, "Failed to generate refresh token")
		return
	}

	h.logger.Info("ログイン成功", "user_id", user.ID, "email", user.Email)

	// レスポンス
	response := AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		UserID:       user.ID,
	}

	respondWithJSON(w, http.StatusOK, response)
}

// HandleRegister ユーザー登録処理
func (h *AuthHandlerNew) HandleRegister(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.logger.Warn("不正なHTTPメソッド", "method", r.Method, "path", r.URL.Path)
		respondWithError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	var req RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.logger.Warn("リクエストボディのパースエラー", "error", err)
		respondWithError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// バリデーション
	if err := validation.ValidateEmail(req.Email); err != nil {
		h.logger.Warn("バリデーションエラー", "error", err)
		respondWithError(w, http.StatusBadRequest, err.Error())
		return
	}
	if err := validation.ValidatePassword(req.Password); err != nil {
		h.logger.Warn("バリデーションエラー", "error", err)
		respondWithError(w, http.StatusBadRequest, err.Error())
		return
	}
	if err := validation.ValidateName(req.Name); err != nil {
		h.logger.Warn("バリデーションエラー", "error", err)
		respondWithError(w, http.StatusBadRequest, err.Error())
		return
	}

	h.logger.Info("ユーザー登録試行", "email", req.Email, "name", req.Name)

	// ユーザー重複チェック
	existingUser, err := h.userRepo.GetByEmail(req.Email)
	if err != nil {
		h.logger.Error("ユーザー存在確認エラー", "error", err)
		respondWithError(w, http.StatusInternalServerError, "Internal server error")
		return
	}
	if existingUser != nil {
		h.logger.Warn("ユーザー登録失敗: ユーザーが既に存在", "email", req.Email)
		respondWithError(w, http.StatusConflict, "User already exists")
		return
	}

	// パスワードハッシュ化
	passwordHash, err := utils.HashPassword(req.Password)
	if err != nil {
		h.logger.Error("パスワードハッシュ化エラー", "error", err)
		respondWithError(w, http.StatusInternalServerError, "Internal server error")
		return
	}

	// 新規ユーザー作成（未認証状態）
	user := &repository.User{
		Email:        req.Email,
		PasswordHash: passwordHash,
		Name:         req.Name,
		IsVerified:   false,
	}
	if err := h.userRepo.Create(user); err != nil {
		h.logger.Error("ユーザー作成エラー", "error", err)
		respondWithError(w, http.StatusInternalServerError, "Failed to create user")
		return
	}

	h.logger.Info("新規ユーザー作成完了", "user_id", user.ID, "email", req.Email)

	// 認証コード生成（有効期限15分）
	verification, err := h.verificationRepo.Create(user.ID, 15*time.Minute)
	if err != nil {
		h.logger.Error("認証コード生成エラー", "error", err)
		// ユーザーは作成されたが認証コードに失敗
		respondWithError(w, http.StatusInternalServerError, "Failed to generate verification code")
		return
	}

	// 認証コードをメール送信
	if err := h.emailService.SendVerificationCode(user.Email, user.Name, verification.Code); err != nil {
		h.logger.Error("メール送信エラー", "error", err)
		// ユーザーと認証コードは作成されたがメール送信に失敗
		respondWithError(w, http.StatusInternalServerError, "Failed to send verification email")
		return
	}

	h.logger.Info("ユーザー登録成功（未認証）", "user_id", user.ID, "email", user.Email)

	// レスポンス（トークンは発行しない、認証完了後に発行）
	respondWithJSON(w, http.StatusCreated, map[string]interface{}{
		"message": "User created. Please check your email for verification code.",
		"userId":  user.ID,
		"email":   user.Email,
	})
}

// HandleRefresh トークンリフレッシュ処理
func (h *AuthHandlerNew) HandleRefresh(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.logger.Warn("不正なHTTPメソッド", "method", r.Method, "path", r.URL.Path)
		respondWithError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	var req RefreshRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.logger.Warn("リクエストボディのパースエラー", "error", err)
		respondWithError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	h.logger.Debug("トークンリフレッシュ試行")

	// リフレッシュトークン検証
	claims, err := VerifyToken(req.RefreshToken)
	if err != nil {
		h.logger.Warn("リフレッシュトークン検証失敗", "error", err)
		respondWithError(w, http.StatusUnauthorized, "Invalid or expired refresh token")
		return
	}

	// 新しいアクセストークン生成
	accessToken, err := GenerateAccessToken(claims.UserID, claims.Email)
	if err != nil {
		h.logger.Error("アクセストークン生成エラー", "error", err, "user_id", claims.UserID)
		respondWithError(w, http.StatusInternalServerError, "Failed to generate access token")
		return
	}

	h.logger.Info("トークンリフレッシュ成功", "user_id", claims.UserID, "email", claims.Email)

	// レスポンス
	response := RefreshResponse{
		AccessToken: accessToken,
	}

	respondWithJSON(w, http.StatusOK, response)
}
