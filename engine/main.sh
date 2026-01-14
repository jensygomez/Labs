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

# ==============================================================================
# BLOQUE 1 — RUTAS BASE (CORREGIDAS)
# ==============================================================================
ENGINE_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$ENGINE_DIR/.." && pwd)"
export LAB_ENGINE_DIR="$ENGINE_DIR"
export LAB_ROOT_DIR="$ROOT_DIR"

# ✅ CAMBIO CRÍTICO: Disco dedicado VMs (sdb1)
VM_DISK="/mnt/vms"

# ==============================================================================
# BLOQUE 2 — ARCHIVOS DEL MOTOR
# ==============================================================================
DB_FILE="$ENGINE_DIR/labs.db"
BASE_VM_IMG="/mnt/vms/rocky-ir-base-junior-v1.qcow2"

# ==============================================================================
# BLOQUE 3 — ESTRUCTURAS DE DATOS
# ==============================================================================
LABS=()

# ==============================================================================
# BLOQUE 4 — CARGA BASE DE DATOS (SIN CAMBIOS)
# ==============================================================================
load_db() {
    LABS=()
    [[ ! -f "$DB_FILE" ]] && { echo "[DEBUG] labs.db no existe"; return; }

    while IFS='|' read -r id track level artifact type uses status; do
        [[ "$id" == "id" ]] && continue
        [[ "$status" != "active" ]] && continue
        artifact="${artifact/#\.\//$ROOT_DIR/}"
        [[ ! -f "$artifact" ]] && continue
        LABS+=("$id|$track|$level|$artifact|$type|$uses")
    done < "$DB_FILE"
}

# ==============================================================================
# BLOQUE 5 — MENÚ PRINCIPAL (SIN CAMBIOS)
# ==============================================================================
main_menu() {
    clear
    echo "========================================"
    echo " INCIDENT RESPONSE LAB ENGINE v2.0"
    echo "========================================"
    echo "  💾 VMs en: $VM_DISK"
    echo "  📊 Labs cargados: ${#LABS[@]}"
    echo
    echo "Seleccione su nivel:"
    echo "1) Junior    2) Pleno    3) Senior"
    echo "0) Salir"
    echo
    read -rp "Opción: " option
    case "$option" in 1) assign_lab "Junior" ;; 2) assign_lab "Pleno" ;; 3) assign_lab "Senior" ;; 0) exit 0 ;; esac
}

# ==============================================================================
# BLOQUE 6 — ASIGNACIÓN LAB (SIN CAMBIOS)
# ==============================================================================
assign_lab() {
    local LEVEL="$1"
    echo "[DEBUG] Buscando labs para: $LEVEL"

    local MIN_USES=999999 CANDIDATES=()
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

    [[ ${#CANDIDATES[@]} -eq 0 ]] && { echo "[ERROR] Sin labs para $LEVEL"; read -rp "ENTER..."; return; }

    local SELECTED="${CANDIDATES[$RANDOM % ${#CANDIDATES[@]}]}"
    echo "[DEBUG] Lab seleccionado: $SELECTED"
    IFS='|' read -r id track level artifact type uses <<< "$SELECTED"
    run_lab "$id" "$artifact" "$level"
}

# ==============================================================================
# BLOQUE 7 — EJECUCIÓN VM (TOTALMENTE RECONSTRUIDO)
# ==============================================================================
run_lab() {
    local ID="$1"
    local CLOUDINIT_TEMPLATE="$2"  # ✅ scenarios/junior/J00/cloudinit/variant_1.yml
    local LEVEL="$3"

    echo "[DEBUG] === INICIANDO LAB: $ID ($LEVEL) ==="
    read -rp "Presione ENTER para generar cloud-init ISO..."

    # ✅ RUTA CORREGIDA: Disco VMs (igual que cloudinit_generator.sh)
    TMP_DIR="$VM_DISK/labs/tmp"
    mkdir -p "$TMP_DIR"
    echo "[DEBUG] Usando disco VMs: $TMP_DIR"

    # Generar ISO cloud-init
    ISO_PATH=$(bash "$LAB_ENGINE_DIR/cloudinit_generator.sh" "$LEVEL" "$ID" "$CLOUDINIT_TEMPLATE")
    echo "[DEBUG] ✅ ISO creado: $ISO_PATH"
    [[ ! -f "$ISO_PATH" ]] && { echo "[ERROR] ISO falló"; read -rp "ENTER..."; return; }
    read -rp "Presione ENTER para crear VM overlay..."

    # ✅ VM NOMBRE ÚNICO
    VM_NAME="${ID}_${LEVEL}_$(date +%Y%m%d_%H%M%S)"

    # ✅ QCOW2 BACKING FILE (200MB vs 30G copia)
    CLONE_IMG="$TMP_DIR/${VM_NAME}.qcow2"
    echo "[DEBUG] Creando overlay qcow2..."
    qemu-img create -f qcow2 -b "$BASE_VM_IMG" "$CLONE_IMG"
    read -rp "Presione ENTER para virt-install..."

    # ✅ VIRT-INSTALL ROBUSTO
    echo "[DEBUG] Creando VM: $VM_NAME"
    virt-install \
        --name "$VM_NAME" \
        --memory 2048 \
        --vcpus 2 \
        --disk path="$CLONE_IMG",format=qcow2,bus=virtio \
        --disk path="$ISO_PATH",device=cdrom \
        --import \
        --os-variant rhel9.0 \
        --network bridge=br0 \
        --noautoconsole \
        --graphics none \
        --quiet

    read -rp "Presione ENTER para arrancar VM..."
    
    # ✅ ARRANCAR VM
    virsh start "$VM_NAME" || { echo "[WARN] virsh start falló"; }
    echo "[DEBUG] ✅ VM lista: $VM_NAME"
    echo "   🖥️  SSH: ssh jensy@$(virsh domifaddr $VM_NAME | grep ipv4 | awk '{print $2}')"
    
    read -rp "Presione ENTER al finalizar lab para cleanup..."
    
    # ✅ CLEANUP VM
    echo "[DEBUG] Limpiando VM..."
    virsh destroy "$VM_NAME" 2>/dev/null || true
    virsh undefine "$VM_NAME" --remove-all-storage 2>/dev/null || true
    rm -f "$CLONE_IMG" "$ISO_PATH"
    echo "[DEBUG] ✅ Cleanup completado"

    # Actualizar métricas
    increment_uses "$ID"
    echo "[DEBUG] ✅ Lab $ID registrado"
    read -rp "Presione ENTER para menú principal..."
}

# ==============================================================================
# BLOQUE 8 — MÉTRICAS (SIN CAMBIOS)
# ==============================================================================
increment_uses() {
    local ID="$1"
    awk -F'|' -v id="$ID" 'BEGIN{OFS=FS} NR==1 {print; next} {if ($1 == id) $6++; print}' \
        "$DB_FILE" > "$DB_FILE.tmp" && mv "$DB_FILE.tmp" "$DB_FILE"
    load_db
}

# ==============================================================================
# BLOQUE 9 — PUNTO DE ENTRADA
# ==============================================================================
echo "[DEBUG] 🚀 Iniciando Lab Engine..."
load_db
echo "[DEBUG] 📊 $((${#LABS[@]})) labs activos cargados"

[[ ${#LABS[@]} -eq 0 ]] && { echo "[ERROR] Sin labs activos en $DB_FILE"; exit 1; }

while true; do
    main_menu
done
