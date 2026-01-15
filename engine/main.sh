#!/bin/bash 
# INCIDENT RESPONSE LAB ENGINE v1.1 - DOCUMENTACIÓN ACTUALIZADA
# ==============================================================
# Documentación actualizada para reflejar EXACTAMENTE las variables
# utilizadas en el código implementado.
#
# Última revisión: 2024
#-----------------------------------------------------------------

## 🔄 **OBSERVACIÓN IMPORTANTE:**
# La documentación anterior contenía un "contrato ideal" de variables
# que no se implementó completamente. Esta versión documenta SOLO
# las variables realmente utilizadas en el código.

#==============================================================================
# VARIABLES GLOBALES IMPLEMENTADAS
#==============================================================================

# -----------------------------------------------------------------
# 1. VARIABLES DE DIRECTORIOS Y PATHS (CONSTANTES AL INICIO)
# -----------------------------------------------------------------
# ENGINE_DIR
#   Descripción: Directorio donde reside el script engine (motor principal)
#   Definición: ENGINE_DIR="$(cd "$(dirname "$0")" && pwd)"
#   Uso: Referencia base para todos los paths relativos del motor

# ROOT_DIR  
#   Descripción: Directorio padre del proyecto (un nivel arriba de ENGINE_DIR)
#   Definición: ROOT_DIR="$(cd "$ENGINE_DIR/.." && pwd)"
#   Uso: Acceso a la raíz del proyecto donde están los escenarios

# DB_FILE
#   Descripción: Archivo de base de datos de laboratorios
#   Definición: DB_FILE="$ENGINE_DIR/labs.db"
#   Formato: ID|NIVEL|PATH|USES (ej: J01|Junior|scenarios/junior/J01|5)
#   Uso: Persistencia del conteo de usos por lab

# -----------------------------------------------------------------
# 2. ARRAYS Y ESTRUCTURAS DE DATOS
# -----------------------------------------------------------------
# LABS (array)
#   Descripción: Almacena en memoria todos los labs cargados desde DB_FILE
#   Formato: Cada elemento es string "ID|LEVEL|PATH|USES"
#   Ciclo de vida: Se llena en load_db(), se usa en select_lab_by_level()
#   Nota: Variable GLOBAL del script

# -----------------------------------------------------------------
# 3. VARIABLES DE FUNCIONES (PASO DE PARÁMETROS Y RETORNOS)
# -----------------------------------------------------------------
# FUNCIÓN: load_db()
#   - No usa parámetros
#   - No retorna valores (modifica array global LABS)

# FUNCIÓN: select_lab_by_level(LEVEL)
#   Parámetro: LEVEL (string) - "Junior", "Pleno" o "Senior"
#   Variables locales:
#     - FILTERED (array): Labs filtrados por nivel
#     - MIN_USES (int): Mínimo número de usos encontrado
#     - CANDIDATES (array): Labs empatados con MIN_USES
#     - SELECTED_LAB (string): Lab elegido aleatoriamente "ID|LEVEL|PATH|USES"
#   Retorno: echo "ID|LEVEL|PATH" (capturado por llamante)

# FUNCIÓN: update_lab_uses(TARGET_ID, NEW_USES)
#   Parámetros:
#     - TARGET_ID (string): ID del lab a actualizar (ej: "J01")
#     - NEW_USES (int): Nuevo valor del contador
#   Variables locales:
#     - TMP_DB (string): Path temporal para archivo DB

# FUNCIÓN: select_variant(LAB_PATH)
#   Parámetro: LAB_PATH (string) - Ruta relativa del lab
#   Variables locales:
#     - VARIANT_DIR (string): Path absoluto a directorio de variantes
#     - VARIANTS (array): Lista de archivos variant_*.yml
#   Retorno: echo del path completo de una variante aleatoria

# FUNCIÓN: assign_lab(LEVEL)
#   Parámetro: LEVEL (string) - Nivel seleccionado
#   Variables locales:
#     - LAB_INFO (string): Salida de select_lab_by_level()
#     - ID, LAB_LEVEL, LAB_PATH (strings): Partes de LAB_INFO
#     - VARIANT (string): Salida de select_variant()

# FUNCIÓN: run_lab(ID, TEMPLATE, LEVEL)
#   Parámetros:
#     - ID (string): Identificador del lab (ej: "J01")
#     - TEMPLATE (string): Path completo al archivo variant_*.yml
#     - LEVEL (string): Nivel del lab
#   Variables locales CRÍTICAS:
#     - ISO_PATH (string): Ruta de la ISO generada por cloudinit_generator.sh
#     - VM_NAME (string): Nombre único de VM: "lab-{ID}-{timestamp}"
#     - VM_IMG (string): Path del overlay qcow2: /mnt/vms/labs/tmp/{VM_NAME}.qcow2
#   Nota: Esta función maneja el CICLO COMPLETO de creación de VM

# -----------------------------------------------------------------
# 4. VARIABLES DE CONFIGURACIÓN HARDCODED
# -----------------------------------------------------------------
# PATHS ABSOLUTOS (configuración del entorno MX Linux + KVM):
#   - Imagen base: "/mnt/vms/rocky-ir-base-junior-v1.qcow2"
#   - Directorio temporal VMs: "/mnt/vms/labs/tmp/"
#   - Directorio temporal ISOs: "/tmp/" (implícito en cloudinit_generator.sh)

# PARÁMETROS DE VIRT-INSTALL (hardcoded en run_lab()):
#   --memory 2048 --vcpus 2
#   --os-variant rhel9.0
#   --boot uefi
#   --network network=default
#   --graphics vnc,listen=0.0.0.0

# -----------------------------------------------------------------
# 5. VARIABLES DE ESTADO EN FUNCIONES DE GESTIÓN
# -----------------------------------------------------------------
# FUNCIÓN: manage_single_vm(VM_NAME)
#   Parámetro: VM_NAME (string) - Nombre de la VM a gestionar
#   Variables locales:
#     - STATE (string): Estado de VM ("running", "shut off", etc.)
#     - IP (string): Dirección IP asignada o "no-ip"
#     - opt (string): Opción seleccionada por usuario en submenú

# FUNCIÓN: cleanup_vm(VM_NAME)
#   Parámetro: VM_NAME (string) - Nombre de la VM a eliminar
#   Nota: Elimina VM, definición libvirt, storage asociado e ISO

# -----------------------------------------------------------------
# 6. VARIABLES DE INTERACCIÓN CON USUARIO
# -----------------------------------------------------------------
# option (main_menu)
#   Descripción: Opción numérica del menú principal (1,2,3,0)
#   Tipo: string (capturada por read)

# opt (manage_single_vm)
#   Descripción: Opción numérica del submenú de gestión VM (1-4,0)
#   Tipo: string (capturada por read)

# -----------------------------------------------------------------
# 7. FLUJO DE DATOS ENTRE VARIABLES (REAL)
# -----------------------------------------------------------------
# SECUENCIA TÍPICA:
#   1. load_db() → llena array global LABS
#   2. select_lab_by_level("Junior") → devuelve "J01|Junior|scenarios/junior/J01"
#   3. select_variant("scenarios/junior/J01") → devuelve "/ruta/variant_1.yml"
#   4. run_lab("J01", "/ruta/variant_1.yml", "Junior") → crea VM
#   5. Variables dentro run_lab:
#       ISO_PATH = (generada por cloudinit_generator.sh)
#       VM_NAME = "lab-J01-20240115-143022"
#       VM_IMG = "/mnt/vms/labs/tmp/lab-J01-20240115-143022.qcow2"

#==============================================================================
# DISEÑO ARQUITECTÓNICO IMPLEMENTADO
#==============================================================================

# 1. PATRÓN: Modelo de datos en array asociativo simple
#    - LABS: Array indexado con strings delimitados por "|"
#    - Ventaja: Simple, sin dependencias externas
#    - Desventaja: Parsing manual con IFS en cada lectura

# 2. PATRÓN: Paso de datos via stdout/stderr
#    - select_lab_by_level: echo "ID|LEVEL|PATH"
#    - select_variant: echo "/ruta/completa/variant_X.yml"
#    - Las funciones llamantes capturan con $(...)

# 3. PATRÓN: Rutas absolutas consistentes
#    - Todas las rutas se convierten a absolutas al inicio
#    - Uso de $(cd ... && pwd) evita problemas con rutas relativas

# 4. PATRÓN: Separación clara de responsabilidades
#    - load_db: Solo carga datos
#    - select_lab_by_level: Lógica de selección + actualización DB
#    - select_variant: Selección aleatoria de variante
#    - run_lab: Orquestación completa de creación VM
#    - manage_single_vm: Gestión post-creación

# 5. PATRÓN: Nombrado consistente de recursos
#    - VM_NAME: "lab-{ID}-{timestamp}"
#    - VM_IMG: "/mnt/vms/labs/tmp/{VM_NAME}.qcow2"
#    - ISO: "/tmp/{VM_NAME}-seed.iso" (generada por cloudinit_generator.sh)

#==============================================================================
# FIN DE DOCUMENTACIÓN ACTUALIZADA
#==============================================================================


set -euo pipefail

#==============================================================================
# CONSTANTES GLOBALES
#==============================================================================
ENGINE_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$ENGINE_DIR/.." && pwd)"
DB_FILE="$ENGINE_DIR/labs.db"
LABS=()

#==============================================================================
# FUNCIONES DE CARGA DE LABS
#==============================================================================
load_db() {
    LABS=()

    if [[ ! -f "$DB_FILE" || ! -s "$DB_FILE" ]]; then
        echo "❌ ERROR: Base de datos inexistente o vacía: $DB_FILE" >&2
        exit 1
    fi

    while IFS='|' read -r ID LEVEL PATH USES; do
        [[ "$ID" == "ID" ]] && continue   # saltar header si existe
        LABS+=("$ID|$LEVEL|$PATH|$USES")
    done < "$DB_FILE"

    echo "✅ DB cargada: ${#LABS[@]} laboratorios"
}



#==============================================================================
# FUNCION DE LECTURA DE LAB POR NIVEL Y SELECCIÓN
#==============================================================================
select_lab_by_level() {
    echo "=== ENTRANDO A select_lab_by_level ===" >&2
    echo "Parámetro recibido: '$1'" >&2
    
    local LEVEL="$1"
    local FILTERED=()
    local MIN_USES=""
    local CANDIDATES=()
    local ID LAB_LEVEL LAB_PATH USES  # ✅ Locales para parseo

    echo "=== DEBUG START ==="
    echo "Buscando nivel: '$LEVEL'"
    echo "Total LABS: ${#LABS[@]}"
    
    # 1. Filtrar por nivel
    for LAB in "${LABS[@]}"; do
        IFS='|' read -r ID LAB_LEVEL PATH USES <<< "$LAB"
        echo "Lab: ID=$ID, LEVEL='$LAB_LEVEL', PATH='$PATH', USES=$USES"
        
        # Comparación insensible a mayúsculas
        if [[ "${LAB_LEVEL,,}" == "${LEVEL,,}" ]]; then
            FILTERED+=("$LAB")
            echo "  ✓ COINCIDE - Agregado a FILTERED"
        else
            echo "  ✗ NO coincide"
        fi
    done
    
    echo "FILTERED encontrados: ${#FILTERED[@]}"
    echo "=== DEBUG END ==="

    if [[ ${#FILTERED[@]} -eq 0 ]]; then
        echo "❌ No hay labs para nivel $LEVEL" >&2
        return 1
    fi

    # 2. Encontrar mínimo USES
    for LAB in "${FILTERED[@]}"; do
        IFS='|' read -r _ _ _ USES <<< "$LAB"
        [[ -z "$MIN_USES" || "$USES" -lt "$MIN_USES" ]] && MIN_USES="$USES"
    done

    # 3. Candidatos con mínimo USES
    for LAB in "${FILTERED[@]}"; do
        IFS='|' read -r _ _ _ USES <<< "$LAB"
        [[ "$USES" -eq "$MIN_USES" ]] && CANDIDATES+=("$LAB")
    done

    echo "DEBUG: CANDIDATES count = ${#CANDIDATES[@]}"
    echo "DEBUG: CANDIDATES = ${CANDIDATES[*]}"
    
    # 4. Elegir aleatoriamente
    if [[ ${#CANDIDATES[@]} -eq 0 ]]; then
        echo "ERROR: No hay candidatos para seleccionar" >&2
        return 1
    fi
    
    local SELECTED_LAB="${CANDIDATES[RANDOM % ${#CANDIDATES[@]}]}"
    echo "DEBUG: SELECTED_LAB = $SELECTED_LAB"

    # ✅ 5. AHORA parsear PRIMERO → luego update
    IFS='|' read -r ID LAB_LEVEL LAB_PATH USES <<< "$SELECTED_LAB"

    # 6. Incrementar USES y persistir
    update_lab_uses "$ID" "$((USES + 1))"

    # 7. Devolver datos
    echo "$ID|$LAB_LEVEL|$LAB_PATH"
}


#==============================================================================
# FUNCION DE ACTUALIZACIÓN DE LAB USAGES
#==============================================================================
update_lab_uses() {
    local TARGET_ID="$1"
    local NEW_USES="$2"
    local TMP_DB

    TMP_DB="$(mktemp)"

    # ✅ Backup original DB antes de sobrescribir
    cp "$DB_FILE" "$TMP_DB"

    while IFS='|' read -r ID LEVEL PATH USES; do
        [[ "$ID" == "ID" ]] && continue  # ✅ Salta header como load_db()
        if [[ "$ID" == "$TARGET_ID" ]]; then
            echo "$ID|$LEVEL|$PATH|$NEW_USES" >> "$TMP_DB"
        else
            echo "$ID|$LEVEL|$PATH|$USES" >> "$TMP_DB"
        fi
    done < "$DB_FILE"

    mv "$TMP_DB" "$DB_FILE"
    echo "✅ Updated uses for $TARGET_ID → $NEW_USES" >&2
}



#==============================================================================
# FUNCION DE SELECCIÓN DE VARIANTE
#==============================================================================
select_variant() {
    local LAB_PATH="$1"
    local VARIANT_DIR="$ROOT_DIR/$LAB_PATH"

    if [[ ! -d "$VARIANT_DIR" ]]; then
        echo "❌ No existe directorio de variantes: $VARIANT_DIR" >&2
        return 1
    fi

    VARIANTS=($(find "$VARIANT_DIR" -name "variant_*.yml" 2>/dev/null))


    if [[ ${#VARIANTS[@]} -eq 0 ]]; then
        echo "❌ No hay variantes en $VARIANT_DIR" >&2
        return 1
    fi

    echo "${VARIANTS[RANDOM % ${#VARIANTS[@]}]}"
}

#==============================================================================
# FUNCION DE ASIGNACIÓN DE LAB (CON CHECKPOINTS)
#==============================================================================
assign_lab() {
    echo "🚀 [assign_lab] >>> INICIANDO <<<" >&2
    
    local LEVEL="$1"
    echo "📍 [1/7] Recibido parámetro LEVEL='$LEVEL'" >&2
    
    # Limpiar espacios
    LEVEL="${LEVEL//[[:space:]]/}"
    echo "📍 [2/7] LEVEL limpio = '$LEVEL'" >&2
    
    local ORIGINAL_LEVEL="$LEVEL"

    echo "📍 [3/7] Llamando load_db()..." >&2
    load_db
    echo "📍 [3/7] load_db() TERMINADO - LABS=${#LABS[@]}" >&2
    
    echo "📍 [4/7] === LLAMANDO select_lab_by_level '$ORIGINAL_LEVEL' ===" >&2
    
    # ✅ FIX 1: NOMBRE CORRECTO + ORIGINAL_LEVEL
    LAB_INFO="$(select_lab_by_level "$ORIGINAL_LEVEL" 2>&1)"
    local RET_CODE=$?
    
    # ✅ FIX 2: Usa LAB_INFO (no LLAB_INFO)
    echo "📍 [4/7] select_lab_by_level RETORNÓ CODE=$RET_CODE" >&2
    echo "📍 [4/7] LAB_INFO capturado = '$LAB_INFO'" >&2
    
    if [[ $RET_CODE -ne 0 ]]; then
        echo "💥 [4/7] ERROR en select_lab_by_level" >&2
        echo "💥 [4/7] Salida fue: $LAB_INFO" >&2
        return 1
    fi
    echo "✅ [4/7] === select_lab_by_level COMPLETADO ===" >&2

    # ✅ FIX 3: Ya existe LAB_INFO válido
    echo "📍 [5/7] Parseando LAB_INFO='$LAB_INFO'" >&2
    IFS='|' read -r ID LAB_LEVEL LAB_PATH <<< "$LAB_INFO"
    echo "📍 [5/7] EXTRAÍDO → ID='$ID' LAB_LEVEL='$LAB_LEVEL' LAB_PATH='$LAB_PATH'" >&2
    
    if [[ -z "$ID" || -z "$LAB_PATH" ]]; then
        echo "💥 [5/7] ERROR: ID o LAB_PATH vacío" >&2
        return 1
    fi
    echo "✅ [5/7] Parseo correcto" >&2

    echo "📍 [6/7] Llamando select_variant('$LAB_PATH')" >&2
    VARIANT="$(select_variant "$LAB_PATH")"
    local RET_VARIANT=$?
    echo "📍 [6/7] select_variant RETORNÓ CODE=$RET_VARIANT" >&2
    echo "📍 [6/7] VARIANT='$VARIANT'" >&2
    
    if [[ $RET_VARIANT -ne 0 || -z "$VARIANT" ]]; then
        echo "💥 [6/7] ERROR en select_variant" >&2
        return 1
    fi

    echo "📍 [7/7] 🚀 LLAMANDO run_lab('$ID', '$VARIANT', '$LAB_LEVEL')" >&2
    run_lab "$ID" "$VARIANT" "$LAB_LEVEL"
    
    echo "🚀 [assign_lab] >>> COMPLETADO <<<" >&2
}



#==============================================================================
# FUNCION DE EJECUCIÓN DE LAB
#==============================================================================
run_lab() {
    local ID="$1" TEMPLATE="$2" LEVEL="$3"
    
    echo "🚀 LAB: $ID ($LEVEL)"
    echo "═══════════════════════"
    
    # 1. ISO
    echo "🔨 [1/5] ISO..."
    local ISO_PATH=$(bash "$ENGINE_DIR/cloudinit_generator.sh" "$LEVEL" "$ID" "$TEMPLATE")
    echo "✅ [1/5] $ISO_PATH"
    
    # 2. VM
    local VM_NAME="lab-${ID}-$(date +%Y%m%d-%H%M%S)"
    local VM_IMG="/mnt/vms/labs/tmp/${VM_NAME}.qcow2"
    
    echo "🔧 [2/5] Overlay..."
    mkdir -p /mnt/vms/labs/tmp
    qemu-img create -f qcow2 -F qcow2 -b "/mnt/vms/rocky-ir-base-junior-v1.qcow2" "$VM_IMG"
    echo "✅ [2/5] $VM_IMG"
    
    # 3. VM
    echo "🎮 [3/5] Creando VM..."
    sudo virt-install \
        --name "$VM_NAME" \
        --memory 2048 --vcpus 2 \
        --disk path="$VM_IMG",format=qcow2,bus=virtio \
        --disk path="$ISO_PATH",device=cdrom \
        --import \
        --os-variant rhel9.0 \
        --boot uefi \
        --network network=default \
        --graphics vnc,listen=0.0.0.0 \
        --video virtio \
        --noautoconsole || echo "⚠️  Warning normal"
    
    echo "✅ [3/5] VM '$VM_NAME' CREADA!"
    
    # 4. Espera arranque
    sleep 5
    STATE=$(sudo virsh domstate "$VM_NAME" 2>/dev/null || echo "starting")
    if [[ "$STATE" == "running" ]]; then
        echo "✅ [4/5] VM RUNNING!"
    else
        echo "🚀 [4/5] Estado: $STATE (arrancando...)"
    fi
    
    # 5. INFO CONEXIÓN + VOLVER AL MENÚ (SIN CLEANUP)
    echo ""
    echo "🔗 ===== VM ACTIVA Y LISTA ====="
    echo "VM: $VM_NAME"
    echo "VNC: $(sudo virsh vncdisplay "$VM_NAME" 2>/dev/null || echo 'starting...')"
    IP=$(sudo virsh domifaddr "$VM_NAME" 2>/dev/null | awk 'NR>1{print $4}' || echo 'booting...')
    echo "IP: $IP"
    echo ""
    echo "💡 VM queda CORRIENDO → Opción 5) Gestión VMs para administrar"
    echo "💡 ISO queda en: $(dirname "$ISO_PATH")"
    echo ""
    
    echo ""
    echo "➡️  Entrando en gestión directa de la VM..."
    sleep 1

    manage_single_vm "$VM_NAME"

} 


#==============================================================================
# FUNCION DEL MENÚ PRINCIPAL
#==============================================================================
main_menu() {
    while true; do
        printf "\033c"
        echo "================================================"
        echo " INCIDENT RESPONSE LAB ENGINE v1.1"
        echo "================================================"
        echo " Base VM: rocky-ir-base-junior-v1.qcow2"
        echo
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
            0)
                echo "Saliendo del Lab Engine..."
                exit 0
                ;;
            *)
                echo "❌ Opción inválida"
                sleep 1
                ;;
        esac
    done
}



#==============================================================================
# FUNCION DE GESTIÓN DIRECTA POST-CREACIÓN DE VM
#==============================================================================
manage_single_vm() {
    local VM_NAME="$1"

    while true; do
        printf "\033c"
        STATE=$(sudo virsh domstate "$VM_NAME" 2>/dev/null || echo "unknown")
        IP=$(sudo virsh domifaddr "$VM_NAME" 2>/dev/null | awk 'NR>1{print $4}' || echo "no-ip")

        echo "=============================================="
        echo " GESTIÓN DE VM ACTIVA"
        echo "=============================================="
        echo " VM    : $VM_NAME"
        echo " Estado: $STATE"
        echo " IP    : $IP"
        echo
        echo "1) Reiniciar VM"
        echo "2) Parar VM"
        echo "3) Prender VM"
        echo "4) Eliminar VM (TOTAL)"
        echo "0) Volver al menú principal"
        echo
        read -rp "Opción: " opt

        case "$opt" in
            1)
                echo "🔄 Reiniciando VM..."
                sudo virsh reboot "$VM_NAME" >/dev/null 2>&1
                sleep 2
                ;;
            2)
                echo "⏹️  Parando VM..."
                sudo virsh shutdown "$VM_NAME" >/dev/null 2>&1
                sleep 3
                ;;
            3)
                echo "▶️  Encendiendo VM..."
                sudo virsh start "$VM_NAME" >/dev/null 2>&1
                sleep 2
                ;;
            4)
                echo "⚠️  Eliminando VM completamente..."
                cleanup_vm "$VM_NAME"
                echo "✅ VM eliminada sin residuos"
                sleep 2
                return 0   # ← vuelve al menú principal
                ;;
            0)
                return 0
                ;;
            *)
                echo "❌ Opción inválida"
                sleep 1
                ;;
        esac
    done
}




#==============================================================================
# FUNCION DE LIMPIEZA DE VM
#==============================================================================
cleanup_vm() {
    local VM_NAME="$1"

    echo "[CLEANUP] Apagando VM si está activa..."
    virsh destroy "$VM_NAME" >/dev/null 2>&1 || true

    echo "[CLEANUP] Eliminando definición y storage..."
    virsh undefine "$VM_NAME" --remove-all-storage >/dev/null 2>&1 || true

    echo "[CLEANUP] Limpiando ISOs cloud-init..."
    rm -f /mnt/vms/labs/tmp/"${VM_NAME}.qcow2" 2>/dev/null || true
    rm -f "/tmp/${VM_NAME}-seed.iso" 2>/dev/null || true

    echo "[CLEANUP] Cleanup completo"
}



#==============================================================================
# INICIO
#==============================================================================
echo "🚀 Incident Response Lab Engine v1.1"
load_db
while true; do main_menu; done
