#!/bin/bash
# /home/jensy/GitHub/Labs/002_Storage/Partitioning_Filesystems.sh
# RHCSA EX200 - Storage: Partitioning & Filesystems (Troubleshooting - Basic)

source ./lab.conf

sshpass -p "$LAB_PASS" ssh -o StrictHostKeyChecking=no ${LAB_USER}@${LAB_IP} <<'EOF'

# Create mount points
mkdir -p /mnt/data_ext4
mkdir -p /mnt/data_xfs

# Partition disks
parted -s /dev/sdb mklabel gpt
parted -s /dev/sdb mkpart primary 1MiB 1GiB

parted -s /dev/sde mklabel gpt
parted -s /dev/sde mkpart primary 1MiB 100%

# Create filesystems (silent)
mkfs.ext4 -F /dev/sdb1 > /dev/null 2>&1
mkfs.xfs  -f /dev/sde1 > /dev/null 2>&1

# Inject persistent configuration (do not validate)
cat <<EOT >> /etc/fstab
/dev/sdb1  /mnt/data_ext4  xfs   defaults  0 0
/dev/sde1  /mnt/data_xfs   ext4  defaults  0 0
EOT

exit 0
EOF

echo "Scenario injected successfully."
