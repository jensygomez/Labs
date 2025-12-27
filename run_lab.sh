#!/bin/bash
set -e

BASE_DIR="$HOME/GitHub/Labs"
CONF_FILE="$BASE_DIR/config/lab.conf"

[[ -f "$CONF_FILE" ]] && source "$CONF_FILE" || { echo "ERROR: No $CONF_FILE"; exit 1; }

for var in LAB_USER LAB_PASS LAB_IP; do
  [[ -z "${!var}" ]] && { echo "ERROR: Variable $var no definida"; exit 1; }
done

DOMAIN_KEY="$1"
SLOT="$2"
[[ -z "$DOMAIN_KEY" || -z "$SLOT" ]] && { echo "Uso: $0 <dominio> <slot>"; exit 1; }

DOMAIN_DIR=$(find "$BASE_DIR" -maxdepth 1 -type d -iname "*$DOMAIN_KEY*" | head -n1)
[[ -z "$DOMAIN_DIR" ]] && { echo "Dominio no encontrado"; exit 1; }

LAB_DIR=$(find "$DOMAIN_DIR" -maxdepth 1 -type d -iname "$SLOT*" | head -n1)
[[ -z "$LAB_DIR" ]] && { echo "Ejercicio no encontrado"; exit 1; }

INJECTOR=$(ls "$LAB_DIR"/inject_V*.sh 2>/dev/null | shuf -n1)
[[ -z "$INJECTOR" ]] && { echo "No hay injectores"; exit 1; }

echo
echo "Tema     : $(basename "$DOMAIN_DIR")"
echo "Ejercicio: $(basename "$LAB_DIR")"
echo "Injector : $(basename "$INJECTOR")"
echo "VM       : $LAB_USER@$LAB_IP"
echo "----------------------------------------"

echo -n "Probando conexión SSH... "
sshpass -p "$LAB_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
  "$LAB_USER@$LAB_IP" "echo OK" >/dev/null 2>&1 && echo "OK" || { echo "FALLÓ"; exit 1; }

echo -n "Inyectando escenario... "
TEMP_SCRIPT="/tmp/inject_temp.sh"

# Copia con timeout
timeout 10 sshpass -p "$LAB_PASS" scp -o StrictHostKeyChecking=no "$INJECTOR" "$LAB_USER@$LAB_IP:$TEMP_SCRIPT" >/dev/null 2>&1 || { echo "❌ SCP falló"; exit 1; }

# Ejecuta con timeout y mejor manejo
timeout 20 sshpass -p "$LAB_PASS" ssh -o StrictHostKeyChecking=no "$LAB_USER@$LAB_IP" "
  chmod +x '$TEMP_SCRIPT' &&
  echo '$LAB_PASS' | sudo -S bash '$TEMP_SCRIPT' &&
  echo '=== INYECCIÓN OK ===' &&
  rm -f '$TEMP_SCRIPT'
" >/dev/null 2>&1 || { echo "❌ Inyección falló"; exit 1; }

echo "¡OK!"

echo
echo "=== VERIFICACIÓN FINAL ==="
sshpass -p "$LAB_PASS" ssh -o StrictHostKeyChecking=no "$LAB_USER@$LAB_IP" "
  echo 'Estado LVM:'
  sudo lvs vg_exam 2>/dev/null | tail -n +2 || echo 'vg_exam creado'
  echo -e '\nEstado /data:'
  df -hT /data 2>/dev/null || echo '/data montado'
  echo -e '\nDiscos usados:'
  lsblk | grep -E 'sd[b-f]'
"
echo
echo "¡Listo para practicar RHCSA! Conéctate a la VM."
