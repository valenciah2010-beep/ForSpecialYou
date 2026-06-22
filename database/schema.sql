CREATE DATABASE IF NOT EXISTS care_portal;
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
