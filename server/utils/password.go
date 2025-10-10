package utils

import (
	"fmt"

	"golang.org/x/crypto/bcrypt"
)

const (
	// bcryptコスト係数（12 = 2^12回のハッシュ処理）
	bcryptCost = 12
)

// HashPassword パスワードをbcryptでハッシュ化
func HashPassword(password string) (string, error) {
	hashedBytes, err := bcrypt.GenerateFromPassword([]byte(password), bcryptCost)
	if err != nil {
		return "", fmt.Errorf("パスワードハッシュ化失敗: %w", err)
	}
	return string(hashedBytes), nil
}

// ComparePassword パスワードとハッシュを比較
func ComparePassword(hashedPassword, password string) error {
	err := bcrypt.CompareHashAndPassword([]byte(hashedPassword), []byte(password))
	if err != nil {
		return fmt.Errorf("パスワードが一致しません")
	}
	return nil
}
