#!/usr/bin/env bash
# ============================================================
# Restores a backup file into a database.
#
#   bash database/backup/restore.sh backups/KISII_LIBRARY_2026-11-14_120000.sql
#       restores into KISII_LIBRARY (asks you to type YES first, because it
#       REPLACES the tables that are there now)
#
#   bash database/backup/restore.sh backups/FILE.sql SOME_OTHER_DB
#       restores into a different database. Safe for practice.
#
#   bash database/backup/restore.sh --verify backups/FILE.sql
#       restores into a temporary database, compares it with KISII_LIBRARY,
#       prints PASS or FAIL, then deletes the temporary database.
#       Nothing in KISII_LIBRARY changes.
#
# DB_USER defaults to root, because restoring needs the right to create tables.
# (You are asked for the password once, and your typing is hidden.)
# ============================================================
set -u
set -o pipefail

DB_USER="${DB_USER:-root}"
SOURCE_DB="${SOURCE_DB:-KISII_LIBRARY}"
CNF="${LIBRARY_RESTORE_CNF:-$HOME/.library_restore.cnf}"

if [ -f "$CNF" ]; then AUTH=(--defaults-extra-file="$CNF"); else
  read -r -s -p "Password for MySQL user $DB_USER: " MYSQL_PWD; echo
  export MYSQL_PWD
  AUTH=(-u "$DB_USER")
fi

# tr removes the hidden carriage returns that mysql.exe adds on Windows
q() { mysql "${AUTH[@]}" -N -B -e "$1" | tr -d '\r'; }

count_tables() { q "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='$1' AND TABLE_TYPE='BASE TABLE'"; }
count_rows() {  # total rows across all base tables
  local total=0 t n
  for t in $(q "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='$1' AND TABLE_TYPE='BASE TABLE' ORDER BY 1"); do
    n="$(q "SELECT COUNT(*) FROM \`$1\`.\`$t\`")"
    total=$((total + n))
  done
  echo "$total"
}

check_file() {
  if [ ! -f "$1" ]; then echo "File not found: $1" >&2; exit 1; fi
  if [ "$(wc -c < "$1")" -lt 2000 ] || ! grep -q "Dump completed" "$1"; then
    echo "This backup file looks empty or incomplete. Not restoring." >&2; exit 1
  fi
}

if [ "${1:-}" = "--verify" ]; then
  FILE="${2:-}"; [ -z "$FILE" ] && { echo "Usage: $0 --verify backups/FILE.sql" >&2; exit 1; }
  check_file "$FILE"
  TEST_DB="${SOURCE_DB}_VERIFY"
  q "DROP DATABASE IF EXISTS \`$TEST_DB\`; CREATE DATABASE \`$TEST_DB\` CHARACTER SET utf8mb4;" || exit 1
  if ! mysql "${AUTH[@]}" "$TEST_DB" < "$FILE"; then
    q "DROP DATABASE IF EXISTS \`$TEST_DB\`"; echo "FAIL: the backup could not be loaded." >&2; exit 1
  fi
  T1="$(count_tables "$SOURCE_DB")"; T2="$(count_tables "$TEST_DB")"
  R1="$(count_rows "$SOURCE_DB")";   R2="$(count_rows "$TEST_DB")"
  q "DROP DATABASE \`$TEST_DB\`"
  echo "Live database: $T1 tables, $R1 rows"
  echo "Restored copy: $T2 tables, $R2 rows"
  if [ "$T1" = "$T2" ] && [ "$R1" = "$R2" ]; then echo "PASS: the backup restores to an identical copy."; exit 0
  else echo "FAIL: the restored copy differs from the live database (changes made after the backup would also cause this)." >&2; exit 1; fi
fi

FILE="${1:-}"; TARGET="${2:-KISII_LIBRARY}"
[ -z "$FILE" ] && { echo "Usage: bash $0 backups/FILE.sql [TARGET_DB]   or   bash $0 --verify backups/FILE.sql" >&2; exit 1; }
check_file "$FILE"

if [ "$TARGET" = "KISII_LIBRARY" ]; then
  echo "This REPLACES the tables in KISII_LIBRARY with the backup. Anything added since is lost."
  read -r -p "Type YES to continue: " ANSWER
  [ "$ANSWER" = "YES" ] || { echo "Cancelled."; exit 1; }
fi

q "CREATE DATABASE IF NOT EXISTS \`$TARGET\` CHARACTER SET utf8mb4;" || exit 1
mysql "${AUTH[@]}" "$TARGET" < "$FILE" || { echo "RESTORE FAILED." >&2; exit 1; }
echo "Restored $FILE into $TARGET: $(count_tables "$TARGET") tables, $(count_rows "$TARGET") rows."
