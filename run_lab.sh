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
  fi
done

DOMAIN_KEY="$1"
SLOT="$2"

if [[ -z "$DOMAIN_KEY" || -z "$SLOT" ]]; then
  echo "Uso: run_lab.sh <dominio> <slot>"
  exit 1
fi

### === Resolver paths ===
DOMAIN_DIR=$(find "$BASE_DIR" -maxdepth 1 -type d -iname "*$DOMAIN_KEY*" | head -n1)
if [[ -z "$DOMAIN_DIR" ]]; then
  echo "No se encontró el dominio: $DOMAIN_KEY"
  exit 1
fi

LAB_DIR=$(find "$DOMAIN_DIR" -maxdepth 1 -type d -iname "$SLOT*" | head -n1)
if [[ -z "$LAB_DIR" ]]; then
  echo "No se encontró el ejercicio $SLOT en $DOMAIN_DIR"
  exit 1
fi

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

### === 1. Validar conexión SSH ===
echo -n "Probando conexión SSH... "
if sshpass -p "$LAB_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 \
     "$LAB_USER@$LAB_IP" "echo OK" >/dev/null 2>&1; then
  echo "OK"
else
  echo "FALLÓ"
  exit 1
fi

### === 2. Inyección real (como root) - VERSIÓN ROBUSTA ===
# Usamos un comando remoto explícito con sudo dentro de bash -s
# y redirigimos stderr a stdout para ver posibles errores
sshpass -p "$LAB_PASS" ssh -o StrictHostKeyChecking=no \
  "$LAB_USER@$LAB_IP" \
  "echo '$LAB_PASS' | sudo -S -p '' bash -s --" <<'EOF' 2>&1
$(cat "$INJECTOR")
echo "=== INYECTOR EJECUTADO CON ÉXITO ==="
EOF

echo "Inyección completada."