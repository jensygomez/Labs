#!/bin/bash
# RHCSA EX200 – Storage Slot 05 – Variation 2
# Purpose: LV shrunk but filesystem oversized (Troubleshooting)

set -e

DISK=$(lsblk -dn -o NAME,TYPE | awk '$2=="disk"{print $1}' | grep -E '^sd[b-f]$' | shuf -n1)
DEVICE="/dev/${DISK}"
VG="vg_exam"
LV="lv_data"
MNT="/data"

wipefs -a "$DEVICE"
pvcreate -ff -y "$DEVICE" >/dev/null

if ! vgdisplay "$VG" >/dev/null 2>&1; then
    vgcreate "$VG" "$DEVICE" >/dev/null
    lvcreate -L 2G -n "$LV" "$VG" >/dev/null
    mkfs.ext4 -F "/dev/$VG/$LV" >/dev/null
else
    lvresize -L 1G -f "/dev/$VG/$LV" >/dev/null  # Shrink LV
fi

mkdir -p "$MNT"
mount "/dev/$VG/$LV" "$MNT"

UUID=$(blkid -s UUID -o value "/dev/$VG/$LV")
grep -q "$MNT" /etc/fstab || echo "UUID=$UUID $MNT ext4 defaults 0 0" >> /etc/fstab

sync
