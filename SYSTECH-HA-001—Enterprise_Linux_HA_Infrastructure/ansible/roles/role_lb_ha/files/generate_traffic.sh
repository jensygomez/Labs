#!/bin/bash

# Configuración
VIP_TARGET="http://10.10.10.30"  # VIP de Keepalived / HAProxy
LOG_FILE="/var/log/infinite_scroll.log"

mkdir -p /var/log

echo "[$(date '%Y-%m-%d %H:%M:%S')] Starting Infinite Scroll Traffic Generator targeting $VIP_TARGET" >> "$LOG_FILE"

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 1. Simular carga del Feed (/api/feed o la raíz)
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 --max-time 5 "$VIP_TARGET/")
    
    # Registrar según el resultado
    if [ "$HTTP_STATUS" -eq 200 ]; stream; then
        echo "[$TIMESTAMP] GET / - STATUS: $HTTP_STATUS OK" >> "$LOG_FILE"
    else
        echo "[$TIMESTAMP] GET / - STATUS: $HTTP_STATUS FAIL/TIMEOUT" >> "$LOG_FILE"
    fi

    # 2. Simular petición de imágenes / recursos estáticos
    HTTP_IMG_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 --max-time 5 "$VIP_TARGET/images/test.jpg")
    
    # Breve pausa entre scrolls (0.5 segundos) para no saturar por completo la CPU del cliente
    sleep 0.5
done
