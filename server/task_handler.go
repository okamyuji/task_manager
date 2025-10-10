package main

import (
	"encoding/json"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"
)

// TaskHandler タスク関連のハンドラー
type TaskHandler struct {
	Store *TaskStore
}

// HandleTasks タスク一覧の取得と作成
func (h *TaskHandler) HandleTasks(w http.ResponseWriter, r *http.Request) {
	// 認証情報を取得
	userID := r.Header.Get("X-User-ID")
	if userID == "" {
		logger.Warn("ユーザーIDが見つかりません")
		respondWithError(w, http.StatusUnauthorized, "User ID not found")
		return
	}

	switch r.Method {
	case http.MethodGet:
		h.getTasks(w, userID)
	case http.MethodPost:
		h.createTask(w, r, userID)
	default:
		respondWithError(w, http.StatusMethodNotAllowed, "Method not allowed")
	}
}

// HandleTaskByID タスクの取得、更新、削除
func (h *TaskHandler) HandleTaskByID(w http.ResponseWriter, r *http.Request) {
	// 認証情報を取得
	userID := r.Header.Get("X-User-ID")
	if userID == "" {
		logger.Warn("ユーザーIDが見つかりません")
		respondWithError(w, http.StatusUnauthorized, "User ID not found")
		return
	}

	// URLからタスクIDを取得
	path := strings.TrimPrefix(r.URL.Path, "/tasks/")

	// complete/incompleteのチェック
	if strings.HasSuffix(path, "/complete") {
		taskID := strings.TrimSuffix(path, "/complete")
		h.completeTask(w, r, userID, taskID)
		return
	}
	if strings.HasSuffix(path, "/incomplete") {
		taskID := strings.TrimSuffix(path, "/incomplete")
		h.incompleteTask(w, r, userID, taskID)
		return
	}

	taskID := path

	switch r.Method {
	case http.MethodGet:
		h.getTask(w, userID, taskID)
	case http.MethodPut:
		h.updateTask(w, r, userID, taskID)
	case http.MethodDelete:
		h.deleteTask(w, userID, taskID)
	default:
		respondWithError(w, http.StatusMethodNotAllowed, "Method not allowed")
	}
}

// getTasks タスク一覧を取得（自分のタスクのみ）
func (h *TaskHandler) getTasks(w http.ResponseWriter, userID string) {
	h.Store.Mutex.RLock()
	defer h.Store.Mutex.RUnlock()

	tasks := make([]*Task, 0)
	for _, task := range h.Store.Tasks {
		if task.UserID == userID {
			tasks = append(tasks, task)
		}
	}

	logger.Info("タスク一覧取得", "user_id", userID, "count", len(tasks))
	respondWithJSON(w, http.StatusOK, tasks)
}

// getTask タスク詳細を取得（自分のタスクのみ）
func (h *TaskHandler) getTask(w http.ResponseWriter, userID, taskID string) {
	h.Store.Mutex.RLock()
	defer h.Store.Mutex.RUnlock()

	task, exists := h.Store.Tasks[taskID]
	if !exists {
		logger.Warn("タスクが見つかりません", "task_id", taskID, "user_id", userID)
		respondWithError(w, http.StatusNotFound, "Task not found")
		return
	}

	// 所有者チェック
	if task.UserID != userID {
		logger.Warn("タスクへのアクセス権限がありません",
			"task_id", taskID,
			"task_owner", task.UserID,
			"requesting_user", userID,
		)
		respondWithError(w, http.StatusForbidden, "Access denied")
		return
	}

	logger.Debug("タスク詳細取得", "task_id", taskID, "user_id", userID, "title", task.Title)
	respondWithJSON(w, http.StatusOK, task)
}

// createTask タスクを作成
func (h *TaskHandler) createTask(w http.ResponseWriter, r *http.Request, userID string) {
	var task Task
	if err := json.NewDecoder(r.Body).Decode(&task); err != nil {
		logger.Warn("タスク作成: リクエストボディのパースエラー", "error", err, "user_id", userID)
		respondWithError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// IDが空の場合は生成
	if task.ID == "" {
		task.ID = uuid.New().String()
	}

	// ユーザーIDを設定（必須）
	task.UserID = userID

	// 作成日時を設定
	if task.CreatedAt.IsZero() {
		task.CreatedAt = FlexibleTime{Time: time.Now()}
	}

	// タグが未設定の場合は空配列
	if task.Tags == nil {
		task.Tags = []string{}
	}

	// 優先度のデフォルト値
	if task.Priority == "" {
		task.Priority = "medium"
	}

	h.Store.Mutex.Lock()
	h.Store.Tasks[task.ID] = &task
	h.Store.Mutex.Unlock()

	logger.Info("タスク作成完了",
		"task_id", task.ID,
		"user_id", userID,
		"title", task.Title,
		"priority", task.Priority,
	)

	respondWithJSON(w, http.StatusCreated, task)
}

// updateTask タスクを更新（自分のタスクのみ）
func (h *TaskHandler) updateTask(w http.ResponseWriter, r *http.Request, userID, taskID string) {
	h.Store.Mutex.Lock()
	defer h.Store.Mutex.Unlock()

	// 既存タスクの確認
	existingTask, exists := h.Store.Tasks[taskID]
	if !exists {
		logger.Warn("タスク更新: タスクが見つかりません", "task_id", taskID, "user_id", userID)
		respondWithError(w, http.StatusNotFound, "Task not found")
		return
	}

	// 所有者チェック
	if existingTask.UserID != userID {
		logger.Warn("タスク更新: アクセス権限がありません",
			"task_id", taskID,
			"task_owner", existingTask.UserID,
			"requesting_user", userID,
		)
		respondWithError(w, http.StatusForbidden, "Access denied")
		return
	}

	var task Task
	if err := json.NewDecoder(r.Body).Decode(&task); err != nil {
		logger.Warn("タスク更新: リクエストボディのパースエラー", "error", err, "task_id", taskID, "user_id", userID)
		respondWithError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	// IDとユーザーIDを保持
	task.ID = taskID
	task.UserID = userID

	// タグが未設定の場合は空配列
	if task.Tags == nil {
		task.Tags = []string{}
	}

	h.Store.Tasks[taskID] = &task

	logger.Info("タスク更新完了", "task_id", taskID, "user_id", userID, "title", task.Title)
	respondWithJSON(w, http.StatusOK, task)
}

// deleteTask タスクを削除（自分のタスクのみ）
func (h *TaskHandler) deleteTask(w http.ResponseWriter, userID, taskID string) {
	h.Store.Mutex.Lock()
	defer h.Store.Mutex.Unlock()

	task, exists := h.Store.Tasks[taskID]
	if !exists {
		logger.Warn("タスク削除: タスクが見つかりません", "task_id", taskID, "user_id", userID)
		respondWithError(w, http.StatusNotFound, "Task not found")
		return
	}

	// 所有者チェック
	if task.UserID != userID {
		logger.Warn("タスク削除: アクセス権限がありません",
			"task_id", taskID,
			"task_owner", task.UserID,
			"requesting_user", userID,
		)
		respondWithError(w, http.StatusForbidden, "Access denied")
		return
	}

	delete(h.Store.Tasks, taskID)

	logger.Info("タスク削除完了", "task_id", taskID, "user_id", userID, "title", task.Title)
	w.WriteHeader(http.StatusNoContent)
}

// completeTask タスクを完了状態にする（自分のタスクのみ）
func (h *TaskHandler) completeTask(w http.ResponseWriter, r *http.Request, userID, taskID string) {
	if r.Method != http.MethodPatch {
		logger.Warn("不正なHTTPメソッド", "method", r.Method, "path", r.URL.Path)
		respondWithError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	h.Store.Mutex.Lock()
	defer h.Store.Mutex.Unlock()

	task, exists := h.Store.Tasks[taskID]
	if !exists {
		logger.Warn("タスク完了: タスクが見つかりません", "task_id", taskID, "user_id", userID)
		respondWithError(w, http.StatusNotFound, "Task not found")
		return
	}

	// 所有者チェック
	if task.UserID != userID {
		logger.Warn("タスク完了: アクセス権限がありません",
			"task_id", taskID,
			"task_owner", task.UserID,
			"requesting_user", userID,
		)
		respondWithError(w, http.StatusForbidden, "Access denied")
		return
	}

	task.IsCompleted = true
	now := FlexibleTime{Time: time.Now()}
	task.CompletedAt = &now

	logger.Info("タスク完了", "task_id", taskID, "user_id", userID, "title", task.Title)
	respondWithJSON(w, http.StatusOK, task)
}

// incompleteTask タスクを未完了状態にする（自分のタスクのみ）
func (h *TaskHandler) incompleteTask(w http.ResponseWriter, r *http.Request, userID, taskID string) {
	if r.Method != http.MethodPatch {
		logger.Warn("不正なHTTPメソッド", "method", r.Method, "path", r.URL.Path)
		respondWithError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	h.Store.Mutex.Lock()
	defer h.Store.Mutex.Unlock()

	task, exists := h.Store.Tasks[taskID]
	if !exists {
		logger.Warn("タスク未完了化: タスクが見つかりません", "task_id", taskID, "user_id", userID)
		respondWithError(w, http.StatusNotFound, "Task not found")
		return
	}

	// 所有者チェック
	if task.UserID != userID {
		logger.Warn("タスク未完了化: アクセス権限がありません",
			"task_id", taskID,
			"task_owner", task.UserID,
			"requesting_user", userID,
		)
		respondWithError(w, http.StatusForbidden, "Access denied")
		return
	}

	task.IsCompleted = false
	task.CompletedAt = nil

	logger.Info("タスク未完了化", "task_id", taskID, "user_id", userID, "title", task.Title)
	respondWithJSON(w, http.StatusOK, task)
}
