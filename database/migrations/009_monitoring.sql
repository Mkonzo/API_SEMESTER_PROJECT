-- ============================================================
-- 009 Monitoring (D7): change log, health views and alert rules
-- Run ONCE, as root. Run it AFTER the sample data is loaded
-- (the sample-data scripts would otherwise fill the change log).
--
-- Adds:
--   audit_log           one row for every change to loans, fines and
--                       M-Pesa payments, and to a member's active/verified flag
--   v_monitor_health    one row of key numbers (a mini dashboard)
--   v_monitor_table_sizes   rows and size of every table
--   v_monitor_alerts    one row for every problem found right now
-- ============================================================
USE KISII_LIBRARY;

-- ---------- 1. The change log ----------
CREATE TABLE audit_log (
  Audit_ID   BIGINT       NOT NULL AUTO_INCREMENT,
  Table_name VARCHAR(64)  NOT NULL,
  Row_id     INT          NOT NULL,
  Action     ENUM('INSERT','UPDATE','DELETE') NOT NULL,
  Old_values JSON         NULL,
  New_values JSON         NULL,
  Changed_by VARCHAR(100) NOT NULL,
  Changed_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (Audit_ID),
  KEY idx_audit_table_row (Table_name, Row_id),
  KEY idx_audit_time (Changed_at)
) ENGINE=InnoDB;

-- ---------- 2. Loans ----------
CREATE TRIGGER trg_loans_insert AFTER INSERT ON loans FOR EACH ROW
  INSERT INTO audit_log (Table_name, Row_id, Action, New_values, Changed_by)
  VALUES ('loans', NEW.Loan_ID, 'INSERT',
          JSON_OBJECT('Book_ID', NEW.Book_ID, 'Member_ID', NEW.Member_ID, 'Due_date', NEW.Due_date,
                      'Returned_at', NEW.Returned_at, 'Renewal_count', NEW.Renewal_count, 'Status', NEW.Status),
          USER());

CREATE TRIGGER trg_loans_update AFTER UPDATE ON loans FOR EACH ROW
  INSERT INTO audit_log (Table_name, Row_id, Action, Old_values, New_values, Changed_by)
  VALUES ('loans', NEW.Loan_ID, 'UPDATE',
          JSON_OBJECT('Book_ID', OLD.Book_ID, 'Member_ID', OLD.Member_ID, 'Due_date', OLD.Due_date,
                      'Returned_at', OLD.Returned_at, 'Renewal_count', OLD.Renewal_count, 'Status', OLD.Status),
          JSON_OBJECT('Book_ID', NEW.Book_ID, 'Member_ID', NEW.Member_ID, 'Due_date', NEW.Due_date,
                      'Returned_at', NEW.Returned_at, 'Renewal_count', NEW.Renewal_count, 'Status', NEW.Status),
          USER());

CREATE TRIGGER trg_loans_delete AFTER DELETE ON loans FOR EACH ROW
  INSERT INTO audit_log (Table_name, Row_id, Action, Old_values, Changed_by)
  VALUES ('loans', OLD.Loan_ID, 'DELETE',
          JSON_OBJECT('Book_ID', OLD.Book_ID, 'Member_ID', OLD.Member_ID, 'Due_date', OLD.Due_date,
                      'Returned_at', OLD.Returned_at, 'Renewal_count', OLD.Renewal_count, 'Status', OLD.Status),
          USER());

-- ---------- 3. Fines ----------
CREATE TRIGGER trg_fines_insert AFTER INSERT ON fines FOR EACH ROW
  INSERT INTO audit_log (Table_name, Row_id, Action, New_values, Changed_by)
  VALUES ('fines', NEW.Fine_ID, 'INSERT',
          JSON_OBJECT('Loan_ID', NEW.Loan_ID, 'Member_ID', NEW.Member_ID, 'Status', NEW.Status, 'Reason', NEW.Reason,
                      'Amount', NEW.Amount, 'Paid_at', NEW.Paid_at, 'Mpesa_receipt', NEW.Mpesa_receipt),
          USER());

CREATE TRIGGER trg_fines_update AFTER UPDATE ON fines FOR EACH ROW
  INSERT INTO audit_log (Table_name, Row_id, Action, Old_values, New_values, Changed_by)
  VALUES ('fines', NEW.Fine_ID, 'UPDATE',
          JSON_OBJECT('Loan_ID', OLD.Loan_ID, 'Member_ID', OLD.Member_ID, 'Status', OLD.Status, 'Reason', OLD.Reason,
                      'Amount', OLD.Amount, 'Paid_at', OLD.Paid_at, 'Mpesa_receipt', OLD.Mpesa_receipt),
          JSON_OBJECT('Loan_ID', NEW.Loan_ID, 'Member_ID', NEW.Member_ID, 'Status', NEW.Status, 'Reason', NEW.Reason,
                      'Amount', NEW.Amount, 'Paid_at', NEW.Paid_at, 'Mpesa_receipt', NEW.Mpesa_receipt),
          USER());

CREATE TRIGGER trg_fines_delete AFTER DELETE ON fines FOR EACH ROW
  INSERT INTO audit_log (Table_name, Row_id, Action, Old_values, Changed_by)
  VALUES ('fines', OLD.Fine_ID, 'DELETE',
          JSON_OBJECT('Loan_ID', OLD.Loan_ID, 'Member_ID', OLD.Member_ID, 'Status', OLD.Status, 'Reason', OLD.Reason,
                      'Amount', OLD.Amount, 'Paid_at', OLD.Paid_at, 'Mpesa_receipt', OLD.Mpesa_receipt),
          USER());

-- ---------- 4. M-Pesa payments ----------
CREATE TRIGGER trg_mpesa_insert AFTER INSERT ON mpesa_transactions FOR EACH ROW
  INSERT INTO audit_log (Table_name, Row_id, Action, New_values, Changed_by)
  VALUES ('mpesa_transactions', NEW.Transaction_ID, 'INSERT',
          JSON_OBJECT('Fine_ID', NEW.Fine_ID, 'Member_ID', NEW.Member_ID, 'Amount', NEW.Amount,
                      'Status', NEW.Status, 'Mpesa_receipt', NEW.Mpesa_receipt, 'Completed_at', NEW.Completed_at),
          USER());

CREATE TRIGGER trg_mpesa_update AFTER UPDATE ON mpesa_transactions FOR EACH ROW
  INSERT INTO audit_log (Table_name, Row_id, Action, Old_values, New_values, Changed_by)
  VALUES ('mpesa_transactions', NEW.Transaction_ID, 'UPDATE',
          JSON_OBJECT('Fine_ID', OLD.Fine_ID, 'Member_ID', OLD.Member_ID, 'Amount', OLD.Amount,
                      'Status', OLD.Status, 'Mpesa_receipt', OLD.Mpesa_receipt, 'Completed_at', OLD.Completed_at),
          JSON_OBJECT('Fine_ID', NEW.Fine_ID, 'Member_ID', NEW.Member_ID, 'Amount', NEW.Amount,
                      'Status', NEW.Status, 'Mpesa_receipt', NEW.Mpesa_receipt, 'Completed_at', NEW.Completed_at),
          USER());

CREATE TRIGGER trg_mpesa_delete AFTER DELETE ON mpesa_transactions FOR EACH ROW
  INSERT INTO audit_log (Table_name, Row_id, Action, Old_values, Changed_by)
  VALUES ('mpesa_transactions', OLD.Transaction_ID, 'DELETE',
          JSON_OBJECT('Fine_ID', OLD.Fine_ID, 'Member_ID', OLD.Member_ID, 'Amount', OLD.Amount,
                      'Status', OLD.Status, 'Mpesa_receipt', OLD.Mpesa_receipt, 'Completed_at', OLD.Completed_at),
          USER());

-- ---------- 5. Members: only the active / verified flags ----------
-- Names, emails and phone numbers are deliberately NOT written to the log.
CREATE TRIGGER trg_members_flags AFTER UPDATE ON members FOR EACH ROW
  INSERT INTO audit_log (Table_name, Row_id, Action, Old_values, New_values, Changed_by)
  SELECT 'members', NEW.Member_ID, 'UPDATE',
         JSON_OBJECT('Is_active', OLD.Is_active, 'Is_verified', OLD.Is_verified),
         JSON_OBJECT('Is_active', NEW.Is_active, 'Is_verified', NEW.Is_verified),
         USER()
  FROM DUAL
  WHERE OLD.Is_active <> NEW.Is_active OR OLD.Is_verified <> NEW.Is_verified;

-- ---------- 6. Dashboard numbers ----------
CREATE OR REPLACE VIEW v_monitor_health AS
SELECT
  (SELECT COUNT(*) FROM members WHERE Is_active = TRUE)                                   AS Active_members,
  (SELECT COUNT(*) FROM books)                                                            AS Books,
  (SELECT COUNT(*) FROM loans WHERE Returned_at IS NULL)                                  AS Open_loans,
  (SELECT COUNT(*) FROM loans WHERE Returned_at IS NULL AND Due_date < CURDATE())         AS Overdue_loans,
  (SELECT COALESCE(SUM(Amount), 0) FROM fines WHERE Status = 'Unpaid')                    AS Unpaid_fines_total,
  (SELECT COUNT(*) FROM mpesa_transactions WHERE Status = 'Pending')                      AS Pending_mpesa,
  (SELECT COUNT(*) FROM notifications WHERE Status = 'Failed')                            AS Failed_notifications,
  (SELECT Status FROM registry_sync_log ORDER BY Sync_ID DESC LIMIT 1)                    AS Last_sync_status,
  (SELECT MAX(Started_at) FROM registry_sync_log)                                         AS Last_sync_at,
  (SELECT COUNT(*) FROM audit_log WHERE Changed_at >= NOW() - INTERVAL 1 DAY)             AS Changes_last_24h;

-- ---------- 7. Table sizes (approximate: MySQL refreshes these numbers about once a day) ----------
CREATE OR REPLACE VIEW v_monitor_table_sizes AS
SELECT TABLE_NAME AS Table_name,
       TABLE_ROWS AS Approx_rows,
       ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024, 3) AS Size_mb
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'KISII_LIBRARY' AND TABLE_TYPE = 'BASE TABLE';

-- ---------- 8. Alerts: one row for every problem found right now ----------
CREATE OR REPLACE VIEW v_monitor_alerts AS
SELECT 'CRIT' AS Severity, 'Copy counts do not match loans' AS Alert, COUNT(*) AS Count_or_value,
       'Books whose available copies differ from total copies minus open loans' AS Detail
FROM books b
WHERE b.Available_Copies <> b.Total_Copies - (SELECT COUNT(*) FROM loans l WHERE l.Book_ID = b.Book_ID AND l.Returned_at IS NULL)
HAVING COUNT(*) > 0
UNION ALL
SELECT 'CRIT', 'Registry sync failed', COUNT(*),
       'The most recent student registry sync ended in failure'
FROM (SELECT Status FROM registry_sync_log ORDER BY Sync_ID DESC LIMIT 1) last_sync
WHERE Status = 'Failed'
HAVING COUNT(*) > 0
UNION ALL
SELECT 'WARN', 'Registry sync is stale', 1,
       'No successful student registry sync in the last 7 days'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM registry_sync_log WHERE Status = 'Success' AND Started_at >= NOW() - INTERVAL 7 DAY)
UNION ALL
SELECT 'WARN', 'Overdue loans', COUNT(*),
       'Loans past their due date and not yet returned'
FROM loans WHERE Returned_at IS NULL AND Due_date < CURDATE()
HAVING COUNT(*) > 0
UNION ALL
SELECT 'WARN', 'Old unpaid fines', COUNT(*),
       'Fines unpaid for more than 30 days'
FROM fines WHERE Status = 'Unpaid' AND Issued_at < CURDATE() - INTERVAL 30 DAY
HAVING COUNT(*) > 0
UNION ALL
SELECT 'WARN', 'M-Pesa payments stuck', COUNT(*),
       'Payments still Pending after more than 1 day'
FROM mpesa_transactions WHERE Status = 'Pending' AND Initiated_at < NOW() - INTERVAL 1 DAY
HAVING COUNT(*) > 0
UNION ALL
SELECT 'WARN', 'M-Pesa payments failed', COUNT(*),
       'Payments that ended as Failed'
FROM mpesa_transactions WHERE Status = 'Failed'
HAVING COUNT(*) > 0
UNION ALL
SELECT 'WARN', 'Notifications failed', COUNT(*),
       'Messages that could not be sent'
FROM notifications WHERE Status = 'Failed'
HAVING COUNT(*) > 0
UNION ALL
SELECT 'INFO', 'Books with no copies on the shelf', COUNT(*),
       'Books where every copy is out'
FROM books WHERE Available_Copies = 0
HAVING COUNT(*) > 0;
