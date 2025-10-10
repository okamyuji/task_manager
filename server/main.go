package main

import (
	"log/slog"
	"net/http"
	"os"
	"sync"
	"time"
)

var logger *slog.Logger

func main() {
	// 構造化ロガーの初期化
	logLevel := slog.LevelInfo
	if os.Getenv("DEBUG") == "true" {
		logLevel = slog.LevelDebug
	}

	handler := slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level:     logLevel,
		AddSource: true, // ソースコードの位置を含める
	})
	logger = slog.New(handler)
	slog.SetDefault(logger)

	logger.Info("サーバーを初期化中...")

	// データストアの初期化
	store := &TaskStore{
		Tasks: make(map[string]*Task),
		Mutex: &sync.RWMutex{},
	}

	// サンプルデータの追加
	initSampleData(store)
	logger.Info("サンプルデータを初期化しました", "count", len(store.Tasks))

	// ハンドラーの作成
	taskHandler := &TaskHandler{Store: store}
	authHandler := &AuthHandler{}
	uploadHandler := &UploadHandler{}

	// ルーティング設定
	mux := http.NewServeMux()

	// タスク関連エンドポイント（認証必要）
	mux.HandleFunc("/tasks", loggingMiddleware(authMiddleware(corsMiddleware(taskHandler.HandleTasks))))
	mux.HandleFunc("/tasks/", loggingMiddleware(authMiddleware(corsMiddleware(taskHandler.HandleTaskByID))))

	// 認証関連エンドポイント（認証不要）
	mux.HandleFunc("/auth/login", loggingMiddleware(corsMiddleware(authHandler.HandleLogin)))
	mux.HandleFunc("/auth/register", loggingMiddleware(corsMiddleware(authHandler.HandleRegister)))
	mux.HandleFunc("/auth/refresh", loggingMiddleware(corsMiddleware(authHandler.HandleRefresh)))

	// 画像アップロードエンドポイント（認証必要）
	mux.HandleFunc("/upload", loggingMiddleware(authMiddleware(corsMiddleware(uploadHandler.HandleUpload))))

	// 静的ファイル配信（アップロードされた画像）
	mux.Handle("/uploads/", http.StripPrefix("/uploads/", http.FileServer(http.Dir("./uploads"))))

	// アップロードディレクトリの作成
	if err := os.MkdirAll("./uploads", 0755); err != nil {
		logger.Error("アップロードディレクトリの作成に失敗しました", "error", err)
		os.Exit(1)
	}
	logger.Info("アップロードディレクトリを作成しました", "path", "./uploads")

	// サーバー起動
	port := "8080"
	if p := os.Getenv("PORT"); p != "" {
		port = p
	}

	logger.Info("サーバーを起動しました",
		"port", port,
		"endpoints", []string{
			"POST   /auth/login",
			"POST   /auth/register",
			"POST   /auth/refresh",
			"GET    /tasks",
			"POST   /tasks",
			"GET    /tasks/{id}",
			"PUT    /tasks/{id}",
			"DELETE /tasks/{id}",
			"PATCH  /tasks/{id}/complete",
			"PATCH  /tasks/{id}/incomplete",
			"POST   /upload",
		},
	)

	if err := http.ListenAndServe(":"+port, mux); err != nil {
		logger.Error("サーバーの起動に失敗しました", "error", err)
		os.Exit(1)
	}
}

// サンプルデータの初期化
func initSampleData(store *TaskStore) {
	now := time.Now()

	// デフォルトユーザー（test@example.comのユーザーID）
	defaultUserID := "user-1"

	sampleTasks := []*Task{
		{
			ID:          "1",
			UserID:      defaultUserID,
			Title:       "Flutterを学ぶ",
			Description: "基本的な概念を理解する",
			CreatedAt:   now,
			IsCompleted: false,
			Tags:        []string{"学習", "Flutter"},
			Priority:    "high",
		},
		{
			ID:          "2",
			UserID:      defaultUserID,
			Title:       "Riverpodを理解する",
			Description: "Provider、StateNotifierの違いを学ぶ",
			CreatedAt:   now,
			DueDate:     timePtr(now.AddDate(0, 0, 7)),
			IsCompleted: false,
			Tags:        []string{"学習", "フレームワーク"},
			Priority:    "medium",
		},
		{
			ID:          "3",
			UserID:      defaultUserID,
			Title:       "リスト表示を実装",
			Description: "ListViewとNavigationの使い方",
			CreatedAt:   now,
			IsCompleted: true,
			CompletedAt: timePtr(now.Add(-24 * time.Hour)),
			Tags:        []string{"実装"},
			Priority:    "low",
		},
		{
			ID:          "4",
			UserID:      defaultUserID,
			Title:       "REST API統合",
			Description: "DioとRetrofitでバックエンドと通信",
			CreatedAt:   now,
			DueDate:     timePtr(now.AddDate(0, 0, 3)),
			IsCompleted: false,
			Tags:        []string{"実装", "ネットワーク"},
			Priority:    "urgent",
		},
		{
			ID:          "5",
			UserID:      defaultUserID,
			Title:       "JWT認証の実装",
			Description: "セキュアな認証フローを構築",
			CreatedAt:   now,
			IsCompleted: false,
			Tags:        []string{"セキュリティ", "認証"},
			Priority:    "high",
		},
	}

	for _, task := range sampleTasks {
		store.Tasks[task.ID] = task
	}
}

func timePtr(t time.Time) *time.Time {
	return &t
}
