package main

import (
	"log/slog"
	"net/http"
	"os"

	"task_manager_server/database"
	"task_manager_server/database/repository"
	"task_manager_server/email"
	"task_manager_server/handlers"
	"task_manager_server/middleware"
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
		AddSource: true,
	})
	logger = slog.New(handler)
	slog.SetDefault(logger)

	logger.Info("サーバーを初期化中...")

	// データベース初期化
	dbPath := os.Getenv("DATABASE_PATH")
	if dbPath == "" {
		dbPath = "./data/tasks.db"
	}

	db, err := database.NewDB(dbPath, logger)
	if err != nil {
		logger.Error("データベース接続失敗", "error", err)
		os.Exit(1)
	}
	defer func() {
		_ = db.Close()
	}()

	// マイグレーション実行
	if err := db.Migrate(); err != nil {
		logger.Error("マイグレーション失敗", "error", err)
		os.Exit(1)
	}

	// リポジトリ初期化
	userRepo := repository.NewUserRepository(db.DB)
	taskRepo := repository.NewTaskRepository(db.DB)
	verificationRepo := repository.NewVerificationRepository(db.DB)

	// メールサービス初期化
	emailService := email.NewEmailService(logger)

	// レート制限初期化
	middleware.InitRateLimiters(logger)

	// ハンドラー初期化
	authHandler := NewAuthHandler(userRepo, verificationRepo, emailService, logger)
	taskHandler := NewTaskHandler(taskRepo, logger)
	verificationHandler := handlers.NewVerificationHandler(userRepo, verificationRepo, emailService, logger)
	uploadHandler := &UploadHandler{}

	// ルーティング設定
	mux := http.NewServeMux()

	// 認証関連エンドポイント（レート制限あり）
	mux.HandleFunc("/auth/login", loggingMiddleware(middleware.AuthRateLimiter.Middleware(corsMiddleware(authHandler.HandleLogin))))
	mux.HandleFunc("/auth/register", loggingMiddleware(middleware.AuthRateLimiter.Middleware(corsMiddleware(authHandler.HandleRegister))))
	mux.HandleFunc("/auth/refresh", loggingMiddleware(middleware.AuthRateLimiter.Middleware(corsMiddleware(authHandler.HandleRefresh))))
	mux.HandleFunc("/auth/verify", loggingMiddleware(middleware.AuthRateLimiter.Middleware(corsMiddleware(verificationHandler.HandleVerify))))
	mux.HandleFunc("/auth/resend-code", loggingMiddleware(middleware.AuthRateLimiter.Middleware(corsMiddleware(verificationHandler.HandleResendCode))))

	// タスク関連エンドポイント（認証 + レート制限）
	mux.HandleFunc("/tasks", loggingMiddleware(middleware.TaskRateLimiter.Middleware(authMiddleware(corsMiddleware(taskHandler.HandleTasks)))))
	mux.HandleFunc("/tasks/", loggingMiddleware(middleware.TaskRateLimiter.Middleware(authMiddleware(corsMiddleware(taskHandler.HandleTaskByID)))))

	// 画像アップロードエンドポイント（認証 + レート制限）
	mux.HandleFunc("/upload", loggingMiddleware(middleware.UploadRateLimiter.Middleware(authMiddleware(corsMiddleware(uploadHandler.HandleUpload)))))

	// 静的ファイル配信（アップロードされた画像）
	mux.Handle("/uploads/", http.StripPrefix("/uploads/", http.FileServer(http.Dir("./uploads"))))

	// アップロードディレクトリの作成
	if err := os.MkdirAll("./uploads", 0755); err != nil {
		logger.Error("アップロードディレクトリの作成に失敗しました", "error", err)
		os.Exit(1)
	}
	logger.Info("アップロードディレクトリを作成しました", "path", "./uploads")

	// サーバー起動
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// 環境変数の確認
	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		logger.Warn("JWT_SECRETが設定されていません。本番環境では必ず設定してください。")
	}

	allowedOrigins := os.Getenv("ALLOWED_ORIGINS")
	if allowedOrigins == "" {
		logger.Warn("ALLOWED_ORIGINSが設定されていません。全てのオリジンを許可します（開発環境用）。")
	}

	logger.Info("サーバーを起動しました",
		"port", port,
		"database", dbPath,
		"jwt_secret_configured", jwtSecret != "",
		"cors_configured", allowedOrigins != "",
		"endpoints", []string{
			"POST   /auth/login",
			"POST   /auth/register",
			"POST   /auth/refresh",
			"POST   /auth/verify",
			"POST   /auth/resend-code",
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
