#!/bin/bash
# ===========================================================================
# LAB J04 – JUNIOR
# Escenario: Firewall bloquea tráfico legítimo tras cambios de seguridad
# ===========================================================================
set -uo pipefail


# ==============================================================================
# Función 1: Mostrar ticket J04
# ==============================================================================
show_ticket() {
    clear
    printf "\033[1;36m========================================================\033[0m\n"
    printf "\033[1;36m   LAB J04 – JUNIOR – FIREWALL BLOCKS LEGITIMATE TRAFFIC\033[0m\n"
    printf "\033[1;36m========================================================\033[0m\n\n"

    printf "\033[1;33mEscenario:\033[0m\n"
    printf "  En Linux, la seguridad no consiste en bloquearlo todo, sino en permitir\n"
    printf "  exactamente lo necesario. El firewall no es un enemigo del servicio,\n"
    printf "  es su guardián. Tras un ajuste reciente —probablemente bien intencionado—\n"
    printf "  el sistema sigue estable, el servicio está vivo y el puerto escucha.\n"
    printf "  Sin embargo, el acceso ha desaparecido. El firewall, fiel a su diseño,\n"
    printf "  está cumpliendo órdenes con precisión… aunque ya no coincidan con la realidad.\n\n"

    printf "\033[1;33mSíntomas:\033[0m\n"
    printf "  \033[1;31m• El servicio está activo y ejecutándose sin errores.\033[0m\n"
    printf "  \033[1;31m• El puerto correspondiente aparece en estado LISTEN.\033[0m\n"
    printf "  \033[1;31m• El sistema responde a ping y no muestra fallos evidentes.\033[0m\n"
    printf "  \033[1;31m• Las conexiones al servicio son rechazadas o hacen timeout.\033[0m\n\n"

    printf "\033[1;33mTarea:\033[0m\n"
    printf "  Restaurar el equilibrio entre seguridad y operación:\n"
    printf "  - Identificar qué zona protege la interfaz de red\n"
    printf "  - Comprender qué servicios están realmente permitidos\n"
    printf "  - Autorizar solo el tráfico legítimo que el sistema espera\n"
    printf "  La solución correcta no consiste en desactivar el firewall,\n"
    printf "  sino en alinearlo nuevamente con la intención del servicio.\n\n"

    printf "\033[1;33mRestricciones:\033[0m\n"
    printf "  • Prohibido detener o deshabilitar firewalld\n"
    printf "  • Prohibido mover la interfaz a zonas totalmente confiables\n"
    printf "  • Evitar reglas genéricas que rompan el principio de mínimo acceso\n"
    printf "  • Los cambios deben persistir tras reiniciar el sistema\n\n"

    printf "\033[1;33mPistas:\033[0m\n"
    printf "  • El firewall decide en función de zonas, no de suposiciones\n"
    printf "  • Un servicio permitido comunica más intención que un puerto abierto\n"
    printf "  • Revisa qué ve firewalld, no solo lo que escucha el sistema\n"
    printf "  • Cuando la solución es correcta, el firewall no se nota\n\n"

    printf "\033[1;36m========================================================\033[0m\n"
    printf "\nEjecutar con --apply para inyectar el fallo...\n"
}




# ==============================================================================
# Función 2: Configurar servicio personalizado
# ==============================================================================
setup_custom_service() {
    local port=$1
    local service_name="custom-app-$port"
    
    # Crear definición de servicio personalizado
    cat > /etc/firewalld/services/${service_name}.xml << EOF
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>Custom Application Port $port</short>
  <description>Servicio personalizado para lab J04 en puerto $port</description>
  <port protocol="tcp" port="$port"/>
</service>
EOF
    
    # Iniciar servicio dummy en ese puerto
    python3 -m http.server $port --directory /tmp &
    echo $! > /tmp/custom_service_$port.pid
    
    echo $service_name
}

# ==============================================================================
# Función 3: Aplicar fallo aleatorio
# ==============================================================================
apply_lab() {
    local IFACE
    IFACE=$(ip route | awk '/default/ {print $5; exit}')
    
    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB J04: Iniciando inyección de fallo"
        echo "Interfaz: $IFACE"
        echo "Escenario aleatorio: $RANDOM_SCENARIO"
        echo "========================================"
    } >> "$LOG"
    
    # Validación root
    if [ "$EUID" -ne 0 ]; then
        echo "ERROR: Ejecutar como root" | tee -a "$LOG"
        return 1
    fi
    
    # Asegurar que firewalld y httpd están activos
    systemctl enable --now firewalld >> "$LOG" 2>&1
    systemctl enable --now httpd >> "$LOG" 2>&1
    
    # Resetear firewall a estado conocido
    firewall-cmd --runtime-to-permanent >> "$LOG" 2>&1
    
    # Escenario aleatorio
    case $RANDOM_SCENARIO in
        0)
            # ESCENARIO 1: HTTP bloqueado (el original)
            echo "Configurando ESCENARIO 1: HTTP bloqueado" >> "$LOG"
            firewall-cmd --zone=public --change-interface="$IFACE" >> "$LOG" 2>&1
            firewall-cmd --zone=public --remove-service=http --permanent >> "$LOG" 2>&1
            firewall-cmd --reload >> "$LOG" 2>&1
            
            {
                echo "Problema: HTTP (puerto 80) bloqueado"
                echo "Servicio activo: Apache (httpd)"
                echo "Zona: public"
                echo "Servicios permitidos: $(firewall-cmd --zone=public --list-services)"
            } >> "$LOG"
            ;;
            
        1)
            # ESCENARIO 2: HTTPS bloqueado
            echo "Configurando ESCENARIO 2: HTTPS bloqueado" >> "$LOG"
            firewall-cmd --zone=public --change-interface="$IFACE" >> "$LOG" 2>&1
            firewall-cmd --zone=public --add-service=http --permanent >> "$LOG" 2>&1
            firewall-cmd --zone=public --remove-service=https --permanent >> "$LOG" 2>&1
            
            # Configurar Apache para HTTPS (simplificado)
            if ! openssl version &>/dev/null; then
                yum install -y mod_ssl openssl >> "$LOG" 2>&1
            fi
            systemctl restart httpd >> "$LOG" 2>&1
            
            firewall-cmd --reload >> "$LOG" 2>&1
            
            {
                echo "Problema: HTTPS (puerto 443) bloqueado"
                echo "Servicios activos: Apache (http y https configurados)"
                echo "Zona: public"
                echo "HTTP permitido, HTTPS bloqueado"
            } >> "$LOG"
            ;;
            
        2)
            # ESCENARIO 3: Servicio personalizado bloqueado
            RANDOM_PORT=$((1024 + RANDOM % 30000))
            echo "Configurando ESCENARIO 3: Servicio personalizado en puerto $RANDOM_PORT" >> "$LOG"
            
            SERVICE_NAME=$(setup_custom_service $RANDOM_PORT)
            
            firewall-cmd --zone=public --change-interface="$IFACE" >> "$LOG" 2>&1
            firewall-cmd --zone=public --add-service=http --permanent >> "$LOG" 2>&1
            firewall-cmd --zone=public --add-service=https --permanent >> "$LOG" 2>&1
            firewall-cmd --reload >> "$LOG" 2>&1
            
            {
                echo "Problema: Servicio personalizado en puerto $RANDOM_PORT bloqueado"
                echo "Servicio activo: Python HTTP server en puerto $RANDOM_PORT"
                echo "PID: $(cat /tmp/custom_service_$RANDOM_PORT.pid 2>/dev/null)"
                echo "Zona: public"
                echo "Servicios permitidos: $(firewall-cmd --zone=public --list-services)"
                echo "NOTA: Este servicio NO está en la lista de servicios permitidos"
            } >> "$LOG"
            ;;
            
        3)
            # ESCENARIO 4: Zona incorrecta
            echo "Configurando ESCENARIO 4: Zona bloqueada" >> "$LOG"
            
            # Mover a zona block (la más restrictiva)
            firewall-cmd --zone=block --change-interface="$IFACE" >> "$LOG" 2>&1
            firewall-cmd --zone=block --add-service=ssh --permanent >> "$LOG" 2>&1  # Solo SSH para administración
            
            {
                echo "Problema: Interfaz en zona 'block'"
                echo "Servicio activo: Apache (httpd)"
                echo "Zona actual: block (muy restrictiva)"
                echo "Servicios permitidos en block: $(firewall-cmd --zone=block --list-services)"
                echo "Consejo: Revisa en qué zona está la interfaz"
            } >> "$LOG"
            ;;
    esac
    
    firewall-cmd --reload >> "$LOG" 2>&1
    
    # Mostrar resumen al usuario
    echo "========================================" | tee -a "$LOG"
    echo "LAB J04 CONFIGURADO - ESCENARIO $RANDOM_SCENARIO" | tee -a "$LOG"
    echo "Log completo: $LOG" | tee -a "$LOG"
    echo "" | tee -a "$LOG"
    echo "PISTAS INICIALES:" | tee -a "$LOG"
    echo "1. Verifica servicios activos: systemctl list-units | grep -E '(http|firewalld)'" | tee -a "$LOG"
    echo "2. Verifica puertos en escucha: ss -tlnp" | tee -a "$LOG"
    echo "3. Revisa configuración de firewall: firewall-cmd --get-active-zones" | tee -a "$LOG"
    echo "4. Consulta el log para más detalles: tail -20 $LOG" | tee -a "$LOG"
    echo "========================================" | tee -a "$LOG"
}

# ==============================================================================
# Función 4: Limpiar lab (opcional)
# ==============================================================================
cleanup_lab() {
    echo "Limpiando configuración del lab..." | tee -a "$LOG"
    
    # Matar servicios personalizados
    pkill -f "python3 -m http.server" 2>/dev/null
    rm -f /tmp/custom_service_*.pid 2>/dev/null
    
    # Remover servicios personalizados de firewalld
    rm -f /etc/firewalld/services/custom-app-*.xml 2>/dev/null
    
    # Restaurar zona public con servicios básicos
    IFACE=$(ip route | awk '/default/ {print $5; exit}')
    firewall-cmd --zone=public --change-interface="$IFACE" --permanent >> "$LOG" 2>&1
    firewall-cmd --zone=public --add-service=ssh --permanent >> "$LOG" 2>&1
    firewall-cmd --zone=public --add-service=http --permanent >> "$LOG" 2>&1
    firewall-cmd --zone=public --add-service=https --permanent >> "$LOG" 2>&1
    firewall-cmd --reload >> "$LOG" 2>&1
    
    echo "Lab limpiado. Firewall restaurado a estado normal." | tee -a "$LOG"
}

# ==============================================================================
# Ejecución principal
# ==============================================================================
case "${1:-}" in
    --apply)
        apply_lab
        ;;
    --cleanup)
        cleanup_lab
        ;;
    *)
        show_ticket
        ;;
esac