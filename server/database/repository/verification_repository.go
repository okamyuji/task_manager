package repository

import (
	"crypto/rand"
	"database/sql"
	"fmt"
	"math/big"
	"time"
)

// VerificationCode 認証コードモデル
type VerificationCode struct {
	ID        int64
	UserID    string
	Code      string
	ExpiresAt time.Time
	CreatedAt time.Time
	Used      bool
}

// VerificationRepository 認証コードリポジトリインターフェース
type VerificationRepository interface {
	Create(userID string, expiresIn time.Duration) (*VerificationCode, error)
	GetByUserIDAndCode(userID, code string) (*VerificationCode, error)
	MarkAsUsed(id int64) error
	DeleteExpired() error
	DeleteByUserID(userID string) error
}

type verificationRepository struct {
	db *sql.DB
}

// NewVerificationRepository 認証コードリポジトリを作成
func NewVerificationRepository(db *sql.DB) VerificationRepository {
	return &verificationRepository{db: db}
}

// Create 新しい認証コードを生成
func (r *verificationRepository) Create(userID string, expiresIn time.Duration) (*VerificationCode, error) {
	// 6桁のランダムコード生成
	code, err := generateVerificationCode()
	if err != nil {
		return nil, fmt.Errorf("認証コード生成失敗: %w", err)
	}

	verification := &VerificationCode{
		UserID:    userID,
		Code:      code,
		ExpiresAt: time.Now().Add(expiresIn),
		CreatedAt: time.Now(),
		Used:      false,
	}

	query := `
		INSERT INTO verification_codes (user_id, code, expires_at, created_at, used)
		VALUES (?, ?, ?, ?, ?)
	`
	result, err := r.db.Exec(query, verification.UserID, verification.Code, verification.ExpiresAt, verification.CreatedAt, verification.Used)
	if err != nil {
		return nil, fmt.Errorf("認証コード保存失敗: %w", err)
	}

	id, err := result.LastInsertId()
	if err != nil {
		return nil, err
	}
	verification.ID = id

	return verification, nil
}

// GetByUserIDAndCode ユーザーIDとコードで認証コードを取得
func (r *verificationRepository) GetByUserIDAndCode(userID, code string) (*VerificationCode, error) {
	verification := &VerificationCode{}
	query := `
		SELECT id, user_id, code, expires_at, created_at, used
		FROM verification_codes
		WHERE user_id = ? AND code = ? AND used = FALSE
		ORDER BY created_at DESC
		LIMIT 1
	`
	err := r.db.QueryRow(query, userID, code).Scan(
		&verification.ID,
		&verification.UserID,
		&verification.Code,
		&verification.ExpiresAt,
		&verification.CreatedAt,
		&verification.Used,
	)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("認証コード取得失敗: %w", err)
	}
	return verification, nil
}

// MarkAsUsed 認証コードを使用済みにする
func (r *verificationRepository) MarkAsUsed(id int64) error {
	query := `UPDATE verification_codes SET used = TRUE WHERE id = ?`
	result, err := r.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("認証コード使用済み更新失敗: %w", err)
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return err
	}
	if rows == 0 {
		return fmt.Errorf("認証コードが見つかりません: %d", id)
	}

	return nil
}

// DeleteExpired 期限切れの認証コードを削除
func (r *verificationRepository) DeleteExpired() error {
	query := `DELETE FROM verification_codes WHERE expires_at < ?`
	_, err := r.db.Exec(query, time.Now())
	if err != nil {
		return fmt.Errorf("期限切れ認証コード削除失敗: %w", err)
	}
	return nil
}

// DeleteByUserID ユーザーIDで認証コードを全て削除
func (r *verificationRepository) DeleteByUserID(userID string) error {
	query := `DELETE FROM verification_codes WHERE user_id = ?`
	_, err := r.db.Exec(query, userID)
	if err != nil {
		return fmt.Errorf("認証コード削除失敗: %w", err)
	}
	return nil
}

// generateVerificationCode 6桁のランダムコードを生成
func generateVerificationCode() (string, error) {
	const digits = "0123456789"
	code := make([]byte, 6)
	for i := range code {
		n, err := rand.Int(rand.Reader, big.NewInt(int64(len(digits))))
		if err != nil {
			return "", err
		}
		code[i] = digits[n.Int64()]
	}
	return string(code), nil
}
