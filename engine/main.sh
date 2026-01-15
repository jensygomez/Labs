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
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

check_env() {
    [[ -z "${PATH:-}" ]] && {
        echo "❌ PATH CORRUPTO — abortando"
        exit 99
    }
}


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

    # --- Validación del archivo DB ---
    if [[ ! -f "$DB_FILE" || ! -s "$DB_FILE" ]]; then
        echo "❌ ERROR: Base de datos inexistente o vacía: $DB_FILE" >&2
        exit 1
    fi

    # --- Carga segura de registros ---
    while IFS='|' read -r ID LEVEL LAB_PATH USES; do
        # Saltar header
        [[ "$ID" == "ID" ]] && continue

        # --- Validaciones estrictas ---
        [[ -z "$ID" || -z "$LEVEL" || -z "$LAB_PATH" || -z "$USES" ]] && {
            echo "❌ DB corrupta: campos vacíos → '$ID|$LEVEL|$LAB_PATH|$USES'" >&2
            exit 2
        }

        [[ ! "$USES" =~ ^[0-9]+$ ]] && {
            echo "❌ DB corrupta: USES no numérico para $ID → '$USES'" >&2
            exit 3
        }

        [[ "$LAB_PATH" == *":"* ]] && {
            echo "❌ DB corrupta: LAB_PATH parece PATH del sistema para $ID → '$LAB_PATH'" >&2
            exit 4
        }

        LABS+=("$ID|$LEVEL|$LAB_PATH|$USES")

    done < "$DB_FILE"

    echo "✅ DB cargada correctamente: ${#LABS[@]} laboratorios" >&2
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
    local ID LAB_LEVEL LAB_PATH USES

    echo "Buscando nivel: '$LEVEL'" >&2
    echo "Total LABS: ${#LABS[@]}" >&2
    
    # 1. Filtrar por nivel
    for LAB in "${LABS[@]}"; do
        IFS='|' read -r ID LAB_LEVEL LAB_PATH USES <<< "$LAB"
        echo "Lab: ID=$ID, LEVEL='$LAB_LEVEL', PATH='$LAB_PATH', USES=$USES" >&2
        
        if [[ "${LAB_LEVEL,,}" == "${LEVEL,,}" ]]; then
            FILTERED+=("$LAB")
            echo "  ✓ COINCIDE - Agregado a FILTERED" >&2
        else
            echo "  ✗ NO coincide" >&2
        fi
    done

    echo "FILTERED encontrados: ${#FILTERED[@]}" >&2

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

    echo "CANDIDATES count = ${#CANDIDATES[@]}" >&2
    echo "CANDIDATES = ${CANDIDATES[*]}" >&2

    if [[ ${#CANDIDATES[@]} -eq 0 ]]; then
        echo "ERROR: No hay candidatos para seleccionar" >&2
        return 1
    fi

    local SELECTED_LAB="${CANDIDATES[RANDOM % ${#CANDIDATES[@]}]}"
    echo "SELECTED_LAB = $SELECTED_LAB" >&2

    IFS='|' read -r ID LAB_LEVEL LAB_PATH USES <<< "$SELECTED_LAB"

    update_lab_uses "$ID" "$((USES + 1))"

    # ✔️ ÚNICA salida por stdout
    echo "$ID|$LAB_LEVEL|$LAB_PATH"


}

#==============================================================================
# FUNCION DE ACTUALIZACIÓN DE LAB USAGES (0 DEPENDENCIAS)
#==============================================================================
update_lab_uses() {
    local TARGET_ID="$1"
    local NEW_USES="$2"

    awk -F'|' -v OFS='|' -v id="$TARGET_ID" -v uses="$NEW_USES" '
        NR==1 { print; next }
        $1==id { $4=uses }
        { print }
    ' "$DB_FILE" > "${DB_FILE}.tmp" && mv "${DB_FILE}.tmp" "$DB_FILE"

    echo "✅ Updated uses for $TARGET_ID → $NEW_USES" >&2
}


#==============================================================================
# FUNCION DE SELECCIÓN DE VARIANTE
#==============================================================================
select_variant() {
    local LAB_PATH="$1"
    local VARIANT_DIR="$ROOT_DIR/$LAB_PATH"
    local -a VARIANTS=()

    if [[ ! -d "$VARIANT_DIR" ]]; then
        echo "❌ No existe directorio de variantes: $VARIANT_DIR" >&2
        return 1
    fi

    # Bash puro: globbing seguro
    shopt -s nullglob
    VARIANTS=("$VARIANT_DIR"/variant_*.yml)
    shopt -u nullglob

    if [[ ${#VARIANTS[@]} -eq 0 ]]; then
        echo "❌ No hay variantes en $VARIANT_DIR" >&2
        return 1
    fi

    # stdout limpio
    echo "${VARIANTS[RANDOM % ${#VARIANTS[@]}]}"
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
# INICIO
#==============================================================================
echo "🚀 Incident Response Lab Engine v1.1"
load_db
while true; do main_menu; done

