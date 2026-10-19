-- MySQL dump 10.13  Distrib 8.0.44, for Win64 (x86_64)
--
-- Host: localhost    Database: KISII_LIBRARY
-- ------------------------------------------------------
-- Server version	8.0.44

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
  CONSTRAINT `fk_books_category` FOREIGN KEY (`Category_ID`) REFERENCES `categories` (`Category_ID`)
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
  CONSTRAINT `fines_ibfk_2` FOREIGN KEY (`Loan_ID`) REFERENCES `loans` (`Loan_ID`)
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
  KEY `Member_ID` (`Member_ID`),
  CONSTRAINT `loans_ibfk_1` FOREIGN KEY (`Book_ID`) REFERENCES `books` (`Book_ID`),
  CONSTRAINT `loans_ibfk_2` FOREIGN KEY (`Member_ID`) REFERENCES `members` (`Member_ID`)
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
INSERT INTO `members` VALUES ('Test Student One','student1@example.com','0700000001','CS/0001/2022','Student',1,1),('Test Student Two','student2@example.com','0700000002','CS/0002/2022','Student',2,1),('Test Librarian','librarian@example.com','0700000003','STAFF/001','Staff',3,1);
/*!40000 ALTER TABLE `members` ENABLE KEYS */;
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
  CONSTRAINT `reservations_ibfk_2` FOREIGN KEY (`Member_ID`) REFERENCES `members` (`Member_ID`)
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
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-18 19:08:54
