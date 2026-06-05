---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Playground: PG-004-v2
Titulo: Instalación de herramienta corporativa fallida (Repositorios y DNF)
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

Ticket: |-
  INC-3471

  El equipo de Seguridad ha desplegado una nueva versión de la herramienta interna "secure-monitor".
  Esta herramienta es crítica para el monitoreo de endpoints y cumplimiento de políticas de hardening.

  Al intentar instalarla vía DNF (`dnf install secure-monitor`), el proceso falla con errores de repositorios
  y metadatos. El paquete proviene de un repositorio local corporativo recién migrado.

  Por favor, realice un diagnóstico completo, corrija la configuración de repositorios, instale el paquete
  correctamente y deje el servicio operativo y persistente.

Validacion:
  - Objetivo: Repositorio 'corp-internal.repo' corregido y funcional (con metadatos)
    Peso: 25 %
  - Objetivo: Paquete 'secure-monitor' instalado correctamente
    Peso: 30 %
  - Objetivo: Servicio 'secure-monitor.service' activo y running
    Peso: 25 %
  - Objetivo: Servicio habilitado al arranque + logs sin errores
    Peso: 20 %

Calificacion Final:
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
  echo -e "\e[1;33m TICKET: INC-3471\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Fallo en instalación de secure-monitor (herramienta crítica de seguridad)"
  echo -e " \e[1mSeveridad:\e[0m Alta - Bloquea rollout de monitoreo"
  echo -e ""
  echo -e " \e[1mTarea L2/L3:\e[0m"
  echo -e " Diagnostique con 'dnf repolist', 'dnf clean', 'journalctl'. Corrija repositorio local,"
  echo -e " genere metadatos (createrepo), instale el paquete y configure el servicio."
  echo -e ""
  echo -e " \e[1mCriterios de Aceptación:\e[0m"
  echo -e "  [ ] Repositorio corp-internal.repo funcional con metadatos         → 25%"
  echo -e "  [ ] Paquete secure-monitor instalado correctamente                 → 30%"
  echo -e "  [ ] Servicio active (running)                                      → 25%"
  echo -e "  [ ] Servicio enabled + logs operativos                             → 20%"
  echo -e " ------------------------------------------------------------------------------"
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
