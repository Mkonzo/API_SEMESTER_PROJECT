-- ============================================================
-- 007 M-Pesa payments and registry sync (D5)
-- Run ONCE. Supports POST /payments/mpesa/initiate and the
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
