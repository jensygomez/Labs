#!/bin/bash
# Pre-check de conectividad y acceso al laboratorio

set -e

CONF_FILE="/home/jensy/GitHub/Labs/config/lab.conf"

if [[ ! -f "$CONF_FILE" ]]; then
  echo "[ERROR] No existe $CONF_FILE"
  exit 1
fi

source "$CONF_FILE"

for var in LAB_IP LAB_USER LAB_PASS; do
  if [[ -z "${!var}" ]]; then
    echo "[ERROR] Variable $var no definida en lab.conf"
    exit 1
  fi
done

if ! ping -c 1 -W 2 "$LAB_IP" >/dev/null; then
  echo "[ERROR] No hay conectividad IP con $LAB_IP"
  exit 1
fi

if ! nc -z "$LAB_IP" 22 >/dev/null 2>&1; then
  echo "[ERROR] Puerto SSH no disponible en $LAB_IP"
  exit 1
fi

SSH_OPTS="-o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5"

if ! sshpass -p "$LAB_PASS" ssh $SSH_OPTS ${LAB_USER}@${LAB_IP} "id -u" >/dev/null 2>&1; then
  echo "[ERROR] No fue posible autenticarse por SSH"
  exit 1
fi

echo "[OK] Conectividad y acceso SSH verificados"
