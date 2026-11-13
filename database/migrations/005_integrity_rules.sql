-- ============================================================
-- 005 Safety rules on the existing tables (D3)
-- Run ONCE. The database now rejects data that makes no sense.
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
