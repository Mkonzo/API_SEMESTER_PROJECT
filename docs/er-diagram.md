# ER diagram: the KISII_LIBRARY database

An ER (entity-relationship) diagram shows the tables and how they are connected.

**How to read it**

- Each box is a table. The black bar holds its name.
- **PK** marks the primary key (the column that identifies each row). **FK** marks a foreign key: a column that must match a row in another table. **UK** marks a column whose values must be unique.
- A line runs from a foreign key to the key it points to. The end with a small bar is the *one* side. The forked end (crow's foot) is the *many* side. For example, one category has many books.
- A dashed line is a link that is made by matching values, not enforced by the database.

## The main picture (key columns only)

![ER diagram with the key columns of every table](er-diagram.png)

Every column of every table is described in the [data dictionary](data-dictionary.md).

## All columns

![ER diagram with every column](er-diagram-full.png)

## Interactive version

GitHub draws this one itself, straight from the text below.

```mermaid
%%{init: {'theme': 'neutral'}}%%
erDiagram
  audit_log {
    bigint Audit_ID PK
    varchar Table_name
    int Row_id
    enum Action
    json Old_values
    json New_values
    varchar Changed_by
    datetime Changed_at
  }
  authors {
    int Author_ID PK
    varchar Name
    text Bio
  }
  book_authors {
    int Book_ID PK,FK
    int Author_ID PK,FK
  }
  book_embeddings {
    int Book_ID PK,FK
    varchar Model_name PK
    json Embedding
    timestamp Created_at
    timestamp Updated_at
  }
  books {
    int Book_ID PK
    varchar Isbn UK
    varchar Title
    text Description
    varchar Publisher
    int Published_Year
    int Category_ID FK
    int Total_Copies
    int Available_Copies
  }
  categories {
    int Category_ID PK
    varchar Name UK
    text Description
  }
  demand_forecast {
    int Forecast_ID PK
    int Book_ID FK
    date Forecast_month
    int Predicted_loans
    datetime Generated_at
  }
  fines {
    int Fine_ID PK
    int Loan_ID FK
    int Member_ID FK
    enum Status
    enum Reason
    decimal Amount
    date Issued_at
    date Paid_at
    varchar Mpesa_receipt
  }
  loans {
    int Loan_ID PK
    date Borrowed_at
    date Due_date
    date Returned_at
    int Book_ID FK
    int Member_ID FK
    int Renewal_count
    enum Status
  }
  members {
    int Member_ID PK
    varchar Full_Name
    varchar Email UK
    varchar Phone_Number
    varchar Reg_No UK
    varchar Member_Type
    tinyint Is_active
    tinyint Is_verified
    datetime Verified_at
  }
  mpesa_transactions {
    int Transaction_ID PK
    int Fine_ID FK
    int Member_ID FK
    varchar Phone_Number
    decimal Amount
    varchar Checkout_request_id UK
    varchar Mpesa_receipt UK
    enum Status
    varchar Result_description
    datetime Initiated_at
    datetime Completed_at
  }
  notifications {
    int Notification_ID PK
    int Member_ID FK
    enum Channel
    enum Status
    date Sent_at
    text Message
    varchar Subject
  }
  recommendation_log {
    int Recommendation_ID PK
    int Member_ID FK
    int Book_ID FK
    decimal Score
    datetime Generated_at
  }
  registry_sync_log {
    int Sync_ID PK
    datetime Started_at
    datetime Finished_at
    int Records_checked
    int Records_updated
    enum Status
    text Error_message
  }
  reservations {
    int Reservation_ID PK
    int Book_ID FK
    int Member_ID FK
    date Reserved_at
    date Expires_at
    enum Status
  }
  student_registry {
    varchar Reg_No PK
    varchar Full_Name
    varchar Programme
    tinyint Year_of_study
    enum Enrollment_status
    timestamp Updated_at
  }
  books ||--o{ book_authors : "Book_ID"
  authors ||--o{ book_authors : "Author_ID"
  books ||--o{ book_embeddings : "Book_ID"
  categories ||--o{ books : "Category_ID"
  books ||--o{ demand_forecast : "Book_ID"
  members ||--o{ fines : "Member_ID"
  loans ||--o{ fines : "Loan_ID"
  books ||--o{ loans : "Book_ID"
  members ||--o{ loans : "Member_ID"
  fines ||--o{ mpesa_transactions : "Fine_ID"
  members ||--o{ mpesa_transactions : "Member_ID"
  members ||--o{ notifications : "Member_ID"
  books ||--o{ recommendation_log : "Book_ID"
  members ||--o{ recommendation_log : "Member_ID"
  books ||--o{ reservations : "Book_ID"
  members ||--o{ reservations : "Member_ID"
  student_registry ||..o| members : "same Reg_No"
```

## Relationships in words

| One row of | can have many rows of | linked by | If the parent row is deleted |
|---|---|---|---|
| `books` | `book_authors` | `book_authors.Book_ID` | deleting the parent also deletes these rows |
| `authors` | `book_authors` | `book_authors.Author_ID` | deleting the parent also deletes these rows |
| `books` | `book_embeddings` | `book_embeddings.Book_ID` | deleting the parent also deletes these rows |
| `categories` | `books` | `books.Category_ID` | the parent can't be deleted while rows point to it |
| `books` | `demand_forecast` | `demand_forecast.Book_ID` | deleting the parent also deletes these rows |
| `members` | `fines` | `fines.Member_ID` | the parent can't be deleted while rows point to it |
| `loans` | `fines` | `fines.Loan_ID` | the parent can't be deleted while rows point to it |
| `books` | `loans` | `loans.Book_ID` | the parent can't be deleted while rows point to it |
| `members` | `loans` | `loans.Member_ID` | the parent can't be deleted while rows point to it |
| `fines` | `mpesa_transactions` | `mpesa_transactions.Fine_ID` | the parent can't be deleted while rows point to it |
| `members` | `mpesa_transactions` | `mpesa_transactions.Member_ID` | the parent can't be deleted while rows point to it |
| `members` | `notifications` | `notifications.Member_ID` | the parent can't be deleted while rows point to it |
| `books` | `recommendation_log` | `recommendation_log.Book_ID` | deleting the parent also deletes these rows |
| `members` | `recommendation_log` | `recommendation_log.Member_ID` | deleting the parent also deletes these rows |
| `books` | `reservations` | `reservations.Book_ID` | the parent can't be deleted while rows point to it |
| `members` | `reservations` | `reservations.Member_ID` | the parent can't be deleted while rows point to it |

## Links that are not enforced by the database

- `student_registry.Reg_No` and `members.Reg_No` hold the same registration number. It is not a foreign key, because a registry student does not have to be a library member.
- `audit_log.Table_name` and `audit_log.Row_id` point at rows in `loans`, `fines`, `mpesa_transactions` and `members` by value.
- `registry_sync_log` stands alone. It is a diary of sync runs.
