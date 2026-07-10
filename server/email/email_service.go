package email

import (
	"fmt"
	"log/slog"
	"net/smtp"
	"os"
	"strings"
)

// EmailService メール送信サービス
type EmailService struct {
	smtpHost string
	smtpPort string
	from     string
	logger   *slog.Logger
}

// NewEmailService メールサービスを作成
func NewEmailService(logger *slog.Logger) *EmailService {
	smtpHost := os.Getenv("SMTP_HOST")
	if smtpHost == "" {
		smtpHost = "mailhog" // Docker Compose内のデフォルト
	}

	smtpPort := os.Getenv("SMTP_PORT")
	if smtpPort == "" {
		smtpPort = "1025" // MailHogのデフォルトポート
	}

	from := os.Getenv("MAIL_FROM")
	if from == "" {
		from = "noreply@taskmanager.local"
	}

	return &EmailService{
		smtpHost: smtpHost,
		smtpPort: smtpPort,
		from:     from,
		logger:   logger,
	}
}

// SendVerificationCode 認証コードを送信
func (s *EmailService) SendVerificationCode(to, name, code string) error {
	subject := "【Task Manager】認証コードのお知らせ"
	body := s.buildVerificationEmailBody(name, code)

	return s.sendEmail(to, subject, body)
}

// SendWelcomeEmail ウェルカムメールを送信
func (s *EmailService) SendWelcomeEmail(to, name string) error {
	subject := "【Task Manager】ご登録ありがとうございます"
	body := s.buildWelcomeEmailBody(name)

	return s.sendEmail(to, subject, body)
}

// sanitizeHeader メールヘッダインジェクション対策として CR/LF を除去
func sanitizeHeader(v string) string {
	return strings.NewReplacer("\r", "", "\n", "").Replace(v)
}

// sendEmail メールを送信（実装）
func (s *EmailService) sendEmail(to, subject, body string) error {
	// ヘッダ行に流し込まれる値は CR/LF を除去してインジェクションを防ぐ
	to = sanitizeHeader(to)
	subject = sanitizeHeader(subject)
	// メール形式
	message := s.buildMessage(sanitizeHeader(s.from), to, subject, body)

	// SMTPサーバーに接続（認証なし: MailHog用）
	addr := fmt.Sprintf("%s:%s", s.smtpHost, s.smtpPort)

	s.logger.Info("メール送信中",
		"to", to,
		"subject", subject,
		"smtp", addr,
	)

	// MailHogは認証不要のため、smtp.SendMailを直接使用
	err := smtp.SendMail(
		addr,
		nil, // 認証なし
		s.from,
		[]string{to},
		[]byte(message),
	)

	if err != nil {
		s.logger.Error("メール送信失敗",
			"error", err,
			"to", to,
			"smtp", addr,
		)
		return fmt.Errorf("メール送信失敗: %w", err)
	}

	s.logger.Info("メール送信成功", "to", to)
	return nil
}

// buildMessage メールメッセージを構築
func (s *EmailService) buildMessage(from, to, subject, body string) string {
	var builder strings.Builder

	builder.WriteString(fmt.Sprintf("From: %s\r\n", from))
	builder.WriteString(fmt.Sprintf("To: %s\r\n", to))
	builder.WriteString(fmt.Sprintf("Subject: %s\r\n", subject))
	builder.WriteString("MIME-Version: 1.0\r\n")
	builder.WriteString("Content-Type: text/plain; charset=UTF-8\r\n")
	builder.WriteString("\r\n")
	builder.WriteString(body)

	return builder.String()
}

// buildVerificationEmailBody 認証コードメール本文を構築
func (s *EmailService) buildVerificationEmailBody(name, code string) string {
	return fmt.Sprintf(`%s 様

Task Managerにご登録いただきありがとうございます。

以下の認証コードを入力して、アカウント登録を完了してください。

━━━━━━━━━━━━━━━━━━━━
認証コード: %s
━━━━━━━━━━━━━━━━━━━━

※このコードの有効期限は15分です。
※このメールに心当たりがない場合は、無視してください。

Task Manager運営チーム
`, name, code)
}

// buildWelcomeEmailBody ウェルカムメール本文を構築
func (s *EmailService) buildWelcomeEmailBody(name string) string {
	return fmt.Sprintf(`%s 様

Task Managerへようこそ！

アカウント認証が完了しました。
今すぐタスク管理を始めましょう。

【主な機能】
・タスクの作成・編集・削除
・優先度とタグによる整理
・期限管理
・画像添付

ご不明な点がございましたら、お気軽にお問い合わせください。

Task Manager運営チーム
`, name)
}
