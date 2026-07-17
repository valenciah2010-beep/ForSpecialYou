-- ForSpecialYou / Care Portal database update file
-- Use this on a server that may already have the care_portal database.
-- It creates missing tables/columns only and does not drop or overwrite existing records.

CREATE DATABASE IF NOT EXISTS care_portal
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE care_portal;

CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(80) NOT NULL UNIQUE,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('patient', 'parent', 'caregiver', 'doctor', 'admin') NOT NULL,
  profile_image LONGTEXT NULL,
  blocked_until DATETIME NULL,
  blocked_indefinitely TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS parent_app_data (
  user_id INT PRIMARY KEY,
  child_profile LONGTEXT NULL,
  health_logs LONGTEXT NULL,
  saved_meals LONGTEXT NULL,
  nutrient_daily_usage LONGTEXT NULL,
  nutrient_daily_limit INT NOT NULL DEFAULT 3,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT parent_app_data_user_fk
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
);

-- Keep old databases compatible with current app roles.
ALTER TABLE users
  MODIFY role ENUM('patient', 'parent', 'caregiver', 'doctor', 'admin') NOT NULL;

UPDATE users
SET role = 'parent'
WHERE role = 'patient';

-- users.profile_image
SET @has_column = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'users'
    AND COLUMN_NAME = 'profile_image'
);

SET @sql = IF(
  @has_column = 0,
  'ALTER TABLE users ADD COLUMN profile_image LONGTEXT NULL',
  'SELECT ''users.profile_image already exists'' AS message'
);
PREPARE statement_to_run FROM @sql;
EXECUTE statement_to_run;
DEALLOCATE PREPARE statement_to_run;

-- users.blocked_until
SET @has_column = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'users'
    AND COLUMN_NAME = 'blocked_until'
);

SET @sql = IF(
  @has_column = 0,
  'ALTER TABLE users ADD COLUMN blocked_until DATETIME NULL',
  'SELECT ''users.blocked_until already exists'' AS message'
);
PREPARE statement_to_run FROM @sql;
EXECUTE statement_to_run;
DEALLOCATE PREPARE statement_to_run;

-- users.blocked_indefinitely
SET @has_column = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'users'
    AND COLUMN_NAME = 'blocked_indefinitely'
);

SET @sql = IF(
  @has_column = 0,
  'ALTER TABLE users ADD COLUMN blocked_indefinitely TINYINT(1) NOT NULL DEFAULT 0',
  'SELECT ''users.blocked_indefinitely already exists'' AS message'
);
PREPARE statement_to_run FROM @sql;
EXECUTE statement_to_run;
DEALLOCATE PREPARE statement_to_run;

-- parent_app_data.child_profile
SET @has_column = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'parent_app_data'
    AND COLUMN_NAME = 'child_profile'
);

SET @sql = IF(
  @has_column = 0,
  'ALTER TABLE parent_app_data ADD COLUMN child_profile LONGTEXT NULL',
  'SELECT ''parent_app_data.child_profile already exists'' AS message'
);
PREPARE statement_to_run FROM @sql;
EXECUTE statement_to_run;
DEALLOCATE PREPARE statement_to_run;

-- parent_app_data.health_logs
SET @has_column = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'parent_app_data'
    AND COLUMN_NAME = 'health_logs'
);

SET @sql = IF(
  @has_column = 0,
  'ALTER TABLE parent_app_data ADD COLUMN health_logs LONGTEXT NULL AFTER child_profile',
  'SELECT ''parent_app_data.health_logs already exists'' AS message'
);
PREPARE statement_to_run FROM @sql;
EXECUTE statement_to_run;
DEALLOCATE PREPARE statement_to_run;

-- parent_app_data.saved_meals
SET @has_column = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'parent_app_data'
    AND COLUMN_NAME = 'saved_meals'
);

SET @sql = IF(
  @has_column = 0,
  'ALTER TABLE parent_app_data ADD COLUMN saved_meals LONGTEXT NULL AFTER health_logs',
  'SELECT ''parent_app_data.saved_meals already exists'' AS message'
);
PREPARE statement_to_run FROM @sql;
EXECUTE statement_to_run;
DEALLOCATE PREPARE statement_to_run;

-- parent_app_data.nutrient_daily_usage
SET @has_column = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'parent_app_data'
    AND COLUMN_NAME = 'nutrient_daily_usage'
);

SET @sql = IF(
  @has_column = 0,
  'ALTER TABLE parent_app_data ADD COLUMN nutrient_daily_usage LONGTEXT NULL AFTER saved_meals',
  'SELECT ''parent_app_data.nutrient_daily_usage already exists'' AS message'
);
PREPARE statement_to_run FROM @sql;
EXECUTE statement_to_run;
DEALLOCATE PREPARE statement_to_run;

-- parent_app_data.nutrient_daily_limit
SET @has_column = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'parent_app_data'
    AND COLUMN_NAME = 'nutrient_daily_limit'
);

SET @sql = IF(
  @has_column = 0,
  'ALTER TABLE parent_app_data ADD COLUMN nutrient_daily_limit INT NOT NULL DEFAULT 3 AFTER nutrient_daily_usage',
  'SELECT ''parent_app_data.nutrient_daily_limit already exists'' AS message'
);
PREPARE statement_to_run FROM @sql;
EXECUTE statement_to_run;
DEALLOCATE PREPARE statement_to_run;

-- parent_app_data.updated_at
SET @has_column = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'parent_app_data'
    AND COLUMN_NAME = 'updated_at'
);

SET @sql = IF(
  @has_column = 0,
  'ALTER TABLE parent_app_data ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP',
  'SELECT ''parent_app_data.updated_at already exists'' AS message'
);
PREPARE statement_to_run FROM @sql;
EXECUTE statement_to_run;
DEALLOCATE PREPARE statement_to_run;
