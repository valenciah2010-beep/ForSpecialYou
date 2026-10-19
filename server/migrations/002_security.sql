CREATE TABLE IF NOT EXISTS auth_sessions (
 token_hash CHAR(64) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
 user_id INT NOT NULL, kind ENUM('admin','app') NOT NULL,
 expires_at DATETIME NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 INDEX session_expiry (expires_at), INDEX user_sessions (user_id),
 FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS ai_daily_usage (
 user_id INT NOT NULL, usage_date DATE NOT NULL, kind VARCHAR(20) NOT NULL,
 used INT NOT NULL DEFAULT 0,
 PRIMARY KEY (user_id, usage_date, kind),
 FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS audit_events (
 id BIGINT AUTO_INCREMENT PRIMARY KEY, actor_id INT NULL,
 action VARCHAR(80) NOT NULL, target_id INT NULL,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 INDEX audit_created (created_at)
);
CREATE TABLE IF NOT EXISTS api_rate_limits (
 bucket CHAR(64) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
 window_start BIGINT NOT NULL, hits INT NOT NULL, expires_at DATETIME NOT NULL,
 INDEX rate_expiry (expires_at)
);
