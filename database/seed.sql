-- ============================================================
-- Kisii University Library API - sample (seed) data
-- Matches the KISII_LIBRARY tables AFTER fix_schema.sql is run.
-- All data is made up. ISBNs are fake sample values.
-- Insert order matters: parent tables first, because a foreign
-- key can only point to a row that already exists.
-- Run ONCE: running it again fails with "Duplicate entry".
-- ============================================================

USE KISII_LIBRARY;

-- 1. Tables with no foreign keys ------------------------------

INSERT INTO categories (Category_ID, Name, Description) VALUES
  (1, 'Fiction',          'Novels and short stories'),
  (2, 'Computer Science', 'Programming, algorithms and databases'),
  (3, 'History',          'History and African studies');

INSERT INTO authors (Author_ID, Name, Bio) VALUES
  (1, 'Chinua Achebe',      'Nigerian novelist'),
  (2, 'Ngugi wa Thiong''o', 'Kenyan writer and academic'),
  (3, 'Thomas H. Cormen',   'Computer science author'),
  (4, 'Alan Beaulieu',      'Database author');

INSERT INTO members (Member_ID, Full_Name, Email, Phone_Number, Reg_No, Member_Type, Is_active) VALUES
  (1, 'Test Student One', 'student1@example.com',  '0700000001', 'CS/0001/2022', 'Student', TRUE),
  (2, 'Test Student Two', 'student2@example.com',  '0700000002', 'CS/0002/2022', 'Student', TRUE),
  (3, 'Test Librarian',   'librarian@example.com', '0700000003', 'STAFF/001',    'Staff',   TRUE);

-- 2. Tables that point to the above ----------------------------

INSERT INTO books (Book_ID, Isbn, Title, Description, Publisher, Published_Year, Category_ID, Total_Copies, Available_Copies) VALUES
  (1, '9780000000001', 'Things Fall Apart',          'A novel about Okonkwo and his village', 'Heinemann',       1958, 1, 3, 3),
  (2, '9780000000002', 'The River Between',          'A novel set in colonial Kenya',         'Heinemann',       1965, 1, 2, 1),
  (3, '9780000000003', 'Introduction to Algorithms', 'A standard algorithms textbook',        'MIT Press',       2009, 2, 2, 1),
  (4, '9780000000004', 'Learning SQL',               'A beginner guide to SQL',               'O''Reilly Media', 2020, 2, 1, 1);

INSERT INTO book_authors (Book_ID, Author_ID) VALUES
  (1, 1),
  (2, 2),
  (3, 3),
  (4, 4);

INSERT INTO loans (Loan_ID, Book_ID, Member_ID, Borrowed_at, Due_date, Returned_at, Renewal_count, Status) VALUES
  (1, 1, 1, '2026-09-20', '2026-10-04', '2026-10-03', 0, 'Returned'),
  (2, 3, 2, '2026-10-01', '2026-10-15', NULL,         0, 'Overdue'),
  (3, 2, 1, '2026-10-10', '2026-10-24', NULL,         0, 'Active');

INSERT INTO reservations (Reservation_ID, Book_ID, Member_ID, Reserved_at, Expires_at, Status) VALUES
  (1, 3, 1, '2026-10-12', '2026-10-26', 'Waiting');

-- 3. Tables that point to loans / members ----------------------

INSERT INTO fines (Fine_ID, Loan_ID, Member_ID, Amount, Reason, Status, Issued_at, Paid_at, Mpesa_receipt) VALUES
  (1, 2, 2, 20.00, 'Overdue', 'Unpaid', '2026-10-17', NULL, NULL);

INSERT INTO notifications (Notification_ID, Member_ID, Channel, Subject, Message, Status, Sent_at) VALUES
  (1, 2, 'Email', 'Book overdue',    'Your loan of Introduction to Algorithms was due on 2026-10-15.', 'Sent',    '2026-10-16'),
  (2, 1, 'SMS',   'Return reminder', 'Your loan of The River Between is due on 2026-10-24.',           'Pending', NULL);

-- Check it worked:
-- SELECT COUNT(*) FROM books;   -- expect 4
-- SELECT COUNT(*) FROM loans;   -- expect 3
