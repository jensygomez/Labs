#!/bin/bash
# RHCSA EX200 – Storage Slot 05 – Variation 3
# Purpose: XFS LV expanded, no fstab entry (Advanced)

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
    lvcreate -L 1G -n "$LV" "$VG" >/dev/null
    mkfs.xfs -f "/dev/$VG/$LV" >/dev/null  # XFS!
else
    lvextend -L +1G "/dev/$VG/$LV" >/dev/null
fi

mkdir -p "$MNT"
mount "/dev/$VG/$LV" "$MNT"

# ¡SIN fstab! Debe agregarlo manualmente

sync
