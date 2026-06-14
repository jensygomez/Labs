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
Script: |2-
    cat << 'EOF' > /tmp/setup-EC-001-v1.sh
    #!/bin/bash
    set -e

    echo -e "\e[1;33m⏳ Preparando el escenario de fallo EC-001: El Acceso Perdido...\e[0m"

    # ============================================
    # CONFIGURACIÓN EN NODE02 (Servidor con Problemas)
    # ============================================
    if [[ "$(hostname)" == "node02" ]]; then
      echo -e "\e[1;36m[+] Configurando node02 (servidor objetivo)...\e[0m"

      # Fallo 1: Deshabilitar autenticación por contraseña en SSH
      sudo sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
      sudo sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
      sudo systemctl restart sshd

      # Fallo 2: Eliminar paquetes de documentación del sistema
      sudo apt-get remove -y man-db info --purge -qq 2>/dev/null || true
      sudo rm -rf /usr/share/doc/coreutils 2>/dev/null || true

      # Fallo 3: Crear archivo de configuración de aplicación crítica
      sudo mkdir -p /etc/app-config
      sudo bash -c 'cat > /etc/app-config/settings.conf << CONF
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
  CONF'
      sudo chmod 644 /etc/app-config/settings.conf

      echo -e "\e[1;32m[✓] node02 configurado: SSH sin contraseña, documentación eliminada, settings.conf creado\e[0m"
    fi

    # ============================================
    # CONFIGURACIÓN EN NODE03 (Backup Empresarial)
    # ============================================
    if [[ "$(hostname)" == "node03" ]]; then
      echo -e "\e[1;36m[+] Configurando node03 (backup vault)...\e[0m"

      sudo mkdir -p /opt/backup-vault/essential-commands
      sudo chown bob:bob /opt/backup-vault/essential-commands
      sudo chmod 750 /opt/backup-vault/essential-commands

      echo -e "\e[1;32m[✓] node03 preparado como backup vault\e[0m"
    fi

    # ============================================
    # CONFIGURACIÓN EN NODE01 (Estación de Admin)
    # ============================================
    if [[ "$(hostname)" == "node01" ]]; then
      echo -e "\e[1;36m[+] Configurando node01 (estación de administración)...\e[0m"

      sudo apt-get update -qq
      sudo apt-get install -y sshpass -qq

      mkdir -p "$HOME/EC-001-lab"
      cd "$HOME/EC-001-lab"

      clear
      echo -e "\e[1;36m================================================================================\e[0m"
      echo -e "\e[1;33m  TICKET INC-4471  │  Severidad: ALTA  │  Ambiente: PRODUCCIÓN – ESSENTIAL COMMANDS\e[0m"
      echo -e "\e[1;36m================================================================================\e[0m"
      echo -e "\e[1;32m  ⚙️  EC-001-v1 — El Acceso Perdido: Conectividad y Documentación del Sistema\e[0m"
      echo -e "\e[1;36m  Módulo: Essential Commands  │  Dificultad: 5/10  │  Nivel: L2\e[0m"
      echo -e " ------------------------------------------------------------------------------"
      echo -e " \e[1mArquitectura del Escenario:\e[0m"
      echo -e "  \e[1;34m[node01]\e[0m → Estación de Administración (TU POSICIÓN ACTUAL)"
      echo -e "  \e[1;31m[node02]\e[0m → Servidor con Problemas (OBJETIVO DE DIAGNÓSTICO)"
      echo -e "  \e[1;32m[node03]\e[0m → Backup Empresarial (DESTINO DE RESULTADOS)"
      echo -e " ------------------------------------------------------------------------------"
      echo -e " \e[1mContexto del Incidente:\e[0m"
      echo -e ""
      echo -e "  El pasado martes por la tarde, el equipo de infraestructura de TechCorp"
      echo -e "  recibió una notificación urgente por parte del departamento de seguridad"
      echo -e "  informática. Durante una ventana de mantenimiento de emergencia ejecutada"
      echo -e "  la noche anterior, un técnico externo realizó modificaciones en el servidor"
      echo -e "  de producción node02. Al día siguiente, cuando el equipo de operaciones"
      echo -e "  intentó acceder de manera rutinaria al servidor para ejecutar sus tareas"
      echo -e "  de monitoreo, el sistema rechazó completamente la autenticación por"
      echo -e "  contraseña. El técnico, al reforzar las políticas de seguridad, había"
      echo -e "  deshabilitado ese método de acceso sin dejar configuradas las claves SSH"
      echo -e "  correspondientes ni documentar el procedimiento realizado."
      echo -e ""
      echo -e "  Como si la situación no fuera suficientemente delicada, el equipo de"
      echo -e "  aplicaciones reportó que node02 también había perdido sus paquetes de"
      echo -e "  documentación del sistema durante el proceso de limpieza ejecutado por"
      echo -e "  el técnico. Los ingenieros de nivel 2 no podían consultar los manuales"
      echo -e "  de los comandos en el propio servidor, ni acceder a las páginas de"
      echo -e "  referencia necesarias para continuar con las tareas de diagnóstico."
      echo -e "  Adicionalmente, se descubrió que el archivo de configuración principal"
      echo -e "  de la aplicación CoreService, ubicado en /etc/app-config/settings.conf,"
      echo -e "  contiene parámetros críticos que deben ser respaldados de inmediato en"
      echo -e "  el vault empresarial antes de cualquier intervención adicional."
      echo -e ""
      echo -e "  Has sido asignado como ingeniero de guardia para resolver este incidente."
      echo -e "  Tu primera responsabilidad es restablecer el acceso seguro a node02"
      echo -e "  mediante la configuración correcta de autenticación por clave pública."
      echo -e "  Una vez dentro, deberás restaurar la documentación del sistema,"
      echo -e "  explorar las man pages disponibles y extraer la información de"
      echo -e "  configuración crítica. Todo lo que encuentres debe quedar registrado"
      echo -e "  en node03 a través del pipeline de backup, como evidencia auditada"
      echo -e "  de las acciones tomadas durante la atención del incidente."
      echo -e ""
      echo -e " \e[1mParámetros Técnicos Obligatorios:\e[0m"
      echo -e ""
      echo -e "  \e[1;31m1. Restablecer Acceso SSH a node02 con Autenticación por Clave\e[0m"
      echo -e "     Genera un par de claves SSH en node01 (sin passphrase)."
      echo -e "     Usa sshpass con la contraseña caleston123 para copiar la clave"
      echo -e "     pública a node02 (ssh-copy-id). Verifica que el acceso funciona"
      echo -e "     sin contraseña antes de continuar."
      echo -e ""
      echo -e "  \e[1;31m2. Restaurar Documentación del Sistema en node02\e[0m"
      echo -e "     Instala los paquetes man-db e info en node02 vía sshpass."
      echo -e "     Verifica que las secciones 1, 5 y 8 de man pages estén disponibles"
      echo -e "     consultando: man 1 ls, man 5 passwd, man 8 useradd."
      echo -e ""
      echo -e "  \e[1;31m3. Extraer Información Crítica de Configuración\e[0m"
      echo -e "     Desde node01, extrae el contenido de /etc/app-config/settings.conf"
      echo -e "     ubicado en node02. Identifica el APP_PORT, DB_HOST y BACKUP_SCHEDULE."
      echo -e "     Documenta también la descripción del comando ssh obtenida de man 1 ssh."
      echo -e ""
      echo -e "  \e[1;31m4. Pipeline de Resultados a node03 (REGLA DE ORO)\e[0m"
      echo -e "     \e[1;33m❌ NUNCA guardes resultados en node01\e[0m"
      echo -e "     \e[1;32m✅ SIEMPRE envía a node03 via pipeline\e[0m"
      echo -e ""
      echo -e "     Ejemplo de pipeline:"
      echo -e "     \e[1;37msshpass -p 'caleston123' ssh bob@node02 'cat /etc/app-config/settings.conf' | \e[0m"
      echo -e "     \e[1;37msshpass -p 'caleston123' ssh bob@node03 'cat > /opt/backup-vault/essential-commands/settings-backup.conf'\e[0m"
      echo -e ""
      echo -e " \e[1mEntregables en node03:\e[0m"
      echo -e "  - \e[1m/opt/backup-vault/essential-commands/settings-backup.conf\e[0m"
      echo -e "  - \e[1m/opt/backup-vault/essential-commands/ssh-man-summary.txt\e[0m"
      echo -e "  - \e[1m/opt/backup-vault/essential-commands/ssh-key-report.txt\e[0m"
      echo -e ""
      echo -e " \e[1mCriterios de Aceptación:\e[0m"
      echo -e ""
      echo -e "  [ ] Clave pública de node01 presente en ~/.ssh/authorized_keys de node02  --> \e[1;35m25%\e[0m"
      echo -e "  [ ] Acceso SSH a node02 desde node01 sin contraseña (clave pública)       --> \e[1;35m20%\e[0m"
      echo -e "  [ ] Paquetes man-db e info instalados y funcionales en node02             --> \e[1;35m15%\e[0m"
      echo -e "  [ ] settings-backup.conf en node03 con contenido íntegro de settings.conf --> \e[1;35m20%\e[0m"
      echo -e "  [ ] ssh-man-summary.txt en node03 con descripción extraída de man 1 ssh   --> \e[1;35m10%\e[0m"
      echo -e "  [ ] ssh-key-report.txt en node03 con fingerprint de la clave generada     --> \e[1;35m10%\e[0m"
      echo -e "  [ ] CERO archivos de resultados almacenados en node01                     --> \e[1;35m0%\e[0m  \e[1;31m(DESCALIFICA)\e[0m"
      echo -e " ------------------------------------------------------------------------------"
      echo -e " \e[1;32m🚨 REGLA DE ORO:\e[0m"
      echo -e "  - Trabaja SIEMPRE desde \e[1mnode01\e[0m"
      echo -e "  - Conéctate a \e[1mnode02\e[0m vía \e[1msshpass\e[0m"
      echo -e "  - Envía resultados a \e[1mnode03\e[0m via \e[1mpipeline\e[0m (|)"
      echo -e "  - \e[1;31mNUNCA\e[0m guardes archivos de resultados en \e[1mnode01\e[0m"
      echo -e "\e[1;36m================================================================================\e[0m"
    fi
    EOF

    chmod +x /tmp/setup-EC-001-v1.sh
    bash /tmp/setup-EC-001-v1.sh
    rm -f /tmp/setup-EC-001-v1.sh
tags:
  - Laboratorios-del-LFCS
  - Essential-Commands
  - Linux-Fundamentals
  - SSH
  - Man-Pages
---

