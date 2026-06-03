USE care_portal;

SET @has_profile_image = (
  SELECT COUNT(*)
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'users'
    AND COLUMN_NAME = 'profile_image'
);

SET @add_profile_image_sql = IF(
  @has_profile_image = 0,
  'ALTER TABLE users ADD COLUMN profile_image LONGTEXT NULL',
  'SELECT "profile_image column already exists"'
);

PREPARE add_profile_image_statement FROM @add_profile_image_sql;
EXECUTE add_profile_image_statement;
DEALLOCATE PREPARE add_profile_image_statement;
