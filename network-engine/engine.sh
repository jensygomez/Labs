#!/bin/bash
# network-engine/engine.sh
# Motor principal - Carga dinámica y modular

set -Eeo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🚀 Iniciando engine..." >&2

# ==============================================================================
# FUNCIONES AUXILIARES
# ==============================================================================

# Cargador genérico con validación
load_component() {
  local file="$1"
  local required="${2:-true}"  # Por defecto es requerido
  
  if [[ -f "$BASE_DIR/$file" ]]; then
    source "$BASE_DIR/$file"
    return 0
  else
    if [[ "$required" == "true" ]]; then
      echo "❌ ERROR CRÍTICO: No se encuentra $file" >&2
      exit 1
    else
      [[ -n "$DEBUG" ]] && echo "⚠️  Archivo opcional no encontrado: $file" >&2
      return 1
    fi
  fi
}

# Cargador de directorio completo
load_directory() {
  local dir="$1"
  local base_first="${2:-true}"  # Cargar base.conf primero
  local pattern="${3:-*.sh}"      # Patrón de archivos
  
  [[ ! -d "$BASE_DIR/$dir" ]] && return 0
  
  # Contar archivos para mostrar progreso
  local total_files=$(find "$BASE_DIR/$dir" -maxdepth 1 -name "$pattern" | wc -l)
  [[ $total_files -eq 0 ]] && return 0
  
  [[ -n "$DEBUG" ]] && echo "📂 Cargando $dir/ ($total_files archivos)..." >&2
  
  # Cargar base.conf primero si existe y se solicita
  if [[ "$base_first" == "true" ]] && [[ -f "$BASE_DIR/$dir/base.conf" ]]; then
    [[ -n "$DEBUG" ]] && echo "   • base.conf" >&2
    source "$BASE_DIR/$dir/base.conf"
  fi
  
  # Cargar todos los demás archivos
  for file in "$BASE_DIR/$dir"/$pattern; do
    [[ ! -f "$file" ]] && continue
    [[ "$(basename "$file")" == "base.conf" ]] && continue
    
    [[ -n "$DEBUG" ]] && echo "   • $(basename "$file")" >&2
    source "$file"
  done
}

# ==============================================================================
# 1. CONFIGURACIÓN BASE
# ==============================================================================
echo "📋 Cargando configuración de topología..." >&2

load_component "topology/lab.conf"

# ==============================================================================
# 2. ESTRUCTURAS GLOBALES
# ==============================================================================
# Declarar arrays asociativos ANTES de cargar las configuraciones

declare -A FW_ZONES
declare -A FW_POLICIES
declare -A FW_RULES
declare -A FW_FORWARD
declare -a FW_NAMESPACES

# ==============================================================================
# 3. CONFIGURACIONES DECLARATIVAS
# ==============================================================================
# Estas son cargadas por lab.conf, pero podemos cargarlas explícitamente
# si queremos un orden específico

[[ -n "$DEBUG" ]] && echo "📦 Configuraciones declarativas cargadas por lab.conf" >&2

# Si necesitas forzar orden específico, descomenta y ajusta:
# load_directory "topology/firewall" "true" "*.conf"
# load_directory "topology/routing" "true" "*.conf"
# load_directory "topology/vlans" "true" "*.conf"

# ==============================================================================
# 4. GUARDIA DE SEGURIDAD
# ==============================================================================
load_component "lib/guard.sh"
require_root
echo "🔍 Privilegios de root verificados." >&2

# ==============================================================================
# 5. LIBRERÍAS DE FUNCIONES (CARGA DINÁMICA)
# ==============================================================================
echo "📚 Cargando librerías..." >&2

# Cargar librerías principales (excluyendo subdirectorios)
for lib in "$BASE_DIR"/lib/*.sh; do
  [[ ! -f "$lib" ]] && continue
  
  lib_name=$(basename "$lib")
  [[ -n "$DEBUG" ]] && echo "   • $lib_name" >&2
  source "$lib"
done

# Cargar módulos de servicios (subdirectorio lib/services/)
if [[ -d "$BASE_DIR/lib/services" ]]; then
  [[ -n "$DEBUG" ]] && echo "   📦 Módulos de servicios:" >&2
  for service_module in "$BASE_DIR"/lib/services/*.sh; do
    [[ ! -f "$service_module" ]] && continue
    [[ -n "$DEBUG" ]] && echo "      • $(basename "$service_module")" >&2
    # No hacer source aquí - se cargan bajo demanda por services.sh
  done
fi

# ==============================================================================
# 6. EJECUCIÓN DE FASES (ORDEN NUMÉRICO)
# ==============================================================================
echo "🔧 Ejecutando fases..." >&2

# Obtener fases ordenadas numéricamente
phases=($(ls -v "$BASE_DIR"/phases/*.sh 2>/dev/null))

if [[ ${#phases[@]} -eq 0 ]]; then
  echo "❌ No se encontraron fases en phases/" >&2
  exit 1
fi

for phase in "${phases[@]}"; do
  [[ ! -f "$phase" ]] && continue
  
  phase_name=$(basename "$phase")
  echo "📦 Ejecutando fase: $phase_name" >&2
  
  source "$phase"
  
  # Verificar que la fase define run_phase
  if ! declare -f run_phase >/dev/null; then
    echo "⚠️  ADVERTENCIA: $phase_name no define run_phase()" >&2
    continue
  fi
  
  # Ejecutar la fase
  if ! run_phase; then
    echo "❌ ERROR en fase $phase_name" >&2
    exit 1
  fi
  
  # Limpiar función para siguiente fase
  unset -f run_phase 2>/dev/null || true
done

# ==============================================================================
# 7. FINALIZACIÓN
# ==============================================================================
echo "✅ Topología convergida completamente" >&2