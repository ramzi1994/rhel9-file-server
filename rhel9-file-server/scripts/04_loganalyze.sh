#!/usr/bin/env bash
# Experiment 4 - summarise SSH authentication activity using grep, sed, sort and uniq.
#
# Usage: ./04_loganalyze.sh [logfile] [report_file]
#   logfile      default: sample/auth_sample.log   (use /var/log/secure on a real server)
#   report_file  default: report.txt in the current directory
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="${1:-$HERE/../sample/auth_sample.log}"
OUT="${2:-report.txt}"
IPRE='([0-9]{1,3}\.){3}[0-9]{1,3}'

[[ -r "$LOG" ]] || { echo "Cannot read $LOG" >&2; exit 1; }

{
  echo "=========== SSH LOG REPORT ==========="
  echo "File      : $LOG"
  echo "Generated : $(date)"
  echo
  echo "Total failed logins     : $(grep -c 'Failed password' "$LOG")"
  echo "Total successful logins : $(grep -c 'Accepted password' "$LOG")"
  echo "Invalid user attempts   : $(grep -ci 'invalid user' "$LOG")"
  echo
  echo "--- Top offending IP addresses ---"
  grep 'Failed password' "$LOG" | grep -oE "$IPRE" | sort | uniq -c | sort -rn | head -5
  echo
  echo "--- Usernames targeted ---"
  grep 'Failed password' "$LOG" \
    | sed -E 's/.*for (invalid user )?([A-Za-z0-9_]+) from.*/\2/' \
    | sort | uniq -c | sort -rn
  echo
  echo "--- Users who logged in successfully ---"
  grep 'Accepted password' "$LOG" \
    | sed -E 's/.*for ([A-Za-z0-9_]+) from.*/\1/' | sort -u
  echo
  echo "--- Suspicious IPs (3 or more failures) ---"
  grep 'Failed password' "$LOG" | grep -oE "$IPRE" | sort | uniq -c \
    | awk '$1>=3 {print $2" ("$1" attempts)"}'
} > "$OUT"

cat "$OUT"
