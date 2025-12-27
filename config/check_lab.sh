# /home/jensy/GitHub/Labs/config/check_lab.sh
#!/bin/bash
# RHCSA EX200 - Pre-check de conectividad y privilegios

set -e

CONF_FILE="/home/jensy/GitHub/Labs/config/lab.conf"

# 1. Validar archivo
if [[ ! -f "$CONF_FILE" ]]; then
  echo "[ERROR] No existe $CONF_FILE"
  exit 1
fi

source "$CONF_FILE"

# 2. Validar variables
for var in LAB_IP LAB_USER LAB_PASS; do
  if [[ -z "${!var}" ]]; then
    echo "[ERROR] Variable $var no definida"
    exit 1
  fi
done

# 3. Ping
if ! ping -c 1 -W 2 "$LAB_IP" >/dev/null; then
  echo "[ERROR] No hay conectividad IP con $LAB_IP"
  exit 1
fi

# 4. Puerto SSH
if ! nc -z "$LAB_IP" 22 >/dev/null 2>&1; then
  echo "[ERROR] Puerto SSH no disponible en $LAB_IP"
  exit 1
fi

# 5. SSH + sudo
SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"

if ! sshpass -p "$LAB_PASS" ssh $SSH_OPTS ${LAB_USER}@${LAB_IP} "sudo -n true" >/dev/null 2>&1; then
  echo "[ERROR] El usuario ${LAB_USER} no tiene sudo sin password"
  exit 1
fi

echo "[OK] Conectividad, SSH y sudo verificados"
