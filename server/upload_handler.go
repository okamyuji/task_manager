package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/google/uuid"
)

// UploadHandler 画像アップロード関連のハンドラー
type UploadHandler struct{}

// HandleUpload 画像アップロード処理
func (h *UploadHandler) HandleUpload(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		logger.Warn("不正なHTTPメソッド", "method", r.Method, "path", r.URL.Path)
		respondWithError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	logger.Info("画像アップロード開始", "remote_addr", r.RemoteAddr)

	// マルチパートフォームをパース（最大10MB）
	if err := r.ParseMultipartForm(10 << 20); err != nil {
		logger.Warn("マルチパートフォームのパースエラー", "error", err)
		respondWithError(w, http.StatusBadRequest, "Failed to parse multipart form")
		return
	}

	// 画像ファイルを取得
	file, header, err := r.FormFile("image")
	if err != nil {
		logger.Warn("画像ファイル取得エラー", "error", err)
		respondWithError(w, http.StatusBadRequest, "Failed to get image file")
		return
	}
	defer file.Close()

	logger.Debug("画像ファイル受信",
		"filename", header.Filename,
		"size_bytes", header.Size,
		"content_type", header.Header.Get("Content-Type"),
	)

	// ファイル拡張子を取得
	ext := filepath.Ext(header.Filename)
	if ext == "" {
		ext = ".jpg" // デフォルト
	}

	// ユニークなファイル名を生成
	filename := fmt.Sprintf("%d_%s%s", time.Now().Unix(), uuid.New().String(), ext)
	filepath := filepath.Join("./uploads", filename)

	// ファイルを保存
	dst, err := os.Create(filepath)
	if err != nil {
		logger.Error("ファイル作成エラー", "error", err, "path", filepath)
		respondWithError(w, http.StatusInternalServerError, "Failed to create file")
		return
	}
	defer dst.Close()

	copiedBytes, err := io.Copy(dst, file)
	if err != nil {
		logger.Error("ファイル保存エラー", "error", err, "path", filepath)
		respondWithError(w, http.StatusInternalServerError, "Failed to save file")
		return
	}

	logger.Info("画像ファイル保存完了",
		"filename", filename,
		"size_bytes", copiedBytes,
		"path", filepath,
	)

	// URLを生成（本番環境では実際のドメインを使用）
	scheme := "http"
	host := r.Host
	if host == "" {
		host = "localhost:8080"
	}
	url := fmt.Sprintf("%s://%s/uploads/%s", scheme, host, filename)

	// レスポンス
	response := UploadResponse{
		URL: url,
	}

	logger.Info("画像アップロード完了", "url", url)
	respondWithJSON(w, http.StatusOK, response)
}
