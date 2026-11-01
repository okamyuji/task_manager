package main

import (
	"errors"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"github.com/google/uuid"
)

// UploadHandler 画像アップロード関連のハンドラー
type UploadHandler struct{}

var allowedImageExts = map[string]string{
	"image/png":  ".png",
	"image/jpeg": ".jpg",
	"image/gif":  ".gif",
	"image/webp": ".webp",
}

var errNotImage = errors.New("not a PNG, JPEG, GIF or WebP image")

// detectImageExt は拡張子を送られた名前ではなく中身から決め、読む位置を先頭に戻す。
// .html や .svg を /uploads/ から配信すると、同じオリジンでスクリプトが動くため
func detectImageExt(file multipart.File) (string, error) {
	head := make([]byte, 512)
	n, err := io.ReadFull(file, head)
	if err != nil && err != io.ErrUnexpectedEOF {
		return "", err
	}
	ext, ok := allowedImageExts[http.DetectContentType(head[:n])]
	if !ok {
		return "", errNotImage
	}
	_, err = file.Seek(0, io.SeekStart)
	return ext, err
}

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
	defer func() {
		if err := file.Close(); err != nil {
			logger.Error("ファイルクローズエラー", "error", err)
		}
	}()

	logger.Debug("画像ファイル受信",
		"filename", header.Filename,
		"size_bytes", header.Size,
		"content_type", header.Header.Get("Content-Type"),
	)

	ext, err := detectImageExt(file)
	if err != nil {
		logger.Warn("画像ファイルを受け付けない", "filename", header.Filename, "error", err)
		respondWithError(w, http.StatusBadRequest, "Only PNG, JPEG, GIF and WebP images are allowed")
		return
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
	defer func() {
		if err := dst.Close(); err != nil {
			logger.Error("ファイルクローズエラー", "error", err, "path", filepath)
		}
	}()

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
