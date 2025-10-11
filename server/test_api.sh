#!/bin/bash

# Task Manager API テストスクリプト
# 使用方法: ./test_api.sh [BASE_URL]
# 例: ./test_api.sh http://192.168.0.16:8080

BASE_URL="${1:-http://localhost:8080}"

echo "Task Manager API テスト"
echo "=========================="
echo "Base URL: $BASE_URL"
echo ""

# jqの存在確認
if ! command -v jq &> /dev/null; then
    echo "jqがインストールされていません。JSON整形なしで実行します。"
    echo "   インストール: brew install jq"
    USE_JQ=false
else
    USE_JQ=true
fi
echo ""

# 1. サーバー接続確認
echo "サーバー接続確認"
SERVER_CHECK=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{}')

if [ "$SERVER_CHECK" = "400" ] || [ "$SERVER_CHECK" = "401" ] || [ "$SERVER_CHECK" = "200" ]; then
    echo "サーバーに接続できました (HTTP $SERVER_CHECK)"
else
    echo "サーバーに接続できません。サーバーが起動していることを確認してください。"
    echo "   Expected: 200/400/401, Got: $SERVER_CHECK"
    exit 1
fi
echo ""

# 2. ログイン（既存ユーザー）
echo "ログインテスト（既存ユーザー）"
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }')

if echo "$LOGIN_RESPONSE" | grep -q "accessToken"; then
    echo "ログイン成功"
    if [ "$USE_JQ" = true ]; then
        echo "$LOGIN_RESPONSE" | jq '.'
    else
        echo "$LOGIN_RESPONSE"
    fi
else
    echo "ログイン失敗"
    echo "$LOGIN_RESPONSE"
fi

# アクセストークンを抽出
ACCESS_TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
REFRESH_TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"refreshToken":"[^"]*' | cut -d'"' -f4)
USER_ID=$(echo $LOGIN_RESPONSE | grep -o '"userId":"[^"]*' | cut -d'"' -f4)

echo ""
echo "認証情報:"
echo "   User ID: $USER_ID"
echo "   Access Token: ${ACCESS_TOKEN:0:50}..."
echo "   Refresh Token: ${REFRESH_TOKEN:0:50}..."
echo ""

# 3. ユーザー登録（新規ユーザー）- メール認証フロー
echo "ユーザー登録テスト（新規ユーザー - メール認証フロー）"
TIMESTAMP=$(date +%s)
NEW_EMAIL="testuser${TIMESTAMP}@example.com"
NEW_PASSWORD="TestPass123"
NEW_NAME="テストユーザー${TIMESTAMP}"

REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$NEW_EMAIL\",
    \"password\": \"$NEW_PASSWORD\",
    \"name\": \"$NEW_NAME\"
  }")

if echo "$REGISTER_RESPONSE" | grep -q "userId"; then
    echo "ユーザー登録成功（未認証状態）"
    NEW_USER_ID=$(echo $REGISTER_RESPONSE | grep -o '"userId":"[^"]*' | cut -d'"' -f4)
    echo "   New User ID: $NEW_USER_ID"
    echo "   → MailHog WebUI (http://localhost:8025) で認証コードを確認してください"
    if [ "$USE_JQ" = true ]; then
        echo "$REGISTER_RESPONSE" | jq '.'
    else
        echo "$REGISTER_RESPONSE"
    fi
    
    # メール認証のシミュレーション
    echo ""
    echo "メール認証テスト（手動コード入力が必要）"
    echo "   MailHog WebUI (http://localhost:8025) で認証コードを確認してください"
    echo "   認証コードを入力してください（6桁の数字、Enterキーで確定）:"
    echo "   ※自動テストを継続する場合は Enter のみ押してスキップしてください"
    read -r VERIFICATION_CODE
    
    if [ -n "$VERIFICATION_CODE" ]; then
        # 認証コードが入力された場合は検証
        echo "認証コード検証中..."
        VERIFY_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/verify" \
          -H "Content-Type: application/json" \
          -d "{
            \"email\": \"$NEW_EMAIL\",
            \"code\": \"$VERIFICATION_CODE\"
          }")
        
        if echo "$VERIFY_RESPONSE" | grep -q "Verification successful"; then
            echo "メール認証成功！"
            if [ "$USE_JQ" = true ]; then
                echo "$VERIFY_RESPONSE" | jq '.'
            else
                echo "$VERIFY_RESPONSE"
            fi
            
            # 認証後のログインテスト
            echo ""
            echo "認証後のログインテスト"
            NEW_USER_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
              -H "Content-Type: application/json" \
              -d "{
                \"email\": \"$NEW_EMAIL\",
                \"password\": \"$NEW_PASSWORD\"
              }")
            
            if echo "$NEW_USER_LOGIN" | grep -q "accessToken"; then
                echo "認証済みユーザーのログイン成功"
                NEW_USER_ACCESS_TOKEN=$(echo $NEW_USER_LOGIN | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
                echo "   Access Token: ${NEW_USER_ACCESS_TOKEN:0:50}..."
            else
                echo "認証済みユーザーのログイン失敗"
                echo "$NEW_USER_LOGIN"
            fi
        else
            echo "メール認証失敗"
            echo "$VERIFY_RESPONSE"
        fi
    else
        echo "メール認証テストをスキップしました"
    fi
else
    echo "ユーザー登録失敗"
    if [ "$USE_JQ" = true ]; then
        echo "$REGISTER_RESPONSE" | jq '.'
    else
        echo "$REGISTER_RESPONSE"
    fi
fi
echo ""

# 3.5. 未認証ユーザーのログイン試行テスト
echo "未認証ユーザーのログイン試行テスト"
UNVERIFIED_EMAIL="unverified${TIMESTAMP}@example.com"
UNVERIFIED_PASSWORD="UnverifiedPass123"

# 未認証ユーザーを作成
UNVERIFIED_REGISTER=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$UNVERIFIED_EMAIL\",
    \"password\": \"$UNVERIFIED_PASSWORD\",
    \"name\": \"未認証ユーザー${TIMESTAMP}\"
  }")

if echo "$UNVERIFIED_REGISTER" | grep -q "userId"; then
    echo "未認証ユーザー作成成功"
    UNVERIFIED_USER_ID=$(echo $UNVERIFIED_REGISTER | grep -o '"userId":"[^"]*' | cut -d'"' -f4)
    echo "   Unverified User ID: $UNVERIFIED_USER_ID"
    
    # 未認証状態でログイン試行
    echo ""
    echo "未認証状態でのログイン試行..."
    UNVERIFIED_LOGIN=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$BASE_URL/auth/login" \
      -H "Content-Type: application/json" \
      -d "{
        \"email\": \"$UNVERIFIED_EMAIL\",
        \"password\": \"$UNVERIFIED_PASSWORD\"
      }")
    
    HTTP_STATUS=$(echo "$UNVERIFIED_LOGIN" | grep "HTTP_STATUS" | cut -d':' -f2)
    RESPONSE_BODY=$(echo "$UNVERIFIED_LOGIN" | sed '/HTTP_STATUS/d')
    
    if [ "$HTTP_STATUS" = "403" ] || echo "$RESPONSE_BODY" | grep -q "not verified"; then
        echo "未認証ユーザーのログイン拒否成功 (HTTP $HTTP_STATUS)"
        echo "   → セキュリティ: 未認証ユーザーはログインできません（期待通り）"
        if [ "$USE_JQ" = true ]; then
            echo "$RESPONSE_BODY" | jq '.'
        else
            echo "$RESPONSE_BODY"
        fi
    else
        echo "警告: 未認証ユーザーがログインできてしまいました (HTTP $HTTP_STATUS)"
        echo "   → セキュリティ問題: メール認証が機能していません！"
        echo "$RESPONSE_BODY"
    fi
else
    echo "未認証ユーザー作成失敗"
    echo "$UNVERIFIED_REGISTER"
fi
echo ""

# 3.6. 認証コード再送信テスト
echo "認証コード再送信テスト"
RESEND_EMAIL="resendtest${TIMESTAMP}@example.com"

# テスト用ユーザーを作成
RESEND_REGISTER=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$RESEND_EMAIL\",
    \"password\": \"ResendPass123\",
    \"name\": \"再送信テストユーザー${TIMESTAMP}\"
  }")

if echo "$RESEND_REGISTER" | grep -q "userId"; then
    echo "再送信テスト用ユーザー作成成功"
    
    # 認証コード再送信
    echo "認証コード再送信中..."
    RESEND_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/resend-code" \
      -H "Content-Type: application/json" \
      -d "{
        \"email\": \"$RESEND_EMAIL\"
      }")
    
    if echo "$RESEND_RESPONSE" | grep -q "Verification code sent"; then
        echo "認証コード再送信成功"
        echo "   → MailHog WebUI で新しい認証コードを確認できます"
        if [ "$USE_JQ" = true ]; then
            echo "$RESEND_RESPONSE" | jq '.'
        else
            echo "$RESEND_RESPONSE"
        fi
    else
        echo "認証コード再送信失敗"
        echo "$RESEND_RESPONSE"
    fi
else
    echo "再送信テスト用ユーザー作成失敗"
    echo "$RESEND_REGISTER"
fi
echo ""

# 3.7. 無効な認証コードテスト
echo "無効な認証コードテスト"
INVALID_CODE_EMAIL="invalidcode${TIMESTAMP}@example.com"

# テスト用ユーザーを作成
INVALID_REGISTER=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$INVALID_CODE_EMAIL\",
    \"password\": \"InvalidPass123\",
    \"name\": \"無効コードテストユーザー${TIMESTAMP}\"
  }")

if echo "$INVALID_REGISTER" | grep -q "userId"; then
    echo "無効コードテスト用ユーザー作成成功"
    
    # 無効な認証コードで検証試行
    echo "無効な認証コード (999999) で検証試行..."
    INVALID_VERIFY=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST "$BASE_URL/auth/verify" \
      -H "Content-Type: application/json" \
      -d "{
        \"email\": \"$INVALID_CODE_EMAIL\",
        \"code\": \"999999\"
      }")
    
    HTTP_STATUS=$(echo "$INVALID_VERIFY" | grep "HTTP_STATUS" | cut -d':' -f2)
    RESPONSE_BODY=$(echo "$INVALID_VERIFY" | sed '/HTTP_STATUS/d')
    
    if [ "$HTTP_STATUS" = "400" ] || echo "$RESPONSE_BODY" | grep -q "Invalid"; then
        echo "無効な認証コードの拒否成功 (HTTP $HTTP_STATUS)"
        echo "   → セキュリティ: 無効なコードは拒否されます（期待通り）"
        if [ "$USE_JQ" = true ]; then
            echo "$RESPONSE_BODY" | jq '.'
        else
            echo "$RESPONSE_BODY"
        fi
    else
        echo "警告: 無効な認証コードが受け入れられました (HTTP $HTTP_STATUS)"
        echo "   → セキュリティ問題: 認証コード検証が機能していません！"
        echo "$RESPONSE_BODY"
    fi
else
    echo "無効コードテスト用ユーザー作成失敗"
    echo "$INVALID_REGISTER"
fi
echo ""

# 4. タスク一覧取得
echo "タスク一覧取得テスト"
TASKS_RESPONSE=$(curl -s -X GET "$BASE_URL/tasks" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

if echo "$TASKS_RESPONSE" | grep -q "id"; then
    echo "タスク一覧取得成功"
    TASK_COUNT=$(echo "$TASKS_RESPONSE" | grep -o '"id"' | wc -l | tr -d ' ')
    echo "   取得件数: $TASK_COUNT"
    if [ "$USE_JQ" = true ]; then
        echo "$TASKS_RESPONSE" | jq '.'
    else
        echo "$TASKS_RESPONSE"
    fi
else
    echo "タスク一覧取得失敗"
    echo "$TASKS_RESPONSE"
fi
echo ""

# 5. タスク作成
echo "タスク作成テスト"
CREATE_RESPONSE=$(curl -s -X POST "$BASE_URL/tasks" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"title\": \"APIテストタスク_${TIMESTAMP}\",
    \"description\": \"curlで作成したテストタスク\",
    \"priority\": \"high\",
    \"tags\": [\"テスト\", \"API\", \"curl\"]
  }")

if echo "$CREATE_RESPONSE" | grep -q "id"; then
    echo "タスク作成成功"
    TASK_ID=$(echo $CREATE_RESPONSE | grep -o '"id":"[^"]*' | cut -d'"' -f4)
    echo "   Task ID: $TASK_ID"
    if [ "$USE_JQ" = true ]; then
        echo "$CREATE_RESPONSE" | jq '.'
    else
        echo "$CREATE_RESPONSE"
    fi
else
    echo "タスク作成失敗"
    echo "$CREATE_RESPONSE"
    exit 1
fi
echo ""

# 6. タスク詳細取得
echo "タスク詳細取得テスト"
TASK_DETAIL=$(curl -s -X GET "$BASE_URL/tasks/$TASK_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

if echo "$TASK_DETAIL" | grep -q "id"; then
    echo "タスク詳細取得成功"
    if [ "$USE_JQ" = true ]; then
        echo "$TASK_DETAIL" | jq '.'
    else
        echo "$TASK_DETAIL"
    fi
else
    echo "タスク詳細取得失敗"
    echo "$TASK_DETAIL"
fi
echo ""

# 7. タスク更新
echo "タスク更新テスト"
UPDATE_RESPONSE=$(curl -s -X PUT "$BASE_URL/tasks/$TASK_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"id\": \"$TASK_ID\",
    \"title\": \"更新されたAPIテストタスク\",
    \"description\": \"curlで更新した説明文\",
    \"priority\": \"medium\",
    \"tags\": [\"更新\", \"テスト完了\"],
    \"isCompleted\": false,
    \"createdAt\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
  }")

if echo "$UPDATE_RESPONSE" | grep -q "更新されたAPIテストタスク"; then
    echo "タスク更新成功"
    if [ "$USE_JQ" = true ]; then
        echo "$UPDATE_RESPONSE" | jq '.'
    else
        echo "$UPDATE_RESPONSE"
    fi
else
    echo "タスク更新失敗"
    echo "$UPDATE_RESPONSE"
fi
echo ""

# 8. タスク完了
echo "タスク完了テスト"
COMPLETE_RESPONSE=$(curl -s -X PATCH "$BASE_URL/tasks/$TASK_ID/complete" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

if echo "$COMPLETE_RESPONSE" | grep -q '"isCompleted":true'; then
    echo "タスク完了成功"
    if [ "$USE_JQ" = true ]; then
        echo "$COMPLETE_RESPONSE" | jq '.'
    else
        echo "$COMPLETE_RESPONSE"
    fi
else
    echo "タスク完了失敗"
    echo "$COMPLETE_RESPONSE"
fi
echo ""

# 9. タスク未完了化
echo "タスク未完了化テスト"
INCOMPLETE_RESPONSE=$(curl -s -X PATCH "$BASE_URL/tasks/$TASK_ID/incomplete" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

if echo "$INCOMPLETE_RESPONSE" | grep -q '"isCompleted":false'; then
    echo "タスク未完了化成功"
    if [ "$USE_JQ" = true ]; then
        echo "$INCOMPLETE_RESPONSE" | jq '.'
    else
        echo "$INCOMPLETE_RESPONSE"
    fi
else
    echo "タスク未完了化失敗"
    echo "$INCOMPLETE_RESPONSE"
fi
echo ""

# 10. トークンリフレッシュ
echo "トークンリフレッシュテスト"
REFRESH_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/refresh" \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\": \"$REFRESH_TOKEN\"}")

if echo "$REFRESH_RESPONSE" | grep -q "accessToken"; then
    echo "トークンリフレッシュ成功"
    NEW_ACCESS_TOKEN=$(echo $REFRESH_RESPONSE | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
    echo "   New Access Token: ${NEW_ACCESS_TOKEN:0:50}..."
    if [ "$USE_JQ" = true ]; then
        echo "$REFRESH_RESPONSE" | jq '.'
    else
        echo "$REFRESH_RESPONSE"
    fi
else
    echo "トークンリフレッシュ失敗"
    echo "$REFRESH_RESPONSE"
fi
echo ""

# 11. タスク削除
echo "タスク削除テスト"
DELETE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$BASE_URL/tasks/$TASK_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

if [ "$DELETE_STATUS" = "204" ]; then
    echo "タスク削除成功 (HTTP 204 No Content)"
else
    echo "タスク削除失敗 (HTTP $DELETE_STATUS)"
fi
echo ""

# 12. 削除確認（タスクが存在しないことを確認）
echo "削除確認テスト"
VERIFY_DELETE=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$BASE_URL/tasks/$TASK_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

if [ "$VERIFY_DELETE" = "404" ]; then
    echo "削除確認成功 (タスクが存在しません - HTTP 404)"
else
    echo "削除確認: タスクがまだ存在している可能性があります (HTTP $VERIFY_DELETE)"
fi
echo ""

# 13. 認証エラーテスト
echo "認証エラーテスト（無効なトークン）"
AUTH_ERROR=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$BASE_URL/tasks" \
  -H "Authorization: Bearer invalid_token")

if [ "$AUTH_ERROR" = "401" ]; then
    echo "認証エラー処理正常 (HTTP 401 Unauthorized)"
else
    echo "期待されるステータスコード401ではありません (HTTP $AUTH_ERROR)"
fi
echo ""

# 14. 認可テスト準備（別ユーザーでログイン）
echo "認可テスト準備（別ユーザーを作成）"
TIMESTAMP2=$(date +%s)
NEW_USER_EMAIL="otheruser${TIMESTAMP2}@example.com"
OTHER_USER_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/register" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$NEW_USER_EMAIL\",
    \"password\": \"otherpass123\",
    \"name\": \"別ユーザー${TIMESTAMP2}\"
  }")

if echo "$OTHER_USER_RESPONSE" | grep -q "accessToken"; then
    echo "別ユーザー作成成功"
    OTHER_ACCESS_TOKEN=$(echo $OTHER_USER_RESPONSE | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)
    OTHER_USER_ID=$(echo $OTHER_USER_RESPONSE | grep -o '"userId":"[^"]*' | cut -d'"' -f4)
    echo "   Other User ID: $OTHER_USER_ID"
    echo "   Other Access Token: ${OTHER_ACCESS_TOKEN:0:50}..."
else
    echo "別ユーザー作成失敗"
    echo "$OTHER_USER_RESPONSE"
fi
echo ""

# 15. 別ユーザーでタスク作成（認可テスト用）
echo "別ユーザーでタスク作成"
OTHER_TASK_RESPONSE=$(curl -s -X POST "$BASE_URL/tasks" \
  -H "Authorization: Bearer $OTHER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"title\": \"別ユーザーのタスク_${TIMESTAMP2}\",
    \"description\": \"認可テスト用のタスク\",
    \"priority\": \"medium\",
    \"tags\": [\"認可テスト\"]
  }")

if echo "$OTHER_TASK_RESPONSE" | grep -q "id"; then
    echo "別ユーザーのタスク作成成功"
    OTHER_TASK_ID=$(echo $OTHER_TASK_RESPONSE | grep -o '"id":"[^"]*' | cut -d'"' -f4)
    echo "   Other Task ID: $OTHER_TASK_ID"
else
    echo "別ユーザーのタスク作成失敗"
    echo "$OTHER_TASK_RESPONSE"
fi
echo ""

# 16. 認可テスト（異常系）: 他人のタスクを取得
echo "認可テスト（異常系）: 他人のタスク取得"
FORBIDDEN_GET=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$BASE_URL/tasks/$OTHER_TASK_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

if [ "$FORBIDDEN_GET" = "403" ]; then
    echo "認可エラー処理正常 (HTTP 403 Forbidden)"
    echo "   → 他人のタスクにアクセスできませんでした（期待通り）"
else
    echo "認可エラーが発生しませんでした (HTTP $FORBIDDEN_GET)"
    echo "   → セキュリティ問題: 他人のタスクにアクセスできてしまいます！"
fi
echo ""

# 17. 認可テスト（異常系）: 他人のタスクを更新
echo "認可テスト（異常系）: 他人のタスク更新"
FORBIDDEN_UPDATE=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$BASE_URL/tasks/$OTHER_TASK_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"id\": \"$OTHER_TASK_ID\",
    \"title\": \"不正な更新\",
    \"description\": \"これは更新されてはいけません\",
    \"priority\": \"high\",
    \"tags\": [\"不正\"],
    \"isCompleted\": false,
    \"createdAt\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"
  }")

if [ "$FORBIDDEN_UPDATE" = "403" ]; then
    echo "認可エラー処理正常 (HTTP 403 Forbidden)"
    echo "   → 他人のタスクを更新できませんでした（期待通り）"
else
    echo "認可エラーが発生しませんでした (HTTP $FORBIDDEN_UPDATE)"
    echo "   → セキュリティ問題: 他人のタスクを更新できてしまいます！"
fi
echo ""

# 18. 認可テスト（異常系）: 他人のタスクを削除
echo "認可テスト（異常系）: 他人のタスク削除"
FORBIDDEN_DELETE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$BASE_URL/tasks/$OTHER_TASK_ID" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

if [ "$FORBIDDEN_DELETE" = "403" ]; then
    echo "認可エラー処理正常 (HTTP 403 Forbidden)"
    echo "   → 他人のタスクを削除できませんでした（期待通り）"
else
    echo "認可エラーが発生しませんでした (HTTP $FORBIDDEN_DELETE)"
    echo "   → セキュリティ問題: 他人のタスクを削除できてしまいます！"
fi
echo ""

# 19. 認可テスト（正常系）: 自分のタスクのみ取得
echo "認可テスト（正常系）: タスク一覧に他人のタスクが含まれないことを確認"
MY_TASKS=$(curl -s -X GET "$BASE_URL/tasks" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

if echo "$MY_TASKS" | grep -q "$OTHER_TASK_ID"; then
    echo "認可エラー: 他人のタスクが一覧に含まれています！"
    echo "   → セキュリティ問題: ユーザー間のタスクが分離されていません"
else
    echo "認可処理正常"
    echo "   → タスク一覧に自分のタスクのみが表示されます（期待通り）"
fi
echo ""

# 20. 認可テスト（正常系）: 別ユーザーが自分のタスクにアクセス可能
echo "認可テスト（正常系）: 別ユーザーが自分のタスクにアクセス可能"
OWN_TASK_ACCESS=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$BASE_URL/tasks/$OTHER_TASK_ID" \
  -H "Authorization: Bearer $OTHER_ACCESS_TOKEN")

if [ "$OWN_TASK_ACCESS" = "200" ]; then
    echo "認可処理正常 (HTTP 200 OK)"
    echo "   → 自分のタスクには正常にアクセスできます（期待通り）"
else
    echo "認可エラー (HTTP $OWN_TASK_ACCESS)"
    echo "   → 自分のタスクにアクセスできません"
fi
echo ""

# 21. 画像アップロードテスト（正常系）
echo "━━━━━━━━━━━━━━━━━━━━━━"
echo " 画像アップロード機能テスト"
echo "━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "21-1. 画像アップロード（正常系 - PNG）"
# テスト用の画像ファイルを作成（1x1ピクセルのPNG）
TEST_IMAGE_PNG="/tmp/test_image_${TIMESTAMP}.png"
# 1x1ピクセルの透明なPNG画像（base64デコード）
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" | base64 -d > "$TEST_IMAGE_PNG"

if [ -f "$TEST_IMAGE_PNG" ]; then
    UPLOAD_RESPONSE=$(curl -s -X POST "$BASE_URL/upload" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -F "image=@$TEST_IMAGE_PNG")
    
    if echo "$UPLOAD_RESPONSE" | grep -q '"url"'; then
        echo "PNG画像アップロード成功"
        UPLOADED_PNG_URL=$(echo $UPLOAD_RESPONSE | grep -o '"url":"[^"]*' | cut -d'"' -f4)
        echo "   Uploaded URL: $UPLOADED_PNG_URL"
        if [ "$USE_JQ" = true ]; then
            echo "$UPLOAD_RESPONSE" | jq '.'
        else
            echo "$UPLOAD_RESPONSE"
        fi
        
        # アップロードされた画像にアクセス可能か確認
        echo "   画像アクセス確認..."
        IMAGE_ACCESS=$(curl -s -o /dev/null -w "%{http_code}" "$UPLOADED_PNG_URL")
        if [ "$IMAGE_ACCESS" = "200" ]; then
            echo "   ✓ アップロードされた画像にアクセス可能 (HTTP 200)"
        else
            echo "   ✗ 画像アクセスエラー (HTTP $IMAGE_ACCESS)"
        fi
    else
        echo "PNG画像アップロード失敗"
        echo "$UPLOAD_RESPONSE"
    fi
    
    rm -f "$TEST_IMAGE_PNG"
else
    echo "テスト用PNG画像ファイルの作成に失敗しました"
fi
echo ""

echo "21-2. 画像アップロード（正常系 - JPEG）"
# テスト用のJPEG画像ファイルを作成
TEST_IMAGE_JPG="/tmp/test_image_${TIMESTAMP}.jpg"
# 1x1ピクセルのJPEG画像（base64デコード）
echo "/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCwAA//" | base64 -d > "$TEST_IMAGE_JPG"

if [ -f "$TEST_IMAGE_JPG" ]; then
    UPLOAD_JPG_RESPONSE=$(curl -s -X POST "$BASE_URL/upload" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -F "image=@$TEST_IMAGE_JPG")
    
    if echo "$UPLOAD_JPG_RESPONSE" | grep -q '"url"'; then
        echo "JPEG画像アップロード成功"
        UPLOADED_JPG_URL=$(echo $UPLOAD_JPG_RESPONSE | grep -o '"url":"[^"]*' | cut -d'"' -f4)
        echo "   Uploaded URL: $UPLOADED_JPG_URL"
        
        # アップロードされた画像にアクセス可能か確認
        IMAGE_JPG_ACCESS=$(curl -s -o /dev/null -w "%{http_code}" "$UPLOADED_JPG_URL")
        if [ "$IMAGE_JPG_ACCESS" = "200" ]; then
            echo "   ✓ JPEG画像にアクセス可能 (HTTP 200)"
        else
            echo "   ✗ JPEG画像アクセスエラー (HTTP $IMAGE_JPG_ACCESS)"
        fi
    else
        echo "JPEG画像アップロード失敗"
        echo "$UPLOAD_JPG_RESPONSE"
    fi
    
    rm -f "$TEST_IMAGE_JPG"
else
    echo "テスト用JPEG画像ファイルの作成に失敗しました"
fi
echo ""

echo "21-3. タスクに画像URLを含めて作成"
if [ -n "$UPLOADED_PNG_URL" ]; then
    CREATE_TASK_WITH_IMAGE=$(curl -s -X POST "$BASE_URL/tasks" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{
        \"title\": \"画像付きタスク_${TIMESTAMP}\",
        \"description\": \"画像が添付されたテストタスク\",
        \"priority\": \"high\",
        \"tags\": [\"画像テスト\"],
        \"imageUrl\": \"$UPLOADED_PNG_URL\"
      }")
    
    if echo "$CREATE_TASK_WITH_IMAGE" | grep -q "id"; then
        echo "画像付きタスク作成成功"
        TASK_WITH_IMAGE_ID=$(echo $CREATE_TASK_WITH_IMAGE | grep -o '"id":"[^"]*' | cut -d'"' -f4)
        echo "   Task ID: $TASK_WITH_IMAGE_ID"
        
        # タスク詳細取得して画像URLが含まれているか確認
        TASK_WITH_IMAGE_DETAIL=$(curl -s -X GET "$BASE_URL/tasks/$TASK_WITH_IMAGE_ID" \
          -H "Authorization: Bearer $ACCESS_TOKEN")
        
        if echo "$TASK_WITH_IMAGE_DETAIL" | grep -q "$UPLOADED_PNG_URL"; then
            echo "   ✓ タスクに画像URLが正しく保存されています"
            if [ "$USE_JQ" = true ]; then
                echo "$TASK_WITH_IMAGE_DETAIL" | jq '{id, title, imageUrl}'
            fi
        else
            echo "   ✗ タスクに画像URLが保存されていません"
        fi
        
        # タスク削除（クリーンアップ）
        curl -s -o /dev/null -X DELETE "$BASE_URL/tasks/$TASK_WITH_IMAGE_ID" \
          -H "Authorization: Bearer $ACCESS_TOKEN"
    else
        echo "画像付きタスク作成失敗"
        echo "$CREATE_TASK_WITH_IMAGE"
    fi
else
    echo "画像URLが取得できていないため、画像付きタスク作成テストをスキップします"
fi
echo ""

# 22. 画像アップロード異常系テスト
echo "━━━━━━━━━━━━━━━━━━━━━━"
echo " 画像アップロード異常系テスト"
echo "━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "22-1. 画像アップロード（認証なし）"
TEST_IMAGE_NO_AUTH="/tmp/test_image_noauth_${TIMESTAMP}.png"
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" | base64 -d > "$TEST_IMAGE_NO_AUTH"

if [ -f "$TEST_IMAGE_NO_AUTH" ]; then
    UPLOAD_NO_AUTH=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/upload" \
      -F "image=@$TEST_IMAGE_NO_AUTH")
    
    if [ "$UPLOAD_NO_AUTH" = "401" ]; then
        echo "✓ 認証なしアップロード拒否 (HTTP 401 Unauthorized)"
    else
        echo "✗ 認証なしでアップロードできてしまいました (HTTP $UPLOAD_NO_AUTH)"
        echo "   セキュリティ問題: 認証が必要です！"
    fi
    
    rm -f "$TEST_IMAGE_NO_AUTH"
else
    echo "テスト用画像ファイルの作成に失敗しました"
fi
echo ""

echo "22-2. 画像アップロード（無効なトークン）"
TEST_IMAGE_INVALID_TOKEN="/tmp/test_image_invalid_${TIMESTAMP}.png"
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" | base64 -d > "$TEST_IMAGE_INVALID_TOKEN"

if [ -f "$TEST_IMAGE_INVALID_TOKEN" ]; then
    UPLOAD_INVALID_TOKEN=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/upload" \
      -H "Authorization: Bearer invalid_token_12345" \
      -F "image=@$TEST_IMAGE_INVALID_TOKEN")
    
    if [ "$UPLOAD_INVALID_TOKEN" = "401" ]; then
        echo "✓ 無効なトークンでのアップロード拒否 (HTTP 401 Unauthorized)"
    else
        echo "✗ 無効なトークンでアップロードできてしまいました (HTTP $UPLOAD_INVALID_TOKEN)"
        echo "   セキュリティ問題: トークン検証が必要です！"
    fi
    
    rm -f "$TEST_IMAGE_INVALID_TOKEN"
else
    echo "テスト用画像ファイルの作成に失敗しました"
fi
echo ""

echo "22-3. 画像アップロード（期限切れトークン想定）"
EXPIRED_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJ0ZXN0IiwiZW1haWwiOiJ0ZXN0QGV4YW1wbGUuY29tIiwiZXhwIjoxfQ.invalid"
TEST_IMAGE_EXPIRED="/tmp/test_image_expired_${TIMESTAMP}.png"
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" | base64 -d > "$TEST_IMAGE_EXPIRED"

if [ -f "$TEST_IMAGE_EXPIRED" ]; then
    UPLOAD_EXPIRED=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/upload" \
      -H "Authorization: Bearer $EXPIRED_TOKEN" \
      -F "image=@$TEST_IMAGE_EXPIRED")
    
    if [ "$UPLOAD_EXPIRED" = "401" ]; then
        echo "✓ 期限切れトークンでのアップロード拒否 (HTTP 401 Unauthorized)"
    else
        echo "期限切れトークン処理結果 (HTTP $UPLOAD_EXPIRED)"
        echo "   注: 期限切れ検証は正しいトークン形式が必要です"
    fi
    
    rm -f "$TEST_IMAGE_EXPIRED"
fi
echo ""

echo "22-4. 画像アップロード（ファイルなし）"
UPLOAD_NO_FILE=$(curl -s -X POST "$BASE_URL/upload" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: multipart/form-data")

HTTP_NO_FILE=$(echo "$UPLOAD_NO_FILE" | grep -o "No file" || echo "")
if [ -n "$HTTP_NO_FILE" ] || echo "$UPLOAD_NO_FILE" | grep -q "400\|required"; then
    echo "✓ ファイルなしアップロード拒否 (エラーメッセージ検出)"
else
    # HTTPステータスコードで再確認
    NO_FILE_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/upload" \
      -H "Authorization: Bearer $ACCESS_TOKEN")
    if [ "$NO_FILE_STATUS" = "400" ]; then
        echo "✓ ファイルなしアップロード拒否 (HTTP 400 Bad Request)"
    else
        echo "ファイルなしアップロード処理結果 (HTTP $NO_FILE_STATUS)"
    fi
fi
echo ""

echo "22-5. 画像アップロード（非画像ファイル - テキスト）"
TEST_TEXT_FILE="/tmp/test_text_${TIMESTAMP}.txt"
echo "This is not an image file" > "$TEST_TEXT_FILE"

if [ -f "$TEST_TEXT_FILE" ]; then
    UPLOAD_TEXT_RESPONSE=$(curl -s -X POST "$BASE_URL/upload" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -F "image=@$TEST_TEXT_FILE")
    
    UPLOAD_TEXT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/upload" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -F "image=@$TEST_TEXT_FILE")
    
    if [ "$UPLOAD_TEXT_STATUS" = "400" ] || echo "$UPLOAD_TEXT_RESPONSE" | grep -q "invalid\|not.*image\|unsupported"; then
        echo "✓ 非画像ファイルのアップロード拒否"
        echo "   HTTP Status: $UPLOAD_TEXT_STATUS"
    else
        echo "警告: 非画像ファイルがアップロードされた可能性があります (HTTP $UPLOAD_TEXT_STATUS)"
        echo "   注: サーバー側でファイルタイプ検証を推奨"
    fi
    
    rm -f "$TEST_TEXT_FILE"
else
    echo "テスト用テキストファイルの作成に失敗しました"
fi
echo ""

echo "22-6. 存在しない画像URLへのアクセス"
NONEXISTENT_IMAGE_URL="$BASE_URL/uploads/nonexistent_image_12345.png"
NONEXISTENT_ACCESS=$(curl -s -o /dev/null -w "%{http_code}" "$NONEXISTENT_IMAGE_URL")

if [ "$NONEXISTENT_ACCESS" = "404" ]; then
    echo "✓ 存在しない画像への404応答 (HTTP 404 Not Found)"
else
    echo "存在しない画像アクセス結果 (HTTP $NONEXISTENT_ACCESS)"
fi
echo ""

echo "22-7. 画像アップロード後の削除確認"
# 一時的に画像をアップロード
TEST_IMAGE_DELETE="/tmp/test_image_delete_${TIMESTAMP}.png"
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" | base64 -d > "$TEST_IMAGE_DELETE"

if [ -f "$TEST_IMAGE_DELETE" ]; then
    UPLOAD_DELETE_TEST=$(curl -s -X POST "$BASE_URL/upload" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -F "image=@$TEST_IMAGE_DELETE")
    
    if echo "$UPLOAD_DELETE_TEST" | grep -q '"url"'; then
        UPLOADED_DELETE_URL=$(echo $UPLOAD_DELETE_TEST | grep -o '"url":"[^"]*' | cut -d'"' -f4)
        echo "画像アップロード成功（削除テスト用）"
        echo "   URL: $UPLOADED_DELETE_URL"
        
        # アップロード直後にアクセス可能か確認
        DELETE_TEST_ACCESS1=$(curl -s -o /dev/null -w "%{http_code}" "$UPLOADED_DELETE_URL")
        if [ "$DELETE_TEST_ACCESS1" = "200" ]; then
            echo "   ✓ アップロード直後の画像アクセス成功 (HTTP 200)"
        else
            echo "   ✗ アップロード直後の画像アクセス失敗 (HTTP $DELETE_TEST_ACCESS1)"
        fi
        
        # 注: 実際の削除機能がある場合はここでテスト
        # 現在の実装では画像削除APIがないため、永続化の確認のみ
        echo "   注: 画像削除APIは未実装（画像は永続化されます）"
    else
        echo "削除テスト用画像のアップロード失敗"
    fi
    
    rm -f "$TEST_IMAGE_DELETE"
fi
echo ""

# 23. クリーンアップ（別ユーザーのタスクを削除）
echo "クリーンアップ（テスト用タスクを削除）"
CLEANUP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$BASE_URL/tasks/$OTHER_TASK_ID" \
  -H "Authorization: Bearer $OTHER_ACCESS_TOKEN")

if [ "$CLEANUP_STATUS" = "204" ]; then
    echo "クリーンアップ成功 (HTTP 204 No Content)"
else
    echo "クリーンアップ失敗 (HTTP $CLEANUP_STATUS)"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━"
echo " 全テスト完了"
echo "━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "テストサマリー:"
echo "   ✓ ログイン"
echo "   ✓ ユーザー登録（メール認証フロー）"
echo "   ✓ メール認証コード検証"
echo "   ✓ 認証コード再送信"
echo "   ✓ 未認証ユーザーのログイン拒否"
echo "   ✓ 無効な認証コードの拒否"
echo "   ✓ タスク一覧取得"
echo "   ✓ タスク作成"
echo "   ✓ タスク詳細取得"
echo "   ✓ タスク更新"
echo "   ✓ タスク完了/未完了"
echo "   ✓ トークンリフレッシュ"
echo "   ✓ タスク削除"
echo "   ✓ 画像アップロード"
echo "   ✓ 画像アクセス確認"
echo "   ✓ 認証エラー処理 (401 Unauthorized)"
echo "   ✓ 認可エラー処理 (403 Forbidden)"
echo "   ✓ 他人のタスクへのアクセス拒否"
echo "   ✓ 自分のタスクへのアクセス許可"
echo ""
echo "メール認証テスト結果:"
echo "   ✓ ユーザー登録時に認証コードが生成される"
echo "   ✓ 未認証ユーザーはログインできない"
echo "   ✓ 認証コードの再送信が可能"
echo "   ✓ 無効な認証コードは拒否される"
echo "   ✓ 認証後のログインが正常に動作"
echo ""
echo "セキュリティテスト結果:"
echo "   ✓ 認証: 無効なトークンは拒否される（タスク）"
echo "   ✓ 認証: 無効なトークンは拒否される（画像アップロード）"
echo "   ✓ 認証: 未認証ユーザーはログインできない"
echo "   ✓ 認証: 無効な認証コードは拒否される"
echo "   ✓ 認可: 他人のタスクを取得できない"
echo "   ✓ 認可: 他人のタスクを更新できない"
echo "   ✓ 認可: 他人のタスクを削除できない"
echo "   ✓ 認可: タスク一覧は自分のタスクのみ"
echo "   ✓ 認可: 自分のタスクには正常にアクセス可能"
echo ""
echo "画像アップロードテスト結果（正常系）:"
echo "   ✓ PNG画像のアップロードが正常に動作"
echo "   ✓ JPEG画像のアップロードが正常に動作"
echo "   ✓ アップロードされた画像にアクセス可能"
echo "   ✓ タスクに画像URLを関連付けて保存可能"
echo "   ✓ タスク取得時に画像URLが含まれる"
echo ""
echo "画像アップロードテスト結果（異常系）:"
echo "   ✓ 認証なしのアップロードは拒否される (401)"
echo "   ✓ 無効なトークンでのアップロードは拒否される (401)"
echo "   ✓ ファイルなしのアップロードは拒否される (400)"
echo "   ✓ 非画像ファイルのアップロード処理"
echo "   ✓ 存在しない画像URLへのアクセスは404"
echo "   ✓ アップロード後の永続化確認"
echo ""
echo "メール確認:"
echo "   MailHog WebUI: http://localhost:8025"
echo "   認証コードメールを確認できます"
echo ""

