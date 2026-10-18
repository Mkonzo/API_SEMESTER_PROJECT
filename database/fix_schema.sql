-- ============================================================
-- Kisii University Library API - one-time fixes to the tables
-- Run ONCE on your existing KISII_LIBRARY database:
--   mysql -u root -p KISII_LIBRARY < database/fix_schema.sql
-- Running it a second time fails, because the changes already exist.
-- ============================================================

USE KISII_LIBRARY;

-- 1. Let MySQL number the rows itself (AUTO_INCREMENT).
--    Only Book_ID had this. Without it, every INSERT must supply an id.
--    MySQL refuses to change an id column that other tables point to, so
--    the foreign key checks are switched off for these changes only.
SET FOREIGN_KEY_CHECKS = 0;

ALTER TABLE authors       MODIFY Author_ID       INT NOT NULL AUTO_INCREMENT;
ALTER TABLE categories    MODIFY Category_ID     INT NOT NULL AUTO_INCREMENT;
ALTER TABLE members       MODIFY Member_ID       INT NOT NULL AUTO_INCREMENT;
ALTER TABLE loans         MODIFY Loan_ID         INT NOT NULL AUTO_INCREMENT;
ALTER TABLE reservations  MODIFY Reservation_ID  INT NOT NULL AUTO_INCREMENT;
ALTER TABLE fines         MODIFY Fine_ID         INT NOT NULL AUTO_INCREMENT;
ALTER TABLE notifications MODIFY Notification_ID INT NOT NULL AUTO_INCREMENT;

SET FOREIGN_KEY_CHECKS = 1;

-- 2. books: a book must point to a real category, and ISBNs must be unique.
ALTER TABLE books
  ADD CONSTRAINT fk_books_category
    FOREIGN KEY (Category_ID) REFERENCES categories (Category_ID),
  ADD UNIQUE KEY uq_books_isbn (Isbn);

-- 3. loans: add the due date, renewals and status, and allow
--    Returned_at to be empty (a book that is still out has no return date).
ALTER TABLE loans
  MODIFY Returned_at DATE NULL,
  ADD COLUMN Due_date      DATE NOT NULL AFTER Borrowed_at,
  ADD COLUMN Renewal_count INT  NOT NULL DEFAULT 0,
  ADD COLUMN Status        ENUM('Active','Returned','Overdue') NOT NULL DEFAULT 'Active';

-- 4. members: phone numbers are text (leading zeros, long numbers such as
--    254700000000 do not fit in INT). Emails must be unique. Add Is_active
--    so a member can be deactivated.
ALTER TABLE members
  MODIFY Phone_Number VARCHAR(20) NOT NULL,
  ADD UNIQUE KEY uq_members_email (Email),
  ADD COLUMN Is_active BOOLEAN NOT NULL DEFAULT TRUE;

-- Check it worked:
-- DESCRIBE loans;
-- DESCRIBE members;
