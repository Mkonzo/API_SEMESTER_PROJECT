# Data dictionary: the KISII_LIBRARY database

This page describes every table, column, view and trigger. It was generated from the real database structure (migrations 001 to 010), so the names and types are exact. The descriptions were written by hand. An automatic check on GitHub fails if a table or column is missing from this page, so it cannot quietly go out of date.

## How to read this

- **Required:** *Yes* means a value must be given. *Automatic* means the database fills it in if you leave it out. *No* means it can be empty.
- **Key:** *PK* is the primary key, the column that identifies each row. *FK to x.y* is a foreign key: it must match an existing row in table x. *Unique* means no two rows can share a value.
- Column names use capital letters and underscores (`Book_ID`). The API uses camelCase for the same fields (`bookId`).

The database has **16 tables**, **6 views** and **10 triggers**.

## Which API resource uses which tables

| API resource | Tables and views |
|---|---|
| Books | books, book_authors, authors, categories |
| Members | members, student_registry |
| Loans | loans |
| Reservations | reservations |
| Fines | fines, mpesa_transactions |
| Categories | categories |
| Authors | authors, book_authors |
| Notifications | notifications |
| Student registry (external) | student_registry, registry_sync_log, v_verify_student |
| M-Pesa (external) | mpesa_transactions, fines |
| AI features | v_borrow_history, v_book_popularity, book_embeddings, recommendation_log, demand_forecast |
| Monitoring | audit_log, v_monitor_health, v_monitor_table_sizes, v_monitor_alerts |

## Tables at a glance

| Table | What it is for |
|---|---|
| `audit_log` | The change log: who changed a loan, fine or payment, when, and what it looked like before and after. |
| `authors` | The people who write books. |
| `book_authors` | Links books to authors. A book can have several authors and an author can write several books, so each pairing is one row here. |
| `book_embeddings` | AI data: a stored list of numbers for each book that lets smart search match by meaning. |
| `books` | The library catalog: one row for every title. |
| `categories` | Genres and subjects that books are filed under, such as Fiction or Computer Science. |
| `demand_forecast` | AI data: predicted number of loans per book per month. |
| `fines` | Money owed for books returned late or damaged. |
| `loans` | Every time a member borrows a book: when, until when, and whether it came back. |
| `members` | The students and staff who can borrow books. |
| `mpesa_transactions` | Every M-Pesa payment attempt for a fine, with its outcome. |
| `notifications` | Email and SMS messages sent to members, such as reminders. |
| `recommendation_log` | AI data: which books were recommended to which members, and how strongly. |
| `registry_sync_log` | A record of every run of the student registry sync. |
| `reservations` | Holds that members place on books that are currently out. |
| `student_registry` | The university's list of students, used to check that someone is really enrolled. |

## Tables

### `audit_log`

The change log: who changed a loan, fine or payment, when, and what it looked like before and after.

| Column | Type | Required | Key | Description |
|---|---|---|---|---|
| `Audit_ID` | `bigint` | Automatic | PK | Unique number for each row. Numbered automatically. |
| `Table_name` | `varchar(64)` | Yes |  | Which table changed. |
| `Row_id` | `int` | Yes |  | The id of the row that changed. |
| `Action` | `enum('INSERT','UPDATE','DELETE')` | Yes |  | INSERT, UPDATE or DELETE. |
| `Old_values` | `json` | No (can be empty) |  | The values before the change (JSON). Empty for an insert. |
| `New_values` | `json` | No (can be empty) |  | The values after the change (JSON). Empty for a delete. |
| `Changed_by` | `varchar(100)` | Yes |  | The database user that made the change. |
| `Changed_at` | `datetime` | Automatic |  | When the change happened. |

**Indexes** (they make searches faster)

- `idx_audit_table_row` on `Table_name`, `Row_id`
- `idx_audit_time` on `Changed_at`

### `authors`

The people who write books.

| Column | Type | Required | Key | Description |
|---|---|---|---|---|
| `Author_ID` | `int` | Automatic | PK | Unique number for each row. Numbered automatically. |
| `Name` | `varchar(50)` | Yes |  | The author's full name. |
| `Bio` | `text` | No (can be empty) |  | A short biography. Optional. |

**Relationships**

- `book_authors.Author_ID` points here (deleting the parent also deletes these rows).

### `book_authors`

Links books to authors. A book can have several authors and an author can write several books, so each pairing is one row here.

| Column | Type | Required | Key | Description |
|---|---|---|---|---|
| `Book_ID` | `int` | Yes | PK (part), FK to books.Book_ID | The book. |
| `Author_ID` | `int` | Yes | PK (part), FK to authors.Author_ID | One of that book's authors. |

**Relationships**

- `Book_ID` points to `books.Book_ID`.
- `Author_ID` points to `authors.Author_ID`.

**Indexes** (they make searches faster)

- `Author_ID` on `Author_ID`

### `book_embeddings`

AI data: a stored list of numbers for each book that lets smart search match by meaning.

| Column | Type | Required | Key | Description |
|---|---|---|---|---|
| `Book_ID` | `int` | Yes | PK (part), FK to books.Book_ID | The book. |
| `Model_name` | `varchar(100)` | Yes | PK (part) | The AI model that produced the numbers. |
| `Embedding` | `json` | Yes |  | The list of numbers (stored as JSON) used for smart search. |
| `Created_at` | `timestamp` | Automatic |  | When it was first stored. |
| `Updated_at` | `timestamp` | Automatic |  | When it last changed. |

**Relationships**

- `Book_ID` points to `books.Book_ID`.

### `books`

The library catalog: one row for every title.

| Column | Type | Required | Key | Description |
|---|---|---|---|---|
| `Book_ID` | `int` | Automatic | PK | Unique number for each row. Numbered automatically. |
| `Isbn` | `varchar(20)` | Yes | Unique | International Standard Book Number, kept as text. Unique. |
| `Title` | `varchar(200)` | Yes |  | The book's title. |
| `Description` | `text` | Yes |  | A summary of the book. |
| `Publisher` | `varchar(100)` | Yes |  | The company that published it. |
| `Published_Year` | `int` | Yes |  | Year of publication, for example 1958. |
| `Category_ID` | `int` | Yes | FK to categories.Category_ID | The category the book is filed under. |
| `Total_Copies` | `int` | Yes |  | How many copies the library owns. |
| `Available_Copies` | `int` | Yes |  | How many copies are on the shelf now. Goes down when a book is borrowed and up when it is returned. |

**Relationships**

- `Category_ID` points to `categories.Category_ID`.
- `book_authors.Book_ID` points here (deleting the parent also deletes these rows).
- `book_embeddings.Book_ID` points here (deleting the parent also deletes these rows).
- `demand_forecast.Book_ID` points here (deleting the parent also deletes these rows).
- `loans.Book_ID` points here (the parent can't be deleted while rows point to it).
- `recommendation_log.Book_ID` points here (deleting the parent also deletes these rows).
- `reservations.Book_ID` points here (the parent can't be deleted while rows point to it).

**Safety rules** (the database rejects data that breaks them)

- Available copies can't be more than total copies.
- Total and available copies can't be negative.

**Indexes** (they make searches faster)

- `fk_books_category` on `Category_ID`
- `idx_books_title` on `Title`
- `uq_books_isbn` on `Isbn` (unique)

### `categories`

Genres and subjects that books are filed under, such as Fiction or Computer Science.

| Column | Type | Required | Key | Description |
|---|---|---|---|---|
| `Category_ID` | `int` | Automatic | PK | Unique number for each row. Numbered automatically. |
| `Name` | `varchar(100)` | Yes | Unique | Name of the genre or subject, for example Fiction. No two categories share a name. |
| `Description` | `text` | No (can be empty) |  | What the category covers. Optional. |

**Relationships**

- `books.Category_ID` points here (the parent can't be deleted while rows point to it).

**Indexes** (they make searches faster)

- `Name` on `Name` (unique)

### `demand_forecast`

AI data: predicted number of loans per book per month.

| Column | Type | Required | Key | Description |
|---|---|---|---|---|
| `Forecast_ID` | `int` | Automatic | PK | Unique number for each row. Numbered automatically. |
| `Book_ID` | `int` | Yes | FK to books.Book_ID | The book. |
| `Forecast_month` | `date` | Yes |  | The month predicted, stored as the first day of that month. |
| `Predicted_loans` | `int` | Yes |  | Expected number of loans that month. |
| `Generated_at` | `datetime` | Automatic |  | When the forecast was made. |

**Relationships**

- `Book_ID` points to `books.Book_ID`.

**Safety rules** (the database rejects data that breaks them)

- Predicted loans can't be negative.

**Indexes** (they make searches faster)

- `uq_forecast_book_month` on `Book_ID`, `Forecast_month` (unique)

### `fines`

Money owed for books returned late or damaged.

| Column | Type | Required | Key | Description |
|---|---|---|---|---|
| `Fine_ID` | `int` | Automatic | PK | Unique number for each row. Numbered automatically. |
| `Loan_ID` | `int` | Yes | FK to loans.Loan_ID | The loan that caused the fine. |
| `Member_ID` | `int` | Yes | FK to members.Member_ID | The member who owes it. |
| `Status` | `enum('Unpaid','Paid')` | Yes |  | Unpaid or Paid. |
| `Reason` | `enum('Overdue','Damage')` | Yes |  | Overdue or Damage. |
| `Amount` | `decimal(10,2)` | Yes |  | Money owed, with two decimal places. |
| `Issued_at` | `date` | Yes |  | Date the fine was issued. |
| `Paid_at` | `date` | No (can be empty) |  | Date it was paid. Empty until then. |
| `Mpesa_receipt` | `varchar(50)` | No (can be empty) |  | M-Pesa receipt code, if it was paid that way. Optional. |

**Relationships**

- `Member_ID` points to `members.Member_ID`.
- `Loan_ID` points to `loans.Loan_ID`.
- `mpesa_transactions.Fine_ID` points here (the parent can't be deleted while rows point to it).

**Safety rules** (the database rejects data that breaks them)

- A fine can't be negative.
- A Paid fine must have a paid date. An Unpaid fine must not have one.

**Indexes** (they make searches faster)

- `Loan_ID` on `Loan_ID`
- `Member_ID` on `Member_ID`

### `loans`

Every time a member borrows a book: when, until when, and whether it came back.

| Column | Type | Required | Key | Description |
|---|---|---|---|---|
| `Loan_ID` | `int` | Automatic | PK | Unique number for each row. Numbered automatically. |
| `Borrowed_at` | `date` | Yes |  | Date the book was borrowed. |
| `Due_date` | `date` | Yes |  | Date the book must be back. |
| `Returned_at` | `date` | No (can be empty) |  | Date it was returned. Empty while the book is still out. |
| `Book_ID` | `int` | Yes | FK to books.Book_ID | The book that was borrowed. |
| `Member_ID` | `int` | Yes | FK to members.Member_ID | The member who borrowed it. |
| `Renewal_count` | `int` | Automatic |  | How many times the loan has been renewed (0 to 2). |
| `Status` | `enum('Active','Returned','Overdue')` | Automatic |  | Active, Returned or Overdue. |

**Relationships**

- `Book_ID` points to `books.Book_ID`.
- `Member_ID` points to `members.Member_ID`.
- `fines.Loan_ID` points here (the parent can't be deleted while rows point to it).

**Safety rules** (the database rejects data that breaks them)

- The due date can't be before the borrow date.
- A loan can be renewed 0 to 2 times.
- The return date can't be before the borrow date.
- A Returned loan must have a return date. Any other loan must not have one.

**Indexes** (they make searches faster)

- `Book_ID` on `Book_ID`
- `idx_loans_member` on `Member_ID`, `Status`

### `members`

The students and staff who can borrow books.

| Column | Type | Required | Key | Description |
|---|---|---|---|---|
| `Member_ID` | `int` | Automatic | PK | Unique number for each row. Numbered automatically. |
| `Full_Name` | `varchar(50)` | Yes |  | The member's full name. |
| `Email` | `varchar(50)` | No (can be empty) | Unique | Email address. Unique. |
| `Phone_Number` | `varchar(20)` | Yes |  | Phone number kept as text (for example 254700000001), so leading zeros and long numbers are safe. |
| `Reg_No` | `varchar(30)` | Yes | Unique | Student registration number or staff number. Unique. |
| `Member_Type` | `varchar(15)` | Yes |  | Student or Staff. |
| `Is_active` | `tinyint(1)` | Automatic |  | True for current members, false once deactivated. |
| `Is_verified` | `tinyint(1)` | Automatic |  | True once the member has been checked against the student registry. |
| `Verified_at` | `datetime` | No (can be empty) |  | When that check was done. Empty until then. |

**Relationships**

- `fines.Member_ID` points here (the parent can't be deleted while rows point to it).
- `loans.Member_ID` points here (the parent can't be deleted while rows point to it).
- `mpesa_transactions.Member_ID` points here (the parent can't be deleted while rows point to it).
- `notifications.Member_ID` points here (the parent can't be deleted while rows point to it).
- `recommendation_log.Member_ID` points here (deleting the parent also deletes these rows).
- `reservations.Member_ID` points here (the parent can't be deleted while rows point to it).

**Indexes** (they make searches faster)

- `Reg_No` on `Reg_No` (unique)
- `uq_members_email` on `Email` (unique)

### `mpesa_transactions`

Every M-Pesa payment attempt for a fine, with its outcome.

| Column | Type | Required | Key | Description |
|---|---|---|---|---|
| `Transaction_ID` | `int` | Automatic | PK | Unique number for each row. Numbered automatically. |
| `Fine_ID` | `int` | Yes | FK to fines.Fine_ID | The fine being paid. |
| `Member_ID` | `int` | Yes | FK to members.Member_ID | Who is paying. |
| `Phone_Number` | `varchar(20)` | Yes |  | The phone that was asked to pay. |
| `Amount` | `decimal(10,2)` | Yes |  | Amount requested. |
| `Checkout_request_id` | `varchar(100)` | No (can be empty) | Unique | M-Pesa's reference for the request. Unique. |
| `Mpesa_receipt` | `varchar(50)` | No (can be empty) | Unique | M-Pesa receipt code once paid. Unique. |
| `Status` | `enum('Pending','Success','Failed','Cancelled')` | Automatic |  | Pending, Success, Failed or Cancelled. |
| `Result_description` | `varchar(255)` | No (can be empty) |  | M-Pesa's explanation of the result. |
| `Initiated_at` | `datetime` | Automatic |  | When the request was sent. |
| `Completed_at` | `datetime` | No (can be empty) |  | When M-Pesa answered. Empty until then. |

**Relationships**

- `Fine_ID` points to `fines.Fine_ID`.
- `Member_ID` points to `members.Member_ID`.

**Safety rules** (the database rejects data that breaks them)

- A payment amount must be more than 0.

**Indexes** (they make searches faster)

- `fk_mpesa_member` on `Member_ID`
- `idx_mpesa_fine` on `Fine_ID`
- `uq_mpesa_checkout` on `Checkout_request_id` (unique)
- `uq_mpesa_receipt` on `Mpesa_receipt` (unique)

### `notifications`

Email and SMS messages sent to members, such as reminders.

| Column | Type | Required | Key | Description |
|---|---|---|---|---|
| `Notification_ID` | `int` | Automatic | PK | Unique number for each row. Numbered automatically. |
| `Member_ID` | `int` | Yes | FK to members.Member_ID | The member the message is for. |
| `Channel` | `enum('Email','SMS')` | No (can be empty) |  | Email or SMS. |
| `Status` | `enum('Pending','Sent','Failed')` | No (can be empty) |  | Pending, Sent or Failed. |
| `Sent_at` | `date` | No (can be empty) |  | Date it was sent. Empty until then. |
| `Message` | `text` | Yes |  | The message text. |
| `Subject` | `varchar(200)` | No (can be empty) |  | Subject line, mainly for email. Optional. |

**Relationships**

- `Member_ID` points to `members.Member_ID`.

**Indexes** (they make searches faster)

- `Member_ID` on `Member_ID`

### `recommendation_log`

AI data: which books were recommended to which members, and how strongly.

| Column | Type | Required | Key | Description |
|---|---|---|---|---|
| `Recommendation_ID` | `int` | Automatic | PK | Unique number for each row. Numbered automatically. |
| `Member_ID` | `int` | Yes | FK to members.Member_ID | Who the book was recommended to. |
| `Book_ID` | `int` | Yes | FK to books.Book_ID | The recommended book. |
| `Score` | `decimal(5,4)` | Yes |  | How strong the recommendation is, from 0 to 1. |
| `Generated_at` | `datetime` | Automatic |  | When it was generated. |

**Relationships**

- `Book_ID` points to `books.Book_ID`.
- `Member_ID` points to `members.Member_ID`.

**Safety rules** (the database rejects data that breaks them)

- A recommendation score must be between 0 and 1.

**Indexes** (they make searches faster)

- `fk_reclog_book` on `Book_ID`
- `idx_reclog_member` on `Member_ID`, `Generated_at`

### `registry_sync_log`

A record of every run of the student registry sync.

| Column | Type | Required | Key | Description |
|---|---|---|---|---|
| `Sync_ID` | `int` | Automatic | PK | Unique number for each row. Numbered automatically. |
| `Started_at` | `datetime` | Automatic |  | When the sync started. |
| `Finished_at` | `datetime` | No (can be empty) |  | When it finished. Empty while running. |
| `Records_checked` | `int` | Automatic |  | How many students were looked at. |
| `Records_updated` | `int` | Automatic |  | How many were changed. |
| `Status` | `enum('Running','Success','Failed')` | Automatic |  | Running, Success or Failed. |
| `Error_message` | `text` | No (can be empty) |  | What went wrong, if it failed. |

### `reservations`

Holds that members place on books that are currently out.

| Column | Type | Required | Key | Description |
|---|---|---|---|---|
| `Reservation_ID` | `int` | Automatic | PK | Unique number for each row. Numbered automatically. |
| `Book_ID` | `int` | Yes | FK to books.Book_ID | The book being reserved. |
| `Member_ID` | `int` | Yes | FK to members.Member_ID | The member who reserved it. |
| `Reserved_at` | `date` | Yes |  | Date the reservation was made. |
| `Expires_at` | `date` | No (can be empty) |  | Date the reservation lapses if not collected. Optional. |
| `Status` | `enum('Waiting','Ready','Fulfilled','Cancelled')` | No (can be empty) |  | Waiting, Ready, Fulfilled or Cancelled. |

**Relationships**

- `Book_ID` points to `books.Book_ID`.
- `Member_ID` points to `members.Member_ID`.

**Safety rules** (the database rejects data that breaks them)

- A reservation can't expire before it was made.

**Indexes** (they make searches faster)

- `Book_ID` on `Book_ID`
- `Member_ID` on `Member_ID`

### `student_registry`

The university's list of students, used to check that someone is really enrolled.

| Column | Type | Required | Key | Description |
|---|---|---|---|---|
| `Reg_No` | `varchar(30)` | Yes | PK | The student's registration number. Matches members.Reg_No. |
| `Full_Name` | `varchar(100)` | Yes |  | The student's full name. |
| `Programme` | `varchar(100)` | No (can be empty) |  | Course of study. Optional. |
| `Year_of_study` | `tinyint` | No (can be empty) |  | Current year of study, 1 to 8. Optional. |
| `Enrollment_status` | `enum('Enrolled','Deferred','Graduated','Suspended')` | Automatic |  | Enrolled, Deferred, Graduated or Suspended. |
| `Updated_at` | `timestamp` | Automatic |  | When the row last changed. Set automatically. |

**Safety rules** (the database rejects data that breaks them)

- Year of study must be between 1 and 8, or empty.

## Views

A view is a saved query that behaves like a read-only table. It stores no data of its own.

### `v_book_popularity`

How many times each book has been borrowed, and when it was last borrowed.

Columns: `Book_ID`, `Title`, `Category_ID`, `Times_borrowed`, `Last_borrowed_at`

### `v_borrow_history`

Every loan together with its book's category. Used by the recommendations.

Columns: `Loan_ID`, `Member_ID`, `Book_ID`, `Category_ID`, `Borrowed_at`, `Returned_at`, `Status`

### `v_monitor_alerts`

One row for every problem found right now. No rows means no problems.

Columns: `Severity`, `Alert`, `Count_or_value`, `Detail`

### `v_monitor_health`

One row of key numbers: a mini dashboard.

Columns: `Active_members`, `Books`, `Open_loans`, `Overdue_loans`, `Unpaid_fines_total`, `Pending_mpesa`, `Failed_notifications`, `Last_sync_status`, `Last_sync_at`, `Changes_last_24h`

### `v_monitor_table_sizes`

Every table with its approximate size on disk.

Columns: `Table_name`, `Approx_rows`, `Size_mb`

### `v_verify_student`

What the verify-student endpoint reads: each registry student and whether they are currently enrolled.

Columns: `Reg_No`, `Full_Name`, `Enrollment_status`, `Is_enrolled`

## Triggers

A trigger runs by itself when data changes. These ones write to `audit_log`.

| Trigger | Table | Runs when |
|---|---|---|
| `trg_fines_delete` | `fines` | a row is deleted |
| `trg_fines_insert` | `fines` | a new row is added |
| `trg_fines_update` | `fines` | a row is changed |
| `trg_loans_delete` | `loans` | a row is deleted |
| `trg_loans_insert` | `loans` | a new row is added |
| `trg_loans_update` | `loans` | a row is changed |
| `trg_members_flags` | `members` | a row is changed (only if `Is_active` or `Is_verified` changed) |
| `trg_mpesa_delete` | `mpesa_transactions` | a row is deleted |
| `trg_mpesa_insert` | `mpesa_transactions` | a new row is added |
| `trg_mpesa_update` | `mpesa_transactions` | a row is changed |
