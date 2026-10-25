#!/usr/bin/env bash
# Shared helpers sourced by the other scripts.
set -euo pipefail

log()  { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[FAIL]\033[0m %s\n' "$*" >&2; exit 1; }

require_root() {
  [[ $EUID -eq 0 ]] || die "Run this script as root (use sudo)."
}

confirm() {
  # confirm "message"  -> returns 0 only if the user types 'yes'
  local ans
  read -r -p "$1 Type 'yes' to continue: " ans
  [[ "$ans" == "yes" ]]
}

# Shared configuration (override by exporting before running)
: "${SHARE_DIR:=/srv/dept}"
: "${VG_NAME:=vg_dept}"
: "${LV_NAME:=lv_share}"
: "${LV_SIZE:=4G}"
: "${ACCOUNT_EXPIRY:=2027-05-31}"
