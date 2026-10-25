# Secure Departmental File Server on RHEL 9

LVM storage, ACL-based access control and automated log analysis on Red Hat Enterprise Linux 9.
A Linux Administration lab mini project (Chandigarh University, University Institute of Computing)
that combines four lab experiments in one realistic scenario.

| Experiment | Topic | Script |
|---|---|---|
| 1 | RHEL 9 installation, yum repositories, updates | `scripts/01_setup_packages.sh` |
| 2 | Partitions (fdisk/gdisk style), mkfs, mount, swap partition + swap file, LVM | `scripts/02_storage_lvm.sh`, `scripts/extend_lvm.sh` |
| 3 | Users, groups, expiry dates, chmod/chown/chgrp, ACLs | `scripts/03_users_acl.sh` |
| 4 | grep / egrep / fgrep / sed, sort + uniq pipelines, report script | `scripts/04_loganalyze.sh`, `scripts/demo_filters.sh` |

The full written report is in [`docs/`](docs/).

## Scenario

A computer-science department needs one server for three teams: **faculty**, **students**, **admins**.

```
/dev/sda  -> /boot, /, swap              (system disk)
/dev/sdb1 -> ext4 -> /data
/dev/sdd1 -> swap partition
LVM: sdb2 + sdd2 -> vg_dept -> lv_share (xfs) -> /srv/dept

/srv/dept/
  course/       faculty read/write, students read-only (ACL), setgid 2775
  submissions/  students upload, cannot delete each other's files (setgid + sticky 3770)
  faculty/      faculty only (770)       students/  students only (770)
  admins/       admin1 only (700)
```

## Requirements

- RHEL 9 VM (VMware Workstation or VirtualBox), 2 vCPU, 2 GB RAM, 20 GB system disk
- Extra virtual disks: one 5 GB (`/dev/sdb`) and one 2 GB or larger (`/dev/sdd`). Check names with `lsblk`.
- Root access (`sudo`). Internet or a RHEL subscription, or use the local-ISO repo option.

## Quick start

```bash
git clone https://github.com/<your-username>/rhel9-file-server.git
cd rhel9-file-server

sudo ./scripts/01_setup_packages.sh              # LOCAL_REPO=1 to use the install ISO as repo
sudo DISK_A=/dev/sdb DISK_B=/dev/sdd ./scripts/02_storage_lvm.sh   # DESTRUCTIVE - lab disks only
sudo ./scripts/03_users_acl.sh
sudo ./tests/run_tests.sh                        # system tests (13 checks)
./scripts/04_loganalyze.sh                       # works without root on the sample log
```

Run the log analysis on a real server log: `sudo ./scripts/04_loganalyze.sh /var/log/secure report.txt`

Extend the share online: `sudo ./scripts/extend_lvm.sh +2G`

### Configuration (environment variables)

| Variable | Default | Meaning |
|---|---|---|
| `DISK_A`, `DISK_B` | `/dev/sdb`, `/dev/sdd` | Spare disks used by step 2 |
| `SHARE_DIR` | `/srv/dept` | Mount point of the shared LV |
| `VG_NAME`, `LV_NAME`, `LV_SIZE` | `vg_dept`, `lv_share`, `4G` | LVM names and size |
| `ACCOUNT_EXPIRY` | `2027-05-31` | Expiry date for student accounts |

## Safety notes

- **Step 2 wipes DISK_A and DISK_B.** It refuses to touch the root disk or mounted disks and asks you to type `yes`.
- Use a **virtual machine**, never your host PC.
- Step 3 generates random initial passwords, saves them in `/root/dept_initial_passwords.txt` (mode 600) and forces a
  change at first login. Delete that file after distributing the passwords.
- `fstab` entries are appended once (re-running does not duplicate them). Test with `mount -a` before rebooting.

## Tests

| Test | Needs root/VM | Command |
|---|---|---|
| Log-analysis output vs sample log (7 checks) | No | `bash tests/test_loganalyze.sh` |
| Swap, LVM, mounts, expiry, permissions, ACL, sticky bit (13 checks) | Yes | `sudo bash tests/run_tests.sh` |

Expected report for `sample/auth_sample.log`: 6 failed logins, 2 successful, 3 invalid-user lines;
`10.0.0.77` is flagged with 3 failed root logins.

## Manual command reference

The scripts automate these standard commands, which are explained in the report:
`fdisk`, `gdisk`, `mkfs.ext4`, `mkfs.xfs`, `mount`, `mkswap`, `swapon`, `pvcreate`, `vgcreate`, `lvcreate`,
`lvextend`, `xfs_growfs`, `groupadd`, `useradd`, `passwd`, `chage`, `chmod`, `chown`, `chgrp`, `setfacl`, `getfacl`,
`grep`, `egrep`, `fgrep`, `sed`, `sort`, `uniq`.

## Repository layout

```
rhel9-file-server/
├── README.md
├── LICENSE
├── .gitignore
├── docs/        project report (.docx)
├── sample/      auth_sample.log
├── scripts/     00_common.sh  01_setup_packages.sh  02_storage_lvm.sh  03_users_acl.sh
│                04_loganalyze.sh  extend_lvm.sh  demo_filters.sh
└── tests/       test_loganalyze.sh  run_tests.sh
```

## Author

[Your Name] - UID [Your UID] - Section [Your Section]

## License

MIT - see [LICENSE](LICENSE).
