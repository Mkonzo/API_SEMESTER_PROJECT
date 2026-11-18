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
#   MYSQL_HOST / MYSQL_PORT   connect over the network (default: this computer)
#   MYSQL_PWD    the password, if you do not want to be asked
#   LIBRARY_CNF  a file holding user/password so nothing is typed
#                (default ~/.library_backup.cnf, never put it in the repo).
#                If the password has # or \ or quote characters, see SECURITY.md.
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

# On Windows (Git Bash) a Windows program needs a Windows-style path to the option file
cnf_path() { if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s' "$1"; fi; }
if [ -f "$CNF" ]; then
  AUTH=(--defaults-extra-file="$(cnf_path "$CNF")")
else
  AUTH=(-u "$DB_USER")
  [ -n "${MYSQL_HOST:-}" ] && AUTH+=(-h "$MYSQL_HOST" -P "${MYSQL_PORT:-3306}" --protocol=TCP)
  # the password comes from MYSQL_PWD if it is already set, otherwise you are asked once
  if [ -z "${MYSQL_PWD+x}" ]; then
    read -r -s -p "Password for MySQL user $DB_USER: " MYSQL_PWD; echo
  fi
  export MYSQL_PWD
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
