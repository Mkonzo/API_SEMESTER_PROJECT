#!/usr/bin/env bash
# ============================================================
# Builds a FRESH copy of the database from the numbered files and checks it.
# GitHub runs this on every push (see .github/workflows/database-ci.yml).
# You can also run it by hand:   bash database/ci/check_database.sh
#
# It never touches your real KISII_LIBRARY database. It works in a separate
# database called KISII_LIBRARY_CI (and deletes it again at the end).
#
# Settings (all optional):
#   MYSQL_HOST / MYSQL_PORT   connect over the network (default: local socket)
#   MYSQL_USER                default root
#   MYSQL_PWD                 the password (if not set, you are asked once)
#   DB_NAME                   default KISII_LIBRARY_CI (KISII_LIBRARY is refused)
#
# When you add a migration or change the sample data, update the EXPECTED_
# numbers below. A failing check then tells you the files and the numbers
# no longer agree.
# ============================================================
set -u
set -o pipefail

EXPECTED_TABLES=16
EXPECTED_VIEWS=6
EXPECTED_TRIGGERS=10
EXPECTED_CHECKS=13
EXPECTED_FOREIGN_KEYS=16
EXPECTED_ROWS="categories=3 authors=4 members=3 books=4 book_authors=4 loans=3 reservations=1 fines=1 notifications=2 student_registry=5 book_embeddings=1 recommendation_log=1 demand_forecast=1 mpesa_transactions=1 registry_sync_log=1 audit_log=0"

DB="${DB_NAME:-KISII_LIBRARY_CI}"
if [ "$DB" = "KISII_LIBRARY" ]; then
  echo "Refusing to run against KISII_LIBRARY. This script deletes and rebuilds its database." >&2
  exit 2
fi
EXPORT_DB="${DB}_EXPORT"
USER_NAME="${MYSQL_USER:-root}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DBDIR="$HERE/database"

ARGS=(-u "$USER_NAME")
if [ -n "${MYSQL_HOST:-}" ]; then
  ARGS+=(-h "$MYSQL_HOST" -P "${MYSQL_PORT:-3306}" --protocol=TCP)
fi
if [ -z "${MYSQL_PWD+x}" ]; then
  read -r -s -p "Password for MySQL user $USER_NAME: " MYSQL_PWD; echo
fi
export MYSQL_PWD

WORK="$(mktemp -d)"
cleanup() {
  mysql "${ARGS[@]}" -e "DROP DATABASE IF EXISTS \`$DB\`; DROP DATABASE IF EXISTS \`$EXPORT_DB\`; DROP DATABASE IF EXISTS \`${DB}_VERIFY\`;" >/dev/null 2>&1
  rm -rf "$WORK"
}
trap cleanup EXIT

PASS=0; FAIL=0
ok()  { echo "  PASS  $1"; PASS=$((PASS + 1)); }
bad() { echo "  FAIL  $1" >&2; FAIL=$((FAIL + 1)); }
q()   { mysql "${ARGS[@]}" -N -B -e "$1" | tr -d '\r'; }
qdb() { mysql "${ARGS[@]}" "$DB" -N -B -e "$1" | tr -d '\r'; }
expect_equal() { if [ "$2" = "$3" ]; then ok "$1 ($2)"; else bad "$1: expected $3, found $2"; fi; }

# run a SQL file against $DB: the files say KISII_LIBRARY, so the name is swapped on the way in
run_file() { sed "s/KISII_LIBRARY/$DB/g" "$1" | mysql "${ARGS[@]}"; }

echo "== 1. Connecting"
if q "SELECT 1" >/dev/null 2>&1; then ok "connected to MySQL (version $(q 'SELECT VERSION()'))"; else bad "could not connect to MySQL"; exit 1; fi

echo "== 2. Building a fresh database from the numbered files"
q "DROP DATABASE IF EXISTS \`$DB\`" || exit 1
for f in migrations/001_initial_schema.sql migrations/002_fix_schema.sql migrations/003_add_indexes.sql seed.sql \
         migrations/004_student_registry.sql migrations/005_integrity_rules.sql migrations/006_ai_data_store.sql \
         migrations/007_mpesa_and_sync.sql seed_extra.sql migrations/009_monitoring.sql migrations/010_portable_table_sizes_view.sql; do
  if [ ! -f "$DBDIR/$f" ]; then bad "missing file database/$f"; continue; fi
  if run_file "$DBDIR/$f" 2>"$WORK/err.txt"; then ok "ran $f"; else bad "$f failed: $(head -1 "$WORK/err.txt")"; fi
done

echo "== 3. Shape of the database"
expect_equal "base tables" "$(q "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='$DB' AND TABLE_TYPE='BASE TABLE'")" "$EXPECTED_TABLES"
expect_equal "views"       "$(q "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='$DB' AND TABLE_TYPE='VIEW'")" "$EXPECTED_VIEWS"
expect_equal "safety rules (CHECK)" "$(q "SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA='$DB' AND CONSTRAINT_TYPE='CHECK'")" "$EXPECTED_CHECKS"
expect_equal "triggers (change log)" "$(q "SELECT COUNT(*) FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA='$DB'")" "$EXPECTED_TRIGGERS"
expect_equal "foreign keys" "$(q "SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA='$DB' AND CONSTRAINT_TYPE='FOREIGN KEY'")" "$EXPECTED_FOREIGN_KEYS"

echo "== 4. Sample data"
for pair in $EXPECTED_ROWS; do
  t="${pair%%=*}"; n="${pair##*=}"
  expect_equal "rows in $t" "$(qdb "SELECT COUNT(*) FROM \`$t\`" 2>/dev/null)" "$n"
done
for v in v_verify_student v_borrow_history v_book_popularity v_monitor_table_sizes; do
  n="$(qdb "SELECT COUNT(*) FROM $v" 2>/dev/null)"
  if [ -n "$n" ] && [ "$n" -gt 0 ] 2>/dev/null; then ok "view $v returns rows ($n)"; else bad "view $v is empty or broken"; fi
done

echo "== 5. Bad data must be rejected"
reject() {
  if mysql "${ARGS[@]}" "$DB" -e "$2" >/dev/null 2>&1; then bad "$1 was ACCEPTED (it should be rejected)"; else ok "rejected: $1"; fi
}
reject "more available copies than total"   "UPDATE books SET Available_Copies = 99 WHERE Book_ID = 1;"
reject "negative copies"                    "UPDATE books SET Available_Copies = -1 WHERE Book_ID = 4;"
reject "due date before borrow date"        "INSERT INTO loans (Book_ID, Member_ID, Borrowed_at, Due_date) VALUES (4, 1, '2026-10-20', '2026-10-01');"
reject "3 renewals"                         "UPDATE loans SET Renewal_count = 3 WHERE Loan_ID = 3;"
reject "Returned loan with no return date"  "UPDATE loans SET Status = 'Returned' WHERE Loan_ID = 3;"
reject "Paid fine with no paid date"        "UPDATE fines SET Status = 'Paid' WHERE Fine_ID = 1;"
reject "negative fine"                      "UPDATE fines SET Amount = -5 WHERE Fine_ID = 1;"
reject "loan for a book that does not exist" "INSERT INTO loans (Book_ID, Member_ID, Borrowed_at, Due_date) VALUES (999, 1, '2026-10-18', '2026-11-01');"
reject "book with an unknown category"      "INSERT INTO books (Isbn,Title,Description,Publisher,Published_Year,Category_ID,Total_Copies,Available_Copies) VALUES ('1','x','x','x',2000,999,1,1);"
reject "duplicate ISBN"                     "INSERT INTO books (Isbn,Title,Description,Publisher,Published_Year,Category_ID,Total_Copies,Available_Copies) VALUES ('9780000000001','dup','x','x',2000,1,1,1);"
reject "duplicate member email"             "INSERT INTO members (Full_Name,Email,Phone_Number,Reg_No,Member_Type) VALUES ('x','student1@example.com','1','Z/9','Student');"
reject "M-Pesa row for a missing fine"      "INSERT INTO mpesa_transactions (Fine_ID, Member_ID, Phone_Number, Amount) VALUES (999, 1, '254700000001', 20);"
reject "deleting a book that has loans"     "DELETE FROM books WHERE Book_ID = 1;"

echo "== 6. Good changes must be accepted (and are undone afterwards)"
accept() {
  if mysql "${ARGS[@]}" "$DB" -e "START TRANSACTION; $2 ROLLBACK;" >/dev/null 2>&1; then ok "accepted: $1"; else bad "$1 was REJECTED (it should be accepted)"; fi
}
accept "a new category (auto-numbered id)" "INSERT INTO categories (Name) VALUES ('CI test');"
accept "returning a loan properly"         "UPDATE loans SET Status='Returned', Returned_at='2026-10-18' WHERE Loan_ID=3;"
accept "paying a fine properly"            "UPDATE fines SET Status='Paid', Paid_at='2026-10-18' WHERE Fine_ID=1;"

echo "== 7. Change log and monitoring"
# each test runs in a transaction that is undone, so nothing is kept
audit_count() { mysql "${ARGS[@]}" "$DB" -N -B -e "START TRANSACTION; $1 SELECT COUNT(*) FROM audit_log WHERE $2; ROLLBACK;" 2>/dev/null | tr -d '\r' | tail -1; }
expect_equal "a loan change is logged once" "$(audit_count "UPDATE loans SET Renewal_count=1 WHERE Loan_ID=3;" "Table_name='loans' AND Row_id=3 AND Action='UPDATE'")" "1"
expect_equal "the log keeps old and new values" "$(audit_count "UPDATE loans SET Renewal_count=1 WHERE Loan_ID=3;" "JSON_EXTRACT(Old_values,'\$.Renewal_count')=0 AND JSON_EXTRACT(New_values,'\$.Renewal_count')=1")" "1"
expect_equal "a fine payment is logged" "$(audit_count "UPDATE fines SET Status='Paid', Paid_at='2026-10-18' WHERE Fine_ID=1;" "Table_name='fines' AND Row_id=1")" "1"
expect_equal "changing a phone number is NOT logged (private data)" "$(audit_count "UPDATE members SET Phone_Number='0711111111' WHERE Member_ID=1;" "Table_name='members'")" "0"
expect_equal "deactivating a member IS logged" "$(audit_count "UPDATE members SET Is_active=FALSE WHERE Member_ID=1;" "Table_name='members'")" "1"
expect_equal "a rejected change leaves no log row" "$(audit_count "" "1=1")" "0"
expect_equal "dashboard view returns one row" "$(qdb "SELECT COUNT(*) FROM v_monitor_health")" "1"
expect_equal "no CRITICAL alerts on the sample data" "$(qdb "SELECT COUNT(*) FROM v_monitor_alerts WHERE Severity='CRIT'")" "0"

echo "== 8. The export file that is saved in the repository"
EXPORT="$DBDIR/KISII_LIBRARY.sql"
if [ ! -f "$EXPORT" ]; then bad "database/KISII_LIBRARY.sql is missing"
else
  SIZE="$(wc -c < "$EXPORT")"
  if [ "$SIZE" -ge 2000 ]; then ok "export is not empty ($SIZE bytes)"; else bad "export is empty or tiny ($SIZE bytes)"; fi
  if grep -q "Dump completed" "$EXPORT"; then ok "export is complete (has the end marker)"; else bad "export is cut off (no end marker)"; fi
  q "DROP DATABASE IF EXISTS \`$EXPORT_DB\`; CREATE DATABASE \`$EXPORT_DB\` CHARACTER SET utf8mb4;"
  if sed "s/KISII_LIBRARY/$EXPORT_DB/g" "$EXPORT" | mysql "${ARGS[@]}" "$EXPORT_DB" 2>"$WORK/err.txt"; then
    ok "export loads into an empty database"
    expect_equal "tables in the export" "$(q "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='$EXPORT_DB' AND TABLE_TYPE='BASE TABLE'")" "$EXPECTED_TABLES"
  else bad "export failed to load: $(head -1 "$WORK/err.txt") (an export made on Windows must also load on Linux; see database/migrations/010)"; fi
fi

echo "== 9. Backup and restore scripts"
# The scripts get their login from the environment, never from a file. Any password
# file in your home folder is ignored here, so the test cannot pick up the wrong login.
NOCNF="$WORK/no-such-file.cnf"
script_env() {
  env MYSQL_PWD="$MYSQL_PWD" DB_USER="$USER_NAME" MYSQL_HOST="${MYSQL_HOST:-}" MYSQL_PORT="${MYSQL_PORT:-3306}" \
      LIBRARY_CNF="$NOCNF" LIBRARY_RESTORE_CNF="$NOCNF" LIBRARY_MONITOR_CNF="$NOCNF" "$@"
}
( cd "$WORK" && mkdir -p database/backup && cp "$DBDIR"/backup/*.sh database/backup/ \
  && script_env DB_NAME="$DB" bash database/backup/backup.sh >"$WORK/backup.log" 2>&1 )
BFILE="$(ls -1t "$WORK"/backups/"${DB}"_*.sql 2>/dev/null | head -1)"
if [ -n "$BFILE" ] && [ -s "$BFILE" ]; then ok "backup.sh made a backup ($(wc -c < "$BFILE") bytes)"; else bad "backup.sh did not make a backup: $(tail -3 "$WORK/backup.log" | tr '\n' ' ')"; fi
if [ -n "$BFILE" ]; then
  if script_env SOURCE_DB="$DB" bash "$DBDIR/backup/restore.sh" --verify "$BFILE" >"$WORK/verify.log" 2>&1; then ok "restore.sh --verify printed PASS"; else bad "restore.sh --verify failed: $(tail -3 "$WORK/verify.log" | tr '\n' ' ')"; fi
fi
: > "$WORK/empty.sql"
if script_env bash "$DBDIR/backup/restore.sh" "$WORK/empty.sql" "${DB}_VERIFY" >/dev/null 2>&1; then bad "restore.sh accepted an EMPTY backup file"; else ok "restore.sh refuses an empty backup file"; fi

echo "== 10. Health check script"
script_env DB_NAME="$DB" BACKUP_DIR="$WORK/backups" bash "$DBDIR/monitor/health_check.sh" >"$WORK/health.log" 2>&1
HC=$?
if [ "$HC" -le 1 ] && grep -q "Library database health" "$WORK/health.log"; then ok "health_check.sh ran (result code $HC: 0 = OK, 1 = warnings)"; else bad "health_check.sh gave code $HC: $(tail -2 "$WORK/health.log" | tr '\n' ' ')"; fi

echo
echo "Result: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "ALL CHECKS PASSED" || { echo "SOME CHECKS FAILED" >&2; exit 1; }
