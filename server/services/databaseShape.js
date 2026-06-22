import { pool } from '../db.js';

let databaseShapeReady = false;

export async function ensureDatabaseShape() {
  let setupFailed = false;

  try {
    await pool.execute(
      "ALTER TABLE users MODIFY role ENUM('patient', 'parent', 'caregiver', 'doctor', 'admin') NOT NULL"
    );
    await pool.execute("UPDATE users SET role = 'parent' WHERE role = 'patient'");
  } catch (error) {
    setupFailed = true;
    console.error('Role setup check failed:', error.message);
  }

  try {
    const [columns] = await pool.execute(
      `SELECT COLUMN_NAME
       FROM INFORMATION_SCHEMA.COLUMNS
       WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'users'
        AND COLUMN_NAME = 'profile_image'`
    );

    if (columns.length === 0) {
      await pool.execute('ALTER TABLE users ADD COLUMN profile_image LONGTEXT NULL');
    }
  } catch (error) {
    setupFailed = true;
    console.error('Profile image setup check failed:', error.message);
  }

  try {
    const [columns] = await pool.execute(
      `SELECT COLUMN_NAME
       FROM INFORMATION_SCHEMA.COLUMNS
       WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'users'
        AND COLUMN_NAME IN ('blocked_until', 'blocked_indefinitely')`
    );
    const existingColumns = new Set(columns.map((column) => column.COLUMN_NAME));

    if (!existingColumns.has('blocked_until')) {
      await pool.execute('ALTER TABLE users ADD COLUMN blocked_until DATETIME NULL');
    }

    if (!existingColumns.has('blocked_indefinitely')) {
      await pool.execute('ALTER TABLE users ADD COLUMN blocked_indefinitely TINYINT(1) NOT NULL DEFAULT 0');
    }
  } catch (error) {
    setupFailed = true;
    console.error('User block setup check failed:', error.message);
  }

  try {
    await pool.execute(
      `CREATE TABLE IF NOT EXISTS parent_app_data (
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
      )`
    );

    const [columns] = await pool.execute(
      `SELECT COLUMN_NAME
       FROM INFORMATION_SCHEMA.COLUMNS
       WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'parent_app_data'
        AND COLUMN_NAME IN ('saved_meals', 'nutrient_daily_usage', 'nutrient_daily_limit')`
    );
    const existingColumns = new Set(columns.map((column) => column.COLUMN_NAME));

    if (!existingColumns.has('saved_meals')) {
      await pool.execute('ALTER TABLE parent_app_data ADD COLUMN saved_meals LONGTEXT NULL AFTER health_logs');
    }

    if (!existingColumns.has('nutrient_daily_usage')) {
      await pool.execute('ALTER TABLE parent_app_data ADD COLUMN nutrient_daily_usage LONGTEXT NULL AFTER saved_meals');
    }

    if (!existingColumns.has('nutrient_daily_limit')) {
      await pool.execute('ALTER TABLE parent_app_data ADD COLUMN nutrient_daily_limit INT NOT NULL DEFAULT 3 AFTER nutrient_daily_usage');
    }
  } catch (error) {
    setupFailed = true;
    console.error('Parent app data setup check failed:', error.message);
  }

  databaseShapeReady = !setupFailed;
}

export async function ensureDatabaseShapeReady() {
  if (!databaseShapeReady) {
    await ensureDatabaseShape();
  }
}
