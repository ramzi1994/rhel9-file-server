#!/usr/bin/env bash
# Experiment 3 - groups, users, directory permissions and ACLs.
# Safe to re-run: existing groups/users are left untouched.
source "$(dirname "$0")/00_common.sh"
require_root
command -v setfacl >/dev/null || die "Install the 'acl' package first (scripts/01_setup_packages.sh)"
mountpoint -q "$SHARE_DIR" || warn "$SHARE_DIR is not a mount point - continuing on the root file system"

CRED_FILE=/root/dept_initial_passwords.txt
: > "$CRED_FILE"; chmod 600 "$CRED_FILE"

# ---- groups ----
for g in faculty students admins; do
  getent group "$g" >/dev/null || { groupadd "$g"; log "Created group $g"; }
done

# ---- directory skeleton (created first so custom home dirs have a parent) ----
mkdir -p "$SHARE_DIR/course" "$SHARE_DIR/submissions" "$SHARE_DIR/faculty" \
         "$SHARE_DIR/students" "$SHARE_DIR/admins"

new_pass() { tr -dc 'A-Za-z0-9' </dev/urandom | head -c 12 || true; }

mkuser() { # mkuser <name> <useradd options...>
  local name=$1; shift
  if id "$name" >/dev/null 2>&1; then
    warn "User $name already exists - skipping"
    return 0
  fi
  useradd "$@" "$name"
  local pw; pw=$(new_pass)
  echo "$name:$pw" | chpasswd
  chage -d 0 "$name"                      # force password change at first login
  echo "$name  $pw" >> "$CRED_FILE"
  log "Created user $name"
}

# Custom home directory + shell
mkuser drsharma -m -d "$SHARE_DIR/faculty/drsharma" -s /bin/bash -g faculty -c "Dr. Sharma"
mkuser admin1   -m -s /bin/bash -g admins -G wheel
# Students: expiry date
mkuser stud1    -m -s /bin/bash -g students -e "$ACCOUNT_EXPIRY"
mkuser stud2    -m -s /bin/bash -g students -e "$ACCOUNT_EXPIRY"
# Service account: no interactive login
mkuser svc_backup -m -s /sbin/nologin -g students

# ---- ownership and permissions ----
chown root:faculty   "$SHARE_DIR/course";      chmod 2775 "$SHARE_DIR/course"      # setgid
chown root:students  "$SHARE_DIR/submissions"; chmod 3770 "$SHARE_DIR/submissions" # setgid+sticky
chown root:students  "$SHARE_DIR/students";    chmod 770  "$SHARE_DIR/students"
chown root:faculty   "$SHARE_DIR/faculty";     chmod 770  "$SHARE_DIR/faculty"
chown admin1:admins  "$SHARE_DIR/admins";      chmod 700  "$SHARE_DIR/admins"

# ---- ACLs ----
setfacl -m  g:students:rX "$SHARE_DIR/course"      # students may read course material
setfacl -d -m g:students:rX "$SHARE_DIR/course"    # inherited by new files
setfacl -m  u:stud1:rwx   "$SHARE_DIR/course"      # stud1 acts as teaching assistant
setfacl -R -m u:admin1:rwx "$SHARE_DIR"            # admin has full access everywhere

log "Directory permissions"
ls -ld "$SHARE_DIR"/*
log "ACL on course/"
getfacl -p "$SHARE_DIR/course"
log "Account expiry (stud1)"
chage -l stud1 | sed -n '1,5p'
log "Initial passwords saved in $CRED_FILE (root only). Users must change them at first login."
log "Done. Next: tests/run_tests.sh and scripts/04_loganalyze.sh"
