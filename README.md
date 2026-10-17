# Kisii University Library API

Semester project for **COMP 330 (API Design)** at Kisii University.

A REST API for the university library. Students and staff can search the catalog, borrow, reserve, renew and return books, and pay fines. Librarians can manage books, members, fines and notifications.

**Author:** Mkonzo Shirlean

---

## Table of contents

1. [Project overview](#1-project-overview)
2. [Repository structure](#2-repository-structure)
3. [Quick start](#3-quick-start)
4. [API design](#4-api-design)
5. [Data models](#5-data-models)
6. [Database](#6-database)
7. [Sample (seed) data](#7-sample-seed-data)
8. [Authentication and security](#8-authentication-and-security)
9. [Errors and pagination](#9-errors-and-pagination)
10. [External integrations and AI features](#10-external-integrations-and-ai-features)
11. [Testing](#11-testing)
12. [Documentation and mock server](#12-documentation-and-mock-server)
13. [Deployment](#13-deployment)
14. [Project timeline and status](#14-project-timeline-and-status)
15. [Tools](#15-tools)

---

## 1. Project overview

**Goal:** design a library API *design-first*. The API contract (an OpenAPI file) is written and agreed before any code, so the frontend, backend and database all build to the same document.

**Users**

| User | What they do |
|---|---|
| Student | Searches books, borrows, reserves, renews, returns and pays fines |
| Staff member | Does the same as a student |
| Librarian | Manages the catalog and members, issues fines, sends notifications |

**Resources:** Books, Members, Loans, Reservations, Fines, Categories, Authors and Notifications.

The OpenAPI file in `spec/` is the **single source of truth**. If this README and the spec ever disagree, the spec wins.

---

## 2. Repository structure

```
API_SEMESTER_PROJECT/
├── README.md
├── spec/
│   └── library-api.yaml          OpenAPI 3.0 specification
├── database/
│   ├── kisii_library_schema.sql  Table definitions only
│   ├── seed.sql                  Sample data
│   └── KISII_LIBRARY.sql         Full export (tables and data)
└── reports/
    └── Week-01-Progress-Report.docx ... Week-15-Progress-Report.docx
```

Add the `spec/` and `reports/` folders and the schema and seed files as you complete each part.

---

## 3. Quick start

You need MySQL installed.

**Option A: restore the full export**

```
mysql -u root -p -e "CREATE DATABASE KISII_LIBRARY CHARACTER SET utf8mb4;"
mysql -u root -p KISII_LIBRARY < database/KISII_LIBRARY.sql
```

The export does not create the database itself, which is why the first command comes first.

**Option B: build from scratch**

```
mysql -u root -p < database/kisii_library_schema.sql
mysql -u root -p < database/seed.sql
```

The schema script creates the database and the tables. The seed script then fills them with sample rows. Table and database names are not case sensitive on Windows, but they are on Linux, so keep the same capitalisation in every file.

**Check it worked**

```
mysql -u root -p -e "USE KISII_LIBRARY; SHOW TABLES;"
```

You should see nine tables.

**View the API specification:** paste `spec/library-api.yaml` into the [Swagger Editor](https://editor.swagger.io) to see every endpoint with its request and response.

---

## 4. API design

The API follows REST: resources are named with plural nouns, the HTTP method is the verb, and each request carries everything the server needs.

**Base URL (local development):** `http://localhost:3000/v1`

### Endpoints

| Resource | Method and path | What it does |
|---|---|---|
| Books | `GET /books` | List or search books (`q`, `categoryId`, `page`, `limit`, `sort`) |
| | `POST /books` | Add a book |
| | `GET /books/{bookId}` | Get one book |
| | `PUT /books/{bookId}` | Replace a book |
| | `PATCH /books/{bookId}` | Change part of a book |
| | `DELETE /books/{bookId}` | Remove a book |
| Members | `GET /members` | List members (librarians only) |
| | `POST /members` | Register a member |
| | `GET /members/{memberId}` | Get one member |
| | `PATCH /members/{memberId}` | Update member details |
| | `POST /members/{memberId}/deactivate` | Deactivate a member |
| Loans | `GET /loans` | List loans (`memberId`, `status`) |
| | `POST /loans` | Borrow a book |
| | `GET /loans/{loanId}` | Get one loan |
| | `POST /loans/{loanId}/return` | Return a book |
| | `POST /loans/{loanId}/renew` | Renew a loan |
| Reservations | `GET /reservations` | List reservations |
| | `POST /reservations` | Reserve a book |
| | `GET /reservations/{reservationId}` | Get one reservation |
| | `DELETE /reservations/{reservationId}` | Cancel a reservation |
| Fines | `GET /fines` | List fines (`status`) |
| | `GET /fines/{fineId}` | Get one fine |
| | `POST /fines/calculate` | Calculate the fine for a loan |
| | `POST /fines/{fineId}/pay` | Pay a fine |
| Categories | `GET /categories` | List categories |
| | `POST /categories` | Create a category |
| | `GET /categories/{categoryId}` | Get one category |
| Authors | `GET /authors` | List authors |
| | `POST /authors` | Create an author |
| | `GET /authors/{authorId}` | Get one author |
| Notifications | `GET /notifications` | List notifications |
| | `POST /notifications` | Send a notification (librarians only) |

### HTTP methods and status codes

| Method | Used for | Success code |
|---|---|---|
| GET | Read data | 200 |
| POST | Create something or start an action | 201 (create), 200 (action) |
| PUT | Replace a whole resource | 200 |
| PATCH | Change part of a resource | 200 |
| DELETE | Remove or cancel | 204 |

| Error code | Meaning | Example |
|---|---|---|
| 400 | Invalid input | A book sent without a title |
| 401 | Not logged in | No token sent |
| 403 | Not allowed | A member tries to delete a book |
| 404 | Not found | Book id 999 does not exist |
| 409 | Conflict | Duplicate ISBN, or no copies left to borrow |
| 422 | Wrong data type | Published year sent as text |
| 500 | Server error | Database unreachable |

---

## 5. Data models

Field names in the API use camelCase. The matching database columns use snake_case (for example `regNo` and `reg_no`).

**Book**

| Field | Type | Notes |
|---|---|---|
| id | integer | Set by the system |
| isbn | string | Up to 20 characters, unique |
| title | string | Required |
| description | string | Optional |
| publisher | string | Optional |
| publishedYear | integer | For example 1958 |
| categoryId | integer | Points to a category |
| totalCopies | integer | Copies the library owns |
| availableCopies | integer | Copies on the shelf now |

**Member**

| Field | Type | Notes |
|---|---|---|
| id | integer | Set by the system |
| regNo | string | Registration number, unique |
| fullName | string | Required |
| email | string | Required, unique |
| phone | string | Optional |
| memberType | string | `student` or `staff` |
| isActive | boolean | false once deactivated |

**Loan**

| Field | Type | Notes |
|---|---|---|
| id | integer | Set by the system |
| bookId | integer | The book borrowed |
| memberId | integer | Who borrowed it |
| borrowedAt | date-time | When it was borrowed |
| dueDate | date | When it must be back |
| returnedAt | date-time or null | Empty until returned |
| renewalCount | integer | Number of renewals |
| status | string | `active`, `returned` or `overdue` |

**Reservation:** `id`, `bookId`, `memberId`, `reservedAt`, `expiresAt`, `status` (`waiting`, `ready`, `fulfilled`, `cancelled`).

**Fine:** `id`, `loanId`, `memberId`, `amount`, `reason` (`overdue`, `damage`), `status` (`unpaid`, `paid`), `issuedAt`, `paidAt`, `mpesaReceipt`.

**Category:** `id`, `name`, `description`. **Author:** `id`, `name`, `bio`.

**Notification:** `id`, `memberId`, `channel` (`email`, `sms`), `subject`, `message`, `status` (`pending`, `sent`, `failed`), `sentAt`.

**Example Book**

```json
{
  "id": 1,
  "isbn": "9780000000001",
  "title": "Things Fall Apart",
  "publisher": "Heinemann",
  "publishedYear": 1958,
  "categoryId": 1,
  "totalCopies": 3,
  "availableCopies": 3
}
```

---

## 6. Database

MySQL, using the InnoDB engine (needed for foreign keys). Database name: `KISII_LIBRARY`.

### Tables, keys and relationships

| Table | Primary key | Foreign keys |
|---|---|---|
| `categories` | `id` | none |
| `authors` | `id` | none |
| `members` | `id` | none |
| `books` | `id` | `category_id` → `categories.id` |
| `book_authors` | `book_id` + `author_id` | `book_id` → `books.id`, `author_id` → `authors.id` |
| `loans` | `id` | `book_id` → `books.id`, `member_id` → `members.id` |
| `reservations` | `id` | `book_id` → `books.id`, `member_id` → `members.id` |
| `fines` | `id` | `loan_id` → `loans.id`, `member_id` → `members.id` |
| `notifications` | `id` | `member_id` → `members.id` |

```
categories ──< books >── book_authors ──< authors
                │
                ├──< loans >── members
                │       │          │
                │       └──< fines─┤
                │                  │
                └──< reservations >┤
                                   │
                          notifications
```

`──<` means one on the left, many on the right.

### Design decisions

- **Surrogate primary keys.** Every table has an `id` that never changes. Real-world identifiers such as `isbn` and `reg_no` are `UNIQUE` columns instead, because they can contain typos, be missing (older books, staff), or change.
- **`book_authors` link table.** A book can have several authors and an author can write several books, which needs a table in the middle.
- **`ON DELETE` rules.** Loans, reservations and fines use `RESTRICT`, so a book or member that still has records cannot be deleted. `book_authors` and `notifications` use `CASCADE`, and a book's category uses `SET NULL`.
- **Table names** are plural, lowercase and use underscores, to match the API paths.
- **Create tables in this order**, because a foreign key can only point to an existing table: `categories`, `authors`, `members`, `books`, `book_authors`, `loans`, `reservations`, `fines`, `notifications`.

### Column types in `books`

| Column | Type |
|---|---|
| `isbn` | `VARCHAR(20)`, unique (text, because ISBNs can start with 0, contain X or hyphens) |
| `title` | `VARCHAR(255)` |
| `description` | `TEXT` |
| `publisher` | `VARCHAR(150)` |
| `published_year` | `SMALLINT` |
| `category_id` | `INT` (same type as `categories.id`) |
| `total_copies`, `available_copies` | `INT` |

### Files

| File | Purpose |
|---|---|
| `database/kisii_library_schema.sql` | Creates the database and all nine tables |
| `database/seed.sql` | Inserts the sample data |
| `database/KISII_LIBRARY.sql` | Full export made with `mysqldump` |

**Re-export after changes**

```
mysqldump -u root -p KISII_LIBRARY > database/KISII_LIBRARY.sql
```

---

## 7. Sample (seed) data

`database/seed.sql` fills the database with made-up rows so every endpoint has something to return. Rows are inserted parent tables first.

| Table | Rows | What is in them |
|---|---|---|
| `categories` | 3 | Fiction, Computer Science, History |
| `authors` | 4 | Four sample authors |
| `members` | 3 | Two students and one staff member |
| `books` | 4 | Sample books with fake ISBNs |
| `book_authors` | 4 | One author linked to each book |
| `loans` | 3 | One returned, one overdue, one active |
| `reservations` | 1 | One waiting reservation |
| `fines` | 1 | One unpaid overdue fine |
| `notifications` | 2 | One email and one SMS |

All data is invented and contains no real student information.

**Test that the foreign keys work.** This should fail with a "foreign key constraint fails" error, which proves the database is protecting your data:

```sql
INSERT INTO loans (book_id, member_id, due_date) VALUES (999, 1, '2026-11-01');
```

---

## 8. Authentication and security

- **Login:** the user logs in and receives a **JWT** (JSON Web Token). The token is sent with every later request:

  ```
  Authorization: Bearer <token>
  ```

- **Roles:**

  | Action | Member | Librarian |
  |---|---|---|
  | Search books | Yes | Yes |
  | Add, edit or delete books | No | Yes |
  | See own loans, fines and notifications | Yes | Yes |
  | See everyone's loans, fines and notifications | No | Yes |
  | Deactivate a member | No | Yes |

- **Measures:** HTTPS only, passwords stored as hashes (never plain text), secrets kept in environment variables and out of GitHub, and rate limiting on requests.
- **401 or 403:** 401 means no valid token, 403 means a valid token without the right role.

---

## 9. Errors and pagination

**Error format.** Every error uses the same shape:

```json
{
  "code": "NOT_FOUND",
  "message": "Book 99 was not found"
}
```

**Pagination.** List endpoints take `page` (default 1) and `limit` (default 20, maximum 100) and return a `meta` object:

```
GET /books?page=2&limit=20
```

```json
{
  "data": [],
  "meta": { "page": 2, "limit": 20, "total": 134 }
}
```

**Search, filter and sort** use query parameters, for example `GET /books?q=python&categoryId=2&sort=-title`.

---

## 10. External integrations and AI features

| External system | Purpose | Endpoint |
|---|---|---|
| Student registry | Verify a student is enrolled | `GET /external/students/{regNo}/verify` |
| M-Pesa | Pay fines | `POST /payments/mpesa/initiate` |
| Email service | Send reminders | `POST /notifications/email` |
| SMS service | Send overdue alerts | `POST /notifications/sms` |
| ISBN lookup | Auto-fill book details | `GET /external/isbn/{isbn}` |

| AI feature | What it does | Endpoint |
|---|---|---|
| Recommendations | Suggests books from borrowing history | `GET /ai/recommendations/{memberId}` |
| Smart search | Natural-language search | `GET /ai/search?q=...` |
| Demand forecasting | Predicts high-demand books | `GET /ai/forecast/demand` |
| Auto-categorization | Suggests a category | `POST /ai/categorize` |
| Chatbot support | Answers member questions | `POST /ai/chat` |

The final hand-in needs at least **one** external integration and **one** AI endpoint.

---

## 11. Testing

Contract tests check that the real API behaves as the specification says.

| No. | Request | Expected |
|---|---|---|
| 1 | `GET /books` | 200 and a list matching the Book schema |
| 2 | `POST /books` with valid data | 201 and the new book |
| 3 | `POST /books` with a duplicate ISBN | 409 |
| 4 | `GET /books/99999` | 404 |
| 5 | `GET /loans` without a token | 401 |
| 6 | `POST /loans` for a book with no copies left | 409 |
| 7 | `DELETE /books/1` as a member | 403 |

Tools: Apidog test scenarios, or a spec-driven tool such as Schemathesis.

---

## 12. Documentation and mock server

- **Mock server:** import `spec/library-api.yaml` into Apidog and turn on the mock server. It returns example data in the right shape, so the frontend can start before the backend exists.
- **Server stubs and client SDKs** can be generated from the spec:

  ```
  npx @openapitools/openapi-generator-cli generate -i spec/library-api.yaml -g python-fastapi -o server
  npx @openapitools/openapi-generator-cli generate -i spec/library-api.yaml -g typescript-fetch -o client
  ```

  Pick the generator that matches your language.
- **Interactive documentation** is published with Swagger UI, Redoc or Apidog.

---

## 13. Deployment

- Host the database and the backend (Render, Railway or an AWS free tier).
- Set environment variables for the database address and password, the JWT secret and any API keys. Never commit them.
- Add a health endpoint, `GET /health`, to confirm the API is running.
- Plan database backups.
- Test the full flow on the live API: register, borrow, return, fine, pay.

**Live API URL:** *to be added*
**Documentation URL:** *to be added*

---

## 14. Project timeline and status

| Weeks | Focus | Milestone |
|---|---|---|
| 1 to 4 | API basics, HTTP, REST, JSON and data modeling | |
| 5 to 6 | Design-first and the OpenAPI specification | **M1** (week 6) |
| 7 | CAT 1 | |
| 8 | Security, errors, pagination, reservations, fines | **M2** (week 8) |
| 9 | Mock server | **M3** (week 9) |
| 10 to 12 | Security, testing, code generation | |
| 13 | API documentation | **M4** (week 13) |
| 14 | Deployment, integrations and AI | **M5** (week 14) |
| 15 | Final presentations | |

**Final deliverables**

- [x] Database: schema and sample data
- [ ] OpenAPI specification
- [ ] Mock server
- [ ] Backend
- [ ] Frontend
- [ ] Deployment
- [ ] Documentation
- [ ] AI integration
- [ ] External integration
- [ ] Final presentation

Weekly progress reports are in `reports/`.

---

## 15. Tools

| Tool | Used for |
|---|---|
| MySQL | Database |
| Git and GitHub | Version control |
| Swagger Editor | Writing and checking the OpenAPI file |
| Apidog | Mock server, testing and documentation |
| OpenAPI Generator | Server stubs and client SDKs |
| Postman or Apidog | Trying the API |
