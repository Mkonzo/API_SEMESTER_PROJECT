# Migrations

Each file is one change to the KISII_LIBRARY database. They are numbered in the order they were made.

| File | What it does | Already applied to the original database? |
|---|---|---|
| 001_initial_schema.sql | The first version of the tables | Yes |
| 002_fix_schema.sql | Auto-numbering, books foreign key, loan due date and status, text phone numbers | Yes |
| 003_add_indexes.sql | Indexes on book titles and loans | Yes |
| 004_student_registry.sql | Student registry, member verification, verify view | No, run once |
| 005_integrity_rules.sql | Safety rules (CHECK constraints) | No, run once |
| 006_ai_data_store.sql | Embeddings, recommendation log, demand forecast, history views | No, run once |
| 007_mpesa_and_sync.sql | M-Pesa transactions and registry sync log | No, run once |
| 008_app_users.sql | Limited database users (needs passwords set first, see the file) | No, run once |
| 009_monitoring.sql | Change log, health views and alert rules (run after the sample data is loaded) | No, run once |

Never run a migration twice. A second run fails because the change already exists.
To build a brand-new database, follow Option B in the main README.
