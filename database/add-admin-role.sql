USE care_portal;

ALTER TABLE users
  MODIFY role ENUM('patient', 'parent', 'caregiver', 'doctor', 'admin') NOT NULL;
