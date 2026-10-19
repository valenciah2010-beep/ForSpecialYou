CREATE TABLE IF NOT EXISTS storage_retention_policy (
  id TINYINT UNSIGNED PRIMARY KEY,
  incomplete_hours INT UNSIGNED NOT NULL DEFAULT 24,
  completed_days INT UNSIGNED NULL DEFAULT 30,
  revision INT UNSIGNED NOT NULL DEFAULT 1,
  updated_by INT NULL,
  updated_at DATETIME NOT NULL
);

INSERT IGNORE INTO storage_retention_policy
  (id, incomplete_hours, completed_days, revision, updated_at)
VALUES (1, 24, 30, 1, UTC_TIMESTAMP());

-- Only upload metadata changes; users and parent_app_data remain untouched.
ALTER TABLE image_uploads MODIFY expires_at DATETIME NULL;

SET @has_retention_start = (
  SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'image_uploads'
    AND COLUMN_NAME = 'retention_started_at'
);
SET @retention_sql = IF(@has_retention_start = 0,
  'ALTER TABLE image_uploads ADD COLUMN retention_started_at DATETIME NULL',
  'SELECT 1');
PREPARE retention_statement FROM @retention_sql;
EXECUTE retention_statement;
DEALLOCATE PREPARE retention_statement;

-- Recover the UTC start from the former fixed deadlines without changing them.
UPDATE image_uploads
SET retention_started_at = IF(completed = 1,
  DATE_SUB(expires_at, INTERVAL 30 DAY), DATE_SUB(expires_at, INTERVAL 1 DAY))
WHERE retention_started_at IS NULL AND expires_at IS NOT NULL;
