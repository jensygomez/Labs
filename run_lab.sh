
#!/usr/bin/env bash
set -euo pipefail

LABS_DIR="$HOME/GitHub/Labs"
CONF_FILE="$LABS_DIR/config/lab.conf"

THEME_KEY="${1:-}"
SLOT="${2:-}"
MODE="${3:-}"

if [[ -z "$THEME_KEY" || -z "$SLOT" ]]; then
    echo "Uso: $0 <tema> <slot> [--random]"
    exit 1
fi

# ─────────────────────────────────────────────
# 0. Cargar configuración
# ─────────────────────────────────────────────
[[ -f "$CONF_FILE" ]] || { echo "Falta $CONF_FILE"; exit 1; }
# shellcheck disable=SC1090
source "$CONF_FILE"

: "${VM_HOST:?}"
: "${VM_USER:?}"
: "${VM_PASS:?}"
VM_PORT="${VM_PORT:-22}"

# ─────────────────────────────────────────────
# 1. Resolver tema (storage, users, etc.)
# ─────────────────────────────────────────────
THEME_DIR=$(find "$LABS_DIR" -maxdepth 1 -type d \
  | grep -Ei "/[0-9]+[[:space:]]+.*${THEME_KEY}" \
  | head -n1)

[[ -z "$THEME_DIR" ]] && { echo "Tema no encontrado"; exit 1; }

# ─────────────────────────────────────────────
# 2. Resolver slot (05, 01, etc.)
# ─────────────────────────────────────────────
SLOT_DIR=$(find "$THEME_DIR" -maxdepth 1 -type d \
  | grep -E "/${SLOT}[[:space:]]+" \
  | head -n1)

[[ -z "$SLOT_DIR" ]] && { echo "Slot $SLOT no encontrado"; exit 1; }

# ─────────────────────────────────────────────
# 3. Detectar injectores
# ─────────────────────────────────────────────
mapfile -t LEVELS < <(find "$SLOT_DIR" -maxdepth 1 -type f -name "inject*.sh" | sort)

[[ "${#LEVELS[@]}" -eq 0 ]] && { echo "No hay injectores"; exit 1; }

# ─────────────────────────────────────────────
# 4. Selección
# ─────────────────────────────────────────────
if [[ "$MODE" == "--random" ]]; then
    LEVEL="${LEVELS[RANDOM % ${#LEVELS[@]}]}"
    echo "Modo RANDOM seleccionado"
else
    echo
    echo "Tema     : $(basename "$THEME_DIR")"
    echo "Ejercicio: $(basename "$SLOT_DIR")"
    echo
    PS3="Selecciona el nivel: "
    select LEVEL in "${LEVELS[@]}"; do
        [[ -n "${LEVEL:-}" ]] && break
        echo "Selección inválida"
    done
fi

echo
echo "Injector : $(basename "$LEVEL")"
echo "VM       : $VM_USER@$VM_HOST:$VM_PORT"
echo "----------------------------------------"

# ─────────────────────────────────────────────
# 5. Verificar SSH (con password)
# ─────────────────────────────────────────────
sshpass -p "$VM_PASS" ssh \
    -p "$VM_PORT" \
    -o StrictHostKeyChecking=no \
    -o ConnectTimeout=5 \
    "$VM_USER@$VM_HOST" "echo OK" >/dev/null \
    || { echo "No se pudo conectar por SSH a la VM"; exit 1; }

# ─────────────────────────────────────────────
# 6. Ejecutar injector COMO ROOT
# ─────────────────────────────────────────────
sshpass -p "$VM_PASS" ssh \
    -p "$VM_PORT" \
    -o StrictHostKeyChecking=no \
    "$VM_USER@$VM_HOST" "sudo -S bash -s" <<<"$VM_PASS" < "$LEVEL"

echo
echo "Inyección completada correctamente"
