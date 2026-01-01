#!/bin/bash
# ==============================================================================
# LAB J01 – JUNIOR
# Escenario: Usuario del servicio incorrecto bloquea aplicación crítica
# ==============================================================================
set -uo pipefail


# ==============================================================================
# Función 2: Mostrar ticket J02
# ==============================================================================
show_ticket() {
    clear
    printf "\033[1;36m========================================================\033[0m\n"
    printf "\033[1;36m   LAB J02 – JUNIOR – DISK USAGE REACHES 100%\033[0m\n"
    printf "\033[1;36m========================================================\033[0m\n\n"

    printf "\033[1;33mEscenario:\033[0m\n"
    printf "  Servidor de aplicaciones en producción comienza a fallar\n"
    printf "  intermitentemente. Las aplicaciones reportan errores de escritura,\n"
    printf "  jobs cron se saltan y las alertas disparan disk full.\n"
    printf "  El filesystem raíz (/) está al 100%, recordándonos que el espacio\n"
    printf "  en disco es un recurso compartido: lo que uno deja crecer,\n"
    printf "  afecta a todo el sistema.\n\n"

    printf "\033[1;33mSíntomas:\033[0m\n"
    printf "  \033[1;31m• df -h muestra / al 100% (o 99%)\033[0m\n"
    printf "  \033[1;31m• Errores \"No space left on device\" en logs de aplicaciones\033[0m\n"
    printf "  \033[1;31m• Algunos servicios o contenedores inestables\033[0m\n\n"

    printf "\033[1;33mTarea:\033[0m\n"
    printf "  Diagnosticar y liberar espacio de forma segura hasta dejar al menos\n"
    printf "  20%% libre. Identifica la causa raíz y actúa con precisión:\n"
    printf "  un senior no solo limpia, investiga por qué ocurrió y previene.\n\n"

    printf "\033[1;33mRestricciones:\033[0m\n"
    printf "  • No borrar ni truncar archivos críticos del sistema\n"
    printf "  • Priorizar métodos estándar y seguros\n"
    printf "  • Las acciones deben ser reversibles o sin impacto en producción\n\n"

    printf "\033[1;33mPistas:\033[0m\n"
    printf "  • df -h / df -i para ver espacio e inodes\n"
    printf "  • du -sh /* | sort -h para localizar los grandes consumidores\n"
    printf "  • Revisa especialmente /var/log, /var/lib/systemd/coredump y /var/cache\n"
    printf "  • Usa herramientas como journalctl --vacuum-*, dnf clean, logrotate\n\n"

    printf "\033[1;36m========================================================\033[0m\n"
    printf "\nEjecutar con --apply para inyectar el fallo...\n"
}







# ==============================================================================
# Función: Aplicar fallo para LAB J02
# ==============================================================================
apply_fall() {
    local LOG="/var/log/lab_j02.log"
    local APP_LOG_DIR="/var/log/application"
    local COREDUMP_DIR="/var/lib/systemd/coredump"
    local CACHE_DIR="/var/cache/dnf"
    local BACKUP="/root/lab_j02_backup"
    local TARGET_USAGE=95  # Apuntar a ~95% para no bloquear el sistema

    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB J02: Iniciando inyección de fallo"
    } >> "$LOG"

    # Validación root
    if [ "$EUID" -ne 0 ]; then
        echo "ERROR: Ejecutar como root" >> "$LOG"
        exit 1
    fi

    # Backup de directorios clave si existen
    mkdir -p "$BACKUP"
    [ -d "$APP_LOG_DIR" ] && cp -r "$APP_LOG_DIR" "$BACKUP" 2>/dev/null || true
    [ -d "$COREDUMP_DIR" ] && cp -r "$COREDUMP_DIR" "$BACKUP" 2>/dev/null || true
    [ -d "$CACHE_DIR" ] && cp -r "$CACHE_DIR" "$BACKUP" 2>/dev/null || true

    # 1. Crear log gigante (~7 GB rápido con dd)
    mkdir -p "$APP_LOG_DIR"
    echo "Creando log gigante de ~7 GB..."
    dd if=/dev/zero of="$APP_LOG_DIR/app.log" bs=1M count=7168 status=progress 2>> "$LOG"

    # 2. Crear múltiples core dumps pequeños (~400 MB cada uno, total ~4 GB)
    mkdir -p "$COREDUMP_DIR"
    for i in {1..10}; do
        echo "Creando core dump $i/10 de ~400 MB..."
        dd if=/dev/zero of="$COREDUMP_DIR/core.app.$(date +%s).$i.gz" bs=1M count=400 status=progress 2>> "$LOG"
    done

    # 3. Inflacionar cache de DNF (~2-3 GB con descargas rápidas)
    echo "Inflando cache de DNF con paquetes grandes..."
    dnf install -y --downloadonly --downloaddir="$CACHE_DIR" epel-release httpd nginx mariadb-server kernel-devel qemu-kvm 2>> "$LOG"
    for i in {1..5}; do
        dnf install -y --downloadonly --downloaddir="$CACHE_DIR" firefox thunderbird libreoffice gcc kernel-headers 2>> "$LOG"
    done

    # Verificar uso final (detener si excede, pero en VM es seguro)
    local CURRENT_USAGE=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
    echo "Uso actual: $CURRENT_USAGE%" >> "$LOG"

    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] LAB J02: Inyección completada"
        echo "   → Log gigante: $APP_LOG_DIR/app.log"
        echo "   → Core dumps: $COREDUMP_DIR"
        echo "   → Cache DNF: $CACHE_DIR"
        echo "   → Backup: $BACKUP"
        echo "   → Prueba: df -h / && touch /tmp/test (debería fallar si lleno)"
    } >> "$LOG"

    echo "Lab J02 inyectado. Revisa logs y uso de disco..."
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
