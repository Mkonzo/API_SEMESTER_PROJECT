# Monitoring the KISII_LIBRARY database (D7)

Monitoring means three things: **logging** (a record of what happened), **metrics** (numbers that show how healthy things are) and **alerts** (a message when something is wrong).

Everything here was added by `database/migrations/009_monitoring.sql` plus the scripts in `database/monitor/`.

## 1. The change log (`audit_log`)

Every change to **loans**, **fines** and **M-Pesa payments** is written to the `audit_log` table by the database itself. A member being activated, deactivated or verified is logged too. Each row records:

| Column | Meaning |
|---|---|
| `Table_name`, `Row_id` | Which row changed |
| `Action` | INSERT, UPDATE or DELETE |
| `Old_values`, `New_values` | What it looked like before and after |
| `Changed_by` | The database user and where they connected from, for example `library_app@localhost` |
| `Changed_at` | When |

**What is deliberately not logged:** names, email addresses and phone numbers. Only the active and verified flags of a member are recorded, so the log does not become a second copy of private data.

**Look at the log**

```sql
-- the 20 most recent changes
SELECT Audit_ID, Table_name, Row_id, Action, Changed_by, Changed_at
FROM audit_log ORDER BY Audit_ID DESC LIMIT 20;

-- the full history of loan number 3
SELECT Action, Old_values, New_values, Changed_by, Changed_at
FROM audit_log WHERE Table_name = 'loans' AND Row_id = 3 ORDER BY Audit_ID;
```

**Keep it from growing forever.** Delete old rows now and then (after backing up):

```sql
DELETE FROM audit_log WHERE Changed_at < NOW() - INTERVAL 90 DAY;
```

**Limits to know about**
- A change that the database **rejects** (for example one that breaks a safety rule) leaves no log row, because nothing changed.
- The log protects against mistakes and lets you trace them. It does not stop someone with full access to the database from editing it. The backend user `library_app` has write access to the whole database, including `audit_log`. For stronger protection, grant that user rights table by table and leave `audit_log` out.

## 2. Dashboard and alert views

| View | What it shows |
|---|---|
| `v_monitor_health` | One row of key numbers: active members, open and overdue loans, unpaid fines, pending M-Pesa payments, failed notifications, last registry sync, changes in the last 24 hours |
| `v_monitor_table_sizes` | Every table with its size (the row counts in it are estimates) |
| `v_monitor_alerts` | One row for every problem found right now. An empty result means no problems |

```sql
SELECT * FROM v_monitor_health;
SELECT Severity, Alert, Count_or_value, Detail FROM v_monitor_alerts;
```

**The alerts, and what to do about each**

| Severity | Alert | What it means | What to do |
|---|---|---|---|
| CRIT | Copy counts do not match loans | A book's available copies differ from total copies minus open loans | The data is inconsistent. Find the book, work out the right number, and fix it. Check the backend's borrow and return code |
| CRIT | Registry sync failed | The last student registry sync ended in failure | Look at `registry_sync_log.Error_message` |
| WARN | Registry sync is stale | No successful sync in 7 days | Run or fix the sync |
| WARN | Overdue loans | Loans past their due date and not returned | Normal in a library. Check that fines and reminders are being created |
| WARN | Old unpaid fines | Fines unpaid for over 30 days | Follow up with the members |
| WARN | M-Pesa payments stuck | Payments still Pending after a day | Check with the M-Pesa integration |
| WARN | M-Pesa payments failed | Payments that failed | Check `mpesa_transactions.Result_description` |
| WARN | Notifications failed | Messages that could not be sent | Check the email and SMS services |
| INFO | Books with no copies on the shelf | Every copy of a book is out | Nothing is wrong. This is for information |

## 3. The health check script

```
bash database/monitor/health_check.sh              # short report
bash database/monitor/health_check.sh --metrics    # report plus numbers and table sizes
```

It asks for the password once (typing is hidden). By default it connects as `library_readonly`, which only needs to read. If you have not created that user yet, use `DB_USER=root bash database/monitor/health_check.sh`.

**Example**

```
Library database health: KISII_LIBRARY   2026-11-18 00:01
  OK    Connected (MySQL 8.0.46, running for 0 days 0 hours)
  OK    Connections: 1 of 151 (0%)
  WARN  M-Pesa payments stuck: 1. Payments still Pending after more than 1 day
  WARN  Old unpaid fines: 1. Fines unpaid for more than 30 days
  WARN  Overdue loans: 2. Loans past their due date and not yet returned
  WARN  Registry sync is stale: 1. No successful student registry sync in the last 7 days
  WARN  No backup found in backups/ (run: bash database/backup/backup.sh)

RESULT: WARN
```

(The warnings in this example are real findings on the sample data: its October loans are now overdue.)

**Exit codes:** 0 = OK, 1 = WARN, 2 = CRIT. A scheduler or another script can react to the code.

**What it checks:** it can connect; the number of connections against the limit; every problem in `v_monitor_alerts`; and how old your newest backup in `backups/` is (a warning after 7 days). If migration 009 has not been run, it says so instead of failing.

**Options (set before the command):** `DB_NAME`, `DB_USER`, `MYSQL_HOST` and `MYSQL_PORT` (to connect over the network), `BACKUP_DIR`, `MAX_BACKUP_AGE_DAYS`, `MAX_CONN_PCT`, `ALERT_WEBHOOK_URL`.

**To avoid typing the password every time**, create a file outside the repository, in your home folder:

```
cat > ~/.library_monitor.cnf << 'EOT'
[client]
user=library_readonly
password=PUT_THE_PASSWORD_HERE
EOT
```

The script uses it automatically. Never put it in the project folder.

## 4. The slow query log

A slow query is one that takes more than 1 second. Turn the log on once, as root, in the MySQL Command Line Client:

```
SOURCE C:/Users/YOURNAME/documents/API_SEMESTER_PROJECT/database/monitor/enable_logging.sql;
```

It prints the log file's location. The setting is saved with `SET PERSIST`, so it survives a MySQL restart. Read the log file with any text editor. A query that shows up there repeatedly usually needs an index.

## 5. Running the check automatically

**Windows (Task Scheduler)**, which runs it every morning. Create a basic task with a daily trigger and this action:

- Program: `C:\Program Files\Git\bin\bash.exe`
- Arguments: `-lc "cd ~/documents/API_SEMESTER_PROJECT && bash database/monitor/health_check.sh >> monitor.log 2>&1"`

This needs the `~/.library_monitor.cnf` file from section 3, because a scheduled task cannot type a password. `*.log` files are already ignored by Git.

**Linux or Mac (cron):** `0 8 * * * cd /path/to/project && bash database/monitor/health_check.sh >> monitor.log 2>&1`

*I tested the script itself thoroughly, but I could not test Task Scheduler or cron here. Run the command by hand first, then schedule it, and check `monitor.log` the next day.*

## 6. Alerts to your phone or a chat

Set `ALERT_WEBHOOK_URL` to the address of an incoming webhook (Slack, Discord or similar). When the result is WARN or CRIT, the script posts a short message there. Nothing is sent when everything is OK.

```
export ALERT_WEBHOOK_URL='https://your-webhook-address'
bash database/monitor/health_check.sh
```

A webhook address works like a password, so keep it out of the repository (set it in your terminal, in `~/.bashrc`, or in the Task Scheduler task).

*I tested this against a local test receiver, and I tested that the script finishes normally if the webhook is down. I could not test it against a real Slack or Discord channel, so try it once with a deliberate warning.*

## 7. On a hosted database

- Creating triggers needs the right to do so. Some hosts do not give that to the main user. If migration 009 fails on the triggers, ask the host or skip the change log and keep the views.
- The slow query log is usually switched on from the host's dashboard, not with `enable_logging.sql`.
- Many hosts have their own monitoring and alerts. Use those as well.

## 8. Checklist

- [ ] Migrations 009 and 010 run, and `SELECT * FROM v_monitor_alerts;` works
- [ ] `health_check.sh` run by hand and the result understood
- [ ] Slow query log turned on
- [ ] A webhook or schedule set up, if you want it automatic
- [ ] `database/KISII_LIBRARY.sql` exported again after migration 009
