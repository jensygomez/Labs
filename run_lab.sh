#!/bin/bash
set -e

### === Configuración central ===
BASE_DIR="$HOME/GitHub/Labs"
CONF_FILE="$BASE_DIR/config/lab.conf"

# Cargar configuración
if [[ ! -f "$CONF_FILE" ]]; then
  echo "ERROR: No existe $CONF_FILE"
  exit 1
fi

source "$CONF_FILE"

# Validación básica
for var in LAB_USER LAB_PASS LAB_IP; do
  if [[ -z "${!var}" ]]; then
    echo "ERROR: Variable $var no definida en lab.conf"
    exit 1
  done
done

DOMAIN_KEY="$1"   # storage, users, selinux, etc
SLOT="$2"         # 05, 01, etc

if [[ -z "$DOMAIN_KEY" || -z "$SLOT" ]]; then
  echo "Uso: run_lab.sh <dominio> <slot>"
  exit 1
fi

### === Resolver dominio real (ej: '1 Storage') ===
DOMAIN_DIR=$(find "$BASE_DIR" -maxdepth 1 -type d -iname "*$DOMAIN_KEY*" | head -n1)

if [[ -z "$DOMAIN_DIR" ]]; then
  echo "No se encontró el dominio: $DOMAIN_KEY"
  exit 1
fi

### === Resolver ejercicio ===
LAB_DIR=$(find "$DOMAIN_DIR" -maxdepth 1 -type d -iname "$SLOT*" | head -n1)

if [[ -z "$LAB_DIR" ]]; then
  echo "No se encontró el ejercicio $SLOT en $DOMAIN_DIR"
  exit 1
fi

### === Seleccionar injector aleatorio ===
INJECTOR=$(ls "$LAB_DIR"/inject_V*.sh 2>/dev/null | shuf -n1)

if [[ -z "$INJECTOR" ]]; then
  echo "No hay injectores en $LAB_DIR"
  exit 1
fi

echo
echo "Tema     : $(basename "$DOMAIN_DIR")"
echo "Ejercicio: $(basename "$LAB_DIR")"
echo "Injector : $(basename "$INJECTOR")"
echo "VM       : $LAB_USER@$LAB_IP"
echo "----------------------------------------"

### === Test de conectividad ===
if ! sshpass -p "$LAB_PASS" ssh -o StrictHostKeyChecking=no \
     -o ConnectTimeout=5 "$LAB_USER@$LAB_IP" "echo OK" >/dev/null 2>&1; then
  echo "ERROR: No se pudo conectar por SSH a la VM"
  exit 1
fi

### === Inyección real (como root) ===
sshpass -p "$LAB_PASS" ssh -o StrictHostKeyChecking=no \
  "$LAB_USER@$LAB_IP" <<EOF
echo "$LAB_PASS" | sudo -S bash /dev/stdin <<'INJECTOR'
$(cat "$INJECTOR")
INJECTOR
EOF

echo "Inyección completada."