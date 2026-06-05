---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Playground: PG-003-v2
Titulo: Auditoría Forense de Logs y Búsquedas Avanzadas (Find, Grep y Regex)
Fecha de Inicio: 2026-06-05
Dificultad: 6/10
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux Pleno
Temas:
  - Search for Files (find)
  - Search File Using Grep
  - Analyze Text Using Basic Regular Expressions (BRE)
  - Extended Regular Expressions (ERE)
Competencias:
  - Dominar búsquedas avanzadas en el sistema de archivos por tamaño y tiempo de modificación
  - Aislar registros específicos en logs masivos mediante patrones condicionales complejos (Grep -E)
  - Filtrar y limpiar archivos de configuración eliminando ruido visual (comentarios y líneas vacías)
Ticket: |-
  INC-3147

  El equipo de Respuesta a Incidentes detectó posible exfiltración de datos por parte de un contractor. Sospechan que ocultó archivos grandes en '/var/log/incident_review' y dejó rastros de IPs internas en los logs del sistema.

  Se solicita realizar las siguientes tareas de auditoría de inmediato:

  1. Localizar dentro de '/var/log/incident_review' cualquier archivo **mayor a 8MB** Y modificado **en las últimas 36 horas**. Copiar ese archivo (o archivos) al directorio '/root/forensic_evidence/'.

  2. Buscar en el archivo '/var/log/incident_review/traffic.log' todas las líneas que contengan direcciones IP que comiencen estrictamente con el rango privado '172.16.' (patrón BRE), y guardar el resultado en '/root/internal_traffic.txt'.

  3. Auditar el mismo log y extraer todas las líneas que contengan errores de tipo 'ERROR' o 'SEVERE' usando una sola expresión regular extendida (ERE), guardando el resultado en '/root/severe_errors.txt'.

  4. El archivo de configuración '/var/log/incident_review/service.conf' está lleno de comentarios y líneas en blanco. Genere una copia limpia en '/root/service.conf.clean' eliminando todas las líneas que comiencen con '#' y las completamente vacías.
Validacion:
  - Objetivo: Archivos pesados y recientes localizados y respaldados en /root/forensic_evidence/.
    Peso: 25 %
  - Objetivo: Extracción de IPs en rango 172.16.x validada con formato BRE en /root/internal_traffic.txt.
    Peso: 25 %
  - Objetivo: Filtrado condicional (ERROR|SEVERE) validado con ERE en /root/severe_errors.txt.
    Peso: 25 %
  - Objetivo: Archivo de configuración limpio de comentarios y líneas vacías en /root/service.conf.clean.
    Peso: 25 %
Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup_sh
  #!/bin/bash
  set -e


  # Crear entorno de simulación
  mkdir -p /var/log/incident_review
  mkdir -p /root/forensic_evidence

  # Crear archivo pesado reciente (> 8MB)
  dd if=/dev/urandom of=/var/log/incident_review/sensitive_backup.img bs=1M count=10 2>/dev/null

  # Crear archivo viejo que no debe ser copiado
  touch -d "3 days ago" /var/log/incident_review/legacy_dump.img
  dd if=/dev/urandom of=/var/log/incident_review/legacy_dump.img bs=1M count=9 2>/dev/null

  # Crear archivo de log simulado
  cat << 'LOGS' > /var/log/incident_review/traffic.log
  2026-06-05 02:10:15 INFO Session established from 192.168.10.45
  2026-06-05 02:15:33 ERROR Failed login attempt from 172.16.5.22
  2026-06-05 02:20:10 WARNING Unusual port scan detected
  2026-06-05 02:25:47 SEVERE Data exfiltration attempt from 172.16.99.180
  2026-06-05 02:30:05 INFO Normal traffic from 10.10.10.50
  2026-06-05 02:35:12 ERROR Database timeout on backend-03
  LOGS

  # Crear archivo de configuración ruidoso
  cat << 'CONF' > /var/log/incident_review/service.conf
  # Main service configuration v3.2
  service_name = secure_gateway

  # Listening configuration
  bind_address = 0.0.0.0
  port = 9443
  max_clients = 1200

  # Security section
  # tls_enabled = true
  # debug = false   <- never enable in production

  log_level = info
  CONF

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;31m 🔍 ESCENARIO CONFIGURADO - ESSENTIAL COMMANDS (PG-003-v2)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-3147\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Posible exfiltración de datos por contractor"
  echo -e " \e[1mSeveridad:\e[0m Alta / IR (Incident Response)\e[0m"
  echo -e ""
  echo -e " Como \e[1mSysadmin L2/L3\e[0m debes:"
  echo -e "  - Identificar artifacts grandes y recientes con find."
  echo -e "  - Extraer IPs sospechosas del rango 172.16. con BRE."
  echo -e "  - Filtrar errores críticos con ERE."
  echo -e "  - Limpiar configuración para revisión del equipo de Seguridad."
  echo -e ""
  echo -e " \e[1mCriterios de aceptación (Peso Total: 100%):\e[0m"
  echo -e "  [ ] Copiar archivos >8MB modificados en <36h a /root/forensic_evidence/   → 25%"
  echo -e "  [ ] Filtrar IPs '172.16.' (BRE) → /root/internal_traffic.txt             → 25%"
  echo -e "  [ ] Filtrar ERROR|SEVERE (ERE) → /root/severe_errors.txt                → 25%"
  echo -e "  [ ] Generar service.conf.clean sin # ni líneas vacías                   → 25%"
  echo -e " ------------------------------------------------------------------------------"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup_sh && rm -f /tmp/setup_sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0

  echo "=== EVALUANDO EXTRACCIÓN TEXTUAL Y BÚSQUEDAS FORENSES v2 ==="

  # 1. Validar find
  if [ -f /root/forensic_evidence/sensitive_backup.img ] && [ ! -f /root/forensic_evidence/legacy_dump.img ]; then
      echo "✔ [25%] Búsqueda find correcta (solo archivo grande y reciente)."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] No se encontraron los archivos correctos en /root/forensic_evidence/"
  fi

  # 2. Validar BRE IPs
  if [ -f /root/internal_traffic.txt ] && grep -q "172.16.5.22" /root/internal_traffic.txt && grep -q "172.16.99.180" /root/internal_traffic.txt && ! grep -q "192.168" /root/internal_traffic.txt; then
      echo "✔ [25%] Extracción BRE de IPs rango 172.16.x correcta."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] El archivo internal_traffic.txt no contiene las IPs esperadas."
  fi

  # 3. Validar ERE
  if [ -f /root/severe_errors.txt ] && grep -q "ERROR" /root/severe_errors.txt && grep -q "SEVERE" /root/severe_errors.txt && ! grep -q "INFO" /root/severe_errors.txt; then
      echo "✔ [25%] Filtrado ERE (ERROR|SEVERE) correcto."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] El archivo severe_errors.txt no filtró correctamente."
  fi

  # 4. Validar limpieza
  CLEAN_FILE="/root/service.conf.clean"
  if [ -f "$CLEAN_FILE" ]; then
      if ! grep -q "^#" "$CLEAN_FILE" && ! grep -q "^$" "$CLEAN_FILE" && grep -q "service_name" "$CLEAN_FILE"; then
          echo "✔ [25%] Archivo service.conf.clean generado correctamente."
          PUNTOS=$((PUNTOS + 25))
      else
          echo "❌ [0%] El archivo limpio aún tiene comentarios o líneas vacías."
      fi
  else
      echo "❌ [0%] No se generó $CLEAN_FILE"
  fi

  echo "============================"
  echo "CALIFICACIÓN FINAL: $PUNTOS / 100"
  echo "============================"
---

[[Laboratorios del LFCS]]
---
