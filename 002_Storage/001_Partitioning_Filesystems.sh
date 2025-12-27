# /home/jensy/GitHub/Labs/002_Storage/001_Partitioning_Filesystems.sh
#!/bin/bash
# RHCSA EX200 - Storage Troubleshooting Injection

set -e

CHECK_SCRIPT="/home/jensy/GitHub/Labs/config/check_lab.sh"
CONF_FILE="/home/jensy/GitHub/Labs/config/lab.conf"

# Validación previa
bash "$CHECK_SCRIPT"

source "$CONF_FILE"

sshpass -p "$LAB_PASS" ssh -o StrictHostKeyChecking=no ${LAB_USER}@${LAB_IP} << 'EOF'
set -e

DISK1=/dev/sdc
DISK2=/dev/sde

wipefs -a $DISK1 >/dev/null 2>&1 || true
wipefs -a $DISK2 >/dev/null 2>&1 || true

parted -s $DISK1 mklabel gpt
parted -s $DISK1 mkpart primary 1MiB 100%

parted -s $DISK2 mklabel gpt
parted -s $DISK2 mkpart primary 1MiB 100%

mkfs.ext4 -F ${DISK1}1 >/dev/null
mkfs.xfs -f ${DISK2}1 >/dev/null

mkdir -p /data_ext4 /data_xfs

echo "${DISK1}1  /data_ext4  ext4  defaults  0 0" >> /etc/fstab
echo "${DISK2}1  /data_xfs   xfs   defaults  0 0" >> /etc/fstab

mount -a || true
EOF

echo "[DONE] Laboratorio inyectado"

