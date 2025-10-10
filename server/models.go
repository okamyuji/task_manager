package main

import (
	"sync"
	"time"
)

// Task タスクモデル
type Task struct {
	ID          string     `json:"id"`
	UserID      string     `json:"userId"` // タスクの所有者
	Title       string     `json:"title"`
	Description string     `json:"description"`
	CreatedAt   time.Time  `json:"createdAt"`
	DueDate     *time.Time `json:"dueDate,omitempty"`
	IsCompleted bool       `json:"isCompleted"`
	CompletedAt *time.Time `json:"completedAt,omitempty"`
	Tags        []string   `json:"tags"`
	Priority    string     `json:"priority"` // low, medium, high, urgent
}

// TaskStore タスクのインメモリストア
type TaskStore struct {
	Tasks map[string]*Task
	Mutex *sync.RWMutex
}

// User ユーザーモデル
type User struct {
	ID       string `json:"id"`
	Email    string `json:"email"`
	Password string `json:"-"` // JSONには含めない
	Name     string `json:"name"`
}

// LoginRequest ログインリクエスト
type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

// RegisterRequest 登録リクエスト
type RegisterRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
	Name     string `json:"name"`
}

// AuthResponse 認証レスポンス
type AuthResponse struct {
	AccessToken  string `json:"accessToken"`
	RefreshToken string `json:"refreshToken"`
	UserID       string `json:"userId"`
}

// RefreshRequest トークンリフレッシュリクエスト
type RefreshRequest struct {
	RefreshToken string `json:"refreshToken"`
}

// RefreshResponse トークンリフレッシュレスポンス
type RefreshResponse struct {
	AccessToken string `json:"accessToken"`
}

// ErrorResponse エラーレスポンス
type ErrorResponse struct {
	Message string `json:"message"`
}

// UploadResponse 画像アップロードレスポンス
type UploadResponse struct {
	URL string `json:"url"`
}
