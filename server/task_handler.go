package main

import (
	"encoding/json"
	"log/slog"
	"net/http"
	"strings"

	"task_manager_server/database/repository"
	"task_manager_server/validation"
)

// TaskHandlerNew タスク関連のハンドラー（リポジトリ版）
type TaskHandlerNew struct {
	taskRepo repository.TaskRepository
	logger   *slog.Logger
}

// NewTaskHandler タスクハンドラーを作成
func NewTaskHandler(taskRepo repository.TaskRepository, logger *slog.Logger) *TaskHandlerNew {
	return &TaskHandlerNew{
		taskRepo: taskRepo,
		logger:   logger,
	}
}

// HandleTasks タスク一覧の取得と作成
func (h *TaskHandlerNew) HandleTasks(w http.ResponseWriter, r *http.Request) {
	// 認証情報を取得
	userID := r.Header.Get("X-User-ID")
	if userID == "" {
		h.logger.Warn("ユーザーIDが見つかりません")
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
func (h *TaskHandlerNew) HandleTaskByID(w http.ResponseWriter, r *http.Request) {
	// 認証情報を取得
	userID := r.Header.Get("X-User-ID")
	if userID == "" {
		h.logger.Warn("ユーザーIDが見つかりません")
		respondWithError(w, http.StatusUnauthorized, "User ID not found")
		return
	}

	// URLからタスクIDを取得
	path := strings.TrimPrefix(r.URL.Path, "/tasks/")

	// complete/incompleteのチェック
	if strings.HasSuffix(path, "/complete") {
		taskID := strings.TrimSuffix(path, "/complete")
		h.setCompletion(w, r, userID, taskID, true)
		return
	}
	if strings.HasSuffix(path, "/incomplete") {
		taskID := strings.TrimSuffix(path, "/incomplete")
		h.setCompletion(w, r, userID, taskID, false)
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
func (h *TaskHandlerNew) getTasks(w http.ResponseWriter, userID string) {
	tasks, err := h.taskRepo.GetByUserID(userID)
	if err != nil {
		h.logger.Error("タスク一覧取得エラー", "error", err, "user_id", userID)
		respondWithError(w, http.StatusInternalServerError, "Internal server error")
		return
	}

	// タスクをAPIモデルに変換
	apiTasks := make([]*Task, len(tasks))
	for i, task := range tasks {
		apiTasks[i] = repositoryTaskToAPITask(task)
	}

	h.logger.Info("タスク一覧取得", "user_id", userID, "count", len(apiTasks))
	respondWithJSON(w, http.StatusOK, apiTasks)
}

// ownedTask は userID が持つタスクを返す。取れないときは応答を書き、nil を返す
func (h *TaskHandlerNew) ownedTask(w http.ResponseWriter, userID, taskID, action string) *repository.Task {
	task, err := h.taskRepo.GetByID(taskID)
	if err != nil {
		h.logger.Error("タスク取得エラー", "error", err, "task_id", taskID, "user_id", userID)
		respondWithError(w, http.StatusInternalServerError, "Internal server error")
		return nil
	}
	if task == nil {
		h.logger.Warn(action+": タスクが見つかりません", "task_id", taskID, "user_id", userID)
		respondWithError(w, http.StatusNotFound, "Task not found")
		return nil
	}
	if task.UserID != userID {
		h.logger.Warn(action+": アクセス権限がありません",
			"task_id", taskID,
			"task_owner", task.UserID,
			"requesting_user", userID,
		)
		respondWithError(w, http.StatusForbidden, "Access denied")
		return nil
	}
	return task
}

// decodeTask はリクエストのタスクを読み、入力を検証する。だめなときは 400 を書き、nil を返す
func (h *TaskHandlerNew) decodeTask(w http.ResponseWriter, r *http.Request, userID string) *Task {
	var apiTask Task
	if err := json.NewDecoder(r.Body).Decode(&apiTask); err != nil {
		h.logger.Warn("リクエストボディのパースエラー", "error", err, "user_id", userID)
		respondWithError(w, http.StatusBadRequest, "Invalid request body")
		return nil
	}
	for _, err := range []error{
		validation.ValidateTaskTitle(apiTask.Title),
		validation.ValidateTaskDescription(apiTask.Description),
		validation.ValidateTaskPriority(apiTask.Priority),
	} {
		if err != nil {
			h.logger.Warn("バリデーションエラー", "error", err)
			respondWithError(w, http.StatusBadRequest, err.Error())
			return nil
		}
	}
	return &apiTask
}

// getTask タスク詳細を取得（自分のタスクのみ）
func (h *TaskHandlerNew) getTask(w http.ResponseWriter, userID, taskID string) {
	task := h.ownedTask(w, userID, taskID, "タスク取得")
	if task == nil {
		return
	}
	h.logger.Debug("タスク詳細取得", "task_id", taskID, "user_id", userID, "title", task.Title)
	respondWithJSON(w, http.StatusOK, repositoryTaskToAPITask(task))
}

// createTask タスクを作成
func (h *TaskHandlerNew) createTask(w http.ResponseWriter, r *http.Request, userID string) {
	apiTask := h.decodeTask(w, r, userID)
	if apiTask == nil {
		return
	}

	task := apiTaskToRepositoryTask(apiTask)
	task.UserID = userID
	if task.Priority == "" {
		task.Priority = "medium"
	}
	if task.Tags == nil {
		task.Tags = []string{}
	}

	if err := h.taskRepo.Create(task); err != nil {
		h.logger.Error("タスク作成エラー", "error", err, "user_id", userID)
		respondWithError(w, http.StatusInternalServerError, "Failed to create task")
		return
	}

	h.logger.Info("タスク作成完了",
		"task_id", task.ID,
		"user_id", userID,
		"title", task.Title,
		"priority", task.Priority,
	)
	respondWithJSON(w, http.StatusCreated, repositoryTaskToAPITask(task))
}

// updateTask タスクを更新（自分のタスクのみ）
func (h *TaskHandlerNew) updateTask(w http.ResponseWriter, r *http.Request, userID, taskID string) {
	existingTask := h.ownedTask(w, userID, taskID, "タスク更新")
	if existingTask == nil {
		return
	}
	apiTask := h.decodeTask(w, r, userID)
	if apiTask == nil {
		return
	}

	task := apiTaskToRepositoryTask(apiTask)
	task.ID = taskID
	task.UserID = userID
	task.CreatedAt = existingTask.CreatedAt // 作成日時は保持
	if task.Tags == nil {
		task.Tags = []string{}
	}

	if err := h.taskRepo.Update(task); err != nil {
		h.logger.Error("タスク更新エラー", "error", err, "task_id", taskID, "user_id", userID)
		respondWithError(w, http.StatusInternalServerError, "Failed to update task")
		return
	}

	h.logger.Info("タスク更新完了", "task_id", taskID, "user_id", userID, "title", task.Title)
	respondWithJSON(w, http.StatusOK, repositoryTaskToAPITask(task))
}

// deleteTask タスクを削除（自分のタスクのみ）
func (h *TaskHandlerNew) deleteTask(w http.ResponseWriter, userID, taskID string) {
	task := h.ownedTask(w, userID, taskID, "タスク削除")
	if task == nil {
		return
	}

	if err := h.taskRepo.Delete(taskID); err != nil {
		h.logger.Error("タスク削除エラー", "error", err, "task_id", taskID, "user_id", userID)
		respondWithError(w, http.StatusInternalServerError, "Failed to delete task")
		return
	}

	h.logger.Info("タスク削除完了", "task_id", taskID, "user_id", userID, "title", task.Title)
	w.WriteHeader(http.StatusNoContent)
}

// setCompletion タスクを完了か未完了にする（自分のタスクのみ）
func (h *TaskHandlerNew) setCompletion(w http.ResponseWriter, r *http.Request, userID, taskID string, done bool) {
	if r.Method != http.MethodPatch {
		h.logger.Warn("不正なHTTPメソッド", "method", r.Method, "path", r.URL.Path)
		respondWithError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	action, change, failMsg := "タスク未完了化", h.taskRepo.Incomplete, "Failed to incomplete task"
	if done {
		action, change, failMsg = "タスク完了", h.taskRepo.Complete, "Failed to complete task"
	}
	if h.ownedTask(w, userID, taskID, action) == nil {
		return
	}

	if err := change(taskID); err != nil {
		h.logger.Error(action+"エラー", "error", err, "task_id", taskID, "user_id", userID)
		respondWithError(w, http.StatusInternalServerError, failMsg)
		return
	}
	updatedTask, err := h.taskRepo.GetByID(taskID)
	if err != nil || updatedTask == nil {
		h.logger.Error(action+"後のタスク取得エラー", "error", err, "task_id", taskID, "user_id", userID)
		respondWithError(w, http.StatusInternalServerError, "Internal server error")
		return
	}

	h.logger.Info(action, "task_id", taskID, "user_id", userID, "title", updatedTask.Title)
	respondWithJSON(w, http.StatusOK, repositoryTaskToAPITask(updatedTask))
}

// repositoryTaskToAPITask リポジトリモデルをAPIモデルに変換
func repositoryTaskToAPITask(task *repository.Task) *Task {
	apiTask := &Task{
		ID:          task.ID,
		UserID:      task.UserID,
		Title:       task.Title,
		Description: task.Description,
		CreatedAt:   FlexibleTime{Time: task.CreatedAt},
		IsCompleted: task.IsCompleted,
		Tags:        task.Tags,
		Priority:    task.Priority,
		ImageUrl:    task.ImageUrl,
	}

	if task.DueDate != nil {
		apiTask.DueDate = &FlexibleTime{Time: *task.DueDate}
	}
	if task.CompletedAt != nil {
		apiTask.CompletedAt = &FlexibleTime{Time: *task.CompletedAt}
	}

	return apiTask
}

// apiTaskToRepositoryTask APIモデルをリポジトリモデルに変換
func apiTaskToRepositoryTask(apiTask *Task) *repository.Task {
	task := &repository.Task{
		ID:          apiTask.ID,
		UserID:      apiTask.UserID,
		Title:       apiTask.Title,
		Description: apiTask.Description,
		CreatedAt:   apiTask.CreatedAt.Time,
		IsCompleted: apiTask.IsCompleted,
		Tags:        apiTask.Tags,
		Priority:    apiTask.Priority,
		ImageUrl:    apiTask.ImageUrl,
	}

	if apiTask.DueDate != nil {
		dueDate := apiTask.DueDate.Time
		task.DueDate = &dueDate
	}
	if apiTask.CompletedAt != nil {
		completedAt := apiTask.CompletedAt.Time
		task.CompletedAt = &completedAt
	}

	return task
}
