-- ============================================================
-- 006 AI data store (D4): borrowing history, embeddings, logs
-- Run ONCE. Supports the /ai/... endpoints.
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
