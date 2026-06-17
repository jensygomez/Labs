---
Curso: Transición Sysadmin a DevOps - Essential Commands LFCS/RHCSA
Modulo: Essential Commands (Fundamentos Linux)
Playground: EC-001-v1
Titulo: El Acceso Perdido – Conectividad y Documentación del Sistema
Fecha de Inicio: 2026-06-15
Dificultad: 7/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno
  - Prepararme para DevOps Engineer y Kubernetes
Temas: |-
  - SSH avanzado: Diagnóstico con modo verbose (ssh -v) y la directiva de seguridad StrictModes (permisos de directorios .ssh)
  - Gestión de Paquetes y Repositorios: Depuración de configuraciones corruptas en /etc/yum.repos.d/ y saneamiento del caché de dnf
  - man pages (secciones 1, 5, 8), info, help y reconstrucción del índice de documentación con mandb
  - Procesamiento avanzado de flujos de texto (Data Streams) en pipelines utilizando filtros de exclusión (grep/sed)
Competencias: |-
  - Diagnosticar fallos silenciosos de autenticación por clave SSH analizando la verbosidad del cliente y corrigiendo infracciones de StrictModes en el servidor remoto.
  - Reparar archivos de configuración de repositorios DNF alterados para desbloquear el administrador de paquetes del sistema operativo.
  - Reconstruir índices del sistema de documentación manual tras instalaciones forzadas o recuperaciones críticas.
  - Construir pipelines complejos que procesen, limpien y purguen líneas de comentarios/vacías de archivos de configuración antes de su transmisión remota a node03.
Script: |-
  cat << 'EOF' > /tmp/setup.sh
  #!/bin/bash
  # =============================================================================
  # EC-001-v1 | El Acceso Perdido – Conectividad y Documentación del Sistema (Voltaje 7/10)
  # Ejecutar ÚNICAMENTE desde node01 como usuario bob
  # =============================================================================
  set -e

  # Colores
  RED='\e[1;31m'
  GREEN='\e[1;32m'
  YELLOW='\e[1;33m'
  CYAN='\e[1;36m'
  BLUE='\e[1;34m'
  BOLD='\e[1m'
  MAGENTA='\e[1;35m'
  WHITE='\e[1;37m'
  RESET='\e[0m'

  echo -e "${YELLOW}⏳ Iniciando configuración del escenario avanzado EC-001 (Dificultad: 7/10)...${RESET}"

  # ============================================
  # FASE 1 — CONFIGURAR NODE02 REMOTAMENTE
  # ============================================
  echo -e "${CYAN}[+] Configurando node02 (servidor con problemas e inyección de fallos L2)...${RESET}"

  sshpass -p 'caleston123' ssh -o StrictHostKeyChecking=no bob@node02 'bash -s' << 'NODE02_SCRIPT'
  set -e

  # 1. Eliminar paquetes de documentación del sistema ANTES de alterar los repositorios
  sudo dnf remove -y man-db info 2>/dev/null || true

  # 2. Fallo de Repositorio: Corromper la base de DNF con un archivo malformado
  # Esto detendrá cualquier ejecución estándar de dnf debido a un error sintáctico global.
  sudo tee /etc/yum.repos.d/security_hardening_backup.repo > /dev/null << 'REPO_FAIL'
  [hardening_backup]
  name=TechCorp Hardening Backup - Temporary
  baseurl=http://internal-vault.security.local/rhel/9/prod
  enabled=1
  gpgcheck=1
  # ERROR_CODE: 0x88492
  UNEXPECTED_TOKEN_MALFORMED_VALUE_WITHOUT_KEY
  REPO_FAIL

  # 3. Fallo de SSH: Trampa de StrictModes
  # Se limpia el archivo authorized_keys pero se alteran los modos de permisos.
  # SSH desestimará las llaves de forma silenciosa obligando al uso de diagnóstico verbose (ssh -v).
  mkdir -p ~/.ssh
  echo "" > ~/.ssh/authorized_keys
  chmod 777 ~/.ssh
  chmod 666 ~/.ssh/authorized_keys

  # 4. Crear archivo de configuración crítica con metadatos, comentarios y espacios
  sudo mkdir -p /etc/app-config
  sudo tee /etc/app-config/settings.conf > /dev/null << 'CONF'
  # ===================================================================
  # App Configuration - Production Server
  # Enterprise CoreService Architecture v3
  # ===================================================================

  APP_NAME=CoreService
  APP_VERSION=3.2.1
  APP_PORT=8443

  # Log level parameter: DEBUG, INFO, WARNING, ERROR, CRITICAL
  APP_LOG_LEVEL=WARNING
  APP_MAX_CONNECTIONS=500
  APP_TIMEOUT=30

  # Database Connectivity Parameters
  DB_HOST=db-prod-01.internal
  DB_PORT=5432
  DB_NAME=coreservice_prod
  DB_USER=svc_coreservice

  # Automated Backup Framework Policy
  BACKUP_ENABLED=true
  BACKUP_SCHEDULE=0 2 * * *
  BACKUP_RETENTION_DAYS=30

  # ===================================================================
  # End of Configuration File
  # ===================================================================
  CONF
  sudo chmod 644 /etc/app-config/settings.conf
  NODE02_SCRIPT

  echo -e "${GREEN}[✓] node02 configurado con las restricciones del escenario${RESET}"

  # ============================================
  # FASE 2 — CONFIGURAR NODE03 REMOTAMENTE
  # ============================================
  echo -e "${CYAN}[+] Configurando node03 (backup vault estricto)...${RESET}"

  sshpass -p 'caleston123' ssh -o StrictHostKeyChecking=no bob@node03 'bash -s' << 'NODE03_SCRIPT'
  set -e
  sudo mkdir -p /opt/backup-vault/essential-commands
  sudo chown bob:bob /opt/backup-vault/essential-commands
  sudo chmod 750 /opt/backup-vault/essential-commands
  NODE03_SCRIPT

  echo -e "${GREEN}[✓] node03 preparado como backup vault${RESET}"

  # ============================================
  # FASE 3 — PREPARAR NODE01 Y LANZAR TICKET
  # ============================================
  echo -e "${CYAN}[+] Preparando estación de administración node01...${RESET}"

  sudo dnf install -y sshpass -q 2>/dev/null || true

  mkdir -p "$HOME/EC-001-lab"
  cd "$HOME/EC-001-lab"

  sleep 1
  clear

  echo -e "${CYAN}================================================================================${RESET}"
  echo -e "${YELLOW}  TICKET INC-4471  │  Severidad: CRÍTICA  │  Ambiente: PRODUCCIÓN (L2)${RESET}"
  echo -e "${CYAN}================================================================================${RESET}"
  echo -e "${GREEN}  ⚙️  EC-001-v1 — El Acceso Perdido: Conectividad y Documentación del Sistema${RESET}"
  echo -e "${CYAN}  Módulo: Essential Commands  │  Dificultad: 7/10  │  Nivel: L2 Avanzado${RESET}"
  echo -e " -------------------------------------------------------------------------------"
  echo -e " ${BOLD}Arquitectura del Escenario:${RESET}"
  echo -e "  ${BLUE}[node01]${RESET} → Estación de Administración  (TU POSICIÓN ACTUAL)"
  echo -e "  ${RED}[node02]${RESET} → Servidor con Problemas      (OBJETIVO DE DIAGNÓSTICO)"
  echo -e "  ${GREEN}[node03]${RESET} → Backup Empresarial          (DESTINO DE RESULTADOS SANITIZADOS)"
  echo -e " -------------------------------------------------------------------------------"
  echo -e " ${BOLD}Contexto del Incidente:${RESET}"
  echo -e ""
  echo -e "  El proveedor externo de seguridad aplicó políticas de hardening el fin"
  echo -e "  de semana en node02. Al iniciar el turno, el acceso por clave SSH está"
  echo -e "  completamente roto. El proveedor insiste en que limpió el archivo"
  echo -e "  'authorized_keys' pero que la infraestructura está lista para recibir"
  echo -e "  las llaves corporativas. Sin embargo, los primeros intentos de inyección"
  echo -e "  de llaves fallan: el servidor sigue pidiendo contraseña repetidamente."
  echo -e "  Sospechamos que el script del proveedor alteró los permisos de las"
  echo -e "  carpetas ocultas, activando los bloqueos automáticos de 'StrictModes'."
  echo -e ""
  echo -e "  Para colmo de males, el equipo de desarrollo reporta que no puede consultar"
  echo -e "  la sintaxis de los comandos locales porque la documentación fue removida."
  echo -e "  Al intentar reinstalar los paquetes 'man-db' e 'info', el administrador"
  echo -e "  de paquetes DNF arroja un error crítico de sintaxis y aborta la operación,"
  echo -e "  dejando al servidor incomunicado de sus repositorios."
  echo -e ""
  echo -e "  Finalmente, SecOps exige evacuar el archivo '/etc/app-config/settings.conf'"
  echo -e "  hacia el vault empresarial en node03 de forma inmediata, pero con una"
  echo -e "  restricción estricta de cumplimiento: el archivo debe ser sanitizado en"
  echo -e "  caliente durante la transferencia. No se permite almacenar comentarios (#)"
  echo -e "  ni líneas en blanco en el almacenamiento de resguardo."
  echo -e ""
  echo -e " -------------------------------------------------------------------------------"
  echo -e " ${BOLD}Restricciones Operativas:${RESET}"
  echo -e ""
  echo -e "  ${RED}⚠${RESET}  Diagnostica la denegación de la llave usando el modo verbose de SSH."
  echo -e "     Corrige las violaciones de políticas de permisos en node02 antes de"
  echo -e "     dar por completado el acceso por par de claves."
  echo -e ""
  echo -e "  ${RED}⚠${RESET}  Sanea el subsistema DNF localizando y eliminando la configuración"
  echo -e "     corrupta introducida en los archivos de repositorios remotos."
  echo -e ""
  echo -e "  ${RED}⚠${RESET}  Está estrictamente prohibido materializar o guardar archivos temporales"
  echo -e "     de resultados en node01. Todo debe fluir en flujos de datos puros (|)."
  echo -e ""
  echo -e " -------------------------------------------------------------------------------"
  echo -e " ${BOLD}Parámetros Técnicos Obligatorios:${RESET}"
  echo -e ""
  echo -e "  ${RED}1. Solucionar e Implementar Acceso SSH por Clave (StrictModes)${RESET}"
  echo -e "     Usa sshpass para auditar node02. Detecta el fallo de permisos e impón"
  echo -e "     el estándar seguro de SSH sobre los directorios correspondientes. Configura"
  echo -e "     el acceso sin contraseña y consolida el hardening deshabilitando"
  echo -e "     PasswordAuthentication en el sshd_config remoto."
  echo -e ""
  echo -e "  ${RED}2. Reparar Infraestructura de Paquetes y Documentación${RESET}"
  echo -e "     Identifica y elimina el archivo corrupto en /etc/yum.repos.d/. Instala"
  echo -e "     man-db e info. Obligatorio: Ejecuta la regeneración manual del índice"
  echo -e "     de páginas de manual utilizando la herramienta del sistema 'mandb'."
  echo -e "     Verifica la disponibilidad de las secciones de man 1, 5 y 8."
  echo -e "     "
  echo -e "  ${RED}3. Pipeline de Extracción y Sanitización de Texto Extremo${RESET}"
  echo -e "     Construye una tubería que extraiga /etc/app-config/settings.conf desde"
  echo -e "     node02, filtre y remueva quirúrgicamente todas las líneas de comentarios"
  echo -e "     y todas las líneas vacías, inyectando el resultado directamente en node03."
  echo -e ""
  echo -e " ${BOLD}Entregables requeridos en node03:${RESET}"
  echo -e "  - ${BOLD}/opt/backup-vault/essential-commands/settings-sanitized.conf${RESET} (Solo parámetros clave=valor)"
  echo -e "  - ${BOLD}/opt/backup-vault/essential-commands/ssh-man-summary.txt${RESET} (Definición limpia de man 1 ssh)"
  echo -e "  - ${BOLD}/opt/backup-vault/essential-commands/ssh-key-report.txt${RESET} (Fingerprint de la clave generada)"
  echo -e ""
  echo -e " ${BOLD}Criterios de Aceptación:${RESET}"
  echo -e ""
  echo -e "  [ ] Corrección de StrictModes (permisos seguros de carpeta .ssh)  --> ${MAGENTA}25%${RESET}"
  echo -e "  [ ] Acceso SSH transparente por clave pública (sin contraseña)   --> ${MAGENTA}15%${RESET}"
  echo -e "  [ ] Eliminación de repositorio corrupto y restauración de man-db  --> ${MAGENTA}20%${RESET}"
  echo -e "  [ ] Índice de documentación reconstruido mediante comando 'mandb' --> ${MAGENTA}10%${RESET}"
  echo -e "  [ ] settings-sanitized.conf sin comentarios (#) ni líneas vacías --> ${MAGENTA}20%${RESET}"
  echo -e "  [ ] Reportes de ssh y llaves alojados correctamente en node03     --> ${MAGENTA}10%${RESET}"
  echo -e "  [ ] Presencia de archivos de evidencia locales en node01        ${RED}(DESCALIFICA)${RESET}"
  echo -e " -------------------------------------------------------------------------------"
  echo -e " ${GREEN}🚨 REGLA DE ORO DE LA OPERACIÓN:${RESET}"
  echo -e "  - Trabaja SIEMPRE desde la consola de ${BOLD}node01${RESET}."
  echo -e "  - Modifica las configuraciones utilizando filtros y automatizaciones remotas."
  echo -e "  - Todo archivo final debe viajar entubado por la red directamente al vault."
  echo -e "${CYAN}================================================================================${RESET}"
  EOF
  chmod +x /tmp/setup.sh
  bash /tmp/setup.sh
  rm -f /tmp/setup.sh
tags:
  - Laboratorios-del-LFCS
  - Essential-Commands
  - Linux-Fundamentals
  - SSH-Troubleshooting
  - Package-Management
  - Text-Processing
Escenario: |-
  Un proveedor externo de seguridad ejecutó controles de hardening sobre `node02` durante una ventana de mantenimiento del fin de semana. Al reiniciar operaciones el lunes, el equipo de aplicaciones reportó pérdida total de acceso SSH. La investigación inicial reveló que el proveedor no solo vació el archivo `authorized_keys`, sino que alteró de forma incorrecta los permisos del directorio raíz del usuario y de la carpeta `.ssh` en `node02`. Esto provoca que el demonio SSH rechace silenciosamente cualquier intento de autenticación por clave debido a las reglas de cumplimiento de `StrictModes`, frustrando los métodos estándar de copia de llaves.

  Adicionalmente, el script de limpieza del proveedor desinstaló la documentación del sistema (`man-db`, `info`) y corrompió deliberadamente el archivo del repositorio local en `/etc/yum.repos.d/`, provocando que cualquier intento de reinstalación falle por fallas de sincronización de metadatos. Por último, el archivo crítico `/etc/app-config/settings.conf` sigue sin respaldo, y las nuevas políticas del vault en `node03` prohíben estrictamente almacenar metadatos basura: todo archivo de configuración que se reciba debe ser sanitizado en caliente a través del pipeline, eliminando cualquier comentario o línea vacía antes de ser guardado en el disco de resguardo.

  El ticket escala a L2 remoto con prioridad crítica. Tienes una ventana de acceso temporal por contraseña vía `sshpass` en `node02`. Tu misión consiste en conectarte usando herramientas de diagnóstico para identificar el fallo de permisos SSH, reparar la base de repositorios de DNF para restaurar las páginas de manual (regenerando su índice con `mandb`), y estructurar un pipeline avanzado de filtrado de texto que evacúe la configuración limpia directamente a `node03` sin dejar rastros intermedios en tu estación de administración (`node01`).
---
[[Laboratorios del LFCS]]

----

