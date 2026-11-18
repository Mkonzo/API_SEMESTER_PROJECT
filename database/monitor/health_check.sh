#!/usr/bin/env bash
# ============================================================
# Health check for the KISII_LIBRARY database.
#
#   bash database/monitor/health_check.sh             short report
#   bash database/monitor/health_check.sh --metrics   short report plus numbers
#
# Result and exit code:  OK = 0   WARN = 1   CRIT = 2
# (so a scheduler or another script can react to the exit code)
#
# Settings (all optional):
#   DB_NAME              default KISII_LIBRARY
#   MYSQL_HOST/MYSQL_PORT  connect over the network (default: this computer)
#   DB_USER              default library_readonly (it only needs to read)
#   LIBRARY_MONITOR_CNF  a file holding user/password so nothing is typed
#                        (default ~/.library_monitor.cnf, never inside the repo)
#   BACKUP_DIR           where backups are kept            default backups
#   MAX_BACKUP_AGE_DAYS  warn if the newest backup is older   default 7
#   MAX_CONN_PCT         warn above this % of connections    default 80
#   ALERT_WEBHOOK_URL    if set, WARN and CRIT results are posted there
# ============================================================
set -u
set -o pipefail

DB="${DB_NAME:-KISII_LIBRARY}"
DB_USER="${DB_USER:-library_readonly}"
CNF="${LIBRARY_MONITOR_CNF:-$HOME/.library_monitor.cnf}"
BACKUP_DIR="${BACKUP_DIR:-backups}"
MAX_BACKUP_AGE_DAYS="${MAX_BACKUP_AGE_DAYS:-7}"
MAX_CONN_PCT="${MAX_CONN_PCT:-80}"
WEBHOOK="${ALERT_WEBHOOK_URL:-}"
SHOW_METRICS=0
[ "${1:-}" = "--metrics" ] && SHOW_METRICS=1

# On Windows (Git Bash) a Windows program needs a Windows-style path to the option file
cnf_path() { if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s' "$1"; fi; }
if [ -f "$CNF" ]; then
  AUTH=(--defaults-extra-file="$(cnf_path "$CNF")")
else
  AUTH=(-u "$DB_USER")
  [ -n "${MYSQL_HOST:-}" ] && AUTH+=(-h "$MYSQL_HOST" -P "${MYSQL_PORT:-3306}" --protocol=TCP)
  if [ -z "${MYSQL_PWD+x}" ]; then
    read -r -s -p "Password for MySQL user $DB_USER: " MYSQL_PWD; echo
  fi
  export MYSQL_PWD
fi

q() { mysql "${AUTH[@]}" "$DB" -N -B -e "$1" </dev/null | tr -d '\r'; }

LEVEL=0
PROBLEMS=""
say() {  # say <0|1|2> <text>
  local label="OK  "
  case "$1" in 1) label="WARN";; 2) label="CRIT";; 3) label="INFO";; esac
  echo "  $label  $2"
  if [ "$1" = 1 ] || [ "$1" = 2 ]; then
    [ "$1" -gt "$LEVEL" ] && LEVEL="$1"
    PROBLEMS="$PROBLEMS$label: $2; "
  fi
}

send_alert() {
  [ "$LEVEL" -eq 0 ] && return 0
  [ -z "$WEBHOOK" ] && return 0
  local name="OK"; [ "$LEVEL" -eq 1 ] && name="WARN"; [ "$LEVEL" -eq 2 ] && name="CRIT"
  local msg
  msg="Library database $DB is $name. $PROBLEMS"
  msg="$(printf '%s' "$msg" | tr -d '"\\\r' | tr '\n' ' ')"
  if curl -s -m 10 -X POST -H "Content-Type: application/json" \
       -d "{\"text\":\"$msg\",\"content\":\"$msg\"}" "$WEBHOOK" >/dev/null 2>&1; then
    echo "  (alert sent)"
  else
    echo "  (could not send the alert)"
  fi
}

echo "Library database health: $DB   $(date '+%Y-%m-%d %H:%M')"

# 1. Can we connect?
VERSION="$(q "SELECT VERSION()" 2>/dev/null)"
if [ -z "$VERSION" ]; then
  say 2 "Cannot connect to the database (is MySQL running, and is the password right?)"
  echo "RESULT: CRIT"
  send_alert
  exit 2
fi
UPTIME="$(q "SHOW GLOBAL STATUS LIKE 'Uptime'" | cut -f2)"
say 0 "Connected (MySQL $VERSION, running for $((UPTIME / 86400)) days $(((UPTIME % 86400) / 3600)) hours)"

# 2. Connections
CONN="$(q "SHOW GLOBAL STATUS LIKE 'Threads_connected'" | cut -f2)"
MAXC="$(q "SELECT @@max_connections")"
PCT=$((CONN * 100 / MAXC))
if [ "$PCT" -ge "$MAX_CONN_PCT" ]; then say 1 "Connections: $CONN of $MAXC ($PCT%), close to the limit"; else say 0 "Connections: $CONN of $MAXC ($PCT%)"; fi

# 3. Problems found in the data
ALERTS="$(q "SELECT Severity, Alert, Count_or_value, Detail FROM v_monitor_alerts ORDER BY FIELD(Severity,'CRIT','WARN','INFO'), Alert" 2>&1)"
if echo "$ALERTS" | grep -q "^ERROR"; then
  say 2 "Could not read v_monitor_alerts. Has migration 009 been run? ($(echo "$ALERTS" | head -1))"
elif [ -z "$ALERTS" ]; then
  say 0 "No problems found in the data"
else
  while IFS=$'\t' read -r sev name count detail; do
    case "$sev" in
      CRIT) say 2 "$name: $count. $detail";;
      WARN) say 1 "$name: $count. $detail";;
      *)    say 3 "$name: $count. $detail";;
    esac
  done <<< "$ALERTS"
fi

# 4. Newest backup
NEWEST="$(ls -1t "$BACKUP_DIR"/*.sql 2>/dev/null | head -1)"
if [ -z "$NEWEST" ]; then
  say 1 "No backup found in $BACKUP_DIR/ (run: bash database/backup/backup.sh)"
else
  AGE=$(( ( $(date +%s) - $(stat -c %Y "$NEWEST") ) / 86400 ))
  if [ "$AGE" -gt "$MAX_BACKUP_AGE_DAYS" ]; then say 1 "Newest backup is $AGE days old (limit $MAX_BACKUP_AGE_DAYS): $NEWEST"; else say 0 "Newest backup is $AGE days old: $NEWEST"; fi
fi

# 5. Optional numbers
if [ "$SHOW_METRICS" -eq 1 ]; then
  echo
  echo "Key numbers"
  q "SELECT * FROM v_monitor_health" | tr '\t' '|' | awk -F'|' '{printf "  Active members %s | Books %s | Open loans %s | Overdue loans %s | Unpaid fines %s | Pending M-Pesa %s | Failed notifications %s | Last sync %s (%s) | Changes in last 24h %s\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10}'
  for v in Questions Slow_queries Threads_running Aborted_connects; do
    printf "  %-18s %s\n" "$v" "$(q "SHOW GLOBAL STATUS LIKE '$v'" | cut -f2)"
  done
  echo "  Slow query log is $(q "SELECT IF(@@global.slow_query_log=1,'ON','OFF')") (queries over $(q "SELECT @@global.long_query_time") seconds)"
  echo "  Database size: $(q "SET SESSION information_schema_stats_expiry=0; SELECT ROUND(SUM(DATA_LENGTH+INDEX_LENGTH)/1024/1024,2) FROM information_schema.TABLES WHERE TABLE_SCHEMA='$DB'") MB"
  echo
  echo "Tables (exact row counts, size on disk)"
  q "SET SESSION information_schema_stats_expiry=0; SELECT Table_name, Size_mb FROM v_monitor_table_sizes ORDER BY Size_mb DESC, Table_name" | while IFS=$'\t' read -r t mb; do
    n="$(q "SELECT COUNT(*) FROM \`$t\`")"
    printf "  %-22s %8s rows  %8s MB\n" "$t" "$n" "$mb"
  done
fi

echo
case "$LEVEL" in 0) echo "RESULT: OK";; 1) echo "RESULT: WARN";; 2) echo "RESULT: CRIT";; esac
send_alert
exit "$LEVEL"
