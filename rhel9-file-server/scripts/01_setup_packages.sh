#!/usr/bin/env bash
# Experiment 1 - update RHEL 9 and install the packages used by the project.
# Optional: LOCAL_REPO=1 builds a local yum repo from the installation ISO (/dev/sr0).
source "$(dirname "$0")/00_common.sh"
require_root

if [[ "${LOCAL_REPO:-0}" == "1" ]]; then
  log "Creating local repository from the installation ISO"
  mkdir -p /mnt/iso
  mountpoint -q /mnt/iso || mount /dev/sr0 /mnt/iso
  cat > /etc/yum.repos.d/local.repo <<'REPO'
[local-baseos]
name=Local BaseOS
baseurl=file:///mnt/iso/BaseOS
enabled=1
gpgcheck=0

[local-appstream]
name=Local AppStream
baseurl=file:///mnt/iso/AppStream
enabled=1
gpgcheck=0
REPO
  yum clean all
fi

log "Enabled repositories"
yum repolist

log "Updating all packages"
yum -y update

log "Installing project packages"
yum -y install acl lvm2 gdisk parted xfsprogs e2fsprogs vim tree rsync

log "Boot target: $(systemctl get-default)"
log "Kernel: $(uname -r)"
log "Done. Next: scripts/02_storage_lvm.sh"
