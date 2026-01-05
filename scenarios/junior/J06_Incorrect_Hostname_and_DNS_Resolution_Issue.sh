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

set -euo pipefail

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
# Función 2: Aplicar inyección
# ==============================================================================
apply_lab() {

    # --------------------------------------------------------------------------
    # Validaciones iniciales
    # --------------------------------------------------------------------------
    if [[ $EUID -ne 0 ]]; then
        echo "ERROR: Este script debe ejecutarse como root o con sudo."
        exit 1
    fi

    echo ">>> J06 | Iniciando inyección del problema..."
    sleep 1

    # --------------------------------------------------------------------------
    # Backups de seguridad
    # --------------------------------------------------------------------------
    echo ">>> Creando backups de archivos críticos..."

    cp -a /etc/hosts /root/hosts.j06.bak
    cp -a /etc/resolv.conf /root/resolv.conf.j06.bak

    echo ">>> Backups creados en /root"
    sleep 1

    # --------------------------------------------------------------------------
    # Paso 1: Hostname incorrecto
    # --------------------------------------------------------------------------
    echo ">>> Inyectando hostname incorrecto..."

    hostnamectl set-hostname localhost

    hostnamectl | grep -E "Static hostname|Transient hostname"
    sleep 1

    # --------------------------------------------------------------------------
    # Paso 2: Resolución local rota
    # --------------------------------------------------------------------------
    echo ">>> Inyectando /etc/hosts incompleto..."

cat << 'EOF' > /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
EOF

    sleep 1

    # --------------------------------------------------------------------------
    # Paso 3: DNS inválido (sin tocar NetworkManager)
    # --------------------------------------------------------------------------
    echo ">>> Inyectando DNS inválido..."

cat << 'EOF' > /etc/resolv.conf
search lab.local
nameserver 192.0.2.53
EOF

    sleep 1

    # --------------------------------------------------------------------------
    # Resumen final
    # --------------------------------------------------------------------------
    echo
    echo ">>> J06 | Inyección completada"
    echo "---------------------------------------------"
    echo "Estado esperado:"
    echo " - ping 8.8.8.8        -> OK"
    echo " - ping google.com     -> FALLA"
    echo " - hostname -f         -> localhost"
    echo " - getent hosts <host> -> FALLA"
    echo " - sudo                -> hostname incorrecto"
    echo
    echo "Rollback:"
    echo " - Restaurar backups en /root"
    echo " - O volver al snapshot"
    echo "---------------------------------------------"
}

# ==============================================================================
# Ejecución
# ==============================================================================
case "${1:-}" in
    --apply)
        apply_lab
        ;;
    *)
        show_ticket
        ;;
esac
