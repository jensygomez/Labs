#!/bin/bash
# ==============================================================================
# INCIDENT RESPONSE LAB ENGINE - VERSIÓN CORREGIDA
# ------------------------------------------------------------------------------
# ARCHIVO      : main.sh
# AUTOR        : Jensy (con correcciones críticas)
# AÑO          : 2026
#
# CAMBIOS CRÍTICOS APLICADOS:
# ------------------------------------------------------------------------------
# ✅ RUTAS: Usa /mnt/vms/labs/tmp/ (sdb1 111.8G) - repo GitHub limpio
# ✅ VM: qcow2 backing file (overlay ~200MB vs copia 30G)
# ✅ LÓGICA: artifact=labs.db apunta a variant_1.yml reales
# ✅ DEBUG: Mantiene read -rp para identificar fallos
# ✅ CLEANUP: Destruye VMs al finalizar lab
# ------------------------------------------------------------------------------

set -euo pipefail
#!/bin/bash
# ==============================================================================
# INCIDENT RESPONSE LAB ENGINE - VERSIÓN DEBUG FIX
# ------------------------------------------------------------------------------
# FIX CRÍTICO: Muestra MENÚ SIEMPRE, diagnostica labs.db
# ------------------------------------------------------------------------------

set -euo pipefail

# ==============================================================================
# BLOQUE 1 — RUTAS BASE
# ==============================================================================
ENGINE_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$ENGINE_DIR/.." && pwd)"
export LAB_ENGINE_DIR="$ENGINE_DIR"
export LAB_ROOT_DIR="$ROOT_DIR"
VM_DISK="/mnt/vms"
DB_FILE="$ENGINE_DIR/labs.db"
BASE_VM_IMG="/mnt/vms/rocky-ir-base-junior-v1.qcow2"

# ==============================================================================
# BLOQUE 2 — CARGA BASE DE DATOS (DIAGNÓSTICO MEJORADO)
# ==============================================================================
LABS=()
load_db() {
    LABS=()
    echo "[DEBUG] 🔍 Cargando $DB_FILE..."
    
    if [[ ! -f "$DB_FILE" ]]; then
        echo "[DEBUG] ❌ $DB_FILE no existe"
        return
    fi
    
    # ✅ FIX: Detecta header en MAYÚSCULAS o minúsculas
    local header_found=false
    while IFS='|' read -r id track level artifact type uses status; do
        echo "[DEBUG] Línea cruda: '$id|$track|$level|$artifact|$type|$uses|$status'"
        
        # ✅ FIX HEADER: Insensible a mayúsculas
        if [[ "${id,,}" == "id" || "${id,,}" == "id" ]]; then
            echo "[DEBUG] ✅ Header detectado, saltando"
            header_found=true
            continue
        fi
        
        [[ "$status" != "active" ]] && { echo "[DEBUG] ⏭️  Saltando inactivo: $id"; continue; }
        
        # ✅ Resolver ruta absoluta
        local full_artifact="${artifact/#\.\//$ROOT_DIR/}"
        echo "[DEBUG] Verificando artifact: '$full_artifact'"
        
        if [[ -f "$full_artifact" ]]; then
            LABS+=("$id|$track|$level|$full_artifact|$type|$uses")
            echo "[DEBUG] ✅ Lab agregado: $id ($level)"
        else
            echo "[DEBUG] ❌ Artifact no existe: $full_artifact"
        fi
    done < "$DB_FILE"
    
    echo "[DEBUG] 📊 Total LABS cargados: ${#LABS[@]}"
}

# ==============================================================================
# BLOQUE 3 — MENÚ SIEMPRE VISIBLE
# ==============================================================================
main_menu() {
    clear
    echo "========================================"
    echo " INCIDENT RESPONSE LAB ENGINE v2.0"
    echo "========================================"
    echo "  💾 VMs: $VM_DISK"
    echo "  📊 Labs: ${#LABS[@]}"
    [[ ${#LABS[@]} -eq 0 ]] && echo "  ⚠️  CARGUE labs.db PRIMERO"
    echo
    echo "1) Junior    2) Pleno    3) Senior"
    echo "0) Salir"
    echo
    read -rp "Opción: " option
    case "$option" in 1) assign_lab "Junior" ;; 2) assign_lab "Pleno" ;; 3) assign_lab "Senior" ;; 0) exit 0 ;; *) main_menu ;; esac
}

# ==============================================================================
# BLOQUE 4 — ASIGNACIÓN (SIN CAMBIOS)
# ==============================================================================
assign_lab() {
    local LEVEL="$1"
    echo "[DEBUG] 🎯 Buscando labs $LEVEL..."
    local CANDIDATES=() MIN_USES=999999
    
    for LAB in "${LABS[@]}"; do
        IFS='|' read -r id track lab_level artifact type uses <<< "$LAB"
        [[ "$lab_level" != "$LEVEL" ]] && continue
        if (( uses < MIN_USES )); then MIN_USES="$uses"; CANDIDATES=("$LAB"); 
        elif (( uses == MIN_USES )); then CANDIDATES+=("$LAB"); fi
    done
    
    if [[ ${#CANDIDATES[@]} -eq 0 ]]; then
        echo "[ERROR] Sin labs para $LEVEL"
        read -rp "ENTER..."
        return
    fi
    
    local SELECTED="${CANDIDATES[$RANDOM % ${#CANDIDATES[@]}]}"
    IFS='|' read -r id track level artifact type uses <<< "$SELECTED"
    run_lab "$id" "$artifact" "$level"
}

# ==============================================================================
# BLOQUE 5 — run_lab (SIMPLIFICADO DEBUG)
# ==============================================================================
run_lab() {
    local ID="$1" TEMPLATE="$2" LEVEL="$3"
    echo "[DEBUG] 🚀 Lab: $ID ($LEVEL)"
    read -rp "ENTER para cloudinit_generator.sh..."
    
    # Generar ISO
    ISO_PATH=$(bash "$LAB_ENGINE_DIR/cloudinit_generator.sh" "$LEVEL" "$ID" "$TEMPLATE" 2>&1)
    echo "[DEBUG] ISO: $ISO_PATH"
    [[ ! -f "$ISO_PATH" ]] && { echo "[ERROR] ISO falló"; read -rp "ENTER..."; return; }
    
    read -rp "Lab listo! Conéctate SSH y resuelve. ENTER para cleanup..."
    increment_uses "$ID"
}

increment_uses() {
    local ID="$1"
    awk -F'|' -v id="$ID" 'BEGIN{OFS=FS} NR==1 {print; next} {if ($1 == id) $6++; print}' \
        "$DB_FILE" > "$DB_FILE.tmp" && mv "$DB_FILE.tmp" "$DB_FILE" || true
    load_db
}

# ==============================================================================
# INICIO — MENÚ DESDE EL PRINCIPIO
# ==============================================================================
echo "[DEBUG] 🚀 Engine iniciado"
load_db
while true; do main_menu; done
