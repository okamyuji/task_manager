package repository

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// Task タスクモデル
type Task struct {
	ID          string
	UserID      string
	Title       string
	Description string
	CreatedAt   time.Time
	DueDate     *time.Time
	IsCompleted bool
	CompletedAt *time.Time
	Priority    string
	Tags        []string
}

// TaskRepository タスクリポジトリインターフェース
type TaskRepository interface {
	Create(task *Task) error
	GetByID(id string) (*Task, error)
	GetByUserID(userID string) ([]*Task, error)
	Update(task *Task) error
	Delete(id string) error
	Complete(id string) error
	Incomplete(id string) error
}

type taskRepository struct {
	db *sql.DB
}

// NewTaskRepository タスクリポジトリを作成
func NewTaskRepository(db *sql.DB) TaskRepository {
	return &taskRepository{db: db}
}

// Create 新規タスクを作成
func (r *taskRepository) Create(task *Task) error {
	if task.ID == "" {
		task.ID = uuid.New().String()
	}
	task.CreatedAt = time.Now()

	// トランザクション開始
	tx, err := r.db.Begin()
	if err != nil {
		return err
	}
	defer func() {
		_ = tx.Rollback()
	}()

	// タスク挿入
	query := `
		INSERT INTO tasks (id, user_id, title, description, created_at, due_date, is_completed, completed_at, priority)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
	`
	_, err = tx.Exec(query, task.ID, task.UserID, task.Title, task.Description, task.CreatedAt, task.DueDate, task.IsCompleted, task.CompletedAt, task.Priority)
	if err != nil {
		return fmt.Errorf("タスク作成失敗: %w", err)
	}

	// タグ挿入
	if len(task.Tags) > 0 {
		tagQuery := `INSERT INTO task_tags (task_id, tag) VALUES (?, ?)`
		for _, tag := range task.Tags {
			if _, err := tx.Exec(tagQuery, task.ID, tag); err != nil {
				return fmt.Errorf("タグ作成失敗: %w", err)
			}
		}
	}

	return tx.Commit()
}

// GetByID IDでタスクを取得
func (r *taskRepository) GetByID(id string) (*Task, error) {
	task := &Task{}
	query := `
		SELECT id, user_id, title, description, created_at, due_date, is_completed, completed_at, priority
		FROM tasks
		WHERE id = ?
	`
	err := r.db.QueryRow(query, id).Scan(
		&task.ID,
		&task.UserID,
		&task.Title,
		&task.Description,
		&task.CreatedAt,
		&task.DueDate,
		&task.IsCompleted,
		&task.CompletedAt,
		&task.Priority,
	)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("タスク取得失敗: %w", err)
	}

	// タグ取得
	tags, err := r.getTaskTags(id)
	if err != nil {
		return nil, err
	}
	task.Tags = tags

	return task, nil
}

// GetByUserID ユーザーIDでタスク一覧を取得
func (r *taskRepository) GetByUserID(userID string) ([]*Task, error) {
	query := `
		SELECT id, user_id, title, description, created_at, due_date, is_completed, completed_at, priority
		FROM tasks
		WHERE user_id = ?
		ORDER BY created_at DESC
	`
	rows, err := r.db.Query(query, userID)
	if err != nil {
		return nil, fmt.Errorf("タスク一覧取得失敗: %w", err)
	}
	defer func() {
		_ = rows.Close()
	}()

	var tasks []*Task
	for rows.Next() {
		task := &Task{}
		if err := rows.Scan(
			&task.ID,
			&task.UserID,
			&task.Title,
			&task.Description,
			&task.CreatedAt,
			&task.DueDate,
			&task.IsCompleted,
			&task.CompletedAt,
			&task.Priority,
		); err != nil {
			return nil, err
		}

		// タグ取得
		tags, err := r.getTaskTags(task.ID)
		if err != nil {
			return nil, err
		}
		task.Tags = tags

		tasks = append(tasks, task)
	}

	return tasks, rows.Err()
}

// Update タスクを更新
func (r *taskRepository) Update(task *Task) error {
	// トランザクション開始
	tx, err := r.db.Begin()
	if err != nil {
		return err
	}
	defer func() {
		_ = tx.Rollback()
	}()

	// タスク更新
	query := `
		UPDATE tasks
		SET title = ?, description = ?, due_date = ?, is_completed = ?, completed_at = ?, priority = ?
		WHERE id = ?
	`
	result, err := tx.Exec(query, task.Title, task.Description, task.DueDate, task.IsCompleted, task.CompletedAt, task.Priority, task.ID)
	if err != nil {
		return fmt.Errorf("タスク更新失敗: %w", err)
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return err
	}
	if rows == 0 {
		return fmt.Errorf("タスクが見つかりません: %s", task.ID)
	}

	// 既存タグ削除
	if _, err := tx.Exec("DELETE FROM task_tags WHERE task_id = ?", task.ID); err != nil {
		return fmt.Errorf("タグ削除失敗: %w", err)
	}

	// 新しいタグ挿入
	if len(task.Tags) > 0 {
		tagQuery := `INSERT INTO task_tags (task_id, tag) VALUES (?, ?)`
		for _, tag := range task.Tags {
			if _, err := tx.Exec(tagQuery, task.ID, tag); err != nil {
				return fmt.Errorf("タグ作成失敗: %w", err)
			}
		}
	}

	return tx.Commit()
}

// Delete タスクを削除
func (r *taskRepository) Delete(id string) error {
	query := `DELETE FROM tasks WHERE id = ?`
	result, err := r.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("タスク削除失敗: %w", err)
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return err
	}
	if rows == 0 {
		return fmt.Errorf("タスクが見つかりません: %s", id)
	}

	return nil
}

// Complete タスクを完了にする
func (r *taskRepository) Complete(id string) error {
	now := time.Now()
	query := `UPDATE tasks SET is_completed = TRUE, completed_at = ? WHERE id = ?`
	result, err := r.db.Exec(query, now, id)
	if err != nil {
		return fmt.Errorf("タスク完了失敗: %w", err)
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return err
	}
	if rows == 0 {
		return fmt.Errorf("タスクが見つかりません: %s", id)
	}

	return nil
}

// Incomplete タスクを未完了にする
func (r *taskRepository) Incomplete(id string) error {
	query := `UPDATE tasks SET is_completed = FALSE, completed_at = NULL WHERE id = ?`
	result, err := r.db.Exec(query, id)
	if err != nil {
		return fmt.Errorf("タスク未完了化失敗: %w", err)
	}

	rows, err := result.RowsAffected()
	if err != nil {
		return err
	}
	if rows == 0 {
		return fmt.Errorf("タスクが見つかりません: %s", id)
	}

	return nil
}

// getTaskTags タスクIDでタグを取得
func (r *taskRepository) getTaskTags(taskID string) ([]string, error) {
	query := `SELECT tag FROM task_tags WHERE task_id = ? ORDER BY tag`
	rows, err := r.db.Query(query, taskID)
	if err != nil {
		return nil, fmt.Errorf("タグ取得失敗: %w", err)
	}
	defer func() {
		_ = rows.Close()
	}()

	var tags []string
	for rows.Next() {
		var tag string
		if err := rows.Scan(&tag); err != nil {
			return nil, err
		}
		tags = append(tags, tag)
	}

	return tags, rows.Err()
}
