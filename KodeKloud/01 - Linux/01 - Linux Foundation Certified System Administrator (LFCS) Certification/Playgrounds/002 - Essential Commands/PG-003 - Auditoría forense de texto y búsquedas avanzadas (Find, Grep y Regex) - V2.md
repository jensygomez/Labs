---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Playground: PG-003-v2
Titulo: Auditoría forense de texto y búsquedas avanzadas (Find, Grep y Regex) - V2
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

  # 1. CREACIÓN DE IDENTIDADES Y ENTORNOS
  id -u contractor &>/dev/null || useradd -m -d /srv/contractor -s /bin/bash contractor
  id -u investigator &>/dev/null || useradd -m -d /srv/investigator -s /bin/bash investigator

  mkdir -p /srv/contractor/app/config
  mkdir -p /srv/contractor/app/logs
  mkdir -p /srv/investigator/forensic_evidence

  # 2. GENERACIÓN DE ARTEFACTOS CON "RUIDO" (TRAMPAS FORENSES)

  # TRAMPA FIND: Tres archivos pesados, solo uno cumple AMBAS condiciones estrictas (<36h Y >8MB)
  # Caso A: Cumple tamaño, cumple tiempo (10MB, hace 2 horas) -> DEBE SER COPIADO
  dd if=/dev/urandom of=/srv/contractor/app/config/sensitive_backup.img bs=1M count=10 2>/dev/null
  touch -m -d "2 hours ago" /srv/contractor/app/config/sensitive_backup.img

  # Caso B: Cumple tamaño, NO cumple tiempo (12MB, hace 40 horas / ~1.6 días) -> NO COPIAR
  dd if=/dev/urandom of=/srv/contractor/app/config/legacy_dump.img bs=1M count=12 2>/dev/null
  touch -m -d "40 hours ago" /srv/contractor/app/config/legacy_dump.img

  # Caso C: NO cumple tamaño, cumple tiempo (5MB, hace 1 hora) -> NO COPIAR
  dd if=/dev/urandom of=/srv/contractor/app/config/false_positive.img bs=1M count=5 2>/dev/null
  touch -m -d "1 hour ago" /srv/contractor/app/config/false_positive.img


  # TRAMPA GREP BRE: Log con IPs engañosas que contienen "172.16" pero cambian de octeto o son texto
  cat << 'LOGS' > /srv/contractor/app/logs/traffic.log
  2026-06-05 02:10:15 INFO Session established from 192.168.10.45
  2026-06-05 02:15:33 ERROR Failed login attempt from 172.16.5.22
  2026-06-05 02:18:01 WARNING Process initialisation status code: 172.1601
  2026-06-05 02:20:10 WARNING Unusual port scan from public host 172.166.99.4
  2026-06-05 02:25:47 SEVERE Data exfiltration attempt to 172.16.99.180
  2026-06-05 02:30:05 INFO Normal traffic from 10.10.10.50
  2026-06-05 02:35:12 ERROR Database timeout on backend-03. Internal tracking ID: ref-172-16-9
  LOGS


  # TRAMPA CLEAN CONFIG: Comentarios tabulados, líneas con espacios en blanco y comentarios inline
  cat << 'CONF' > /srv/contractor/app/config/service.conf
  # Main service configuration v3.2
  service_name = secure_gateway

      # Listening configuration (Tabulado a propósito)
  bind_address = 0.0.0.0
  port = 9443          # Production listening port (Comentario inline!)
  max_clients = 1200

  # Security section
  # tls_enabled = true
  # debug = false   <- never enable in production
        
  log_level = info
  CONF


  # 3. PERMISOS Y ACLs (Manteniendo el entorno logístico aislado)
  chown -R contractor:contractor /srv/contractor
  chmod 750 /srv/contractor
  chmod -R 740 /srv/contractor/app/

  setfacl -R -m u:investigator:r-x /srv/contractor/
  setfacl -R -m u:investigator:r-- /srv/contractor/app/config/*
  setfacl -R -m u:investigator:r-- /srv/contractor/app/logs/*

  chown -R investigator:investigator /srv/investigator
  chmod 700 /srv/investigator

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;31m 🔍 ENTORNO CALIBRADO - AUDITORÍA FORENSE AVANZADA (PG-003-v2-HARDENED)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-3147 (NIVEL: JUNIOR-TO-SENIOR DRILL)\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mIdentidad para el laboratorio:\e[0m Ejecute: \e[1;32msudo su - investigator\e[0m"
  echo -e " \e[1mEvidencia base en:\e[0m /srv/contractor"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1m⚠️ ALERTA DE CONFIGURACIÓN:\e[0m"
  echo -e "  El entorno contiene múltiples 'falsos positivos'. Sus comandos de búsqueda"
  echo -e "  deben ser quirúrgicos. Si sus expresiones regulares o filtros de tiempo"
  echo -e "  son demasiado generales, arrastrará basura y fallará la auditoría legal."
  echo -e ""
  echo -e " \e[1mTareas requeridas (Como usuario 'investigator'):\e[0m"
  echo -e ""
  echo -e "  \e[1;31m1.\e[0m Localice en '/srv/contractor' el archivo exacto que supere los 8MB"
  echo -e "     Y que haya sido modificado estrictamente en las últimas 36 horas."
  echo -e "     Cópielo a '/srv/investigator/forensic_evidence/'."
  echo -e "     *(Cuidado con los archivos que cumplen solo una de las condiciones)*"
  echo -e ""
  echo -e "  \e[1;31m2.\e[0m Extraiga de 'traffic.log' solo las líneas con IPs del segmento"
  echo -e "     privado '172.16.x.x' usando una expresión regular básica (BRE)."
  echo -e "     Guarde el resultado en '/srv/investigator/internal_traffic.txt'."
  echo -e "     *(Debe excluir IDs de procesos como 172.1601 o IPs públicas como 172.166.x.x)*"
  echo -e ""
  echo -e "  \e[1;31m3.\e[0m Extraiga del mismo log las líneas con eventos 'ERROR' o 'SEVERE'"
  echo -e "     usando una sola expresión regular extendida (ERE)."
  echo -e "     Guarde el resultado en '/srv/investigator/severe_errors.txt'."
  echo -e ""
  echo -e "  \e[1;31m4.\e[0m Genere una copia limpia en '/srv/investigator/service.conf.clean'."
  echo -e "     Debe remover: líneas vacías, líneas que solo contienen espacios/tabs,"
  echo -e "     líneas de comentarios (que inicien con # o espacios+#) Y limpiar los"
  echo -e "     comentarios inline (como el que está al final del parámetro 'port')."
  echo -e ""
  echo -e " \e[1mCriterios de Validación Rigurosa:\e[0m"
  echo -e "  [ ] Archivo exacto en forensic_evidence/ (1 único archivo)             --> \e[1;35m25%\e[0m"
  echo -e "  [ ] internal_traffic.txt limpio sin falsos positivos de red            --> \e[1;35m25%\e[0m"
  echo -e "  [ ] Timeline de errores (ERROR|SEVERE) correcto                       --> \e[1;35m25%\e[0m"
  echo -e "  [ ] service.conf.clean sin comentarios de ningún tipo ni líneas vacías --> \e[1;35m25%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32mNota del Instructor:\e[0m Si usas atajos perezosos, el script de evaluación"
  echo -e "                     lo detectará. Piensa en las expresiones regulares."
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup_sh && rm -f /tmp/setup_sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash

  # ==============================================================================
  # SCRIPT DE EVALUACIÓN AUTOMÁTICA (PG-003-v2-HARDENED)
  # ==============================================================================

  PUNTOS=0
  TARGET_DIR="/srv/investigator"

  echo -e "\e[1;36m=== EVALUANDO ENTORNO FORENSE ENDURECIDO (7.5/10) ===\e[0m"

  # 1. VALIDAR FIND (Filtrado estricto de tamaño y tiempo)
  # Debe existir un solo archivo copiado, y no los otros dos falsos positivos.
  if [ -f "$TARGET_DIR/forensic_evidence/sensitive_backup.img" ]; then
      if [ ! -f "$TARGET_DIR/forensic_evidence/legacy_dump.img" ] && [ ! -f "$TARGET_DIR/forensic_evidence/false_positive.img" ]; then
          echo -e "✔ \e[1;32m[25%]\e[0m Búsqueda 'find' quirúrgica correcta. Evitó falsos positivos de tiempo/tamaño."
          PUNTOS=$((PUNTOS + 25))
      else
          echo -e "❌ \e[1;31m[0%]\e[0m Fallo en 'find': Copió archivos que no cumplían ambas condiciones simultáneamente."
      fi
  else
      echo -e "❌ \e[1;31m[0%]\e[0m No se encontró el artefacto correcto en forensic_evidence/."
  fi

  # 2. VALIDAR BRE IPs (Exclusión de falsos positivos de Red)
  # Debe contener las dos IPs del segmento, pero NO el proceso 172.1601 ni la IP pública 172.166.x.x
  TRAFFIC_FILE="$TARGET_DIR/internal_traffic.txt"
  if [ -f "$TRAFFIC_FILE" ]; then
      # Cuenta cuántas líneas tiene el archivo entregado
      TOTAL_LINES=$(wc -l < "$TRAFFIC_FILE")
      
      if grep -q "172.16.5.22" "$TRAFFIC_FILE" && \
         grep -q "172.16.99.180" "$TRAFFIC_FILE" && \
         ! grep -q "172.1601" "$TRAFFIC_FILE" && \
         ! grep -q "172.166" "$TRAFFIC_FILE" && \
         [ "$TOTAL_LINES" -eq 2 ]; then
          echo -e "✔ \e[1;32m[25%]\e[0m Extracción BRE de IPs correcta. Regex limpia sin falsos positivos."
          PUNTOS=$((PUNTOS + 25))
      else
          echo -e "❌ \e[1;31m[0%]\e[0m internal_traffic.txt contiene ruido (capturó IDs de proceso o subredes incorrectas)."
      fi
  else
      echo -e "❌ \e[1;31m[0%]\e[0m No se generó el archivo internal_traffic.txt."
  fi

  # 3. VALIDAR ERE (Timeline de Errores)
  SEVERE_FILE="$TARGET_DIR/severe_errors.txt"
  if [ -f "$SEVERE_FILE" ]; then
      if grep -q "ERROR" "$SEVERE_FILE" && grep -q "SEVERE" "$SEVERE_FILE" && ! grep -q "INFO" "$SEVERE_FILE" && ! grep -q "WARNING" "$SEVERE_FILE"; then
          echo -e "✔ \e[1;32m[25%]\e[0m Filtrado ERE (ERROR|SEVERE) impecable."
          PUNTOS=$((PUNTOS + 25))
      else
          echo -e "❌ \e[1;31m[0%]\e[0m severe_errors.txt contiene eventos no solicitados (INFO/WARNING) o está incompleto."
      fi
  else
      echo -e "❌ \e[1;31m[0%]\e[0m No se generó el archivo severe_errors.txt."
  fi

  # 4. VALIDAR LIMPIEZA DE CONFIGURACIÓN (Prueba reina de SED/Regex)
  CLEAN_FILE="$TARGET_DIR/service.conf.clean"
  if [ -f "$CLEAN_FILE" ]; then
      # Chequeos minuciosos:
      # - No debe haber líneas que arranquen con '#' (comentarios puros)
      # - No debe haber líneas vacías o que solo tengan espacios/tabs
      # - El comentario inline del puerto DEBE haber sido removido (la línea debe terminar exactamente en 9443)
      HAS_COMMENTS=$(grep -E '^\s*#' "$CLEAN_FILE" || true)
      HAS_BLANK_LINES=$(grep -E '^\s*$' "$CLEAN_FILE" || true)
      INLINE_CLEANED=$(grep -E 'port = 9443\s*$' "$CLEAN_FILE" || true)
      
      if [ -z "$HAS_COMMENTS" ] && [ -z "$HAS_BLANK_LINES" ] && [ -n "$INLINE_CLEANED" ] && grep -q "service_name" "$CLEAN_FILE"; then
          echo -e "✔ \e[1;32m[25%]\e[0m service.conf.clean procesado con nivel experto (sin comentarios inline ni basura)."
          PUNTOS=$((PUNTOS + 25))
      else
          echo -e "❌ \e[1;31m[0%]\e[0m service.conf.clean inválido. No eliminó los comentarios inline o dejó espacios/líneas vacías."
      fi
  else
      echo -e "❌ \e[1;31m[0%]\e[0m No se generó el archivo service.conf.clean."
  fi

  # COLOCACIÓN DE NOTA FINAL
  echo -e "\e[1;36m================================================================================\e[0m"
  if [ $PUNTOS -eq 100 ]; then
      echo -e "  \e[1;32mCALIFICACIÓN FINAL: $PUNTOS / 100 — ¡AUDITORÍA CON CORTE EMPRESARIAL EXITOSA!\e[0m"
  else
      echo -e "  \e[1;31mCALIFICACIÓN FINAL: $PUNTOS / 100 — REVISE SUS EXPRESIONES REGULARES\e[0m"
  fi
  echo -e "\e[1;36m================================================================================\e[0m"
---

[[Laboratorios del LFCS]]
---
