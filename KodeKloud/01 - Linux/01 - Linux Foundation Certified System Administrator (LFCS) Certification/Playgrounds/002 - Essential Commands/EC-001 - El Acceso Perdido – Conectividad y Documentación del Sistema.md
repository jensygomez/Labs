---
Curso: Transición Sysadmin a DevOps - Essential Commands LFCS/RHCSA
Modulo: Essential Commands (Fundamentos Linux)
Playground: EC-001-v1
Titulo: El Acceso Perdido – Conectividad y Documentación del Sistema
Fecha de Inicio: 2026-06-14
Dificultad: 5/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno
  - Prepararme para DevOps Engineer y Kubernetes
Temas: |-
  - SSH y autenticación por clave pública/privada
  - sshpass y acceso remoto desde estación de administración
  - man pages (secciones 1, 5, 8), info, help, /usr/share/doc
  - Instalación de paquetes de documentación (man-db, info)
  - Extracción de información crítica desde archivos de configuración
Competencias: |-
  - Configurar autenticación SSH con par de claves sin depender de contraseña
  - Navegar y extraer información precisa de man pages por sección
  - Recuperar documentación del sistema en un servidor con paquetes faltantes
  - Enviar resultados de diagnóstico a un servidor de backup via pipeline SSH
Script: |-
  cat << 'EOF' > /tmp/setup.sh
  cat << 'EOF' > /tmp/setup.sh
  #!/bin/bash
  # =============================================================================
  # EC-001-v1 | El Acceso Perdido – Conectividad y Documentación del Sistema
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

  echo -e "${YELLOW}⏳ Iniciando configuración del escenario EC-001...${RESET}"

  # ============================================
  # FASE 1 — CONFIGURAR NODE02 REMOTAMENTE
  # ============================================
  echo -e "${CYAN}[+] Configurando node02 (servidor con problemas)...${RESET}"

  sshpass -p 'caleston123' ssh -o StrictHostKeyChecking=no bob@node02 'bash -s' << 'NODE02_SCRIPT'
  set -e

  # Fallo 1: Eliminar clave pública preexistente
  # El proveedor limpió authorized_keys durante el hardening del fin de semana.
  # La contraseña sigue activa — es la única ventana de acceso disponible para el L2 remoto.
  # El ingeniero deberá copiar su clave y luego completar el hardening deshabilitando la contraseña.
  mkdir -p ~/.ssh
  > ~/.ssh/authorized_keys
  chmod 600 ~/.ssh/authorized_keys

  # Fallo 2: Eliminar paquetes de documentación del sistema
  sudo dnf remove -y man-db info 2>/dev/null || true

  # Fallo 3: Crear archivo de configuración crítica de la aplicación
  sudo mkdir -p /etc/app-config
  sudo tee /etc/app-config/settings.conf > /dev/null << 'CONF'
  # App Configuration - Production Server
  APP_NAME=CoreService
  APP_VERSION=3.2.1
  APP_PORT=8443
  APP_LOG_LEVEL=WARNING
  APP_MAX_CONNECTIONS=500
  APP_TIMEOUT=30
  DB_HOST=db-prod-01.internal
  DB_PORT=5432
  DB_NAME=coreservice_prod
  DB_USER=svc_coreservice
  BACKUP_ENABLED=true
  BACKUP_SCHEDULE=0 2 * * *
  BACKUP_RETENTION_DAYS=30
  CONF
  sudo chmod 644 /etc/app-config/settings.conf
  NODE02_SCRIPT

  echo -e "${GREEN}[✓] node02 configurado correctamente${RESET}"

  # ============================================
  # FASE 2 — CONFIGURAR NODE03 REMOTAMENTE
  # ============================================
  echo -e "${CYAN}[+] Configurando node03 (backup vault)...${RESET}"

  sshpass -p 'caleston123' ssh -o StrictHostKeyChecking=no bob@node03 'bash -s' << 'NODE03_SCRIPT'
  set -e
  sudo mkdir -p /opt/backup-vault/essential-commands
  sudo chown bob:bob /opt/backup-vault/essential-commands
  sudo chmod 750 /opt/backup-vault/essential-commands
  NODE03_SCRIPT

  echo -e "${GREEN}[✓] node03 preparado como backup vault${RESET}"

  # ============================================
  # FASE 3 — PREPARAR NODE01
  # ============================================
  echo -e "${CYAN}[+] Preparando estación de administración node01...${RESET}"

  sudo dnf install -y sshpass -q 2>/dev/null || true

  mkdir -p "$HOME/EC-001-lab"
  cd "$HOME/EC-001-lab"

  sleep 1
  clear

  echo -e "${CYAN}================================================================================${RESET}"
  echo -e "${YELLOW}  TICKET INC-4471  │  Severidad: ALTA  │  Ambiente: PRODUCCIÓN${RESET}"
  echo -e "${CYAN}================================================================================${RESET}"
  echo -e "${GREEN}  ⚙️  EC-001-v1 — El Acceso Perdido: Conectividad y Documentación del Sistema${RESET}"
  echo -e "${CYAN}  Módulo: Essential Commands  │  Dificultad: 5/10  │  Nivel: L2${RESET}"
  echo -e " -------------------------------------------------------------------------------"
  echo -e " ${BOLD}Arquitectura del Escenario:${RESET}"
  echo -e "  ${BLUE}[node01]${RESET} → Estación de Administración  (TU POSICIÓN ACTUAL)"
  echo -e "  ${RED}[node02]${RESET} → Servidor con Problemas      (OBJETIVO DE DIAGNÓSTICO)"
  echo -e "  ${GREEN}[node03]${RESET} → Backup Empresarial          (DESTINO DE RESULTADOS)"
  echo -e " -------------------------------------------------------------------------------"
  echo -e " ${BOLD}Contexto del Incidente:${RESET}"
  echo -e ""
  echo -e "  El señor Harpreet Singh, coordinador de infraestructura de TechCorp,"
  echo -e "  recibió el lunes por la tarde una llamada del proveedor externo de"
  echo -e "  seguridad. Le informaron que, durante la madrugada del fin de semana,"
  echo -e "  habían aprovechado una ventana de baja actividad para aplicar los"
  echo -e "  controles de hardening que la auditoría trimestral había exigido sobre"
  echo -e "  el servidor de producción node02. El señor Harpreet Singh, satisfecho"
  echo -e "  con la noticia, agradeció la diligencia del proveedor, confirmó que"
  echo -e "  todo estaba en orden y continuó con su día sin mayor preocupación."
  echo -e ""
  echo -e "  El martes por la mañana, a las 08:17, el ingeniero de turno abrió su"
  echo -e "  terminal, escribió su usuario y contraseña para entrar a node02, y el"
  echo -e "  servidor le respondió con un rechazo. Lo intentó una segunda vez,"
  echo -e "  pensando que había cometido un error tipográfico. El servidor volvió a"
  echo -e "  rechazarlo. Llamó al señor Harpreet Singh. El señor Harpreet Singh"
  echo -e "  llamó al proveedor. El proveedor explicó, con toda la tranquilidad"
  echo -e "  del mundo, que la autenticación por contraseña había sido deshabilitada"
  echo -e "  como parte del hardening, que eso era precisamente lo que la auditoría"
  echo -e "  había solicitado, y que las claves SSH correspondientes debían ser"
  echo -e "  configuradas por el equipo interno. Nadie había documentado el cambio."
  echo -e "  Nadie había coordinado el procedimiento con anterioridad."
  echo -e ""
  echo -e "  Mientras el señor Harpreet Singh intentaba gestionar aquella conversación,"
  echo -e "  llegó un segundo ticket. El equipo de aplicaciones reportó que durante la"
  echo -e "  misma intervención del fin de semana, el script de limpieza del proveedor"
  echo -e "  había eliminado los paquetes de documentación del sistema en node02."
  echo -e "  Los ingenieros ya no podían consultar man pages directamente en el"
  echo -e "  servidor. Para revisar la sintaxis de cualquier comando tenían que salir"
  echo -e "  a internet o llamar a un colega. La situación se estaba complicando."
  echo -e ""
  echo -e "  Para entonces, el equipo de base de datos había abierto un tercer ticket."
  echo -e "  El archivo /etc/app-config/settings.conf en node02, que contiene todos"
  echo -e "  los parámetros críticos de la aplicación CoreService, nunca había sido"
  echo -e "  respaldado formalmente en el vault empresarial. Si algo salía mal durante"
  echo -e "  la recuperación, nadie podría reconstruir la configuración original."
  echo -e ""
  echo -e "  El señor Harpreet Singh te ha asignado como ingeniero responsable de"
  echo -e "  atender los tres tickets de forma coordinada. Él está esperando el"
  echo -e "  reporte de cierre antes del mediodía. El equipo de aplicaciones está"
  echo -e "  esperando que el acceso a node02 sea restablecido. Y el vault de"
  echo -e "  node03 está vacío, esperando los respaldos que nunca llegaron."
  echo -e ""
  echo -e " -------------------------------------------------------------------------------"
  echo -e " ${BOLD}Restricciones Operativas:${RESET}"
  echo -e ""
  echo -e "  ${RED}⚠${RESET}  El proveedor eliminó todas las claves públicas autorizadas en node02."
  echo -e "     La autenticación por contraseña sigue activa temporalmente."
  echo -e "     Usa sshpass con caleston123 para copiar tu clave pública."
  echo -e "     Como paso final del hardening, deshabilita la autenticación por"
  echo -e "     contraseña una vez que la clave esté operativa."
  echo -e ""
  echo -e "  ${RED}⚠${RESET}  Todos los resultados de diagnóstico y los archivos de evidencia"
  echo -e "     deben ser enviados directamente a node03 via pipeline. Está"
  echo -e "     estrictamente prohibido almacenar archivos de resultados en node01."
  echo -e ""
  echo -e " -------------------------------------------------------------------------------"
  echo -e " ${BOLD}Parámetros Técnicos Obligatorios:${RESET}"
  echo -e ""
  echo -e "  ${RED}1. Restablecer Acceso SSH a node02 con Autenticación por Clave${RESET}"
  echo -e "     Usa sshpass con caleston123 para ejecutar ssh-copy-id y copiar"
  echo -e "     la clave pública al servidor node02. Verifica acceso sin contraseña."
  echo -e "     Como paso final, deshabilita PasswordAuthentication en sshd_config"
  echo -e "     y reinicia sshd para completar el hardening."
  echo -e ""
  echo -e "  ${RED}2. Restaurar la Documentación del Sistema en node02${RESET}"
  echo -e "     Instala los paquetes man-db e info en node02. Verifica que las"
  echo -e "     secciones 1, 5 y 8 de man pages están disponibles consultando"
  echo -e "     man 1 ls, man 5 passwd y man 8 useradd en el servidor."
  echo -e ""
  echo -e "  ${RED}3. Extraer y Respaldar la Configuración Crítica${RESET}"
  echo -e "     Extrae el contenido completo de /etc/app-config/settings.conf"
  echo -e "     desde node02. Extrae la descripción del comando ssh desde man 1 ssh."
  echo -e "     Genera el fingerprint de la clave SSH creada en node01."
  echo -e "     Envía los tres resultados a node03 via pipeline."
  echo -e ""
  echo -e "  ${RED}4. Pipeline de Resultados a node03 — REGLA DE ORO${RESET}"
  echo -e "     ${YELLOW}❌ NUNCA guardes resultados en node01${RESET}"
  echo -e "     ${GREEN}✅ SIEMPRE envía a node03 via pipeline${RESET}"
  echo -e ""
  echo -e "     Ejemplo de pipeline:"
  echo -e "     ${WHITE}ssh bob@node02 'cat /etc/app-config/settings.conf' |${RESET}"
  echo -e "     ${WHITE}sshpass -p 'caleston123' ssh bob@node03 \\${RESET}"
  echo -e "     ${WHITE}  'cat > /opt/backup-vault/essential-commands/settings-backup.conf'${RESET}"
  echo -e ""
  echo -e " ${BOLD}Entregables en node03:${RESET}"
  echo -e "  - ${BOLD}/opt/backup-vault/essential-commands/settings-backup.conf${RESET}"
  echo -e "  - ${BOLD}/opt/backup-vault/essential-commands/ssh-man-summary.txt${RESET}"
  echo -e "  - ${BOLD}/opt/backup-vault/essential-commands/ssh-key-report.txt${RESET}"
  echo -e ""
  echo -e " ${BOLD}Criterios de Aceptación:${RESET}"
  echo -e ""
  echo -e "  [ ] Clave pública de node01 en ~/.ssh/authorized_keys de node02   --> ${MAGENTA}25%${RESET}"
  echo -e "  [ ] Acceso SSH a node02 desde node01 sin contraseña               --> ${MAGENTA}20%${RESET}"
  echo -e "  [ ] Paquetes man-db e info instalados y funcionales en node02     --> ${MAGENTA}15%${RESET}"
  echo -e "  [ ] settings-backup.conf en node03 con contenido íntegro          --> ${MAGENTA}20%${RESET}"
  echo -e "  [ ] ssh-man-summary.txt en node03 con descripción de man 1 ssh    --> ${MAGENTA}10%${RESET}"
  echo -e "  [ ] ssh-key-report.txt en node03 con fingerprint de la clave      --> ${MAGENTA}10%${RESET}"
  echo -e "  [ ] CERO archivos de resultados almacenados en node01  ${RED}(DESCALIFICA)${RESET}"
  echo -e " -------------------------------------------------------------------------------"
  echo -e " ${GREEN}🚨 REGLA DE ORO:${RESET}"
  echo -e "  - Trabaja SIEMPRE desde ${BOLD}node01${RESET}"
  echo -e "  - Conéctate a ${BOLD}node02${RESET} vía ${BOLD}sshpass${RESET} (fase inicial) o clave SSH"
  echo -e "  - Envía resultados a ${BOLD}node03${RESET} via ${BOLD}pipeline${RESET} (|)"
  echo -e "  - ${RED}NUNCA${RESET} guardes archivos de resultados en ${BOLD}node01${RESET}"
  echo -e "${CYAN}================================================================================${RESET}"
  EOF
  chmod +x /tmp/setup.sh
  bash /tmp/setup.sh
  rm -f /tmp/setup.sh
  EOF
  chmod +x /tmp/setup.sh
  bash /tmp/setup.sh
  rm -f /tmp/setup.sh
tags:
  - Laboratorios-del-LFCS
  - Essential-Commands
  - Linux-Fundamentals
  - SSH
  - Man-Pages
---
[[Laboratorios del LFCS]]
