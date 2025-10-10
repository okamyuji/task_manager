-- シードデータ: テストユーザー（パスワード: password123）

-- テストユーザー（bcryptハッシュ: password123, cost=12）
INSERT OR IGNORE INTO users (id, email, password_hash, name, is_verified, created_at, updated_at) 
VALUES (
    'user-1',
    'test@example.com',
    '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyYIpPnVZFPu',
    'テストユーザー',
    TRUE,
    datetime('now'),
    datetime('now')
);

-- サンプルタスク
INSERT OR IGNORE INTO tasks (id, user_id, title, description, created_at, due_date, is_completed, completed_at, priority)
VALUES 
    (
        '1',
        'user-1',
        'Flutterを学ぶ',
        '基本的な概念を理解する',
        datetime('now'),
        NULL,
        FALSE,
        NULL,
        'high'
    ),
    (
        '2',
        'user-1',
        'Riverpodを理解する',
        'Provider、StateNotifierの違いを学ぶ',
        datetime('now'),
        datetime('now', '+7 days'),
        FALSE,
        NULL,
        'medium'
    ),
    (
        '3',
        'user-1',
        'リスト表示を実装',
        'ListViewとNavigationの使い方',
        datetime('now'),
        NULL,
        TRUE,
        datetime('now', '-1 day'),
        'low'
    ),
    (
        '4',
        'user-1',
        'REST API統合',
        'DioとRetrofitでバックエンドと通信',
        datetime('now'),
        datetime('now', '+3 days'),
        FALSE,
        NULL,
        'urgent'
    ),
    (
        '5',
        'user-1',
        'JWT認証の実装',
        'セキュアな認証フローを構築',
        datetime('now'),
        NULL,
        FALSE,
        NULL,
        'high'
    );

-- サンプルタスクのタグ
INSERT OR IGNORE INTO task_tags (task_id, tag) VALUES
    ('1', '学習'),
    ('1', 'Flutter'),
    ('2', '学習'),
    ('2', 'フレームワーク'),
    ('3', '実装'),
    ('4', '実装'),
    ('4', 'ネットワーク'),
    ('5', 'セキュリティ'),
    ('5', '認証');

