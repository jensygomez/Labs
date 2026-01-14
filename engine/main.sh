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
INVENTORY="$ENGINE_DIR/inventory.yml"
ANSIBLE_WRAPPER="$ENGINE_DIR/ansible_wrapper.sh"

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
    local MIN_USES=999999
    local CANDIDATES=()

    for LAB in "${LABS[@]}"; do
        IFS='|' read -r id track lab_level artifact type uses <<< "$LAB"

        [[ "$lab_level" != "$LEVEL" ]] && continue

        if (( uses < MIN_USES )); then
            MIN_USES="$uses"
            CANDIDATES=("$LAB")
        elif (( uses == MIN_USES )); then
            CANDIDATES+=("$LAB")
        fi
    done

    # Si no hay labs para ese nivel, se retorna al menú
    [[ ${#CANDIDATES[@]} -eq 0 ]] && return

    # Selección aleatoria entre los menos usados
    local SELECTED="${CANDIDATES[$RANDOM % ${#CANDIDATES[@]}]}"
    IFS='|' read -r id track level artifact type uses <<< "$SELECTED"

    run_lab "$id" "$artifact"
}

# ==============================================================================
# BLOQUE 7 — EJECUCIÓN DEL LABORATORIO
# ==============================================================================
#
# FUNCIÓN: run_lab
#
# RESPONSABILIDAD:
#   - Ejecutar el playbook Ansible asignado
#   - Delegar lógica técnica al laboratorio
#   - Mantener el motor agnóstico
#
run_lab() {
    local ID="$1"
    local PLAYBOOK="$2"

    clear
    echo "========================================"
    echo " Ejecutando laboratorio $ID"
    echo "========================================"
    echo

    "$ANSIBLE_WRAPPER" "$PLAYBOOK" "$INVENTORY"

    increment_uses "$ID"

    echo
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
load_db

while true; do
    main_menu
done

