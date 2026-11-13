-- ============================================================
-- Sample rows for the new tables (made-up data)
-- Run ONCE, AFTER database/seed.sql and migrations 004 to 007.
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
