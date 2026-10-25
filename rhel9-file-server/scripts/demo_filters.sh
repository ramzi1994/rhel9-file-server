#!/usr/bin/env bash
# Prints every grep / egrep / fgrep / sed / sort|uniq example from the report, with headings.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
L="${1:-$HERE/../sample/auth_sample.log}"
run() { printf '\n\033[1m$ %s\033[0m\n' "$*"; eval "$*"; }

run "grep 'Failed' $L"
run "grep -i 'accepted' $L"
run "grep -c 'Failed password' $L"
run "grep -n 'root' $L"
run "grep -v 'Failed' $L"
run "grep -E 'Failed|Invalid' $L"
run "grep -E 'from 10\\.0\\.0\\.[0-9]+' $L"
run "grep -oE '([0-9]{1,3}\\.){3}[0-9]{1,3}' $L"
run "grep -F '192.168.1.50' $L"
run "sed 's/Failed/FAILED/' $L"
run "sed 's/sshd\\[[0-9]*\\]/sshd/g' $L"
run "sed -n '/Accepted/p' $L"
run "sed '/Accepted/d' $L"
run "sed -E 's/([0-9]+\\.){3}[0-9]+/x.x.x.x/g' $L"
run "grep 'Failed password' $L | grep -oE '([0-9]{1,3}\\.){3}[0-9]{1,3}' | sort | uniq -c | sort -rn"
run "grep 'Failed password' $L | sed -E 's/.*for (invalid user )?([A-Za-z0-9_]+) from.*/\\2/' | sort | uniq -c | sort -rn"
