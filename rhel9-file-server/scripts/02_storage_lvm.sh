#!/usr/bin/env bash
# Experiment 2 - partitions, file systems, swap and LVM.
#
# WARNING: DESTRUCTIVE. It wipes the partition tables of DISK_A and DISK_B.
# Use only on the spare virtual disks of your lab VM.
#
# Layout created
#   DISK_A (MBR via sfdisk): p1 2G ext4 -> /data     p2 rest -> LVM PV
#   DISK_B (GPT via sfdisk): p1 1G swap              p2 rest -> LVM PV
#   LVM: VG_NAME (p2 of both disks) -> LV_NAME (LV_SIZE, xfs) -> SHARE_DIR
#   Swap file: /swapfile (512 MiB)
#
# Usage: sudo DISK_A=/dev/sdb DISK_B=/dev/sdd ./02_storage_lvm.sh
source "$(dirname "$0")/00_common.sh"
require_root

DISK_A="${DISK_A:-/dev/sdb}"
DISK_B="${DISK_B:-/dev/sdd}"
[[ -b $DISK_A && -b $DISK_B ]] || die "Disk not found: $DISK_A / $DISK_B (check with lsblk)"
[[ $DISK_A != "$DISK_B" ]] || die "DISK_A and DISK_B must differ"

ROOT_SRC="$(findmnt -n -o SOURCE / || true)"
for d in "$DISK_A" "$DISK_B"; do
  [[ "$ROOT_SRC" == "$d"* ]] && die "$d holds the root file system - refusing to continue"
  if lsblk -nr -o MOUNTPOINT "$d" | grep -q .; then
    die "$d has mounted partitions - unmount first"
  fi
done

lsblk "$DISK_A" "$DISK_B"
confirm "ALL DATA on $DISK_A and $DISK_B will be destroyed." || die "Aborted by user"

part() { # part /dev/sdb 1 -> /dev/sdb1 (nvme/loop style names get a 'p')
  if [[ $1 =~ [0-9]$ ]]; then echo "${1}p${2}"; else echo "${1}${2}"; fi
}

# ---- Partitioning (non-interactive equivalent of fdisk / gdisk) ----
log "Partitioning $DISK_A with an MBR table"
wipefs -a "$DISK_A" >/dev/null
sfdisk "$DISK_A" <<'SFD'
label: dos
,2G,L
,,8e
SFD

log "Partitioning $DISK_B with a GPT table"
wipefs -a "$DISK_B" >/dev/null
sfdisk "$DISK_B" <<'SFD'
label: gpt
,1G,S
,,V
SFD
partprobe "$DISK_A" "$DISK_B"; udevadm settle

A1=$(part "$DISK_A" 1); A2=$(part "$DISK_A" 2)
B1=$(part "$DISK_B" 1); B2=$(part "$DISK_B" 2)

# ---- ext4 file system mounted at /data ----
log "Creating ext4 on $A1 for /data"
mkfs.ext4 -F -q "$A1"
mkdir -p /data
UUID_A1=$(blkid -s UUID -o value "$A1")
grep -q "$UUID_A1" /etc/fstab || echo "UUID=$UUID_A1  /data  ext4  defaults  0 0" >> /etc/fstab

# ---- swap partition ----
log "Creating swap partition on $B1"
mkswap -f "$B1" >/dev/null
UUID_B1=$(blkid -s UUID -o value "$B1")
grep -q "$UUID_B1" /etc/fstab || echo "UUID=$UUID_B1  none  swap  defaults  0 0" >> /etc/fstab

# ---- swap file ----
if [[ ! -f /swapfile ]]; then
  log "Creating 512 MiB swap file"
  dd if=/dev/zero of=/swapfile bs=1M count=512 status=none
  chmod 600 /swapfile
  mkswap /swapfile >/dev/null
  echo '/swapfile  none  swap  defaults  0 0' >> /etc/fstab
fi

# ---- LVM ----
log "Creating LVM: $VG_NAME / $LV_NAME ($LV_SIZE)"
pvcreate -ff -y "$A2" "$B2"
vgcreate "$VG_NAME" "$A2" "$B2"
lvcreate -y -L "$LV_SIZE" -n "$LV_NAME" "$VG_NAME"
mkfs.xfs -f "/dev/$VG_NAME/$LV_NAME"
mkdir -p "$SHARE_DIR"
grep -q "/dev/$VG_NAME/$LV_NAME" /etc/fstab || \
  echo "/dev/$VG_NAME/$LV_NAME  $SHARE_DIR  xfs  defaults  0 0" >> /etc/fstab

systemctl daemon-reload
mount -a
swapon -a

log "Result"
lsblk "$DISK_A" "$DISK_B"
swapon --show
pvs; vgs; lvs
df -hT /data "$SHARE_DIR"
log "Done. Grow the share later with: scripts/extend_lvm.sh +2G"
