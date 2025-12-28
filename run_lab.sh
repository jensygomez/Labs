#!/bin/bash
# /home/jensy/GitHub/Labs/run_lab.sh
# Script principal para ejecutar labs RHCSA con randomización controlada

set -e

# Configuración de paths
LAB_DIR="/home/jensy/GitHub/Labs/1_Storage/05_Resize_LVs_Filesystems"
DONE_FILE="$LAB_DIR/labs_done.txt"
ACTIVE_LAB_FILE="$LAB_DIR/active_lab.tmp"

# 1. Detectamos labs disponibles (inject_*.sh)
AVAILABLE_LABS=($(ls "$LAB_DIR"/inject_*.sh 2>/dev/null))
if [[ ${#AVAILABLE_LABS[@]} -eq 0 ]]; then
    echo "[ERROR] No se encontraron labs disponibles en $LAB_DIR"
    exit 1
fi

# 2. Inicializamos el archivo de labs ya practicados si no existe
if [[ ! -f "$DONE_FILE" ]]; then
    touch "$DONE_FILE"
fi

# 3. Construimos array de labs pendientes
PENDING_LABS=()
for lab in "${AVAILABLE_LABS[@]}"; do
    LAB_NAME=$(basename "$lab")
    if ! grep -qx "$LAB_NAME" "$DONE_FILE"; then
        PENDING_LABS+=("$LAB_NAME")
    fi
done

# 4. Si todos los labs ya se practicaron, reiniciamos la lista
if [[ ${#PENDING_LABS[@]} -eq 0 ]]; then
    echo "[INFO] Todos los labs ya se practicaron. Reiniciando lista..."
    > "$DONE_FILE"
    for lab in "${AVAILABLE_LABS[@]}"; do
        PENDING_LABS+=("$(basename "$lab")")
    done
fi

# 5. Seleccionamos aleatoriamente un lab pendiente
RANDOM_INDEX=$((RANDOM % ${#PENDING_LABS[@]}))
SELECTED_LAB=${PENDING_LABS[$RANDOM_INDEX]}

# 6. Guardamos el lab activo
echo "$SELECTED_LAB" > "$ACTIVE_LAB_FILE"

# 7. Ejecutamos el lab
echo "[INFO] Lab seleccionado: $SELECTED_LAB"
echo "[INFO] Inyectando el lab en la VM..."

bash "$LAB_DIR/$SELECTED_LAB"

# 8. Marcamos este lab como practicado
echo "$SELECTED_LAB" >> "$DONE_FILE"

# 9. Mensaje final
echo "[DONE] Lab inyectado correctamente."
echo "[INFO] Lab activo registrado en $ACTIVE_LAB_FILE"


