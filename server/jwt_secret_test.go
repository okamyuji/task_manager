package main

import (
	"crypto/rand"
	"encoding/hex"
	"strings"
	"testing"
)

func randomHex(t *testing.T, n int) string {
	t.Helper()
	b := make([]byte, n)
	if _, err := rand.Read(b); err != nil {
		t.Fatal(err)
	}
	return hex.EncodeToString(b)
}

func TestValidateJWTSecretRejectsWeakValues(t *testing.T) {
	cases := map[string]string{
		"empty":           "",
		"code default":    "your-256-bit-secret-key-change-this-in-production",
		"compose default": "default-secret-change-in-production",
		"env example":     "your-super-secret-jwt-key-change-this-in-production-256-bits",
		"readme example":  "your-super-secret-production-key-here",
		"padded example":  "  your-256-bit-secret-key-change-this-in-production  ",
		"too short":       randomHex(t, 15),
		// README の置き場所の表示。26 文字だが UTF-8 では 32 バイトある
		"readme placeholder": "<openssl rand -hex 32 の出力>",
	}
	for name, secret := range cases {
		t.Run(name, func(t *testing.T) {
			err := validateJWTSecret(secret)
			if err == nil {
				t.Fatalf("validateJWTSecret accepted a weak secret")
			}
			if secret != "" && strings.Contains(err.Error(), strings.TrimSpace(secret)) {
				t.Fatalf("error message leaks the secret: %v", err)
			}
		})
	}
}

func TestValidateJWTSecretAcceptsRandomValue(t *testing.T) {
	if err := validateJWTSecret(randomHex(t, 32)); err != nil {
		t.Fatalf("validateJWTSecret rejected a random 64-char secret: %v", err)
	}
}
