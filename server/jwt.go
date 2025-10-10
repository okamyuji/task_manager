package main

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"
)

// JWT秘密鍵（本番環境では環境変数から読み込むべき）
var jwtSecret = []byte("your-256-bit-secret-key-change-this-in-production")

// JWTClaims JWTのペイロード
type JWTClaims struct {
	UserID string `json:"userId"`
	Email  string `json:"email"`
	Exp    int64  `json:"exp"` // 有効期限（Unix timestamp）
	Iat    int64  `json:"iat"` // 発行時刻（Unix timestamp）
}

// GenerateAccessToken アクセストークンを生成（15分有効）
func GenerateAccessToken(userID, email string) (string, error) {
	logger.Debug("アクセストークン生成開始", "user_id", userID)
	return generateToken(userID, email, 15*time.Minute)
}

// GenerateRefreshToken リフレッシュトークンを生成（7日有効）
func GenerateRefreshToken(userID, email string) (string, error) {
	logger.Debug("リフレッシュトークン生成開始", "user_id", userID)
	return generateToken(userID, email, 7*24*time.Hour)
}

// generateToken JWTトークンを生成
func generateToken(userID, email string, expiration time.Duration) (string, error) {
	now := time.Now()
	claims := JWTClaims{
		UserID: userID,
		Email:  email,
		Exp:    now.Add(expiration).Unix(),
		Iat:    now.Unix(),
	}

	// ヘッダー
	header := map[string]string{
		"alg": "HS256",
		"typ": "JWT",
	}

	headerJSON, err := json.Marshal(header)
	if err != nil {
		logger.Error("JWTヘッダーのマーシャルエラー", "error", err)
		return "", err
	}

	// ペイロード
	claimsJSON, err := json.Marshal(claims)
	if err != nil {
		logger.Error("JWTクレームのマーシャルエラー", "error", err)
		return "", err
	}

	// Base64エンコード
	headerEncoded := base64.RawURLEncoding.EncodeToString(headerJSON)
	claimsEncoded := base64.RawURLEncoding.EncodeToString(claimsJSON)

	// 署名
	message := headerEncoded + "." + claimsEncoded
	signature := createSignature(message, jwtSecret)

	// トークン生成
	token := message + "." + signature

	logger.Debug("JWTトークン生成成功",
		"user_id", userID,
		"expiration_minutes", expiration.Minutes(),
	)

	return token, nil
}

// VerifyToken トークンを検証してクレームを返す
func VerifyToken(tokenString string) (*JWTClaims, error) {
	// トークンを分割
	parts := strings.Split(tokenString, ".")
	if len(parts) != 3 {
		logger.Debug("トークンフォーマットエラー", "parts_count", len(parts))
		return nil, errors.New("invalid token format")
	}

	headerEncoded := parts[0]
	claimsEncoded := parts[1]
	signatureEncoded := parts[2]

	// 署名検証
	message := headerEncoded + "." + claimsEncoded
	expectedSignature := createSignature(message, jwtSecret)

	if signatureEncoded != expectedSignature {
		logger.Warn("JWT署名検証失敗")
		return nil, errors.New("invalid signature")
	}

	// クレームをデコード
	claimsJSON, err := base64.RawURLEncoding.DecodeString(claimsEncoded)
	if err != nil {
		logger.Warn("クレームデコードエラー", "error", err)
		return nil, fmt.Errorf("failed to decode claims: %w", err)
	}

	var claims JWTClaims
	if err := json.Unmarshal(claimsJSON, &claims); err != nil {
		logger.Warn("クレームアンマーシャルエラー", "error", err)
		return nil, fmt.Errorf("failed to unmarshal claims: %w", err)
	}

	// 有効期限チェック
	now := time.Now().Unix()
	if now > claims.Exp {
		logger.Debug("トークン期限切れ",
			"exp", claims.Exp,
			"now", now,
			"user_id", claims.UserID,
		)
		return nil, errors.New("token expired")
	}

	logger.Debug("トークン検証成功", "user_id", claims.UserID, "email", claims.Email)
	return &claims, nil
}

// createSignature 署名を作成
func createSignature(message string, secret []byte) string {
	h := hmac.New(sha256.New, secret)
	h.Write([]byte(message))
	signature := h.Sum(nil)
	return base64.RawURLEncoding.EncodeToString(signature)
}
