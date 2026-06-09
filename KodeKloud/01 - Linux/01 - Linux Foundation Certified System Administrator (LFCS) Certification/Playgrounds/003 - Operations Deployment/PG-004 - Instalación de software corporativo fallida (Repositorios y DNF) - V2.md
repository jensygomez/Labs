---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Playground: PG-004-v2
Titulo: Instalación de software corporativo fallida (Repositorios y DNF) - V2
Fecha de Inicio: 2026-06-05
Dificultad: 6/10
Level Escalation: L2/L3
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux Pleno
Temas:
  - Software Management (DNF)
  - Repository Configuration
  - Package Metadata
  - Systemd Services
Competencias:
  - Diagnosticar y reparar repositorios locales y remotos
  - Resolver problemas de metadatos y dependencias
  - Gestionar instalación de paquetes no estándar + servicios asociados
Validacion:
  - Objetivo: Repositorio 'corp-internal.repo' corregido y funcional (con metadatos)
    Peso: 25 %
  - Objetivo: Paquete 'secure-monitor' instalado correctamente
    Peso: 30 %
  - Objetivo: Servicio 'secure-monitor.service' activo y running
    Peso: 25 %
  - Objetivo: Servicio habilitado al arranque + logs sin errores
    Peso: 20 %
Script: |-
  cat << 'EOF' > /tmp/setup.sh
  #!/bin/bash
  set -e

  # Crear usuario de servicio
  useradd -r -s /sbin/nologin secmon 2>/dev/null || true

  # Estructura del paquete simulado
  mkdir -p /usr/local/share/corp-repo/Packages
  mkdir -p /opt/secure-monitor

  cat << 'BIN' > /usr/local/share/corp-repo/Packages/secure-monitor
  #!/bin/bash
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Secure Monitor Agent started"
  while true; do
      echo "[$(date '+%H:%M:%S')] Endpoint check OK - No threats detected" >> /var/log/secure-monitor/agent.log
      sleep 10
  done
  BIN
  chmod 755 /usr/local/share/corp-repo/Packages/secure-monitor

  # Repositorio roto (URL incorrecta + sin metadatos)
  cat << 'REPO' > /etc/yum.repos.d/corp-internal.repo
  [corp-internal]
  name=Corporative Internal Repository
  baseurl=http://repo.corp.internal.invalid/linux/\$releasever/\$basearch/
  enabled=1
  gpgcheck=0
  REPO

  # Servicio con ruta incorrecta
  cat << 'SERVICE' > /etc/systemd/system/secure-monitor.service
  [Unit]
  Description=Secure Monitor Agent
  After=network.target

  [Service]
  Type=simple
  ExecStart=/opt/secure-monitor/secure-monitor   # Ruta incorrecta
  User=root
  Restart=always

  [Install]
  WantedBy=multi-user.target
  SERVICE

  systemctl daemon-reload
  systemctl stop secure-monitor.service 2>/dev/null || true
  systemctl disable secure-monitor.service 2>/dev/null || true

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;31m 📦 ESCENARIO PG-004-v2 CONFIGURADO - REPOSITORIOS CORPORATIVOS ROTOS\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-3471 (ALTA SEVERIDAD)\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Fallo en Instalación de Herramienta Crítica de Monitoreo"
  echo -e " \e[1mSeveridad:\e[0m Alta / Bloqueo de Rollout de Seguridad Corporativa"
  echo -e ""
  echo -e " \e[1mContexto del Incidente:\e[0m"
  echo -e "  El equipo de Seguridad acaba de desplegar una nueva versión de"
  echo -e "  'secure-monitor', la herramienta interna encargada del monitoreo"
  echo -e "  de endpoints y del cumplimiento de políticas de hardening en toda"
  echo -e "  la infraestructura. No es una herramienta opcional. Sin ella,"
  echo -e "  los nodos quedan fuera del radar de seguridad corporativa."
  echo -e ""
  echo -e "  El problema se presentó al intentar instalarla a través de DNF."
  echo -e "  El proceso falla. No con un error menor — falla con errores de"
  echo -e "  repositorio y metadatos que impiden que el gestor de paquetes"
  echo -e "  siquiera encuentre el recurso. El paquete proviene de un repositorio"
  echo -e "  local corporativo que fue migrado recientemente, y algo en esa"
  echo -e "  migración quedó mal configurado."
  echo -e ""
  echo -e "  El equipo de Infraestructura escaló el caso porque el rollout"
  echo -e "  de monitoreo está detenido en todos los nodos pendientes."
  echo -e "  Cada hora sin resolución es un endpoint sin cobertura."
  echo -e ""
  echo -e " \e[1mLo que se sabe hasta ahora:\e[0m"
  echo -e ""
  echo -e "  \e[1;31m1.\e[0m El archivo de repositorio apunta a una URL que no resuelve."
  echo -e "     El servidor de paquetes fue movido durante la migración y nadie"
  echo -e "     actualizó la referencia. DNF no puede alcanzar la fuente."
  echo -e ""
  echo -e "  \e[1;31m2.\e[0m Aunque se corrija la URL, el repositorio local no tiene"
  echo -e "     metadatos generados. Sin ellos, DNF no puede indexar ni instalar"
  echo -e "     ningún paquete, independientemente de que la ruta sea correcta."
  echo -e ""
  echo -e "  \e[1;31m3.\e[0m El archivo de servicio systemd fue desplegado con una ruta"
  echo -e "     de ejecución incorrecta. Aunque el paquete se instale, el servicio"
  echo -e "     no levantará hasta que esa ruta refleje dónde está el binario real."
  echo -e ""
  echo -e " \e[1mMisión — diagnóstico, corrección y habilitación completa:\e[0m"
  echo -e ""
  echo -e "  Inspeccione el estado actual de los repositorios con las herramientas"
  echo -e "  disponibles. Corrija la configuración, genere los metadatos necesarios,"
  echo -e "  instale el paquete y deje el servicio operativo, persistente y con"
  echo -e "  evidencia de logs activos. No se acepta una instalación a medias."
  echo -e ""
  echo -e " \e[1mCriterios de Aceptación:\e[0m"
  echo -e "  [ ] Repositorio corp-internal.repo funcional con metadatos         --> \e[1;35m25%\e[0m"
  echo -e "  [ ] Paquete secure-monitor instalado correctamente                 --> \e[1;35m30%\e[0m"
  echo -e "  [ ] Servicio active (running)                                      --> \e[1;35m25%\e[0m"
  echo -e "  [ ] Servicio enabled + logs operativos                             --> \e[1;35m20%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32mNota de Campo:\e[0m El orden importa. Un repositorio sin metadatos"
  echo -e "              es tan inútil como uno con URL incorrecta."
  echo -e "              Resuelva por capas, desde la fuente hasta el servicio."
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup.sh && rm -f /tmp/setup.sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0

  echo "=== EVALUANDO GESTIÓN AVANZADA DE REPOSITORIOS Y PAQUETES - L2/L3 ==="

  # 1. Repositorio corregido
  if [ -f /etc/yum.repos.d/corp-internal.repo ] && grep -q "file:///usr/local/share/corp-repo" /etc/yum.repos.d/corp-internal.repo; then
      echo "✔ [25%] Repositorio corp-internal configurado correctamente (file:// + metadatos)."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] El repositorio sigue roto o sin metadatos."
  fi

  # 2. Paquete instalado
  if [ -f /opt/secure-monitor/secure-monitor ] && [ -x /opt/secure-monitor/secure-monitor ]; then
      echo "✔ [30%] Paquete 'secure-monitor' instalado correctamente."
      PUNTOS=$((PUNTOS + 30))
  else
      echo "❌ [0%] El paquete no se instaló en la ruta esperada."
  fi

  # 3. Servicio activo
  if systemctl is-active --quiet secure-monitor.service; then
      echo "✔ [25%] Servicio 'secure-monitor.service' en ejecución."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] El servicio no está activo."
  fi

  # 4. Habilitado + logs
  if systemctl is-enabled --quiet secure-monitor.service && [ -s /var/log/secure-monitor/agent.log ]; then
      echo "✔ [20%] Servicio habilitado y generando logs correctamente."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] Servicio no habilitado o sin logs."
  fi

  echo "============================"
  echo "CALIFICACIÓN FINAL: $PUNTOS / 100"
  echo "============================"
---

[[Laboratorios del LFCS]]
---
