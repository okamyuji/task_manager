package main

import (
	"bytes"
	"encoding/json"
	"image"
	"image/png"
	"io"
	"log/slog"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"path"
	"testing"
)

func upload(t *testing.T, filename string, body []byte) *httptest.ResponseRecorder {
	t.Helper()
	logger = slog.New(slog.NewTextHandler(io.Discard, nil))
	var buf bytes.Buffer
	mw := multipart.NewWriter(&buf) // bytes.Buffer への書き込みは失敗しない
	fw, _ := mw.CreateFormFile("image", filename)
	fw.Write(body)
	mw.Close()
	req := httptest.NewRequest(http.MethodPost, "/upload", &buf)
	req.Header.Set("Content-Type", mw.FormDataContentType())
	rec := httptest.NewRecorder()
	(&UploadHandler{}).HandleUpload(rec, req)
	return rec
}

func inUploadDir(t *testing.T) {
	t.Chdir(t.TempDir())
	if err := os.Mkdir("uploads", 0o755); err != nil {
		t.Fatal(err)
	}
}

func TestHandleUploadRejectsNonImages(t *testing.T) {
	inUploadDir(t)
	for name, body := range map[string]string{
		"page.html": "<html><body><script>alert(1)</script></body></html>",
		"fake.png":  `<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>`,
		"note.txt":  "plain text",
	} {
		if rec := upload(t, name, []byte(body)); rec.Code != http.StatusBadRequest {
			t.Errorf("%s: status = %d, want 400", name, rec.Code)
		}
	}
	if entries, _ := os.ReadDir("uploads"); len(entries) != 0 {
		t.Fatalf("non-image files were saved: %v", entries)
	}
}

func TestHandleUploadNamesFileByDetectedType(t *testing.T) {
	inUploadDir(t)
	var img bytes.Buffer
	png.Encode(&img, image.NewRGBA(image.Rect(0, 0, 1, 1)))

	rec := upload(t, "photo.html", img.Bytes())
	var resp UploadResponse
	json.Unmarshal(rec.Body.Bytes(), &resp)
	if rec.Code != http.StatusOK || path.Ext(resp.URL) != ".png" {
		t.Fatalf("status = %d, url = %q, want 200 and a .png name", rec.Code, resp.URL)
	}
	if saved, _ := os.ReadFile("uploads/" + path.Base(resp.URL)); !bytes.Equal(saved, img.Bytes()) {
		t.Fatal("saved file differs from the uploaded image")
	}
}
