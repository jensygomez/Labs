#!/bin/bash
# ==============================================================================
# J06 — Incorrect Hostname and DNS Resolution Issue
# INJECT SCRIPT
#
# Objetivo:
# - Introducir hostname incorrecto
# - Romper resolución local
# - Romper DNS
# - Mantener conectividad IP
#
# Distro: RHEL 9 / Rocky / Alma
# Nivel: Sysadmin Junior (producción)
# ==============================================================================

set -uo pipefail




# ==============================================================================
# Función 1: Mostrar ticket J06
# ==============================================================================
show_ticket() {
    clear
    printf "\033[1;36m========================================================\033[0m\n"
    printf "\033[1;36m   LAB J06 – JUNIOR\033[0m\n"
    printf "\033[1;36m========================================================\033[0m\n\n"

    printf "\033[1;33mEscenario:\033[0m\n"
    printf "  Tras un cambio administrativo reciente, el servidor\n"
    printf "  continúa encendido y con conectividad de red activa.\n"
    printf "  Las interfaces están arriba y el tráfico IP funciona,\n"
    printf "  pero comienzan a aparecer fallos extraños en servicios\n"
    printf "  internos y comandos administrativos.\n\n"

    printf "  No se han modificado firewalls ni servicios críticos.\n"
    printf "  Sin embargo, el sistema parece incapaz de resolver\n"
    printf "  correctamente nombres, incluyendo su propio hostname.\n\n"

    printf "\033[1;33mSíntomas:\033[0m\n"
    printf "  \033[1;31m• La conectividad IP funciona (ping por IP responde).\033[0m\n"
    printf "  \033[1;31m• La resolución de nombres falla de forma intermitente.\033[0m\n"
    printf "  \033[1;31m• El hostname reportado no coincide con el esperado.\033[0m\n"
    printf "  \033[1;31m• Comandos como sudo muestran advertencias o demoras.\033[0m\n"
    printf "  \033[1;31m• Servicios que dependen de resolución de nombres fallan.\033[0m\n\n"

    printf "\033[1;33mTarea:\033[0m\n"
    printf "  Restaurar una resolución de nombres coherente en el sistema:\n"
    printf "  - Verificar el hostname configurado\n"
    printf "  - Analizar la resolución local del sistema\n"
    printf "  - Identificar problemas de DNS sin romper la conectividad\n"
    printf "  - Aplicar correcciones persistentes y mínimas\n\n"

    printf "\033[1;33mRestricciones:\033[0m\n"
    printf "  • Prohibido desactivar NetworkManager\n"
    printf "  • Prohibido eliminar conectividad de red\n"
    printf "  • Evitar soluciones temporales no persistentes\n"
    printf "  • No reiniciar servicios sin entender el impacto\n\n"

    printf "\033[1;33mPistas:\033[0m\n"
    printf "  • La resolución local puede preceder al DNS\n"
    printf "  • El hostname incorrecto genera efectos colaterales\n"
    printf "  • getent refleja el comportamiento real del sistema\n"
    printf "  • Un sistema con red no siempre tiene nombres resueltos\n\n"

    printf "\033[1;36m========================================================\033[0m\n"
    printf "\nEjecutar con --apply para inyectar el fallo...\n"
}

# ==============================================================================
# Función 2: Crear configuraciones problemáticas
# ==============================================================================
create_broken_hosts() {
    local scenario=$1
    local original_hostname=$2
    
    case $scenario in
        1)
            # Hosts minimalista (sin FQDN ni hostname real)
            cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
EOF
            ;;
        2)
            # Entradas duplicadas conflictivas
            cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain ${original_hostname}
127.0.0.2   ${original_hostname} ${original_hostname}.lab.local
::1         localhost localhost.localdomain localhost6.localdomain6
192.168.122.1 gateway.guess.domain  # Entrada engañosa
EOF
            ;;
        3)
            # IPv6 primero (raro pero válido) + IPs ficticias
            cat > /etc/hosts << EOF
::1         localhost localhost.localdomain localhost6.localdomain6
127.0.0.1   localhost localhost.localdomain localhost4.localdomain4
127.0.1.1   ${original_hostname}.external.com ${original_hostname}  # Conflicto: .1 vs .1.1
EOF
            ;;
        *)
            # Hosts casi vacío (muy común en problemas reales)
            echo "127.0.0.1 localhost" > /etc/hosts
            echo "# Hostname ${original_hostname} no está en este archivo" >> /etc/hosts
            ;;
    esac
}

create_broken_resolv() {
    local scenario=$1
    
    case $scenario in
        1)
            # DNS inexistente + timeout corto
            cat > /etc/resolv.conf << EOF
# Configuración de prueba - DNS no responde
search lab.local invalid.domain example.test
nameserver 192.0.2.53  # TEST-NET-1, nunca existe
nameserver 198.51.100.53  # TEST-NET-2
options timeout:1 attempts:1 rotate
EOF
            ;;
        2)
            # Search domain excesivo (causa timeouts en búsquedas)
            cat > /etc/resolv.conf << EOF
search lab.local corp.example.com internal.dev team.project.qa staging.env production.corp
nameserver 8.8.8.8
nameserver 192.168.122.1
options timeout:3 attempts:2 ndots:2
EOF
            ;;
        3)
            # Configuración válida pero orden de nsswitch alterado
            cat > /etc/resolv.conf << EOF
search example.com
nameserver 192.168.122.1
nameserver 1.1.1.1
# Comentario: verificar /etc/nsswitch.conf
EOF
            ;;
        4)
            # Configuración mixta confusa (domain + search)
            cat > /etc/resolv.conf << EOF
domain lab.local
search lab.local example.com
nameserver 192.168.122.1
nameserver 8.8.8.8
# nameserver 8.8.4.4  # Comentado intencionalmente
options timeout:2
EOF
            ;;
    esac
}

# ==============================================================================
# Función 3: Aplicar lab dinámico (VARIABLES DENTRO DE FUNCIÓN)
# ==============================================================================
apply_lab() {
    # VARIABLES DINÁMICAS DENTRO DE LA FUNCIÓN
    local RANDOM_SCENARIO=$((RANDOM % 5))
    local LOG="/var/log/lab_j06_$(date +%Y%m%d_%H%M%S).log"
    local ORIGINAL_HOSTNAME=$(hostname)
    local TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    {
        echo "========================================"
        echo "LAB J06 - INYECCIÓN DE PROBLEMA DNS/HOSTNAME"
        echo "Fecha: $TIMESTAMP"
        echo "Escenario: $RANDOM_SCENARIO"
        echo "Hostname original: $ORIGINAL_HOSTNAME"
        echo "========================================"
    } >> "$LOG"
    
    # Validación root
    if [[ $EUID -ne 0 ]]; then
        echo "ERROR: Debe ejecutarse como root" | tee -a "$LOG"
        echo "Use: sudo $0 --apply" | tee -a "$LOG"
        return 1
    fi
    
    echo ">>> Aplicando LAB J06 - Escenario $RANDOM_SCENARIO..." | tee -a "$LOG"
    
    # --------------------------------------------------------------------------
    # 1. CREAR BACKUPS (siempre primero)
    # --------------------------------------------------------------------------
    echo ">>> Creando backups en /root..." | tee -a "$LOG"
    
    # Backup con timestamp único
    local BACKUP_DIR="/root/backup_j06_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    cp -a /etc/hosts "$BACKUP_DIR/hosts"
    cp -a /etc/resolv.conf "$BACKUP_DIR/resolv.conf"
    cp -a /etc/hostname "$BACKUP_DIR/hostname" 2>/dev/null || true
    cp -a /etc/nsswitch.conf "$BACKUP_DIR/nsswitch.conf" 2>/dev/null || true
    
    echo "Backups en: $BACKUP_DIR" >> "$LOG"
    
    # --------------------------------------------------------------------------
    # 2. APLICAR ESCENARIO ESPECÍFICO
    # --------------------------------------------------------------------------
    case $RANDOM_SCENARIO in
        0)
            echo ">>> ESCENARIO 0: Hostname sin FQDN + DNS roto" | tee -a "$LOG"
            
            # Hostname simple sin dominio
            hostnamectl set-hostname "server$(date +%m%d)"
            
            # /etc/hosts minimalista
            create_broken_hosts 1 "$ORIGINAL_HOSTNAME"
            
            # DNS que no responde
            create_broken_resolv 1
            ;;
            
        1)
            echo ">>> ESCENARIO 1: Search domains excesivos" | tee -a "$LOG"
            
            # Hostname con dominio largo
            hostnamectl set-hostname "${ORIGINAL_HOSTNAME}.subdomain.lab.corp.example.com"
            
            # /etc/hosts con entradas conflictivas
            create_broken_hosts 2 "$ORIGINAL_HOSTNAME"
            
            # Demasiados search domains
            create_broken_resolv 2
            ;;
            
        2)
            echo ">>> ESCENARIO 2: /etc/hosts corrupto" | tee -a "$LOG"
            
            # Hostname engañoso
            hostnamectl set-hostname "localhost.localdomain"
            
            # /etc/hosts con IPs conflictivas
            create_broken_hosts 3 "$ORIGINAL_HOSTNAME"
            
            # DNS funcional pero lento
            cat > /etc/resolv.conf << EOF
search example.com
nameserver 192.168.122.1
options timeout:5 attempts:2
EOF
            ;;
            
        3)
            echo ">>> ESCENARIO 3: Orden de resolución alterado" | tee -a "$LOG"
            
            # Hostname original (para confundir)
            hostnamectl set-hostname "$ORIGINAL_HOSTNAME"
            
            # /etc/hosts normal
            create_broken_hosts 1 "$ORIGINAL_HOSTNAME"
            
            # DNS aparentemente normal
            create_broken_resolv 3
            
            # ¡ALTERAR NSSWITCH.CONF! (sutil)
            if [ -f /etc/nsswitch.conf ]; then
                cp /etc/nsswitch.conf "$BACKUP_DIR/nsswitch.conf.original"
                # Cambiar orden: dns ANTES de files
                sed -i 's/^hosts:.*files.*dns.*/hosts:      dns files myhostname/' /etc/nsswitch.conf
                echo "Alterado nsswitch.conf: DNS antes de files" >> "$LOG"
            fi
            ;;
            
        4)
            echo ">>> ESCENARIO 4: Conflicto NetworkManager" | tee -a "$LOG"
            
            # Hostname dinámico
            hostnamectl set-hostname "${ORIGINAL_HOSTNAME}.dynamic.lab"
            
            # /etc/hosts básico
            create_broken_hosts 1 "$ORIGINAL_HOSTNAME"
            
            # Configuración manual que NetworkManager sobrescribirá
            create_broken_resolv 4
            
            # Forzar NetworkManager a ignorar DNS
            cat > /etc/NetworkManager/conf.d/99-j06-lab.conf << EOF
[main]
dns=none
systemd-resolved=false
rc-manager=unmanaged
EOF
            
            systemctl reload NetworkManager >> "$LOG" 2>&1
            echo "Configurado NetworkManager para no gestionar DNS" >> "$LOG"
            ;;
    esac
    
    # --------------------------------------------------------------------------
    # 3. FORZAR ACTUALIZACIÓN DE CONFIGURACIONES
    # --------------------------------------------------------------------------
    echo ">>> Recargando configuraciones..." | tee -a "$LOG"
    
    # Recargar systemd-hostnamed
    systemctl restart systemd-hostnamed 2>/dev/null || true
    
    # Limpiar caché de nscd si existe
    systemctl restart nscd 2>/dev/null || true
    
    # --------------------------------------------------------------------------
    # 4. REGISTRAR ESTADO FINAL
    # --------------------------------------------------------------------------
    {
        echo ""
        echo "=== ESTADO FINAL DEL SISTEMA ==="
        echo "Hostname estático: $(hostnamectl --static)"
        echo "Hostname -f: $(hostname -f 2>/dev/null || echo 'ERROR: No se puede determinar FQDN')"
        echo ""
        echo "=== ARCHIVOS DE CONFIGURACIÓN ==="
        echo "--- /etc/hostname ---"
        cat /etc/hostname 2>/dev/null || echo "(no existe)"
        echo ""
        echo "--- /etc/hosts (primeras 10 líneas) ---"
        head -10 /etc/hosts
        echo ""
        echo "--- /etc/resolv.conf ---"
        cat /etc/resolv.conf
        echo ""
        echo "=== PRUEBAS DE CONECTIVIDAD ==="
        echo -n "Ping a gateway (IP): "
        ping -c1 -W1 192.168.122.1 >/dev/null 2>&1 && echo "OK" || echo "FALLO"
        
        echo -n "Resolución de localhost: "
        getent hosts localhost >/dev/null && echo "OK" || echo "FALLO"
        
        echo -n "Resolución del propio hostname: "
        getent hosts "$(hostname)" >/dev/null && echo "OK" || echo "FALLO"
        
        echo -n "Resolución DNS externa (google.com): "
        timeout 2 dig +short google.com >/dev/null 2>&1 && echo "OK" || echo "FALLO"
        
        echo -n "Comando 'sudo' (primer uso puede mostrar warning): "
        sudo -n true 2>&1 | grep -q "hostname" && echo "POSIBLE WARNING" || echo "OK"
    } >> "$LOG"
    
    # --------------------------------------------------------------------------
    # 5. MOSTRAR RESUMEN AL USUARIO
    # --------------------------------------------------------------------------
    echo ""
    echo "========================================" | tee -a "$LOG"
    echo "✅ LAB J06 APLICADO - ESCENARIO $RANDOM_SCENARIO" | tee -a "$LOG"
    echo "========================================" | tee -a "$LOG"
    echo "📁 Log detallado: $LOG" | tee -a "$LOG"
    echo "📁 Backups en: $BACKUP_DIR" | tee -a "$LOG"
    echo "" | tee -a "$LOG"
    echo "🔍 SÍNTOMAS ESPERADOS:" | tee -a "$LOG"
    echo "  • 'hostname -f' puede fallar o mostrar valor inesperado" | tee -a "$LOG"
    echo "  • Resolución de nombres externos probablemente falle" | tee -a "$LOG"
    echo "  • Algunos comandos pueden mostrar warnings de hostname" | tee -a "$LOG"
    echo "  • Servicios que usan hostname pueden tener problemas" | tee -a "$LOG"
    echo "" | tee -a "$LOG"
    echo "🛠️  COMANDOS DE DIAGNÓSTICO SUGERIDOS:" | tee -a "$LOG"
    echo "  1. hostnamectl status" | tee -a "$LOG"
    echo "  2. hostname -f" | tee -a "$LOG"
    echo "  3. cat /etc/hosts" | tee -a "$LOG"
    echo "  4. cat /etc/resolv.conf" | tee -a "$LOG"
    echo "  5. getent hosts \$(hostname)" | tee -a "$LOG"
    echo "  6. dig google.com +short" | tee -a "$LOG"
    echo "  7. systemctl status systemd-hostnamed" | tee -a "$LOG"
    echo "  8. sudo journalctl -u NetworkManager --since '5 min ago'" | tee -a "$LOG"
    echo "" | tee -a "$LOG"
    echo "🔄 Para restaurar: sudo $0 --cleanup" | tee -a "$LOG"
    echo "========================================" | tee -a "$LOG"
}

# ==============================================================================
# Función 4: Limpieza (también con variables locales)
# ==============================================================================
cleanup_lab() {
    local LOG_CLEANUP="/var/log/lab_j06_cleanup_$(date +%Y%m%d_%H%M%S).log"
    local LATEST_BACKUP=$(ls -td /root/backup_j06_* 2>/dev/null | head -1)
    
    {
        echo "========================================"
        echo "LAB J06 - LIMPIEZA Y RESTAURACIÓN"
        echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "========================================"
    } >> "$LOG_CLEANUP"
    
    if [[ $EUID -ne 0 ]]; then
        echo "ERROR: Se requiere root" | tee -a "$LOG_CLEANUP"
        return 1
    fi
    
    echo ">>> Iniciando limpieza del LAB J06..." | tee -a "$LOG_CLEANUP"
    
    if [ -n "$LATEST_BACKUP" ] && [ -d "$LATEST_BACKUP" ]; then
        echo ">>> Restaurando desde backup: $LATEST_BACKUP" | tee -a "$LOG_CLEANUP"
        
        # Restaurar archivos de configuración
        cp -f "$LATEST_BACKUP/hosts" /etc/hosts 2>/dev/null
        cp -f "$LATEST_BACKUP/resolv.conf" /etc/resolv.conf 2>/dev/null
        cp -f "$LATEST_BACKUP/hostname" /etc/hostname 2>/dev/null
        cp -f "$LATEST_BACKUP/nsswitch.conf" /etc/nsswitch.conf 2>/dev/null
        
        # Restaurar hostname desde backup si existe
        if [ -f "$LATEST_BACKUP/hostname" ]; then
            local RESTORE_HOSTNAME=$(cat "$LATEST_BACKUP/hostname")
            hostnamectl set-hostname "$RESTORE_HOSTNAME"
            echo "Hostname restaurado a: $RESTORE_HOSTNAME" >> "$LOG_CLEANUP"
        fi
    else
        echo ">>> No se encontró backup, restaurando valores por defecto..." | tee -a "$LOG_CLEANUP"
        
        # Valores por defecto razonables
        echo "localhost" > /etc/hostname
        hostnamectl set-hostname "localhost"
        
        cat > /etc/hosts << EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
EOF
        
        # DNS por defecto (gateway)
        cat > /etc/resolv.conf << EOF
search localdomain
nameserver 192.168.122.1
EOF
    fi
    
    # Limpiar configuración de NetworkManager del lab
    rm -f /etc/NetworkManager/conf.d/99-j06-lab.conf 2>/dev/null
    
    # Recargar servicios
    systemctl reload NetworkManager 2>/dev/null
    systemctl restart systemd-hostnamed 2>/dev/null
    systemctl restart nscd 2>/dev/null || true
    
    echo ""
    echo "✅ LAB J06 LIMPIADO CORRECTAMENTE" | tee -a "$LOG_CLEANUP"
    echo "📁 Log de limpieza: $LOG_CLEANUP" | tee -a "$LOG_CLEANUP"
    if [ -n "$LATEST_BACKUP" ]; then
        echo "📁 Backup utilizado: $LATEST_BACKUP" | tee -a "$LOG_CLEANUP"
    fi
    echo "🔄 Reinicia la sesión SSH para ver todos los cambios aplicados"
    echo "========================================" | tee -a "$LOG_CLEANUP"
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
    --test)
        # Comando rápido para probar estado actual
        echo "=== ESTADO ACTUAL DEL SISTEMA ==="
        echo "Hostname: $(hostname)"
        echo "FQDN: $(hostname -f 2>/dev/null || echo 'ERROR')"
        echo "IP: $(hostname -I 2>/dev/null || echo 'N/A')"
        echo ""
        echo "=== PRUEBAS ==="
        echo -n "localhost: "; getent hosts localhost >/dev/null && echo "✓" || echo "✗"
        echo -n "google.com: "; timeout 2 dig +short google.com >/dev/null 2>&1 && echo "✓" || echo "✗"
        echo -n "Gateway ping: "; ping -c1 -W1 192.168.122.1 >/dev/null 2>&1 && echo "✓" || echo "✗"
        ;;
    *)
        show_ticket
        ;;
esac