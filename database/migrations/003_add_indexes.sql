-- ============================================================
-- 003 Indexes (D1). ALREADY APPLIED to your existing database.
-- Do NOT run it again there: it fails with "Duplicate key name".
-- Used only when building a brand-new database (see 001).
-- ============================================================
USE KISII_LIBRARY;

CREATE INDEX idx_books_title  ON books (Title);
CREATE INDEX idx_loans_member ON loans (Member_ID, Status);
