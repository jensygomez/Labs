#!/bin/bash
# ==============================================================================
# CLOUD-INIT GENERATOR v2.0 - CON PARSER DE VARIANTES
# ==============================================================================
# Uso: cloudinit_generator.sh <LEVEL> <LAB_ID> <TEMPLATE_YAML>
# 
# CAMBIOS PRINCIPALES:
# 1. Lee y parsea el YAML de variante ($3)
# 2. Genera cloud-init personalizado basado en la variante
# 3. Mantiene compatibilidad con interfaz original
# ==============================================================================

set -euo pipefail

# ========== PARÁMETROS ==========
LEVEL="$1"          # Ej: "junior"
LAB_ID="$2"         # Ej: "J01" 
TEMPLATE_YAML="$3"  # Ruta completa al YAML de variante (ej: scenarios/junior/J01/variant_1.yml)

# ========== VERIFICACIONES INICIALES ==========
if [[ ! -f "$TEMPLATE_YAML" ]]; then
    echo "❌ ERROR: Template YAML no encontrado: $TEMPLATE_YAML" >&2
    exit 1
fi

if ! mountpoint -q "/mnt/vms"; then
    echo "❌ ERROR: /mnt/vms no montado. Verifica: mount /dev/sdb1 /mnt/vms" >&2
    exit 1
fi

# ========== PARSER DE YAML (MINIMALISTA) ==========
# Extrae valores simples de un YAML básico
parse_yaml_value() {
    local key="$1"
    # Busca "key: valor" ignorando espacios y comentarios
    grep -E "^[[:space:]]*${key}:[[:space:]]+" "$TEMPLATE_YAML" | \
        head -1 | \
        sed "s/^[[:space:]]*${key}:[[:space:]]*//" | \
        sed 's/[[:space:]]*$//' | \
        sed 's/^"//' | sed 's/"$//' | sed "s/^'//" | sed "s/'$//"
}

# Extrae lista bajo una clave (ej: servicios habilitados)
parse_yaml_list() {
    local key="$1"
    local in_section=0
    local items=()
    
    while IFS= read -r line; do
        # Inicio de sección
        if [[ "$line" =~ ^[[:space:]]*${key}:[[:space:]]*$ ]]; then
            in_section=1
            continue
        fi
        
        # Fuera de sección
        [[ "$line" =~ ^[^[:space:]#] ]] && in_section=0
        
        # Dentro de sección, línea con item
        if [[ $in_section -eq 1 ]] && [[ "$line" =~ ^[[:space:]]*-[[:space:]]+ ]]; then
            local item=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//' | sed 's/[[:space:]]*$//' | sed 's/^"//' | sed 's/"$//')
            [[ -n "$item" ]] && items+=("$item")
        fi
    done < "$TEMPLATE_YAML"
    
    # Retornar como string separado por espacios (para array bash)
    echo "${items[@]}"
}

# Extrae comandos de error
parse_error_commands() {
    local in_errors=0
    local in_commands=0
    local commands=()
    
    while IFS= read -r line; do
        # Entrar en sección errors
        if [[ "$line" =~ ^[[:space:]]*errors:[[:space:]]*$ ]]; then
            in_errors=1
            continue
        fi
        
        # Dentro de errors, buscar commands
        if [[ $in_errors -eq 1 ]] && [[ "$line" =~ ^[[:space:]]*commands:[[:space:]]*$ ]]; then
            in_commands=1
            continue
        fi
        
        # Salir si encontramos nueva sección principal
        [[ "$line" =~ ^[^[:space:]] && ! "$line" =~ ^[[:space:]] ]] && [[ ! "$line" =~ errors: ]] && in_errors=0
        
        # Dentro de commands, extraer comandos
        if [[ $in_commands -eq 1 ]]; then
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+ ]]; then
                local cmd=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//' | sed 's/[[:space:]]*$//' | sed 's/^"//' | sed 's/"$//')
                [[ -n "$cmd" ]] && commands+=("$cmd")
            elif [[ "$line" =~ ^[[:space:]]*[^[:space:]-] ]]; then
                # Fin de la lista de commands
                break
            fi
        fi
    done < "$TEMPLATE_YAML"
    
    # Retornar como array
    if [[ ${#commands[@]} -gt 0 ]]; then
        printf '%s\n' "${commands[@]}"
    fi
}

# ========== EXTRAER DATOS DEL TEMPLATE ==========
echo "🔍 Parseando template: $(basename "$TEMPLATE_YAML")"

# Información básica
VARIANT_ID=$(parse_yaml_value "variant_id" || echo "1")
LAB_TITLE=$(parse_yaml_value "title" || echo "Lab ${LAB_ID}")

# Servicios a habilitar
SERVICES_ENABLED=($(parse_yaml_list "enabled"))
if [[ ${#SERVICES_ENABLED[@]} -eq 0 ]]; then
    # Valor por defecto si no se especifica
    SERVICES_ENABLED=("nginx" "firewalld")
fi

# VIPs (búsqueda simple)
VIP_IP=$(grep -o '192\.168\.122\.[0-9]\+' "$TEMPLATE_YAML" | head -1)

# Comandos de error
ERROR_COMMANDS=()
while IFS= read -r cmd; do
    ERROR_COMMANDS+=("$cmd")
done < <(parse_error_commands)

# ========== PREPARAR DIRECTORIO ==========
VMS_TMP_DIR="/mnt/vms/labs/tmp/${LEVEL}_${LAB_ID}_v${VARIANT_ID}_$(date +%s)"
mkdir -p "$VMS_TMP_DIR"
ISO_PATH="$VMS_TMP_DIR/${LAB_ID}_v${VARIANT_ID}_nocloud.iso"

echo "📦 Configuración extraída:"
echo "   - Variante: $VARIANT_ID"
echo "   - Título: $LAB_TITLE"
echo "   - Servicios a habilitar: ${SERVICES_ENABLED[*]}"
echo "   - VIP: ${VIP_IP:-No asignada}"
echo "   - Comandos de error: ${#ERROR_COMMANDS[@]}"

# ========== GENERAR USER-DATA (CLOUD-CONFIG) ==========
echo "🔨 Generando cloud-init personalizado..."

cat > "$VMS_TMP_DIR/user-data" <<EOF
#cloud-config
# ===================================================
# LAB: $LAB_ID - Variante $VARIANT_ID
# $LAB_TITLE
# Generado: $(date)
# ===================================================

hostname: ${LAB_ID}-v${VARIANT_ID}

# Usuario de administración
users:
  - name: jensy
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin, wheel
    shell: /bin/bash
    lock_passwd: false
    passwd: $(openssl passwd -6 "1234")
    ssh_authorized_keys:
      - $(cat /home/jensy/Labs/.ssh/id_rhcsalabs.pub 2>/dev/null || echo "ssh-rsa AAA...")

# Configuración de red (bootcmd se ejecuta temprano)
bootcmd:
EOF

# Agregar VIP si está especificada
if [[ -n "$VIP_IP" ]]; then
    cat >> "$VMS_TMP_DIR/user-data" <<EOF
  - |
    echo "Asignando VIP: $VIP_IP"
    nmcli connection modify "enp1s0" +ipv4.addresses $VIP_IP/24
    nmcli connection down "enp1s0"
    nmcli connection up "enp1s0"
EOF
else
    echo "  - echo 'Sin VIP asignada para este lab'" >> "$VMS_TMP_DIR/user-data"
fi

# Comandos de ejecución (runcmd)
cat >> "$VMS_TMP_DIR/user-data" <<EOF

# Configuración del sistema (runcmd se ejecuta después de boot)
runcmd:
  # 1. Habilitar servicios requeridos
EOF

# Habilitar cada servicio especificado
for service in "${SERVICES_ENABLED[@]}"; do
    case "$service" in
        nginx|mariadb|haproxy|firewalld)
            echo "  - systemctl enable --now $service" >> "$VMS_TMP_DIR/user-data"
            ;;
        *)
            echo "  - echo 'Servicio $service no es estándar, verificando...'" >> "$VMS_TMP_DIR/user-data"
            echo "  - systemctl enable --now $service 2>/dev/null || echo 'Servicio $service no encontrado'" >> "$VMS_TMP_DIR/user-data"
            ;;
    esac
done

# Agregar comandos de error si existen
if [[ ${#ERROR_COMMANDS[@]} -gt 0 ]]; then
    echo "  # 2. Aplicar errores/configuraciones específicas" >> "$VMS_TMP_DIR/user-data"
    for cmd in "${ERROR_COMMANDS[@]}"; do
        echo "  - $cmd" >> "$VMS_TMP_DIR/user-data"
    done
fi

# Información para el estudiante
cat >> "$VMS_TMP_DIR/user-data" <<EOF

  # 3. Crear archivo de información del lab
  - |
    cat > /root/lab_info.txt <<'EOL'
==========================================
INCIDENT RESPONSE LAB
==========================================
LAB: $LAB_ID
VARIANTE: $VARIANT_ID
FECHA: $(date)
HOSTNAME: ${LAB_ID}-v${VARIANT_ID}
IP ADMIN: 192.168.122.20
${VIP_IP:+VIP SERVICIO: $VIP_IP}

SERVICIOS ACTIVOS: ${SERVICES_ENABLED[*]}

INSTRUCCIONES:
1. Conéctate via SSH: ssh jensy@192.168.122.20
2. Investiga el problema reportado
3. Usa los comandos de diagnóstico apropiados

NOTA: Esta VM tiene configuraciones específicas para
simular un incidente real de respuesta a emergencias.
EOL

  # 4. Asegurar permisos y limpieza
  - chmod 644 /root/lab_info.txt
  - echo "Lab $LAB_ID-v$VARIANT_ID listo para diagnóstico" >> /etc/motd

# Configuración final
power_state:
  mode: reboot
  message: "Configuración de lab aplicada, reiniciando..."
  timeout: 120
  condition: true
EOF

# ========== GENERAR META-DATA ==========
cat > "$VMS_TMP_DIR/meta-data" <<EOF
instance-id: ${LAB_ID}-v${VARIANT_ID}
local-hostname: ${LAB_ID}-v${VARIANT_ID}
EOF

# ========== GENERAR ISO ==========
echo "📀 Creando ISO cloud-init..."
genisoimage \
    -output "$ISO_PATH" \
    -volid cidata \
    -joliet \
    -rock \
    "$VMS_TMP_DIR/user-data" \
    "$VMS_TMP_DIR/meta-data" 2>/dev/null

if [[ $? -ne 0 ]]; then
    echo "❌ ERROR al generar ISO" >&2
    exit 1
fi

# ========== VERIFICACIÓN Y SALIDA ==========
ISO_SIZE=$(du -h "$ISO_PATH" | cut -f1)
echo "✅ ISO generado exitosamente!"
echo "   📍 Ruta: $ISO_PATH"
echo "   📏 Tamaño: $ISO_SIZE"
echo "   🖥️  Hostname: ${LAB_ID}-v${VARIANT_ID}"
echo "   🔧 Servicios: ${SERVICES_ENABLED[*]}"
[[ -n "$VIP_IP" ]] && echo "   🌐 VIP: $VIP_IP"
[[ ${#ERROR_COMMANDS[@]} -gt 0 ]] && echo "   🐛 Errores inyectados: ${#ERROR_COMMANDS[@]}"

# IMPORTANTE: Esta línea final es la que main.sh captura
echo "$ISO_PATH"