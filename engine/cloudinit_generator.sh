#!/bin/bash
# ==============================================================================
# CLOUD-INIT GENERATOR v2.0 - CON PARSER DE VARIANTES
# ==============================================================================
# Uso: cloudinit_generator.sh <LEVEL> <LAB_ID> <TEMPLATE_YAML>
# 
# CAMBIO PRINCIPAL: Ahora lee el YAML de variante y genera cloud-init personalizado
# ==============================================================================

set -euo pipefail

# ========== PARÁMETROS ==========
LEVEL="$1"          # "junior"
LAB_ID="$2"         # "J01"
TEMPLATE_YAML="$3"  # Ruta completa al YAML de variante

# ========== VERIFICACIONES ==========
if [[ ! -f "$TEMPLATE_YAML" ]]; then
    echo "❌ ERROR: Template YAML no encontrado: $TEMPLATE_YAML" >&2
    exit 1
fi

if ! mountpoint -q "/mnt/vms"; then
    echo "❌ ERROR: /mnt/vms no montado" >&2
    exit 1
fi

# ========== DIRECTORIO DE TRABAJO ==========
VMS_TMP_DIR="/mnt/vms/labs/tmp/${LEVEL}_${LAB_ID}_$(date +%s)"
mkdir -p "$VMS_TMP_DIR"
ISO_PATH="$VMS_TMP_DIR/${LAB_ID}_nocloud.iso"

# ========== FUNCIÓN PARA EXTRAER VALORES SIMPLES DEL YAML ==========
get_yaml_value() {
    local key="$1"
    grep -A1 "^$key:" "$TEMPLATE_YAML" | tail -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# ========== PARSER BÁSICO DEL YAML ==========
# Extraer información básica
VARIANT_ID=$(get_yaml_value "variant_id")
LAB_TITLE=$(get_yaml_value "title")

# Extraer servicios a habilitar (líneas que siguen a "enabled:")
SERVICES_ENABLED=()
while IFS= read -r line; do
    line=$(echo "$line" | sed 's/^- //;s/[[:space:]]*$//')
    [[ -n "$line" && ! "$line" =~ ^# ]] && SERVICES_ENABLED+=("$line")
done < <(awk '/enabled:/{flag=1} /disabled:/{flag=0} flag && /^[[:space:]]*- /' "$TEMPLATE_YAML")

# Extraer VIPs
VIP_LINES=$(awk '/vips:/{flag=1} /^[^[:space:]]/{if(flag && !/vips:/) flag=0} flag && /ip:/' "$TEMPLATE_YAML")
VIP_IP=$(echo "$VIP_LINES" | grep -o '"192\.168\.122\.[0-9]\+"' | tr -d '"' | head -1)

# Extraer comandos de error (buscando "commands:" dentro de "errors:")
ERROR_COMMANDS=()
while IFS= read -r line; do
    line=$(echo "$line" | sed 's/^- //;s/[[:space:]]*$//')
    [[ -n "$line" && "$line" =~ ^[a-z] ]] && ERROR_COMMANDS+=("$line")
done < <(awk '/errors:/{flag=1} /student_info:/{flag=0} flag && /commands:/{subflag=1; next} subflag && /^[[:space:]]*- /' "$TEMPLATE_YAML")

# ========== GENERAR CLOUD-CONFIG PERSONALIZADO ==========
echo "🔨 Generando cloud-init para: $LAB_ID Variant $VARIANT_ID"
echo "   - Servicios a habilitar: ${SERVICES_ENABLED[*]}"
echo "   - VIP: $VIP_IP"
echo "   - Comandos de error: ${#ERROR_COMMANDS[@]}"

cat > "$VMS_TMP_DIR/user-data" <<EOF
#cloud-config
# ==========================================
# LAB: $LAB_ID - Variant $VARIANT_ID
# $LAB_TITLE
# Generado: $(date)
# ==========================================

hostname: ${LAB_ID}-v${VARIANT_ID}

# Usuario para acceso (mismo que antes)
users:
  - name: jensy
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin
    shell: /bin/bash
    lock_passwd: false
    passwd: $(openssl passwd -6 "1234")

# Asignar VIP si está definida
bootcmd:
EOF

# Agregar comando para VIP si existe
if [[ -n "$VIP_IP" ]]; then
    cat >> "$VMS_TMP_DIR/user-data" <<EOF
  - nmcli connection modify "enp1s0" +ipv4.addresses $VIP_IP/24
  - nmcli connection down "enp1s0" && nmcli connection up "enp1s0"
EOF
else
    echo "  - echo 'No VIP asignada para este lab'" >> "$VMS_TMP_DIR/user-data"
fi

# Agregar sección runcmd
cat >> "$VMS_TMP_DIR/user-data" <<EOF

# Configuración del sistema
runcmd:
EOF

# 1. Habilitar servicios requeridos
for service in "${SERVICES_ENABLED[@]}"; do
    echo "  - systemctl enable --now $service" >> "$VMS_TMP_DIR/user-data"
done

# 2. Aplicar comandos de error
for cmd in "${ERROR_COMMANDS[@]}"; do
    echo "  - $cmd" >> "$VMS_TMP_DIR/user-data"
done

# 3. Crear archivo de información del lab
cat >> "$VMS_TMP_DIR/user-data" <<EOF
  # Crear archivo con información del escenario
  - cat > /root/lab_scenario.txt <<'EOL'
==========================================
LAB: $LAB_ID - Variant $VARIANT_ID
==========================================
Título: $LAB_TITLE
Fecha: $(date)
Hostname: ${LAB_ID}-v${VARIANT_ID}
IP Administrativa: 192.168.122.20
EOF

# Agregar VIP si existe
if [[ -n "$VIP_IP" ]]; then
    echo "VIP Servicio: $VIP_IP" >> "$VMS_TMP_DIR/user-data"
fi

cat >> "$VMS_TMP_DIR/user-data" <<EOF

SERVICIOS HABILITADOS:
EOF

for service in "${SERVICES_ENABLED[@]}"; do
    echo "  - $service" >> "$VMS_TMP_DIR/user-data"
done

cat >> "$VMS_TMP_DIR/user-data" <<EOF

ERROR INYECTADO:
  Firewall bloquea puerto 80/tcp

PARA DIAGNOSTICAR:
  1. Verificar estado de nginx: systemctl status nginx
  2. Verificar reglas de firewall: firewall-cmd --zone=public --list-all
  3. Probar conectividad: curl -v http://${VIP_IP:-192.168.122.50}
EOL
EOF

# ========== METADATA BÁSICA ==========
cat > "$VMS_TMP_DIR/meta-data" <<EOF
instance-id: ${LAB_ID}-v${VARIANT_ID}
local-hostname: ${LAB_ID}-v${VARIANT_ID}
EOF

# ========== GENERAR ISO ==========
echo "🔨 Generando ISO en: $ISO_PATH" >&2
genisoimage \
    -output "$ISO_PATH" \
    -volid cidata \
    -joliet \
    -rock \
    "$VMS_TMP_DIR/user-data" \
    "$VMS_TMP_DIR/meta-data" > /dev/null 2>&1

# ========== RESULTADO ==========
echo "✅ ISO creado: $ISO_PATH" >&2
echo "   - Tamaño: $(du -h "$ISO_PATH" | cut -f1)"
echo "   - Servicios configurados: ${SERVICES_ENABLED[*]:-ninguno}"
echo "   - VIP: ${VIP_IP:-ninguna}"
echo "$ISO_PATH"