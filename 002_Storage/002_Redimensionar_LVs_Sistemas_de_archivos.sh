# /home/jensy/GitHub/Labs/002_Storage/002_Redimensionar_LVs_Sistemas_de_archivos.sh

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

# Selección aleatoria controlada de discos
DISK1="/dev/sdb"   # 3G
DISK2="/dev/sdd"   # 2G

# Limpieza previa
wipefs -a $DISK1
wipefs -a $DISK2

# Crear PVs
pvcreate $DISK1 $DISK2

# Crear VG
vgcreate vg_exam $DISK1 $DISK2

# Crear LV inicial
lvcreate -L 1G -n lv_data vg_exam

# Crear filesystem
mkfs.ext4 /dev/vg_exam/lv_data

# Punto de montaje
mkdir -p /data

# Entrada en fstab
echo "/dev/vg_exam/lv_data /data ext4 defaults 0 0" >> /etc/fstab

# Montar
mount -a

# Simular cambio de requerimiento (sin aplicarlo correctamente)
lvextend -L +1G /dev/vg_exam/lv_data

# NO tocar filesystem (intencional)

EOF
