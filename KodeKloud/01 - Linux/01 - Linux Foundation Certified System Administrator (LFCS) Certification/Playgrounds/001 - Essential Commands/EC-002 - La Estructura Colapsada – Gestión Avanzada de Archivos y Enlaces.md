---
Curso: Transición Sysadmin a DevOps - Essential Commands LFCS/RHCSA
Modulo: Essential Commands (Gestión de Archivos y Enlaces)
Playground: EC-002-v1
Titulo: La Estructura Colapsada – Gestión Avanzada de Archivos y Enlaces
Fecha de Inicio: 2026-06-15
Dificultad: 6/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno
  - Prepararme para DevOps Engineer y Kubernetes
Temas: |-
  - Operaciones de archivos preservando metadatos (cp -a, rsync -a)
  - Enlaces duros (Hard Links) vs. Enlaces simbólicos (Soft Links)
  - Gestión e identificación de inodes (inode management)
  - Búsquedas avanzadas con find (-inum, -samefile, -type l, -type f)
  - Refresco: Conexión remota segura y uso de sshpass (EC-001)
Competencias: |-
  - Reorganizar estructuras de directorios fragmentadas preservando permisos, propietarios y timestamps.
  - Implementar enlaces duros para compartir datos entre aplicaciones sin duplicar espacio en disco, y enlaces simbólicos para mantener compatibilidad de rutas heredadas.
  - Diagnosticar y resolver conflictos de auditoría utilizando find con criterios avanzados de inodes y tipos de archivo.
  - Generar y enviar reportes de integridad referencial directamente a la bóveda de cumplimiento (node03) mediante pipelines SSH, sin materializar archivos en node01.
Script: |-
  cat << 'EOF' > /tmp/setup.sh
  #!/bin/bash
  # =============================================================================
  # EC-002-v1 | La Estructura Colapsada – Gestión Avanzada de Archivos y Enlaces
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

  echo -e "${YELLOW}⏳ Iniciando configuración del escenario EC-002...${RESET}"

  # ============================================
  # FASE 1 — CONFIGURAR NODE02 REMOTAMENTE
  # ============================================
  echo -e "${CYAN}[+] Configurando node02 (sistema de archivos fragmentado)...${RESET}"

  sshpass -p 'caleston123' ssh -o StrictHostKeyChecking=no bob@node02 'bash -s' << 'NODE02_SCRIPT'
  set -e

  # 1. Crear estructura de datos original y archivos de prueba
  sudo mkdir -p /data/originals /data/processing /data/archive /opt/legacy_app
  sudo sh -c 'echo "ID,STATUS,VALUE" > /data/originals/production_data.csv'
  sudo sh -c 'echo "001,ACTIVE,1500" >> /data/originals/production_data.csv'
  sudo sh -c 'echo "002,INACTIVE,0" >> /data/originals/production_data.csv'
  sudo chmod 644 /data/originals/production_data.csv

  # 2. Crear un enlace duro existente (el estudiante deberá identificarlo)
  sudo ln /data/originals/production_data.csv /data/processing/production_data_hard.csv

  # 3. Crear un enlace simbólico ROTO intencionalmente (el estudiante deberá corregirlo)
  sudo ln -s /data/originals/missing_file.csv /data/archive/production_data_link.csv

  # 4. Crear archivos legacy que necesitan migración preservando metadatos
  sudo sh -c 'echo "DB_HOST=localhost" > /opt/legacy_app/app.conf'
  sudo sh -c 'echo "DB_PORT=5432" >> /opt/legacy_app/app.conf'
  sudo chmod 600 /opt/legacy_app/app.conf
  sudo chown root:root /opt/legacy_app/app.conf

  # 5. Dejar un script de auditoría "fallido" como pista
  sudo mkdir -p /usr/local/bin
  sudo tee /usr/local/bin/audit_check.sh > /dev/null << 'AUDIT'
  #!/bin/bash
  # ADVERTENCIA: Este script falla porque solo usa '-inum' y no distingue 
  # entre archivos originales y enlaces duros, ni identifica enlaces simbólicos.
  # El ingeniero debe usar 'find' con criterios avanzados (-samefile, -type l, -type f)
  echo "Ejecutando auditoría básica de inodes..."
  find /data -inum $(stat -c %i /data/originals/production_data.csv)
  AUDIT
  sudo chmod +x /usr/local/bin/audit_check.sh
  NODE02_SCRIPT

  echo -e "${GREEN}[✓] node02 configurado correctamente${RESET}"

  # ============================================
  # FASE 2 — CONFIGURAR NODE03 REMOTAMENTE
  # ============================================
  echo -e "${CYAN}[+] Configurando node03 (backup vault)...${RESET}"

  sshpass -p 'caleston123' ssh -o StrictHostKeyChecking=no bob@node03 'bash -s' << 'NODE03_SCRIPT'
  set -e
  sudo mkdir -p /opt/backup-vault/essential-commands/ec-002
  sudo chown bob:bob /opt/backup-vault/essential-commands/ec-002
  sudo chmod 750 /opt/backup-vault/essential-commands/ec-002
  NODE03_SCRIPT

  echo -e "${GREEN}[✓] node03 preparado como backup vault${RESET}"

  # ============================================
  # FASE 3 — PREPARAR NODE01
  # ============================================
  echo -e "${CYAN}[+] Preparando estación de administración node01...${RESET}"

  sudo dnf install -y sshpass -q 2>/dev/null || sudo apt-get install -y sshpass -qq 2>/dev/null || true

  mkdir -p "$HOME/EC-002-lab"
  cd "$HOME/EC-002-lab"

  sleep 1
  clear

  echo -e "${CYAN}================================================================================${RESET}"
  echo -e "${YELLOW}  TICKET INC-4472  │  Severidad: ALTA  │  Ambiente: PRODUCCIÓN${RESET}"
  echo -e "${CYAN}================================================================================${RESET}"
  echo -e "${GREEN}  ⚙️  EC-002-v1 — La Estructura Colapsada: Gestión Avanzada de Archivos y Enlaces${RESET}"
  echo -e "${CYAN}  Módulo: Essential Commands  │  Dificultad: 6/10  │  Nivel: L2${RESET}"
  echo -e " -------------------------------------------------------------------------------"
  echo -e " ${BOLD}Arquitectura del Escenario:${RESET}"
  echo -e "  ${BLUE}[node01]${RESET} → Estación de Administración  (TU POSICIÓN ACTUAL)"
  echo -e "  ${RED}[node02]${RESET} → Servidor con Problemas      (OBJETIVO DE DIAGNÓSTICO)"
  echo -e "  ${GREEN}[node03]${RESET} → Backup Empresarial          (DESTINO DE RESULTADOS)"
  echo -e " -------------------------------------------------------------------------------"
  echo -e " ${BOLD}Contexto del Incidente:${RESET}"
  echo -e ""
  echo -e "  Tras una migración de datos apresurada realizada por un equipo externo,"
  echo -e "  el sistema de archivos en node02 quedó severamente fragmentado. Una"
  echo -e "  aplicación crítica depende de que los archivos de configuración y datos"
  echo -e "  residan en ubicaciones específicas, pero actualmente están dispersos."
  echo -e ""
  echo -e "  Para ahorrar espacio en disco, se suponía que debían implementarse"
  echo -e "  enlaces duros (hard links) para compartir los mismos datos entre"
  echo -e "  procesos, y enlaces simbólicos (soft links) para mantener la compatibilidad"
  echo -e "  con rutas heredadas. Sin embargo, la implementación fue defectuosa:"
  echo -e "  hay enlaces simbólicos rotos y la estructura de directorios no respeta"
  echo -e "  los permisos ni timestamps originales."
  echo -e ""
  echo -e "  Para colmo, el script de auditoría automática (/usr/local/bin/audit_check.sh)"
  echo -e "  está fallando. Al buscar archivos por número de inode (-inum), el script"
  echo -e "  no logra distinguir correctamente entre el archivo original y sus enlaces"
  echo -e "  duros, ni identifica la presencia de enlaces simbólicos, generando reportes"
  echo -e "  de integridad referencial incompletos y erróicos."
  echo -e ""
  echo -e "  Se te asigna la tarea de reorganizar la estructura, corregir los enlaces"
  echo -e "  y generar un reporte de auditoría preciso utilizando criterios avanzados"
  echo -e "  del comando find."
  echo -e ""
  echo -e " -------------------------------------------------------------------------------"
  echo -e " ${BOLD}Restricciones Operativas:${RESET}"
  echo -e ""
  echo -e "  ${RED}⚠${RESET}  Toda la intervención debe realizarse desde node01 vía SSH."
  echo -e "  ${RED}⚠${RESET}  Está estrictamente prohibido almacenar archivos de resultados"
  echo -e "     o reportes en node01. Deben fluir directamente a node03."
  echo -e ""
  echo -e " -------------------------------------------------------------------------------"
  echo -e " ${BOLD}Parámetros Técnicos Obligatorios:${RESET}"
  echo -e ""
  echo -e "  ${RED}1. Reorganización preservando metadatos${RESET}"
  echo -e "     Mueve o copia el contenido de /opt/legacy_app a /opt/modern_app/data"
  echo -e "     utilizando cp -a o rsync -a para preservar propietarios, grupos,"
  echo -e "     permisos y timestamps originales."
  echo -e ""
  echo -e "  ${RED}2. Corrección de Enlaces${RESET}"
  echo -e "     - Verifica que exista un enlace duro válido hacia production_data.csv."
  echo -e "     - Corrige el enlace simbólico roto en /data/archive/ para que apunte"
  echo -e "       correctamente a la nueva ubicación del archivo de configuración."
  echo -e ""
  echo -e "  ${RED}3. Auditoría Avanzada con find${RESET}"
  echo -e "     El script actual falla. Debes construir un comando find que:"
  echo -e "     a) Identifique TODOS los archivos (incluyendo enlaces duros) que"
  echo -e "        compartan el mismo inode que /data/originals/production_data.csv"
  echo -e "        (Pista: usa -samefile o -inum)."
  echo -e "     b) Identifique por separado todos los enlaces simbólicos (-type l)"
  echo -e "        dentro de /data/ para verificar su estado."
  echo -e ""
  echo -e "  ${RED}4. Pipeline de Resultados a node03 — REGLA DE ORO${RESET}"
  echo -e "     ${YELLOW}❌ NUNCA guardes resultados en node01${RESET}"
  echo -e "     ${GREEN}✅ SIEMPRE envía a node03 via pipeline${RESET}"
  echo -e ""
  echo -e "     Ejemplo de pipeline:"
  echo -e "     ${WHITE}ssh bob@node02 'find /data -samefile /data/originals/production_data.csv' | \\${RESET}"
  echo -e "     ${WHITE}sshpass -p 'caleston123' ssh bob@node03 \\${RESET}"
  echo -e "     ${WHITE}  'cat > /opt/backup-vault/essential-commands/ec-002/inode_audit.txt'${RESET}"
  echo -e ""
  echo -e " ${BOLD}Entregables en node03:${RESET}"
  echo -e "  - ${BOLD}/opt/backup-vault/essential-commands/ec-002/migration_report.txt${RESET}"
  echo -e "    (Salida de ls -la /opt/modern_app/data/ verificando metadatos)"
  echo -e "  - ${BOLD}/opt/backup-vault/essential-commands/ec-002/inode_audit.txt${RESET}"
  echo -e "    (Salida del comando find avanzado con -samefile / -inum)"
  echo -e "  - ${BOLD}/opt/backup-vault/essential-commands/ec-002/symlink_audit.txt${RESET}"
  echo -e "    (Salida de find identificando enlaces simbólicos y su estado)"
  echo -e ""
  echo -e " ${BOLD}Criterios de Aceptación:${RESET}"
  echo -e ""
  echo -e "  [ ] Directorio /opt/modern_app/data creado con metadatos preservados --> ${MAGENTA}25%${RESET}"
  echo -e "  [ ] Enlace duro verificado y enlace simbólico roto corregido         --> ${MAGENTA}25%${RESET}"
  echo -e "  [ ] Uso correcto de find con -samefile/-inum y -type l               --> ${MAGENTA}30%${RESET}"
  echo -e "  [ ] 3 archivos de evidencia presentes en node03 via pipeline         --> ${MAGENTA}20%${RESET}"
  echo -e "  [ ] CERO archivos de resultados almacenados en node01  ${RED}(DESCALIFICA)${RESET}"
  echo -e " -------------------------------------------------------------------------------"
  echo -e " ${GREEN}🚨 REGLA DE ORO:${RESET}"
  echo -e "  - Trabaja SIEMPRE desde ${BOLD}node01${RESET}"
  echo -e "  - Conéctate a ${BOLD}node02${RESET} vía ${BOLD}SSH${RESET}"
  echo -e "  - Envía resultados a ${BOLD}node03${RESET} via ${BOLD}pipeline${RESET} (|)"
  echo -e "  - ${RED}NUNCA${RESET} guardes archivos de resultados en ${BOLD}node01${RESET}"
  echo -e "${CYAN}================================================================================${RESET}"
  EOF

  chmod +x /tmp/setup.sh
  bash /tmp/setup.sh
  rm -f /tmp/setup.sh
tags:
  - Laboratorios-del-LFCS
  - Essential-Commands
  - File-Operations
  - Hard-Links
  - Soft-Links
  - Inode-Management
  - Find-Command
Escenario: |-
  - Situación: Desde node01 te conectas a node02 (utilizando las técnicas de acceso remoto vistas en EC-001). Una aplicación crítica depende de archivos en ubicaciones específicas, pero el sistema de archivos está severamente fragmentado tras una migración fallida. 
  Tu misión:
  1. Reorganizar directorios completos utilizando cp -a o rsync para preservar metadatos críticos.
  2. Crear enlaces duros (hard links) para que múltiples servicios accedan a los mismos datos de base sin consumir espacio adicional, y enlaces simbólicos (soft links) para resolver rutas de compatibilidad.
  3. Un script de auditoría existente falla al buscar archivos por inode, ya que no distingue entre el archivo original y sus enlaces duros (que comparten el mismo inode). Debes usar find con criterios avanzados (-inum, -samefile, -type l) para identificar correctamente la red de archivos y sus enlaces, verificando la integridad referencial.
  Regla de Oro: Todos los reportes de auditoría y verificación de inodes deben enviarse a node03 via pipeline SSH, sin dejar rastros intermedios en node01.
---
[[Laboratorios del LFCS]]
---


Recently, I had to respond to a high-severity incident in a production environment where a data migration performed by an external team left the file system in a fragmented and inconsistent state. A critical application depended on specific file paths, but the structure was completely broken.

My first move was reconnaissance — before touching anything, I mapped the existing state of the system remotely via SSH to understand exactly what was there and what was missing. I identified three concrete problems: a target directory that didn't exist yet, a symbolic link pointing to a file that had never existed, and an unverified hard link that needed confirmation.

I tackled them in order of dependency. First, I migrated the legacy application data to the new directory structure using `cp -a` to ensure that original ownership, permissions, and timestamps were fully preserved — because in production, metadata is just as critical as the data itself. Then I corrected the broken symbolic link by removing it and recreating it pointing to the actual file. I also confirmed that the existing hard link was valid by verifying it shared the same inode as the original file.

For the audit phase, I used `find` with `-samefile` to identify every file sharing that inode across the entire data directory, and separately listed all symbolic links with their targets for referential integrity verification.

One constraint that I took seriously was that no result files could be stored on the administration node. Every piece of evidence had to flow directly from the production server to the backup vault on a third node via SSH pipeline — so I built chained SSH commands that streamed the output without ever touching local disk.

The incident was resolved cleanly, all three audit reports landed in the backup vault, and the application's file structure was restored without data loss.