#!/usr/bin/env bash
# gremlin/inject.sh — inc-001-boot-fstab-mount-failure
#
# NO ABRIR ESTE ARCHIVO DURANTE EL EJERCICIO. Es la causa raiz.
#
# Fallo: durante el "mantenimiento nocturno", alguien reemplazo la linea
# de fstab por una con un typo en la IP del storage Y sin la opcion
# '_netdev'. Sin _netdev, systemd no sabe que este mount depende de la
# red, e intenta montarlo demasiado temprano en el boot (antes de que la
# interfaz de red este arriba) ademas de apuntar a un servidor que no
# existe. Resultado: el mount nunca se completa, y app-backend
# (RequiresMountsFor=/data) queda sin poder arrancar.

set -o errexit
set -o pipefail

echo "[gremlin] Rompiendo el mount NFS en $(hostname)..."

umount /data 2>/dev/null || true

# Sacar la linea sana que puso common-app-baseline.sh
sed -i '/\/data nfs/d' /etc/fstab

# Meter la linea rota: IP con typo (122.14 -> 122.99) y SIN _netdev
echo "192.168.122.99:/srv/nfs/appdata /data nfs defaults 0 0" >> /etc/fstab

systemctl daemon-reload
mount -a || true
systemctl restart app-backend.service || true

echo "[gremlin] Fallo inyectado: fstab apunta a IP inexistente, sin _netdev."
