
#!/usr/bin/env bash
set -euo pipefail

LABS_DIR="$HOME/GitHub/Labs"

THEME_KEY="${1:-}"
SLOT="${2:-}"

if [[ -z "$THEME_KEY" || -z "$SLOT" ]]; then
    echo "Uso: $0 <tema> <slot>"
    echo "Ejemplo: $0 storage 05"
    exit 1
fi

# ─────────────────────────────────────────────
# 1. Resolver TEMA (ej: storage → '1 Storage')
# ─────────────────────────────────────────────
THEME_DIR=$(find "$LABS_DIR" -maxdepth 1 -type d \
    | grep -Ei "/[0-9]+[[:space:]]+.*${THEME_KEY}" \
    | head -n 1)

if [[ -z "$THEME_DIR" ]]; then
    echo "No se encontró el tema para: $THEME_KEY"
    exit 1
fi

# ─────────────────────────────────────────────
# 2. Resolver SLOT exacto (05 → '05  ...')
# ─────────────────────────────────────────────
SLOT_DIR=$(find "$THEME_DIR" -maxdepth 1 -type d \
    | grep -E "/${SLOT}[[:space:]]+" \
    | head -n 1)

if [[ -z "$SLOT_DIR" ]]; then
    echo "No se encontró el slot $SLOT en $(basename "$THEME_DIR")"
    exit 1
fi

# ─────────────────────────────────────────────
# 3. Detectar niveles disponibles (inject*.sh)
# ─────────────────────────────────────────────
mapfile -t LEVELS < <(find "$SLOT_DIR" -maxdepth 1 -type f -name "inject*.sh" | sort)

if [[ "${#LEVELS[@]}" -eq 0 ]]; then
    echo "No hay scripts inject*.sh en $(basename "$SLOT_DIR")"
    exit 1
fi

echo
echo "Tema     : $(basename "$THEME_DIR")"
echo "Ejercicio: $(basename "$SLOT_DIR")"
echo
echo "Niveles disponibles:"
echo

PS3="Selecciona el nivel a ejecutar: "
select LEVEL in "${LEVELS[@]}"; do
    if [[ -n "${LEVEL:-}" ]]; then
        echo
        echo "Ejecutando: $(basename "$LEVEL")"
        echo "----------------------------------------"
        bash "$LEVEL"
        break
    else
        echo "Selección inválida"
    fi
done
