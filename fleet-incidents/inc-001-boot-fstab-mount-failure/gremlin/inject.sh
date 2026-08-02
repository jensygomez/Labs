#!/usr/bin/env bash
# gremlin/inject.sh — inc-001-boot-fstab-mount-failure
#
# NO ABRIR ESTE ARCHIVO DURANTE EL EJERCICIO. Es la causa raíz.
# Solo corre en el nodo que Ruby eligió al azar en el Vagrantfile.
#
# Fallo: /etc/fstab referencia un UUID que NO existe en el dispositivo real.
# Con 'nofail' el boot no se cuelga, pero /data nunca se monta, y
# app-backend.service (que depende de /data) queda reintentando sin arrancar.

set -o errexit
set -o pipefail

echo "🔧 [gremlin] Rompiendo fstab en $(hostname)..."

# El dispositivo /data ya fue armado por common-app-baseline.sh como
# parte del filesystem raíz (no hay disco extra en este incidente nivel 3
# — el "mount roto" es simulado con un bind/tmpfs que gremlin desmonta
# y reemplaza por una entrada fstab con UUID inventado).

# 1. Mover el contenido real a un lugar seguro temporalmente
mv /data /data.real

# 2. Crear el punto de montaje vacío que fstab intentará usar
mkdir -p /data

# 3. Insertar un UUID falso en fstab (simula disco reemplazado sin
#    actualizar el fstab, o copy-paste error durante mantenimiento)
FAKE_UUID="12345678-1234-1234-1234-123456789abc"
echo "UUID=${FAKE_UUID} /data xfs defaults,nofail 0 0" >> /etc/fstab

# 4. Reiniciar systemd para que intente montar (fallará silenciosamente
#    por el nofail, dejando /data vacío)
systemctl daemon-reload
mount -a || true

# 5. Reiniciar app-backend para que quede en su estado real de fallo
#    (RequiresMountsFor=/data + directorio vacío = no encuentra status)
systemctl restart app-backend.service || true

echo "🔧 [gremlin] Fallo inyectado. Datos reales preservados en /data.real"
echo "    (el playbook de fix real debe restaurar el mount correcto,"
echo "     no simplemente mover /data.real de vuelta a mano)"
