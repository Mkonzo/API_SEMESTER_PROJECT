-- ============================================================
-- 010 Fix: make the table-sizes view portable (found by the GitHub check)
-- Run ONCE on your existing database (running it again is harmless).
--
-- Problem: on Windows, mysqldump wrote this view with the table name in
-- lowercase (`information_schema`.`tables`). A Linux server, such as the
-- one GitHub or Docker uses, treats `tables` and `TABLES` as different
-- names, so the saved export failed to load there.
-- Fix: give the table an alias, so the view no longer depends on how the
-- name is capitalised, and compare the database name without case.
-- ============================================================
USE KISII_LIBRARY;

CREATE OR REPLACE VIEW v_monitor_table_sizes AS
SELECT t.TABLE_NAME AS Table_name,
       t.TABLE_ROWS AS Approx_rows,
       ROUND((t.DATA_LENGTH + t.INDEX_LENGTH) / 1024 / 1024, 3) AS Size_mb
FROM information_schema.TABLES AS t
WHERE LOWER(t.TABLE_SCHEMA) = LOWER('KISII_LIBRARY')
  AND t.TABLE_TYPE = 'BASE TABLE';
