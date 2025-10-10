# ビルドステージ
FROM golang:1.25-alpine AS builder

# 必要なツールをインストール
RUN apk add --no-cache git gcc musl-dev sqlite-dev

# 作業ディレクトリを設定
WORKDIR /app

# go.modとgo.sumをコピーして依存関係をダウンロード
COPY go.mod go.sum ./
RUN go mod download

# ソースコードをコピー
COPY . .

# CGOを有効にしてビルド（SQLite3に必要）
RUN CGO_ENABLED=1 GOOS=linux go build -a -installsuffix cgo -o task_manager_server .

# 実行ステージ
FROM alpine:latest

# 必要なパッケージをインストール
RUN apk --no-cache add ca-certificates sqlite-libs wget

# 作業ディレクトリを設定
WORKDIR /app

# ビルドステージから実行ファイルをコピー
COPY --from=builder /app/task_manager_server .

# データとアップロードディレクトリを作成
RUN mkdir -p /app/data /app/uploads

# ポート8080を公開
EXPOSE 8080

# ヘルスチェック用エンドポイント
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/uploads/ || exit 1

# アプリケーションを実行
CMD ["./task_manager_server"]

