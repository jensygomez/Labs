#!/bin/bash
# ==============================================================================
# INCIDENT RESPONSE LAB ENGINE
# ------------------------------------------------------------------------------
# ARCHIVO      : main.sh
# AUTOR        : Jensy
# AÑO          : 2026
#
# PROPÓSITO:
# ------------------------------------------------------------------------------
# Este script actúa como el motor central de orquestación de laboratorios
# prácticos de Incident Response / Troubleshooting en Linux.
#
# Su responsabilidad es:
#   - Cargar la base de datos de laboratorios activos
#   - Seleccionar un laboratorio automáticamente según nivel y uso
#   - Ejecutar el laboratorio (vía Ansible)
#   - Actualizar métricas de uso
#
# Este script NO:
#   - Crea máquinas virtuales (aún)
#   - Instala paquetes
#   - Contiene lógica específica de laboratorios
#
# Es un ORQUESTADOR, no un ejecutor de escenarios.
#
# 👉 Este diseño permite evolucionar el motor para:
#    - Cloud-init
#    - VM automation (libvirt)
#    - Multi-VM labs (Pleno / Senior)
#
# ------------------------------------------------------------------------------
# REQUISITOS:
# ------------------------------------------------------------------------------
# - Bash 4+
# - Ansible instalado en el host
# - inventory.yml válido
# - labs.db correctamente definida
#
# ------------------------------------------------------------------------------
# MODO DE OPERACIÓN:
# ------------------------------------------------------------------------------
# 1. El usuario selecciona su nivel (Junior / Pleno / Senior)
# 2. El motor asigna un laboratorio activo de ese nivel
#    priorizando el menos utilizado
# 3. El laboratorio se ejecuta automáticamente
# 4. Se registra el uso
#
# ------------------------------------------------------------------------------
# ESTILO:
# ------------------------------------------------------------------------------
# - Código deliberadamente legible
# - Comentarios explicativos (no obvios)
# - Diseño orientado a mantenimiento
#
# ==============================================================================

# ==============================================================================
# BLOQUE 0 — CONFIGURACIÓN Y SEGURIDAD DEL SHELL
# ==============================================================================
#
# set -e : aborta el script ante cualquier error no controlado
# set -u : aborta si se usa una variable no inicializada
# set -o pipefail : detecta errores en pipelines
#
# WHY:
# En motores de automatización, fallar rápido es preferible a
# continuar en estado inconsistente.
#
set -euo pipefail

# ==============================================================================
# BLOQUE 1 — DEFINICIÓN DE RUTAS BASE DEL MOTOR
# ==============================================================================
#
# ENGINE_DIR:
#   Directorio donde vive este script (engine)
#
# ROOT_DIR:
#   Raíz del proyecto Labs
#
# 👉 Estas rutas se exportan para permitir que otros scripts
#    (ansible_wrapper, cloud-init generators, etc.) las reutilicen
#
ENGINE_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$ENGINE_DIR/.." && pwd)"

export LAB_ENGINE_DIR="$ENGINE_DIR"
export LAB_ROOT_DIR="$ROOT_DIR"

# ==============================================================================
# BLOQUE 2 — ARCHIVOS CRÍTICOS DEL MOTOR
# ==============================================================================
#
# labs.db:
#   Base de datos declarativa de laboratorios
#
# inventory.yml:
#   Inventario Ansible utilizado para todos los labs
#
# ansible_wrapper.sh:
#   Wrapper que estandariza la ejecución de Ansible
#
DB_FILE="$ENGINE_DIR/labs.db"

# ==============================================================================
# BLOQUE 3 — ESTRUCTURAS DE DATOS EN MEMORIA
# ==============================================================================
#
# LABS:
#   Array en memoria con todos los laboratorios activos
#
#   Formato interno:
#     id|track|level|artifact|type|uses
#
LABS=()

# ==============================================================================
# BLOQUE 4 — CARGA DE LA BASE DE DATOS
# ==============================================================================
#
# FUNCIÓN: load_db
#
# RESPONSABILIDAD:
#   - Leer labs.db
#   - Filtrar solo labs activos
#   - Resolver rutas absolutas
#   - Poblar el array LABS
#
# NOTA:
#   Esta función NO valida semántica de laboratorios,
#   solo carga datos válidos conocidos.
#
load_db() {
    LABS=()

    # ⚠️ Si no existe la BD, el motor continúa sin labs
    [[ ! -f "$DB_FILE" ]] && return

    while IFS='|' read -r id track level artifact type uses status; do
        # Saltar cabecera
        [[ "$id" == "id" ]] && continue

        # Solo laboratorios activos
        [[ "$status" != "active" ]] && continue

        # Resolver rutas relativas
        artifact="${artifact/#\.\//$ROOT_DIR/}"

        # Validar existencia del playbook
        [[ ! -f "$artifact" ]] && continue

        LABS+=("$id|$track|$level|$artifact|$type|$uses")
    done < "$DB_FILE"
}

# ==============================================================================
# BLOQUE 5 — MENÚ PRINCIPAL DE INTERACCIÓN
# ==============================================================================
#
# FUNCIÓN: main_menu
#
# RESPONSABILIDAD:
#   - Presentar opciones al usuario
#   - Traducir selección a nivel lógico
#
# NOTE:
#   Este menú es deliberadamente simple.
#   El motor debe decidir, no el usuario.
#
main_menu() {
    clear
    echo "========================================"
    echo " INCIDENT RESPONSE LAB ENGINE"
    echo "========================================"
    echo
    echo "Seleccione su nivel actual:"
    echo "1) Junior"
    echo "2) Pleno"
    echo "3) Senior"
    echo "0) Salir"
    echo

    read -rp "Opción: " option
    echo "[DEBUG] Opción ingresada: $option"

    case "$option" in
        1) assign_lab "Junior" ;;
        2) assign_lab "Pleno" ;;
        3) assign_lab "Senior" ;;
        0) exit 0 ;;
    esac
}

# ==============================================================================
# BLOQUE 6 — ASIGNACIÓN AUTOMÁTICA DE LABORATORIO
# ==============================================================================
#
# FUNCIÓN: assign_lab
#
# RESPONSABILIDAD:
#   - Filtrar labs por nivel
#   - Priorizar el menos utilizado
#   - Balancear uso entre laboratorios
#
# WHY:
#   Evita repetición de labs y fuerza cobertura homogénea
#
assign_lab() {
    local LEVEL="$1"
    echo "[DEBUG] assign_lab() llamado con nivel: $LEVEL"

    local MIN_USES=999999
    local CANDIDATES=()

    for LAB in "${LABS[@]}"; do
        IFS='|' read -r id track lab_level artifact type uses <<< "$LAB"

        echo "[DEBUG] Revisa LAB: $LAB"

        [[ "$lab_level" != "$LEVEL" ]] && continue

        if (( uses < MIN_USES )); then
            MIN_USES="$uses"
            CANDIDATES=("$LAB")
        elif (( uses == MIN_USES )); then
            CANDIDATES+=("$LAB")
        fi
    done

    if [[ ${#CANDIDATES[@]} -eq 0 ]]; then
        echo "[DEBUG] No se encontraron labs activos para nivel $LEVEL"
        return
    fi

    local SELECTED="${CANDIDATES[$RANDOM % ${#CANDIDATES[@]}]}"
    echo "[DEBUG] Lab seleccionado: $SELECTED"

    IFS='|' read -r id track level artifact type uses <<< "$SELECTED"
    run_lab "$id" "$artifact" "$level"
}


# ==============================================================================
# BLOQUE 7 — EJECUCIÓN DEL LABORATORIO (cloud-init / VM)
# ==============================================================================
#
# FUNCIÓN: run_lab
#
# RESPONSABILIDAD:
#   - Generar ISO cloud-init para la variante seleccionada
#   - Clonar VM base
#   - Adjuntar ISO NoCloud
#   - Arrancar VM en background
#

run_lab() {
    local ID="$1"
    local CLOUDINIT_TEMPLATE="$2"
    local LEVEL="$3"

    echo "[DEBUG] run_lab() llamado con ID=$ID, LEVEL=$LEVEL, TEMPLATE=$CLOUDINIT_TEMPLATE"
    read -rp "Presione ENTER para continuar con la ejecución del lab..."

    # Carpeta temporal
    TMP_DIR="$LAB_ENGINE_DIR/tmp"
    mkdir -p "$TMP_DIR"
    echo "[DEBUG] Carpeta temporal: $TMP_DIR"
    read -rp "ENTER para generar ISO cloud-init..."

    # Generar ISO
    ISO_PATH=$(bash "$LAB_ENGINE_DIR/cloudinit_generator.sh" "$LEVEL" "$ID" "$CLOUDINIT_TEMPLATE")
    echo "[DEBUG] ISO cloud-init generado: $ISO_PATH"
    if [[ ! -f "$ISO_PATH" ]]; then
        echo "[ERROR] ISO no existe. Abortando"
        read -rp "Presione ENTER para volver al menú..."
        return
    fi
    read -rp "ENTER para clonar VM base..."

    # Clonar VM
    VM_NAME="${ID}_$(basename "$CLOUDINIT_TEMPLATE")_$(date +%s)"
    BASE_IMG="/mnt/vms/rocky-ir-base-junior-v1.qcow2"
    CLONE_IMG="$TMP_DIR/${VM_NAME}.qcow2"
    echo "[DEBUG] Clonando VM base..."
    cp "$BASE_IMG" "$CLONE_IMG" || { echo "[ERROR] Falló clonación de VM"; read -rp "ENTER"; return; }
    read -rp "ENTER para crear la VM con virt-install..."

    # Crear VM
    echo "[DEBUG] Creando VM $VM_NAME..."
    virt-install \
        --name "$VM_NAME" \
        --memory 2048 \
        --vcpus 2 \
        --disk path="$CLONE_IMG",format=qcow2 \
        --import \
        --cdrom "$ISO_PATH" \
        --network bridge=br0 \
        --noautoconsole \
        --graphics none
    read -rp "ENTER para arrancar la VM..."

    # Arrancar VM
    echo "[DEBUG] Arrancando VM $VM_NAME..."
    virsh start "$VM_NAME" || echo "[ERROR] virsh start falló"

    # Actualizar métricas
    increment_uses "$ID"
    echo "[DEBUG] Uso del lab actualizado"

    echo "[DEBUG] Laboratorio $ID ejecutado correctamente"
    read -rp "Presione ENTER para volver al menú..."
}




# ==============================================================================
# BLOQUE 8 — MÉTRICAS DE USO
# ==============================================================================
#
# FUNCIÓN: increment_uses
#
# RESPONSABILIDAD:
#   - Incrementar contador de uso del laboratorio
#   - Persistir cambio en labs.db
#
# NOTE:
#   Esta métrica se usa únicamente para balanceo,
#   no para analítica avanzada.
#
increment_uses() {
    local ID="$1"

    awk -F'|' -v id="$ID" 'BEGIN{OFS=FS}
        NR==1 {print; next}
        {
            if ($1 == id) $6++
            print
        }
    ' "$DB_FILE" > "$DB_FILE.tmp" && mv "$DB_FILE.tmp" "$DB_FILE"

    load_db
}

# ==============================================================================
# BLOQUE 9 — PUNTO DE ENTRADA DEL MOTOR
# ==============================================================================
#
# FLOW:
#   1. Cargar base de datos
#   2. Mostrar menú
#   3. Ejecutar en bucle infinito
#

echo "[DEBUG] Inicio del motor - cargando base de datos..."
load_db
echo "[DEBUG] LABS cargados tras load_db:"
printf '%s\n' "${LABS[@]}"


while true; do
    main_menu
done

