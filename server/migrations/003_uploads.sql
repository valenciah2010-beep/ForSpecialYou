CREATE TABLE IF NOT EXISTS image_uploads (
 id CHAR(36) CHARACTER SET ascii COLLATE ascii_bin PRIMARY KEY,
 user_id INT NOT NULL, total_bytes INT NOT NULL, chunk_count INT NOT NULL,
 checksum CHAR(64) NOT NULL, completed TINYINT(1) NOT NULL DEFAULT 0,
 expires_at DATETIME NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 INDEX upload_owner (user_id), INDEX upload_expiry (expires_at),
 FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
