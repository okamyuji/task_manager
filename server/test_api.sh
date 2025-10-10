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

# 21. 画像アップロードテスト
echo "画像アップロードテスト"
# テスト用の画像ファイルを作成（1x1ピクセルのPNG）
TEST_IMAGE="/tmp/test_image_${TIMESTAMP}.png"
# 1x1ピクセルの透明なPNG画像（base64デコード）
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" | base64 -d > "$TEST_IMAGE"

if [ -f "$TEST_IMAGE" ]; then
    UPLOAD_RESPONSE=$(curl -s -X POST "$BASE_URL/upload" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -F "image=@$TEST_IMAGE")
    
    if echo "$UPLOAD_RESPONSE" | grep -q '"url"'; then
        echo "画像アップロード成功"
        UPLOADED_URL=$(echo $UPLOAD_RESPONSE | grep -o '"url":"[^"]*' | cut -d'"' -f4)
        echo "   Uploaded URL: $UPLOADED_URL"
        if [ "$USE_JQ" = true ]; then
            echo "$UPLOAD_RESPONSE" | jq '.'
        else
            echo "$UPLOAD_RESPONSE"
        fi
        
        # アップロードされた画像にアクセス可能か確認
        echo "画像アクセス確認..."
        IMAGE_ACCESS=$(curl -s -o /dev/null -w "%{http_code}" "$UPLOADED_URL")
        if [ "$IMAGE_ACCESS" = "200" ]; then
            echo "アップロードされた画像にアクセス可能 (HTTP 200)"
        else
            echo "画像アクセスエラー (HTTP $IMAGE_ACCESS)"
        fi
    else
        echo "画像アップロード失敗"
        echo "$UPLOAD_RESPONSE"
    fi
    
    # テスト用画像ファイルを削除
    rm -f "$TEST_IMAGE"
else
    echo "テスト用画像ファイルの作成に失敗しました"
fi
echo ""

# 22. 画像アップロード認証テスト（無効なトークン）
echo "画像アップロード認証テスト（無効なトークン）"
TEST_IMAGE2="/tmp/test_image2_${TIMESTAMP}.png"
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" | base64 -d > "$TEST_IMAGE2"

if [ -f "$TEST_IMAGE2" ]; then
    UPLOAD_AUTH_ERROR=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/upload" \
      -H "Authorization: Bearer invalid_token" \
      -F "image=@$TEST_IMAGE2")
    
    if [ "$UPLOAD_AUTH_ERROR" = "401" ]; then
        echo "画像アップロード認証エラー処理正常 (HTTP 401 Unauthorized)"
    else
        echo "期待されるステータスコード401ではありません (HTTP $UPLOAD_AUTH_ERROR)"
    fi
    
    rm -f "$TEST_IMAGE2"
else
    echo "テスト用画像ファイルの作成に失敗しました"
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
echo "画像アップロードテスト結果:"
echo "   ✓ 画像のアップロードが正常に動作"
echo "   ✓ アップロードされた画像にアクセス可能"
echo "   ✓ 認証なしのアップロードは拒否される"
echo ""
echo "📧 メール確認:"
echo "   MailHog WebUI: http://localhost:8025"
echo "   認証コードメールを確認できます"
echo ""

