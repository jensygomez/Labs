#!/bin/bash

VIP_TARGET="http://10.10.10.30"
LOG_FILE="/var/log/infinite_scroll.log"

mkdir -p /var/log

while true; do
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Obtener código de respuesta HTTP
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 --max-time 5 "$VIP_TARGET/")
    
    # Evaluación limpia del código 200
    if [ "$HTTP_STATUS" -eq 200 ]; then
        echo "[$TIMESTAMP] GET / - STATUS: $HTTP_STATUS OK" >> "$LOG_FILE"
    else
        echo "[$TIMESTAMP] GET / - STATUS: $HTTP_STATUS FAIL/TIMEOUT" >> "$LOG_FILE"
    fi

    # Ajuste de intervalo (1 segundo)
    sleep 1
done
