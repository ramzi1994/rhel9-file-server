#!/usr/bin/env bash
# Runs anywhere (no root needed): checks the log-analysis script against the sample log.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$(mktemp)"; trap 'rm -f "$OUT"' EXIT
"$HERE/../scripts/04_loganalyze.sh" "$HERE/../sample/auth_sample.log" "$OUT" >/dev/null
pass=0; fail=0
check() { if grep -qE "$2" "$OUT"; then echo "PASS  $1"; pass=$((pass+1)); else echo "FAIL  $1"; fail=$((fail+1)); fi; }
check "failed logins = 6"        'Total failed logins +: 6'
check "successful logins = 2"    'Total successful logins +: 2'
check "invalid user lines = 3"   'Invalid user attempts +: 3'
check "top IP is 10.0.0.77 (3)"  '3 10\.0\.0\.77'
check "root targeted 3 times"    '3 root'
check "suspicious IP flagged"    '10\.0\.0\.77 \(3 attempts\)'
check "drsharma logged in"       '^drsharma$'
echo "Passed: $pass  Failed: $fail"; [[ $fail -eq 0 ]]
