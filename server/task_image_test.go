package main

import (
	"testing"
	"time"
)

func TestTaskConvertersKeepImageURL(t *testing.T) {
	url := "http://localhost:8080/uploads/a.png"
	api := &Task{ID: "t1", UserID: "u1", Title: "x", CreatedAt: FlexibleTime{Time: time.Now()}, ImageUrl: &url}

	repo := apiTaskToRepositoryTask(api)
	if repo.ImageUrl == nil || *repo.ImageUrl != url {
		t.Fatalf("repository task lost imageUrl: %v", repo.ImageUrl)
	}

	back := repositoryTaskToAPITask(repo)
	if back.ImageUrl == nil || *back.ImageUrl != url {
		t.Fatalf("api task lost imageUrl: %v", back.ImageUrl)
	}
}
