-- ============================================================
-- 004 Student registry and member verification (D2)
-- Run ONCE. Supports GET /external/students/{regNo}/verify
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
