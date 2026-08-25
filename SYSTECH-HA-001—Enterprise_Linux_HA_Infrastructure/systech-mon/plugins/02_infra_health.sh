#!/bin/bash
echo -e "${C_BOLD}🏗️ INFRASTRUCTURE HEALTH (Internal Nodes)${C_RESET}"
echo -e "────────────────────────────────────────────────────────────"
# Columna dinámica de DETALLES para métricas clave:valor
printf " %-10s | %-4s | %-5s | %-5s | %-22s | %s\n" "NODE" "STAT" "LOAD" "DISK" "DETAILS (Services/Metrics)" "ROLE"
echo -e "────────────────────────────────────────────────────────────"

# Función para obtener servicios críticos de un rol
get_critical_services() {
    local role=$1
    for entry in "${CRITICAL_SERVICES[@]}"; do
        IFS=':' read -r r services <<< "$entry"
        if [ "$r" == "$role" ]; then
            echo "$services"
            return
        fi
    done
    echo ""
}

for node_info in "${INFRA_NODES[@]}"; do
    IFS=':' read -r name ip role <<< "$node_info"
    critical_svcs=$(get_critical_services "$role")
    
    # TRUCO MAESTRO: Ejecutamos un script remoto que devuelve UNA sola línea delimitada por '|'
    # Esto evita TODOS los problemas de parsing de múltiples líneas con sed/awk en el lado local.
    metrics=$(ssh -o ConnectTimeout=$SSH_TIMEOUT -o StrictHostKeyChecking=no -o BatchMode=yes ansible@$ip bash -c "'
        # 1. Obtener Load (1 min)
        LOAD=\$(uptime | awk -F\"load average:\" \"{print \\\$2}\" | awk -F\",\" \"{printf \\\"%.2f\\\", \\\$1}\")
        
        # 2. Obtener Disk % de /
        DISK=\$(df -h / | awk \"NR==2 {print \\\$5}\")
        
        # 3. Evaluar servicios críticos y construir cadena dinámica clave:valor
        DETAILS=\"\"
        ALL_OK=true
        IFS=\",\" read -ra SVCS <<< \"$critical_svcs\"
        for svc in \"\${SVCS[@]}\"; do
            if systemctl is-active --quiet \"\$svc\" 2>/dev/null; then
                DETAILS=\"\${DETAILS} \${svc:0:4}:${C_GREEN}✓${C_RESET}\"
            else
                DETAILS=\"\${DETAILS} \${svc:0:4}:${C_RED}✗${C_RESET}\"
                ALL_OK=false
            fi
        done
        
        # 4. Imprimir todo en una sola línea para que el local lo lea fácil
        echo \"UP|\${LOAD}|\${DISK}|\${DETAILS}|\${ALL_OK}\"
    '" 2>/dev/null)

    # Parsear la respuesta localmente (infalible porque siempre son 5 campos)
    IFS='|' read -r STATUS LOAD DISK DETAILS ALL_OK <<< "$metrics"

    if [ "$STATUS" == "UP" ]; then
        # Determinar color del estado general
        if [ "$ALL_OK" == "false" ]; then
            status="${C_YELLOW}DEGR${C_RESET}"
        else
            status="${C_GREEN}UP${C_RESET}  "
        fi
        
        # Colorear disco si es > 80%
        disk_val="${DISK%\%}"
        if [ "$disk_val" -gt 80 ] 2>/dev/null; then
            DISK="${C_RED}${DISK}${C_RESET}"
        fi
    else
        status="${C_RED}DOWN${C_RESET}"
        LOAD="---"; DISK="---"; DETAILS="${C_GRAY}No response${C_RESET}"
    fi
    
    # Imprimir fila formateada
    printf " %-10s | %-10b | %-5s | %-5s | %-22b | %s\n" \
        "$name" "$status" "$LOAD" "$DISK" "$DETAILS" "$role"
done
