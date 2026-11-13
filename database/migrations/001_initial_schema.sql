-- ============================================================
-- 001 Initial schema: the first version of the tables.
-- ALREADY APPLIED to your existing database. Do NOT run it again there.
-- Use it only to build a brand-new empty database, in this order:
--   001, 002, 003, then database/seed.sql, then 004 to 007,
--   then database/seed_extra.sql
-- ============================================================

CREATE DATABASE IF NOT EXISTS KISII_LIBRARY CHARACTER SET utf8mb4;
USE KISII_LIBRARY;

CREATE TABLE authors (
  Name      VARCHAR(50) NOT NULL,
  Bio       TEXT,
  Author_ID INT NOT NULL,
  PRIMARY KEY (Author_ID)
) ENGINE=InnoDB;

CREATE TABLE categories (
  Name        VARCHAR(100) NOT NULL,
  Description TEXT,
  Category_ID INT NOT NULL,
  PRIMARY KEY (Category_ID),
  UNIQUE KEY Name (Name)
) ENGINE=InnoDB;

CREATE TABLE members (
  Full_Name    VARCHAR(50) NOT NULL,
  Email        VARCHAR(50) DEFAULT NULL,
  Phone_Number INT NOT NULL,
  Reg_No       VARCHAR(30) NOT NULL,
  Member_Type  VARCHAR(15) NOT NULL,
  Member_ID    INT NOT NULL,
  PRIMARY KEY (Member_ID),
  UNIQUE KEY Reg_No (Reg_No)
) ENGINE=InnoDB;

CREATE TABLE books (
  Isbn             VARCHAR(20) NOT NULL,
  Title            VARCHAR(200) NOT NULL,
  Description      TEXT NOT NULL,
  Publisher        VARCHAR(100) NOT NULL,
  Published_Year   INT NOT NULL,
  Category_ID      INT NOT NULL,
  Total_Copies     INT NOT NULL,
  Available_Copies INT NOT NULL,
  Book_ID          INT NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (Book_ID)
) ENGINE=InnoDB;

CREATE TABLE book_authors (
  Book_ID   INT NOT NULL,
  Author_ID INT NOT NULL,
  PRIMARY KEY (Book_ID, Author_ID),
  KEY Author_ID (Author_ID),
  CONSTRAINT book_authors_ibfk_1 FOREIGN KEY (Book_ID)   REFERENCES books (Book_ID)     ON DELETE CASCADE,
  CONSTRAINT book_authors_ibfk_2 FOREIGN KEY (Author_ID) REFERENCES authors (Author_ID) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE loans (
  Borrowed_at DATE NOT NULL,
  Returned_at DATE NOT NULL,
  Book_ID     INT NOT NULL,
  Member_ID   INT NOT NULL,
  Loan_ID     INT NOT NULL,
  PRIMARY KEY (Loan_ID),
  KEY Book_ID (Book_ID),
  CONSTRAINT loans_ibfk_1 FOREIGN KEY (Book_ID)   REFERENCES books (Book_ID),
  CONSTRAINT loans_ibfk_2 FOREIGN KEY (Member_ID) REFERENCES members (Member_ID)
) ENGINE=InnoDB;

CREATE TABLE fines (
  Loan_ID       INT NOT NULL,
  Member_ID     INT NOT NULL,
  Status        ENUM('Unpaid','Paid') NOT NULL,
  Reason        ENUM('Overdue','Damage') NOT NULL,
  Amount        DECIMAL(10,2) NOT NULL,
  Issued_at     DATE NOT NULL,
  Paid_at       DATE DEFAULT NULL,
  Mpesa_receipt VARCHAR(50) DEFAULT NULL,
  Fine_ID       INT NOT NULL,
  PRIMARY KEY (Fine_ID),
  KEY Member_ID (Member_ID),
  KEY Loan_ID (Loan_ID),
  CONSTRAINT fines_ibfk_1 FOREIGN KEY (Member_ID) REFERENCES members (Member_ID),
  CONSTRAINT fines_ibfk_2 FOREIGN KEY (Loan_ID)   REFERENCES loans (Loan_ID)
) ENGINE=InnoDB;

CREATE TABLE notifications (
  Member_ID       INT NOT NULL,
  Channel         ENUM('Email','SMS') DEFAULT NULL,
  Status          ENUM('Pending','Sent','Failed') DEFAULT NULL,
  Sent_at         DATE DEFAULT NULL,
  Message         TEXT NOT NULL,
  Subject         VARCHAR(200) DEFAULT NULL,
  Notification_ID INT NOT NULL,
  PRIMARY KEY (Notification_ID),
  KEY Member_ID (Member_ID),
  CONSTRAINT notifications_ibfk_1 FOREIGN KEY (Member_ID) REFERENCES members (Member_ID)
) ENGINE=InnoDB;

CREATE TABLE reservations (
  Book_ID        INT NOT NULL,
  Member_ID      INT NOT NULL,
  Reserved_at    DATE NOT NULL,
  Expires_at     DATE DEFAULT NULL,
  Status         ENUM('Waiting','Ready','Fulfilled','Cancelled') DEFAULT NULL,
  Reservation_ID INT NOT NULL,
  PRIMARY KEY (Reservation_ID),
  KEY Book_ID (Book_ID),
  KEY Member_ID (Member_ID),
  CONSTRAINT reservations_ibfk_1 FOREIGN KEY (Book_ID)   REFERENCES books (Book_ID),
  CONSTRAINT reservations_ibfk_2 FOREIGN KEY (Member_ID) REFERENCES members (Member_ID)
) ENGINE=InnoDB;
