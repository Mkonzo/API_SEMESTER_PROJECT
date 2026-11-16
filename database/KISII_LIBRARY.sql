-- MySQL dump 10.13  Distrib 8.0.46, for Win64 (x86_64)
--
-- Host: localhost    Database: KISII_LIBRARY
-- ------------------------------------------------------
-- Server version	8.0.46

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `authors`
--

DROP TABLE IF EXISTS `authors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `authors` (
  `Name` varchar(50) NOT NULL,
  `Bio` text,
  `Author_ID` int NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`Author_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `authors`
--

LOCK TABLES `authors` WRITE;
/*!40000 ALTER TABLE `authors` DISABLE KEYS */;
INSERT INTO `authors` VALUES ('Chinua Achebe','Nigerian novelist',1),('Ngugi wa Thiong\'o','Kenyan writer and academic',2),('Thomas H. Cormen','Computer science author',3),('Alan Beaulieu','Database author',4);
/*!40000 ALTER TABLE `authors` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `book_authors`
--

DROP TABLE IF EXISTS `book_authors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `book_authors` (
  `Book_ID` int NOT NULL,
  `Author_ID` int NOT NULL,
  PRIMARY KEY (`Book_ID`,`Author_ID`),
  KEY `Author_ID` (`Author_ID`),
  CONSTRAINT `book_authors_ibfk_1` FOREIGN KEY (`Book_ID`) REFERENCES `books` (`Book_ID`) ON DELETE CASCADE,
  CONSTRAINT `book_authors_ibfk_2` FOREIGN KEY (`Author_ID`) REFERENCES `authors` (`Author_ID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `book_authors`
--

LOCK TABLES `book_authors` WRITE;
/*!40000 ALTER TABLE `book_authors` DISABLE KEYS */;
INSERT INTO `book_authors` VALUES (1,1),(2,2),(3,3),(4,4);
/*!40000 ALTER TABLE `book_authors` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `book_embeddings`
--

DROP TABLE IF EXISTS `book_embeddings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `book_embeddings` (
  `Book_ID` int NOT NULL,
  `Model_name` varchar(100) NOT NULL,
  `Embedding` json NOT NULL,
  `Created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`Book_ID`,`Model_name`),
  CONSTRAINT `fk_embeddings_book` FOREIGN KEY (`Book_ID`) REFERENCES `books` (`Book_ID`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `book_embeddings`
--

LOCK TABLES `book_embeddings` WRITE;
/*!40000 ALTER TABLE `book_embeddings` DISABLE KEYS */;
INSERT INTO `book_embeddings` VALUES (1,'sample-model','[0.12, -0.03, 0.88]','2026-11-13 17:13:05','2026-11-13 17:13:05');
/*!40000 ALTER TABLE `book_embeddings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `books`
--

DROP TABLE IF EXISTS `books`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `books` (
  `Isbn` varchar(20) NOT NULL,
  `Title` varchar(200) NOT NULL,
  `Description` text NOT NULL,
  `Publisher` varchar(100) NOT NULL,
  `Published_Year` int NOT NULL,
  `Category_ID` int NOT NULL,
  `Total_Copies` int NOT NULL,
  `Available_Copies` int NOT NULL,
  `Book_ID` int NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`Book_ID`),
  UNIQUE KEY `uq_books_isbn` (`Isbn`),
  KEY `fk_books_category` (`Category_ID`),
  KEY `idx_books_title` (`Title`),
  CONSTRAINT `fk_books_category` FOREIGN KEY (`Category_ID`) REFERENCES `categories` (`Category_ID`),
  CONSTRAINT `chk_books_available_within_total` CHECK ((`Available_Copies` <= `Total_Copies`)),
  CONSTRAINT `chk_books_copies_not_negative` CHECK (((`Total_Copies` >= 0) and (`Available_Copies` >= 0)))
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `books`
--

LOCK TABLES `books` WRITE;
/*!40000 ALTER TABLE `books` DISABLE KEYS */;
INSERT INTO `books` VALUES ('9780000000001','Things Fall Apart','A novel about Okonkwo and his village','Heinemann',1958,1,3,3,1),('9780000000002','The River Between','A novel set in colonial Kenya','Heinemann',1965,1,2,1,2),('9780000000003','Introduction to Algorithms','A standard algorithms textbook','MIT Press',2009,2,2,1,3),('9780000000004','Learning SQL','A beginner guide to SQL','O\'Reilly Media',2020,2,1,1,4);
/*!40000 ALTER TABLE `books` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `categories`
--

DROP TABLE IF EXISTS `categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `categories` (
  `Name` varchar(100) NOT NULL,
  `Description` text,
  `Category_ID` int NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`Category_ID`),
  UNIQUE KEY `Name` (`Name`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `categories`
--

LOCK TABLES `categories` WRITE;
/*!40000 ALTER TABLE `categories` DISABLE KEYS */;
INSERT INTO `categories` VALUES ('Fiction','Novels and short stories',1),('Computer Science','Programming, algorithms and databases',2),('History','History and African studies',3);
/*!40000 ALTER TABLE `categories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `demand_forecast`
--

DROP TABLE IF EXISTS `demand_forecast`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `demand_forecast` (
  `Forecast_ID` int NOT NULL AUTO_INCREMENT,
  `Book_ID` int NOT NULL,
  `Forecast_month` date NOT NULL,
  `Predicted_loans` int NOT NULL,
  `Generated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`Forecast_ID`),
  UNIQUE KEY `uq_forecast_book_month` (`Book_ID`,`Forecast_month`),
  CONSTRAINT `fk_forecast_book` FOREIGN KEY (`Book_ID`) REFERENCES `books` (`Book_ID`) ON DELETE CASCADE,
  CONSTRAINT `chk_forecast_not_negative` CHECK ((`Predicted_loans` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `demand_forecast`
--

LOCK TABLES `demand_forecast` WRITE;
/*!40000 ALTER TABLE `demand_forecast` DISABLE KEYS */;
INSERT INTO `demand_forecast` VALUES (1,3,'2026-12-01',5,'2026-11-13 20:13:05');
/*!40000 ALTER TABLE `demand_forecast` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fines`
--

DROP TABLE IF EXISTS `fines`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `fines` (
  `Loan_ID` int NOT NULL,
  `Member_ID` int NOT NULL,
  `Status` enum('Unpaid','Paid') NOT NULL,
  `Reason` enum('Overdue','Damage') NOT NULL,
  `Amount` decimal(10,2) NOT NULL,
  `Issued_at` date NOT NULL,
  `Paid_at` date DEFAULT NULL,
  `Mpesa_receipt` varchar(50) DEFAULT NULL,
  `Fine_ID` int NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`Fine_ID`),
  KEY `Member_ID` (`Member_ID`),
  KEY `Loan_ID` (`Loan_ID`),
  CONSTRAINT `fines_ibfk_1` FOREIGN KEY (`Member_ID`) REFERENCES `members` (`Member_ID`),
  CONSTRAINT `fines_ibfk_2` FOREIGN KEY (`Loan_ID`) REFERENCES `loans` (`Loan_ID`),
  CONSTRAINT `chk_fines_amount` CHECK ((`Amount` >= 0)),
  CONSTRAINT `chk_fines_paid_matches_date` CHECK ((((`Status` = _cp850'Paid') and (`Paid_at` is not null)) or ((`Status` = _cp850'Unpaid') and (`Paid_at` is null))))
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `fines`
--

LOCK TABLES `fines` WRITE;
/*!40000 ALTER TABLE `fines` DISABLE KEYS */;
INSERT INTO `fines` VALUES (2,2,'Unpaid','Overdue',20.00,'2026-10-17',NULL,NULL,1);
/*!40000 ALTER TABLE `fines` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `loans`
--

DROP TABLE IF EXISTS `loans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `loans` (
  `Borrowed_at` date NOT NULL,
  `Due_date` date NOT NULL,
  `Returned_at` date DEFAULT NULL,
  `Book_ID` int NOT NULL,
  `Member_ID` int NOT NULL,
  `Loan_ID` int NOT NULL AUTO_INCREMENT,
  `Renewal_count` int NOT NULL DEFAULT '0',
  `Status` enum('Active','Returned','Overdue') NOT NULL DEFAULT 'Active',
  PRIMARY KEY (`Loan_ID`),
  KEY `Book_ID` (`Book_ID`),
  KEY `idx_loans_member` (`Member_ID`,`Status`),
  CONSTRAINT `loans_ibfk_1` FOREIGN KEY (`Book_ID`) REFERENCES `books` (`Book_ID`),
  CONSTRAINT `loans_ibfk_2` FOREIGN KEY (`Member_ID`) REFERENCES `members` (`Member_ID`),
  CONSTRAINT `chk_loans_due_not_before_borrowed` CHECK ((`Due_date` >= `Borrowed_at`)),
  CONSTRAINT `chk_loans_renewals` CHECK ((`Renewal_count` between 0 and 2)),
  CONSTRAINT `chk_loans_return_not_before_borrowed` CHECK (((`Returned_at` is null) or (`Returned_at` >= `Borrowed_at`))),
  CONSTRAINT `chk_loans_status_matches_return` CHECK ((((`Status` = _cp850'Returned') and (`Returned_at` is not null)) or ((`Status` <> _cp850'Returned') and (`Returned_at` is null))))
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `loans`
--

LOCK TABLES `loans` WRITE;
/*!40000 ALTER TABLE `loans` DISABLE KEYS */;
INSERT INTO `loans` VALUES ('2026-09-20','2026-10-04','2026-10-03',1,1,1,0,'Returned'),('2026-10-01','2026-10-15',NULL,3,2,2,0,'Overdue'),('2026-10-10','2026-10-24',NULL,2,1,3,0,'Active');
/*!40000 ALTER TABLE `loans` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `members`
--

DROP TABLE IF EXISTS `members`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `members` (
  `Full_Name` varchar(50) NOT NULL,
  `Email` varchar(50) DEFAULT NULL,
  `Phone_Number` varchar(20) NOT NULL,
  `Reg_No` varchar(30) NOT NULL,
  `Member_Type` varchar(15) NOT NULL,
  `Member_ID` int NOT NULL AUTO_INCREMENT,
  `Is_active` tinyint(1) NOT NULL DEFAULT '1',
  `Is_verified` tinyint(1) NOT NULL DEFAULT '0',
  `Verified_at` datetime DEFAULT NULL,
  PRIMARY KEY (`Member_ID`),
  UNIQUE KEY `Reg_No` (`Reg_No`),
  UNIQUE KEY `uq_members_email` (`Email`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `members`
--

LOCK TABLES `members` WRITE;
/*!40000 ALTER TABLE `members` DISABLE KEYS */;
INSERT INTO `members` VALUES ('Test Student One','student1@example.com','0700000001','CS/0001/2022','Student',1,1,1,'2026-10-18 09:00:00'),('Test Student Two','student2@example.com','0700000002','CS/0002/2022','Student',2,1,1,'2026-10-18 09:00:00'),('Test Librarian','librarian@example.com','0700000003','STAFF/001','Staff',3,1,0,NULL);
/*!40000 ALTER TABLE `members` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mpesa_transactions`
--

DROP TABLE IF EXISTS `mpesa_transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `mpesa_transactions` (
  `Transaction_ID` int NOT NULL AUTO_INCREMENT,
  `Fine_ID` int NOT NULL,
  `Member_ID` int NOT NULL,
  `Phone_Number` varchar(20) NOT NULL,
  `Amount` decimal(10,2) NOT NULL,
  `Checkout_request_id` varchar(100) DEFAULT NULL,
  `Mpesa_receipt` varchar(50) DEFAULT NULL,
  `Status` enum('Pending','Success','Failed','Cancelled') NOT NULL DEFAULT 'Pending',
  `Result_description` varchar(255) DEFAULT NULL,
  `Initiated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Completed_at` datetime DEFAULT NULL,
  PRIMARY KEY (`Transaction_ID`),
  UNIQUE KEY `uq_mpesa_checkout` (`Checkout_request_id`),
  UNIQUE KEY `uq_mpesa_receipt` (`Mpesa_receipt`),
  KEY `idx_mpesa_fine` (`Fine_ID`),
  KEY `fk_mpesa_member` (`Member_ID`),
  CONSTRAINT `fk_mpesa_fine` FOREIGN KEY (`Fine_ID`) REFERENCES `fines` (`Fine_ID`),
  CONSTRAINT `fk_mpesa_member` FOREIGN KEY (`Member_ID`) REFERENCES `members` (`Member_ID`),
  CONSTRAINT `chk_mpesa_amount` CHECK ((`Amount` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mpesa_transactions`
--

LOCK TABLES `mpesa_transactions` WRITE;
/*!40000 ALTER TABLE `mpesa_transactions` DISABLE KEYS */;
INSERT INTO `mpesa_transactions` VALUES (1,1,2,'254700000002',20.00,'ws_CO_SAMPLE_0001',NULL,'Pending',NULL,'2026-10-18 11:00:00',NULL);
/*!40000 ALTER TABLE `mpesa_transactions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notifications`
--

DROP TABLE IF EXISTS `notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notifications` (
  `Member_ID` int NOT NULL,
  `Channel` enum('Email','SMS') DEFAULT NULL,
  `Status` enum('Pending','Sent','Failed') DEFAULT NULL,
  `Sent_at` date DEFAULT NULL,
  `Message` text NOT NULL,
  `Subject` varchar(200) DEFAULT NULL,
  `Notification_ID` int NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`Notification_ID`),
  KEY `Member_ID` (`Member_ID`),
  CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`Member_ID`) REFERENCES `members` (`Member_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notifications`
--

LOCK TABLES `notifications` WRITE;
/*!40000 ALTER TABLE `notifications` DISABLE KEYS */;
INSERT INTO `notifications` VALUES (2,'Email','Sent','2026-10-16','Your loan of Introduction to Algorithms was due on 2026-10-15.','Book overdue',1),(1,'SMS','Pending',NULL,'Your loan of The River Between is due on 2026-10-24.','Return reminder',2);
/*!40000 ALTER TABLE `notifications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `recommendation_log`
--

DROP TABLE IF EXISTS `recommendation_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `recommendation_log` (
  `Recommendation_ID` int NOT NULL AUTO_INCREMENT,
  `Member_ID` int NOT NULL,
  `Book_ID` int NOT NULL,
  `Score` decimal(5,4) NOT NULL,
  `Generated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`Recommendation_ID`),
  KEY `idx_reclog_member` (`Member_ID`,`Generated_at`),
  KEY `fk_reclog_book` (`Book_ID`),
  CONSTRAINT `fk_reclog_book` FOREIGN KEY (`Book_ID`) REFERENCES `books` (`Book_ID`) ON DELETE CASCADE,
  CONSTRAINT `fk_reclog_member` FOREIGN KEY (`Member_ID`) REFERENCES `members` (`Member_ID`) ON DELETE CASCADE,
  CONSTRAINT `chk_reclog_score` CHECK (((`Score` >= 0) and (`Score` <= 1)))
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `recommendation_log`
--

LOCK TABLES `recommendation_log` WRITE;
/*!40000 ALTER TABLE `recommendation_log` DISABLE KEYS */;
INSERT INTO `recommendation_log` VALUES (1,1,3,0.8123,'2026-10-18 10:00:00');
/*!40000 ALTER TABLE `recommendation_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `registry_sync_log`
--

DROP TABLE IF EXISTS `registry_sync_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `registry_sync_log` (
  `Sync_ID` int NOT NULL AUTO_INCREMENT,
  `Started_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Finished_at` datetime DEFAULT NULL,
  `Records_checked` int NOT NULL DEFAULT '0',
  `Records_updated` int NOT NULL DEFAULT '0',
  `Status` enum('Running','Success','Failed') NOT NULL DEFAULT 'Running',
  `Error_message` text,
  PRIMARY KEY (`Sync_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `registry_sync_log`
--

LOCK TABLES `registry_sync_log` WRITE;
/*!40000 ALTER TABLE `registry_sync_log` DISABLE KEYS */;
INSERT INTO `registry_sync_log` VALUES (1,'2026-10-18 08:00:00','2026-10-18 08:01:00',5,5,'Success',NULL);
/*!40000 ALTER TABLE `registry_sync_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `reservations`
--

DROP TABLE IF EXISTS `reservations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reservations` (
  `Book_ID` int NOT NULL,
  `Member_ID` int NOT NULL,
  `Reserved_at` date NOT NULL,
  `Expires_at` date DEFAULT NULL,
  `Status` enum('Waiting','Ready','Fulfilled','Cancelled') DEFAULT NULL,
  `Reservation_ID` int NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`Reservation_ID`),
  KEY `Book_ID` (`Book_ID`),
  KEY `Member_ID` (`Member_ID`),
  CONSTRAINT `reservations_ibfk_1` FOREIGN KEY (`Book_ID`) REFERENCES `books` (`Book_ID`),
  CONSTRAINT `reservations_ibfk_2` FOREIGN KEY (`Member_ID`) REFERENCES `members` (`Member_ID`),
  CONSTRAINT `chk_reservations_expiry` CHECK (((`Expires_at` is null) or (`Expires_at` >= `Reserved_at`)))
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `reservations`
--

LOCK TABLES `reservations` WRITE;
/*!40000 ALTER TABLE `reservations` DISABLE KEYS */;
INSERT INTO `reservations` VALUES (3,1,'2026-10-12','2026-10-26','Waiting',1);
/*!40000 ALTER TABLE `reservations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `student_registry`
--

DROP TABLE IF EXISTS `student_registry`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_registry` (
  `Reg_No` varchar(30) NOT NULL,
  `Full_Name` varchar(100) NOT NULL,
  `Programme` varchar(100) DEFAULT NULL,
  `Year_of_study` tinyint DEFAULT NULL,
  `Enrollment_status` enum('Enrolled','Deferred','Graduated','Suspended') NOT NULL DEFAULT 'Enrolled',
  `Updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`Reg_No`),
  CONSTRAINT `chk_registry_year` CHECK (((`Year_of_study` is null) or (`Year_of_study` between 1 and 8)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `student_registry`
--

LOCK TABLES `student_registry` WRITE;
/*!40000 ALTER TABLE `student_registry` DISABLE KEYS */;
INSERT INTO `student_registry` VALUES ('CS/0001/2022','Test Student One','BSc Computer Science',3,'Enrolled','2026-11-13 17:13:05'),('CS/0002/2022','Test Student Two','BSc Computer Science',3,'Enrolled','2026-11-13 17:13:05'),('CS/0003/2022','Sample Student Three','BSc Information Technology',3,'Enrolled','2026-11-13 17:13:05'),('CS/0004/2021','Sample Student Four','BSc Computer Science',4,'Deferred','2026-11-13 17:13:05'),('CS/0005/2019','Sample Student Five','BSc Computer Science',4,'Graduated','2026-11-13 17:13:05');
/*!40000 ALTER TABLE `student_registry` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `v_book_popularity`
--

DROP TABLE IF EXISTS `v_book_popularity`;
/*!50001 DROP VIEW IF EXISTS `v_book_popularity`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_book_popularity` AS SELECT 
 1 AS `Book_ID`,
 1 AS `Title`,
 1 AS `Category_ID`,
 1 AS `Times_borrowed`,
 1 AS `Last_borrowed_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_borrow_history`
--

DROP TABLE IF EXISTS `v_borrow_history`;
/*!50001 DROP VIEW IF EXISTS `v_borrow_history`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_borrow_history` AS SELECT 
 1 AS `Loan_ID`,
 1 AS `Member_ID`,
 1 AS `Book_ID`,
 1 AS `Category_ID`,
 1 AS `Borrowed_at`,
 1 AS `Returned_at`,
 1 AS `Status`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_verify_student`
--

DROP TABLE IF EXISTS `v_verify_student`;
/*!50001 DROP VIEW IF EXISTS `v_verify_student`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_verify_student` AS SELECT 
 1 AS `Reg_No`,
 1 AS `Full_Name`,
 1 AS `Enrollment_status`,
 1 AS `Is_enrolled`*/;
SET character_set_client = @saved_cs_client;

--
-- Final view structure for view `v_book_popularity`
--

/*!50001 DROP VIEW IF EXISTS `v_book_popularity`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_book_popularity` AS select `b`.`Book_ID` AS `Book_ID`,`b`.`Title` AS `Title`,`b`.`Category_ID` AS `Category_ID`,count(`l`.`Loan_ID`) AS `Times_borrowed`,max(`l`.`Borrowed_at`) AS `Last_borrowed_at` from (`books` `b` left join `loans` `l` on((`l`.`Book_ID` = `b`.`Book_ID`))) group by `b`.`Book_ID`,`b`.`Title`,`b`.`Category_ID` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_borrow_history`
--

/*!50001 DROP VIEW IF EXISTS `v_borrow_history`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_borrow_history` AS select `l`.`Loan_ID` AS `Loan_ID`,`l`.`Member_ID` AS `Member_ID`,`l`.`Book_ID` AS `Book_ID`,`b`.`Category_ID` AS `Category_ID`,`l`.`Borrowed_at` AS `Borrowed_at`,`l`.`Returned_at` AS `Returned_at`,`l`.`Status` AS `Status` from (`loans` `l` join `books` `b` on((`b`.`Book_ID` = `l`.`Book_ID`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_verify_student`
--

/*!50001 DROP VIEW IF EXISTS `v_verify_student`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_verify_student` AS select `student_registry`.`Reg_No` AS `Reg_No`,`student_registry`.`Full_Name` AS `Full_Name`,`student_registry`.`Enrollment_status` AS `Enrollment_status`,(`student_registry`.`Enrollment_status` = 'Enrolled') AS `Is_enrolled` from `student_registry` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-11-16 19:22:59
