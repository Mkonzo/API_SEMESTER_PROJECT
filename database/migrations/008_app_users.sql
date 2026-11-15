-- ============================================================
-- 008 Database users with limited rights (D8: security)
-- Run ONCE, as root, in the MySQL Command Line Client.
--
-- PASSWORDS ARE NEVER SAVED IN THIS FILE. Set them first, in the same
-- client window, with your own strong passwords (no single quotes in them):
--
--   SET @app_pw    = 'choose-a-strong-password-1';
--   SET @ro_pw     = 'choose-a-strong-password-2';
--   SET @backup_pw = 'choose-a-strong-password-3';
--   SOURCE C:/Users/YOURNAME/documents/API_SEMESTER_PROJECT/database/migrations/008_app_users.sql;
--
-- If a password is not set, the script stops with an error and creates nothing.
--
-- For a hosted database, change 'localhost' to '%' in this file and add
-- REQUIRE SSL to each CREATE USER, so connections must be encrypted.
-- ============================================================

-- library_app: what the backend uses. Can read and change data, nothing else.
SET @sql = CONCAT('CREATE USER IF NOT EXISTS ''library_app''@''localhost'' IDENTIFIED BY ''', @app_pw, '''');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- library_readonly: for reports and the AI features. Can only read.
SET @sql = CONCAT('CREATE USER IF NOT EXISTS ''library_readonly''@''localhost'' IDENTIFIED BY ''', @ro_pw, '''');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- library_backup: only what a backup needs.
SET @sql = CONCAT('CREATE USER IF NOT EXISTS ''library_backup''@''localhost'' IDENTIFIED BY ''', @backup_pw, '''');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

GRANT SELECT, INSERT, UPDATE, DELETE ON KISII_LIBRARY.* TO 'library_app'@'localhost';
GRANT SELECT ON KISII_LIBRARY.* TO 'library_readonly'@'localhost';
GRANT SELECT, SHOW VIEW, TRIGGER, LOCK TABLES ON KISII_LIBRARY.* TO 'library_backup'@'localhost';

-- None of these users can create, change or drop tables, or touch other databases.

-- Check it worked:
-- SHOW GRANTS FOR 'library_app'@'localhost';
