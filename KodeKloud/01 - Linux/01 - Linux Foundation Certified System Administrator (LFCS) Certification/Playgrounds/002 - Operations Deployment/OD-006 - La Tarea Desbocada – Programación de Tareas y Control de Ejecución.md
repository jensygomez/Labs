---
Curso: Transición Sysadmin a DevOps - Operations Deployment LFCS/RHCSA
Modulo: Operations Deployment (Programación de Tareas y Control de Ejecución)
Playground: OD-006
Titulo: OD-006 - La Tarea Desbocada – Programación de Tareas y Control de Ejecución
Fecha de Inicio: 2026-07-02
Dificultad: 6/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS y RHCSA (Automatización con Cron y At).
  - Pensar como Sysadmin Linux Pleno (Auditoría de tareas del sistema vs usuario, control de ruido/logs).
  - Prepararme para DevOps Engineer y Sysadmin Kubernetes (Entender el scheduling de tareas periódicas y la salud de recursos).
Temas: |-
  - Formato y sintaxis de Crontab de usuario (crontab -e, -l, -u)
  - Directorios de tareas del sistema (/etc/cron.d/, /etc/cron.daily/, /etc/crontab)
  - Gestión de tareas de ejecución única con at y atq
  - Redirección de flujos en cron (evitar envíos de correo por omisión a root mediante > /path/log 2>&1)
  - Verificación y análisis de logs de ejecución (/var/log/cron o journalctl -u cron)
Competencias: |-
  - Auditar de manera exhaustiva las tareas programadas activas tanto a nivel de usuario (crontab) como en las rutas del sistema para identificar procesos desalineados con las ventanas de mantenimiento.
  - Diseñar e implementar expresiones cron cronológicamente correctas para mitigar picos de carga en horas pico, moviendo ejecuciones críticas a horarios nocturnos de bajo impacto.
  - Controlar y encauzar las salidas estándar y de error de los scripts automatizados hacia archivos de bitácora específicos, impidiendo la saturación o spam en el buzón local de correo de root.
  - Diagnosticar el histórico de ejecuciones pasadas mediante la inspección de bitácoras del sistema para verificar la frecuencia real y el estado de salida de los procesos programados.
Script: |-
  cat << 'OUTEREOF' > /tmp/setup_od006.sh
  #!/bin/bash
  set -e

  PASS="caleston123"
  USER_NET="bob"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10"
  SSH2="sshpass -p $PASS ssh $SSH_OPTS ${USER_NET}@${NODE_TARGET}"
  SSH3="sshpass -p $PASS ssh $SSH_OPTS ${USER_NET}@${NODE_VAULT}"

  echo -e "\e[1;33m⏳ Verificando dependencias en node01...\e[0m"
  if ! command -v sshpass &>/dev/null; then
      echo caleston123 | sudo -S apt-get install -y sshpass -qq
  fi

  echo -e "\e[1;33m⏳ Asegurando servicios cron y at en nodos remotos...\e[0m"
  $SSH2 "echo caleston123 | sudo -S apt-get install -y cron at -qq 2>/dev/null && echo caleston123 | sudo -S systemctl start cron atd || true"

  echo -e "\e[1;33m⏳ Inyectando tarea desbocada en node02...\e[0m"
  $SSH2 bash << 'NODE02_INJECT' || echo -e "\e[1;33m  [!] Detalle en node02, continuando...\e[0m"
  echo caleston123 | sudo -S bash << 'SUDO_INNER'

      # 1. Crear el script problemático que genera salida sin redirigir
      mkdir -p /opt/app/scripts
      cat > /opt/app/scripts/app_optimizer.sh << 'SCRIPT'
  #!/bin/bash
  echo "[$(date)] === INICIANDO OPTIMIZACIÓN AGRESIVA DE BASE DE DATOS ==="
  echo "[WARN] Uso de CPU elevado temporalmente..."
  # Simula proceso pesado
  echo "[OK] Índices reconstruidos exitosamente."
  SCRIPT
      chmod +x /opt/app/scripts/app_optimizer.sh

      # 2. Ocultar la tarea en /etc/cron.d con sintaxis de hora pico (12:00 PM todos los días)
      # Nota para el estudiante: Al estar en /etc/cron.d/, requiere especificar el usuario (root)
      cat > /etc/cron.d/bad_optimizer << 'CRONJOB'
  # Tarea de optimización del sistema (Revisar criticidad)
  0 12 * * * root /opt/app/scripts/app_optimizer.sh
  CRONJOB

      # 3. Simular spam en el correo de root
      mkdir -p /var/mail
      echo -e "From: root@node02\nSubject: Cron <root@node02> /opt/app/scripts/app_optimizer.sh\n\n[$(date)] === INICIANDO OPTIMIZACIÓN AGRESIVA DE BASE DE DATOS ===" >> /var/mail/root

      # 4. Asegurar que los logs de cron sean visibles
      touch /var/log/app_optimizer.log
      chown bob:bob /var/log/app_optimizer.log

      echo "[OD-006] Entorno de scheduling desbocado inyectado en node02."
  SUDO_INNER
  NODE02_INJECT

  echo -e "\e[1;33m⏳ Preparando bóveda de cumplimiento en node03...\e[0m"
  $SSH3 "echo caleston123 | sudo -S bash -c '
      rm -rf /opt/ops-compliance/od-006/
      mkdir -p /opt/ops-compliance/od-006/
      chown -R bob:bob /opt/ops-compliance/od-006/
      chmod 755 /opt/ops-compliance/od-006/
      exit 0
  ' || echo -e '\e[1;33m  [!] Advertencia en preparación de node03, continuando...\e[0m'"

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m OD-006-v1 | La Tarea Desbocada | Dificultad: 6/10 | L2\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e " Contraseña del cluster: \e[1mcaleston123\e[0m"
  echo -e " Control: node01  |  Afectado: node02  |  Bóveda: node03:/opt/ops-compliance/od-006/"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " El equipo de monitoreo reporta picos severos de uso de CPU en node02 todos los"
  echo -e " días a las 12:00 PM. Sospechan de un script llamado 'app_optimizer.sh'."
  echo -e " Además, el buzón de correo de root está saturado debido a la falta de"
  echo -e " redirecciones en las tareas programadas."
  echo -e ""
  echo -e " Como ingeniero L2, debes rastrear la tarea, moverla a la ventana segura"
  echo -e " de mantenimiento (3:00 AM) y silenciar el spam de correo enrutando la salida."
  echo -e ""
  echo -e "\e[1;33m RESTRICCIONES OPERACIONALES\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e " \e[1m>\e[0m Diagnóstico y corrección aplicados desde node01 vía SSH hacia node02."
  echo -e " \e[1m>\e[0m No dejes archivos temporales de texto persistentes en node01."
  echo -e " \e[1m>\e[0m No borres el script /opt/app/scripts/app_optimizer.sh, re-prográmalo."
  echo -e ""
  echo -e "\e[1;33m MISIONES TÉCNICAS (TICKET DE AUTOMATIZACIÓN - TIEMPO CONTROLADO: 30 MIN)\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e ""
  echo -e " \e[1mMISIÓN 1: Auditoría e Identificación de la Tarea (35%)\e[0m"
  echo -e "    Rastrea dónde está programado el script 'app_optimizer.sh'. Revisa el crontab"
  echo -e "    de los usuarios ('crontab -l', 'crontab -u bob -l') y los archivos de cron"
  echo -e "    del sistema en '/etc/'. Determina la ruta exacta del archivo responsable."
  echo -e ""
  echo -e " \e[1mMISIÓN 2: Reprogramación Eficiente y Enrutamiento de Logs (45%)\e[0m"
  echo -e "    Modifica la tarea identificada para cumplir con los estándares corporativos:"
  echo -e "      a) Cambia el horario de ejecución para las 3:00 AM de cada día (0 3 * * *)."
  echo -e "      b) Añade redirección completa para que tanto stdout como stderr se escriban"
  echo -e "         en el archivo existente \e[1m/var/log/app_optimizer.log\e[0m."
  echo -e "         (Evita por completo que cron envíe correos locales)."
  echo -e ""
  echo -e " \e[1mMISIÓN 3: Conciliación de Evidencia hacia la Bóveda (20%)\e[0m"
  echo -e "    Envía la solución para auditoría final. El archivo remoto en node03"
  echo -e "    \e[1m/opt/ops-compliance/od-006/reconciliation.txt\e[0m debe contener:"
  echo -e "      - El contenido final de la tarea cron corregida."
  echo -e "      - El estado actual del servicio cron ('systemctl status cron' o 'crond')."
  echo -e ""
  echo -e "\e[1;33m CRITERIOS DE ACEPTACIÓN\e[0m"
  echo -e "\e[1;36m--------------------------------------------------------------------------------\e[0m"
  echo -e "  [ ] Localización exitosa del archivo de configuración de cron          35%"
  echo -e "  [ ] Ajuste de sintaxis de tiempo a las 3:00 AM corporativo             25%"
  echo -e "  [ ] Redirección dual implementada (> /var/log/... 2>&1)                20%"
  echo -e "  [ ] Evidencia consolidada disponible en node03                         20%"
  echo -e "                                                                         -----"
  echo -e "                                                              TOTAL:     100%"
  echo -e ""
  echo -e "\e[1;33m TIEMPO ESTIMADO: 25-30 minutos\e[0m"
  echo -e ""
  echo -e "\e[1;36m================================================================================\e[0m"
  OUTEREOF

  bash /tmp/setup_od006.sh && rm -f /tmp/setup_od006.sh
tags:
  - Laboratorios-del-LFCS
  - Operations-Deployment
  - Cron
  - At-Scheduler
  - Task-Scheduling
  - Resource-Availability
  - Troubleshooting
Escenario: |-
  - Situación: El equipo de monitoreo reporta que todos los días a las 12:00 PM (hora pico de tráfico), node02 sufre una degradación crítica de CPU y ralentiza las aplicaciones. Al revisar los procesos running, sospechan de un script de optimización pesado ("app_optimizer.sh") que se programó de manera descuidada. Además, el buzón de correo del usuario root se está inundando de alertas porque el proceso no tiene redirecciones configuradas.

  Tu misión
  1. Localizar y Auditar la Tarea Intruza. Investiga en node02 si la tarea está corriendo desde el crontab del usuario 'bob', del usuario 'root', o si se encuentra oculta en los directorios de configuración global del sistema (/etc/cron.d/, /etc/crontab, etc.).

  2. Reprogramar y Corregir la Tarea. Mueve la ejecución de la tarea para que corra estrictamente durante la ventana de mantenimiento: todos los días a las 3:00 AM. Modifica su flujo para que NADA se envíe por correo; la salida estándar y los errores deben acumularse de forma persistente en /var/log/app_optimizer.log.

  3. Validar y Sincronizar Evidencia. Confirma que la sintaxis modificada sea válida inspeccionando que el demonio cron acepte la nueva configuración (puedes forzar una ejecución única de prueba con 'at' para las 3:00 AM o verificar con logs). Envía una copia de la tarea corregida y el estado del servicio cron hacia node03 en /opt/ops-compliance/od-006/reconciliation.txt de forma directa.

  Regla de Oro, No elimines el script original, solo corrige su planificación y sus redirecciones de salida. El monitoreo en node03 debe recibir la evidencia limpia mediante tuberías SSH desde node01.
---
[[Laboratorios del LFCS]]

---
