#!/usr/bin/env bash
# System tests for the configured server (run as root on the RHEL 9 VM after steps 01-03).
source "$(dirname "$0")/../scripts/00_common.sh"
set +e
require_root
pass=0; fail=0
t() { # t "description" ok|deny command...
  local d=$1 want=$2; shift 2
  "$@" >/dev/null 2>&1; local rc=$?
  if { [[ $want == ok ]] && [[ $rc -eq 0 ]]; } || { [[ $want == deny ]] && [[ $rc -ne 0 ]]; }; then
    echo "PASS  $d"; pass=$((pass+1))
  else echo "FAIL  $d"; fail=$((fail+1)); fi
}
C="$SHARE_DIR/course"; S="$SHARE_DIR/submissions"
EXP="$(date -d "$ACCOUNT_EXPIRY" '+%b %d, %Y')"

t "swap is active"                      ok   bash -c 'swapon --show | grep -q .'
t "LV $LV_NAME exists"                  ok   lvs "$VG_NAME/$LV_NAME"
t "share is mounted"                    ok   mountpoint -q "$SHARE_DIR"
t "stud1 expiry date is set"            ok   bash -c "chage -l stud1 | grep -q '$EXP'"
t "faculty can write course/"           ok   sudo -u drsharma touch "$C/notes.txt"
t "student can read course/"            ok   sudo -u stud2 cat "$C/notes.txt"
t "student cannot write course/"        deny sudo -u stud2 touch "$C/hack.txt"
t "stud1 (ACL TA) can write course/"    ok   sudo -u stud1 touch "$C/ta_file.txt"
t "student can upload to submissions/"  ok   sudo -u stud1 touch "$S/a1_stud1.txt"
t "sticky bit blocks deleting others"   deny sudo -u stud2 rm "$S/a1_stud1.txt"
t "student cannot enter admins/"        deny sudo -u stud2 ls "$SHARE_DIR/admins"
t "admin can list admins/"              ok   sudo -u admin1 ls "$SHARE_DIR/admins"
t "ACL entry for students on course/"   ok   bash -c "getfacl -p '$C' | grep -q 'group:students:r-x'"

rm -f "$C/notes.txt" "$C/ta_file.txt" "$S/a1_stud1.txt"
echo "Passed: $pass  Failed: $fail"; [[ $fail -eq 0 ]]
