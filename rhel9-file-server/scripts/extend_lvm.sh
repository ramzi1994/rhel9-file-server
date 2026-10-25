#!/usr/bin/env bash
# Grow the department share online.   Usage: sudo ./extend_lvm.sh +2G
source "$(dirname "$0")/00_common.sh"
require_root
SIZE="${1:-+1G}"
log "Extending /dev/$VG_NAME/$LV_NAME by $SIZE"
lvextend -L "$SIZE" "/dev/$VG_NAME/$LV_NAME"
xfs_growfs "$SHARE_DIR"        # XFS is grown via its mount point
df -h "$SHARE_DIR"
