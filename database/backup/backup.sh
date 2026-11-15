#!/usr/bin/env bash
# ============================================================
# Backs up the KISII_LIBRARY database to backups/ with a date in the name.
#
# Run from the project folder:   bash database/backup/backup.sh
#   (you are asked for the password once, and your typing is hidden)
#
# Safety: the dump is written to a temporary file and only kept if it is
# complete. A failed dump can never leave an empty backup behind.
#
# Settings (all optional):
#   DB_NAME   database to back up        default KISII_LIBRARY
#   DB_USER   user to connect as         default library_backup
#   KEEP      how many backups to keep   default 7
#   LIBRARY_CNF  a file holding user/password so nothing is typed
#                (default ~/.library_backup.cnf, never put it in the repo)
# ============================================================
set -u

DB_NAME="${DB_NAME:-KISII_LIBRARY}"
DB_USER="${DB_USER:-library_backup}"
KEEP="${KEEP:-7}"
CNF="${LIBRARY_CNF:-$HOME/.library_backup.cnf}"
OUT_DIR="backups"
MIN_BYTES=2000

mkdir -p "$OUT_DIR"
STAMP="$(date +%Y-%m-%d_%H%M%S)"
FINAL="$OUT_DIR/${DB_NAME}_${STAMP}.sql"
TMP="$(mktemp "$OUT_DIR/.tmp_backup.XXXXXX")"

if [ -f "$CNF" ]; then
  AUTH=(--defaults-extra-file="$CNF")
else
  read -r -s -p "Password for MySQL user $DB_USER: " MYSQL_PWD; echo
  export MYSQL_PWD
  AUTH=(-u "$DB_USER")
fi

echo "Backing up $DB_NAME ..."
if ! mysqldump "${AUTH[@]}" --single-transaction --no-tablespaces --result-file="$TMP" "$DB_NAME"; then
  rm -f "$TMP"
  echo "BACKUP FAILED: mysqldump returned an error. Nothing was saved." >&2
  exit 1
fi

SIZE="$(wc -c < "$TMP")"
if [ "$SIZE" -lt "$MIN_BYTES" ] || ! grep -q "Dump completed" "$TMP"; then
  rm -f "$TMP"
  echo "BACKUP FAILED: the file was empty or incomplete ($SIZE bytes). Nothing was saved." >&2
  exit 1
fi

mv "$TMP" "$FINAL"
TABLES="$(grep -c '^CREATE TABLE' "$FINAL")"
echo "OK: $FINAL ($SIZE bytes, $TABLES tables)"

# keep only the newest $KEEP backups
ls -1t "$OUT_DIR"/${DB_NAME}_*.sql 2>/dev/null | tail -n +"$((KEEP + 1))" | while read -r old; do
  rm -f "$old" && echo "Removed old backup: $old"
done
