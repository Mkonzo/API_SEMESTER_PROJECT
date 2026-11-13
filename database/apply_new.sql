-- Runs migrations 004 to 007 and the extra sample data in one go.
-- Run ONCE on your existing KISII_LIBRARY database.

-- ===== migrations/004_student_registry.sql =====
-- ============================================================
-- 004 Student registry and member verification (D2)
-- ============================================================
USE KISII_LIBRARY;

-- The university's list of students, used to check that someone is enrolled
CREATE TABLE student_registry (
  Reg_No            VARCHAR(30)  NOT NULL,
  Full_Name         VARCHAR(100) NOT NULL,
  Programme         VARCHAR(100) NULL,
  Year_of_study     TINYINT      NULL,
  Enrollment_status ENUM('Enrolled','Deferred','Graduated','Suspended') NOT NULL DEFAULT 'Enrolled',
  Updated_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (Reg_No),
  CONSTRAINT chk_registry_year CHECK (Year_of_study IS NULL OR Year_of_study BETWEEN 1 AND 8)
) ENGINE=InnoDB;

-- Record whether a member has been checked against the registry
ALTER TABLE members
  ADD COLUMN Is_verified BOOLEAN  NOT NULL DEFAULT FALSE,
  ADD COLUMN Verified_at DATETIME NULL;

-- What the verify endpoint reads
CREATE OR REPLACE VIEW v_verify_student AS
SELECT Reg_No,
       Full_Name,
       Enrollment_status,
       (Enrollment_status = 'Enrolled') AS Is_enrolled
FROM student_registry;

-- ===== migrations/005_integrity_rules.sql =====
-- ============================================================
-- 005 Safety rules on the existing tables (D3)
-- Needs MySQL 8.0.16 or newer (older versions ignore CHECK rules).
-- ============================================================
USE KISII_LIBRARY;

ALTER TABLE books
  ADD CONSTRAINT chk_books_copies_not_negative CHECK (Total_Copies >= 0 AND Available_Copies >= 0),
  ADD CONSTRAINT chk_books_available_within_total CHECK (Available_Copies <= Total_Copies);

ALTER TABLE loans
  ADD CONSTRAINT chk_loans_due_not_before_borrowed CHECK (Due_date >= Borrowed_at),
  ADD CONSTRAINT chk_loans_return_not_before_borrowed CHECK (Returned_at IS NULL OR Returned_at >= Borrowed_at),
  ADD CONSTRAINT chk_loans_renewals CHECK (Renewal_count BETWEEN 0 AND 2),
  ADD CONSTRAINT chk_loans_status_matches_return CHECK (
        (Status = 'Returned' AND Returned_at IS NOT NULL)
     OR (Status <> 'Returned' AND Returned_at IS NULL));

ALTER TABLE reservations
  ADD CONSTRAINT chk_reservations_expiry CHECK (Expires_at IS NULL OR Expires_at >= Reserved_at);

ALTER TABLE fines
  ADD CONSTRAINT chk_fines_amount CHECK (Amount >= 0),
  ADD CONSTRAINT chk_fines_paid_matches_date CHECK (
        (Status = 'Paid'   AND Paid_at IS NOT NULL)
     OR (Status = 'Unpaid' AND Paid_at IS NULL));

-- ===== migrations/006_ai_data_store.sql =====
-- ============================================================
-- 006 AI data store (D4): borrowing history, embeddings, logs
-- ============================================================
USE KISII_LIBRARY;

-- Every loan joined with its book's category (used for recommendations)
CREATE OR REPLACE VIEW v_borrow_history AS
SELECT l.Loan_ID, l.Member_ID, l.Book_ID, b.Category_ID,
       l.Borrowed_at, l.Returned_at, l.Status
FROM loans l
JOIN books b ON b.Book_ID = l.Book_ID;

-- How often each book is borrowed (used for "most popular" and forecasting)
CREATE OR REPLACE VIEW v_book_popularity AS
SELECT b.Book_ID, b.Title, b.Category_ID,
       COUNT(l.Loan_ID)   AS Times_borrowed,
       MAX(l.Borrowed_at) AS Last_borrowed_at
FROM books b
LEFT JOIN loans l ON l.Book_ID = b.Book_ID
GROUP BY b.Book_ID, b.Title, b.Category_ID;

-- One stored vector per book and AI model (used for smart search)
CREATE TABLE book_embeddings (
  Book_ID    INT          NOT NULL,
  Model_name VARCHAR(100) NOT NULL,
  Embedding  JSON         NOT NULL,
  Created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  Updated_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (Book_ID, Model_name),
  CONSTRAINT fk_embeddings_book FOREIGN KEY (Book_ID) REFERENCES books (Book_ID) ON DELETE CASCADE
) ENGINE=InnoDB;

-- What the recommender suggested to whom, and how strongly
CREATE TABLE recommendation_log (
  Recommendation_ID INT          NOT NULL AUTO_INCREMENT,
  Member_ID         INT          NOT NULL,
  Book_ID           INT          NOT NULL,
  Score             DECIMAL(5,4) NOT NULL,
  Generated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (Recommendation_ID),
  KEY idx_reclog_member (Member_ID, Generated_at),
  CONSTRAINT fk_reclog_member FOREIGN KEY (Member_ID) REFERENCES members (Member_ID) ON DELETE CASCADE,
  CONSTRAINT fk_reclog_book   FOREIGN KEY (Book_ID)   REFERENCES books (Book_ID)     ON DELETE CASCADE,
  CONSTRAINT chk_reclog_score CHECK (Score >= 0 AND Score <= 1)
) ENGINE=InnoDB;

-- Predicted loans per book per month (demand forecasting)
CREATE TABLE demand_forecast (
  Forecast_ID     INT      NOT NULL AUTO_INCREMENT,
  Book_ID         INT      NOT NULL,
  Forecast_month  DATE     NOT NULL,
  Predicted_loans INT      NOT NULL,
  Generated_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (Forecast_ID),
  UNIQUE KEY uq_forecast_book_month (Book_ID, Forecast_month),
  CONSTRAINT fk_forecast_book FOREIGN KEY (Book_ID) REFERENCES books (Book_ID) ON DELETE CASCADE,
  CONSTRAINT chk_forecast_not_negative CHECK (Predicted_loans >= 0)
) ENGINE=InnoDB;

-- ===== migrations/007_mpesa_and_sync.sql =====
-- ============================================================
-- 007 M-Pesa payments and registry sync (D5)
-- student registry sync.
-- ============================================================
USE KISII_LIBRARY;

-- One row for every M-Pesa payment attempt for a fine
CREATE TABLE mpesa_transactions (
  Transaction_ID      INT          NOT NULL AUTO_INCREMENT,
  Fine_ID             INT          NOT NULL,
  Member_ID           INT          NOT NULL,
  Phone_Number        VARCHAR(20)  NOT NULL,
  Amount              DECIMAL(10,2) NOT NULL,
  Checkout_request_id VARCHAR(100) NULL,
  Mpesa_receipt       VARCHAR(50)  NULL,
  Status              ENUM('Pending','Success','Failed','Cancelled') NOT NULL DEFAULT 'Pending',
  Result_description  VARCHAR(255) NULL,
  Initiated_at        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  Completed_at        DATETIME     NULL,
  PRIMARY KEY (Transaction_ID),
  UNIQUE KEY uq_mpesa_checkout (Checkout_request_id),
  UNIQUE KEY uq_mpesa_receipt (Mpesa_receipt),
  KEY idx_mpesa_fine (Fine_ID),
  CONSTRAINT fk_mpesa_fine   FOREIGN KEY (Fine_ID)   REFERENCES fines (Fine_ID),
  CONSTRAINT fk_mpesa_member FOREIGN KEY (Member_ID) REFERENCES members (Member_ID),
  CONSTRAINT chk_mpesa_amount CHECK (Amount > 0)
) ENGINE=InnoDB;

-- One row for every run of the student registry sync
CREATE TABLE registry_sync_log (
  Sync_ID         INT      NOT NULL AUTO_INCREMENT,
  Started_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  Finished_at     DATETIME NULL,
  Records_checked INT      NOT NULL DEFAULT 0,
  Records_updated INT      NOT NULL DEFAULT 0,
  Status          ENUM('Running','Success','Failed') NOT NULL DEFAULT 'Running',
  Error_message   TEXT     NULL,
  PRIMARY KEY (Sync_ID)
) ENGINE=InnoDB;

-- ===== seed_extra.sql =====
-- ============================================================
-- Sample rows for the new tables (made-up data)
-- ============================================================
USE KISII_LIBRARY;

INSERT INTO student_registry (Reg_No, Full_Name, Programme, Year_of_study, Enrollment_status) VALUES
  ('CS/0001/2022', 'Test Student One',    'BSc Computer Science', 3, 'Enrolled'),
  ('CS/0002/2022', 'Test Student Two',    'BSc Computer Science', 3, 'Enrolled'),
  ('CS/0003/2022', 'Sample Student Three','BSc Information Technology', 3, 'Enrolled'),
  ('CS/0004/2021', 'Sample Student Four', 'BSc Computer Science', 4, 'Deferred'),
  ('CS/0005/2019', 'Sample Student Five', 'BSc Computer Science', 4, 'Graduated');

UPDATE members SET Is_verified = TRUE, Verified_at = '2026-10-18 09:00:00' WHERE Member_ID IN (1, 2);

-- A real embedding has hundreds of numbers. This one is a tiny placeholder.
INSERT INTO book_embeddings (Book_ID, Model_name, Embedding) VALUES
  (1, 'sample-model', '[0.12, -0.03, 0.88]');

INSERT INTO recommendation_log (Member_ID, Book_ID, Score, Generated_at) VALUES
  (1, 3, 0.8123, '2026-10-18 10:00:00');

INSERT INTO demand_forecast (Book_ID, Forecast_month, Predicted_loans) VALUES
  (3, '2026-12-01', 5);

INSERT INTO mpesa_transactions (Fine_ID, Member_ID, Phone_Number, Amount, Checkout_request_id, Status, Initiated_at) VALUES
  (1, 2, '254700000002', 20.00, 'ws_CO_SAMPLE_0001', 'Pending', '2026-10-18 11:00:00');

INSERT INTO registry_sync_log (Started_at, Finished_at, Records_checked, Records_updated, Status) VALUES
  ('2026-10-18 08:00:00', '2026-10-18 08:01:00', 5, 5, 'Success');
