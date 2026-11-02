package main

import (
	"encoding/json"
	"testing"

	"task_manager_server/database/repository"
)

func TestUpdatedImageURL(t *testing.T) {
	stored := "http://localhost:8080/uploads/old.png"
	next := "http://localhost:8080/uploads/new.png"
	cases := []struct {
		name string
		body string
		want *string
	}{
		{"keeps the stored URL when imageUrl is omitted", `{"title":"a"}`, &stored},
		{"clears the URL when imageUrl is null", `{"title":"a","imageUrl":null}`, nil},
		{"replaces the URL when imageUrl has a value", `{"title":"a","imageUrl":"` + next + `"}`, &next},
		// encoding/json はキーの大文字と小文字を区別せずに欄へ対応させる
		{"replaces the URL when the key differs only in case", `{"title":"a","ImageUrl":"` + next + `"}`, &next},
		{"clears the URL when a differently cased key is null", `{"title":"a","IMAGEURL":null}`, nil},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			var req Task
			if err := json.Unmarshal([]byte(c.body), &req); err != nil {
				t.Fatal(err)
			}
			got := updatedImageURL(&req, &repository.Task{ImageUrl: &stored})
			switch {
			case c.want == nil && got != nil:
				t.Fatalf("want nil, got %q", *got)
			case c.want != nil && (got == nil || *got != *c.want):
				t.Fatalf("want %q, got %v", *c.want, got)
			}
		})
	}
}
