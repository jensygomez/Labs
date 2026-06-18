---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Playground: PG-005
Titulo: Servicio inestable en producción (Límites de Recursos e Integridad) - V2
Fecha de Inicio: 2026-06-06
Dificultad: 7/10
Level Escalation: L2/L3
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux Pleno
Temas:
  - Services Hardening and Security Sandboxing
  - Kernel Resource Management (OOM Score & Fork Limits)
  - Verify Integrity and Availability
Competencias:
  - Mitigar la intervención del Kernel OOM Killer mediante directivas de prioridad (OOMScoreAdjust)
  - Implementar aislamiento perimetral del sistema de archivos (ProtectSystem / ProtectHome / PrivateTmp)
  - Controlar la proliferación de hilos del sistema configurando límites de tareas (TasksMax)
Ticket: |-
  INC-8055

  El equipo de SRE y Seguridad Informática ha detectado anomalías críticas en la nueva versión de la API de producción ("prod-api"). Bajo cargas de estrés simuladas, el servicio experimenta dos fallas graves:
  1. El Kernel de Linux lo identifica como una amenaza de consumo de memoria y lo elimina mediante el mecanismo Out-Of-Memory (OOM) Killer.
  2. Una auditoría de seguridad reporta que el servicio se ejecuta con acceso completo de lectura/escritura en todo el almacenamiento, violando el principio de menor privilegio.

  Misión (Pleno L2/L3): Modifique la unidad de Systemd para blindar el servicio contra el OOM Killer, restringir sus hilos máximos en el Kernel y aplicar técnicas de sandboxing sobre el sistema de archivos.
Validacion:
  - Objetivo: Protección OOMScoreAdjust configurada en la unidad para priorizar el proceso (-500).
    Peso: 25 %
  - Objetivo: Límites de control de hilos (TasksMax=64) y descriptores (LimitNOFILE=8192) activos.
    Peso: 25 %
  - Objetivo: Implementación de aislamiento multicapa (PrivateTmp, ProtectHome, ProtectSystem=strict).
    Peso: 30 %
  - Objetivo: Servicio prod-api activo, corriendo y habilitado de forma persistente.
    Peso: 20 %
Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup_v2_sh
  #!/bin/bash
  set -e

  # 1. Limpieza absoluta de entornos previos
  systemctl stop prod-api.service >/dev/null 2>&1 || true
  systemctl disable prod-api.service >/dev/null 2>&1 || true
  rm -f /etc/systemd/system/prod-api.service
  rm -rf /opt/prod-api

  # 2. Crear el directorio y el binario avanzado de la API
  mkdir -p /opt/prod-api
  cat << 'API' > /opt/prod-api/api-engine-v2
  #!/bin/bash
  echo "PROD-API Enterprise Engine v2 Iniciado..."
  
  # Simulación interna: si detecta escritura libre o hilos descontrolados sin límites,
  # emulará inestabilidad o caída.
  while true; do
      sleep 1
  done
  API
  chmod 755 /opt/prod-api/api-engine-v2

  # 3. Crear la unidad de servicio BASE (Totalmente vulnerable e inestable)
  cat << 'SER' > /etc/systemd/system/prod-api.service
  [Unit]
  Description=Production Core API Service V2 - Hardened
  After=network.target

  [Service]
  Type=simple
  ExecStart=/opt/prod-api/api-engine-v2
  Restart=on-failure
  RestartSec=3
  User=root

  # >>> EL SYSADMIN PLENO DEBE INYECTAR LAS DIRECTIVAS DE BASTIONADO AQUÍ <<<

  [Install]
  WantedBy=multi-user.target
  SER

  # 4. Cargar configuraciones iniciales
  systemctl daemon-reload
  systemctl enable --now prod-api.service

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;31m 🔥 ESCENARIO PG-005 V2 CONFIGURADO - HARDENING DE SERVICIOS EN SYSTEMD\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-8055 (NIVEL PLENO L2/L3)\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Bastionado de procesos e inmunidad forense ante el Kernel"
  echo -e " \e[1mSeveridad:\e[0m Crítica / Cumplimiento de Seguridad Corporativa"
  echo -e ""
  echo -e " \e[1mRequerimientos Técnicos Obligatorios:\e[0m"
  echo -e "  [ ] Ajustar 'OOMScoreAdjust=-500' en la sección [Service]        --> \e[1;35m25%\e[0m"
  echo -e "  [ ] Añadir 'LimitNOFILE=8192' y 'TasksMax=64' en [Service]       --> \e[1;35m25%\e[0m"
  echo -e "  [ ] Implementar Sandboxing del FileSystem bajo la sección [Service]:"
  echo -e "       - 'PrivateTmp=true'"
  echo -e "       - 'ProtectHome=true'"
  echo -e "       - 'ProtectSystem=strict'                                   --> \e[1;35m30%\e[0m"
  echo -e "  [ ] Garantizar que el servicio esté corriendo (active) y"
  echo -e "       habilitado persistentemente (enabled)                       --> \e[1;35m20%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32mMisión:\e[0m Edite la unidad con su editor de texto, aplique daemon-reload y valide.\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup_v2_sh && rm -f /tmp/setup_v2_sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0
  UNIT="/etc/systemd/system/prod-api.service"

  echo "=== EVALUANDO CONFIGURACIÓN DE OPERACIONES AVANZADAS (V2) ==="

  # 1. Validar ajuste de protección del Kernel contra OOM
  OOM_SCORE=$(systemctl show -p OOMScoreAdjust prod-api.service | cut -d= -f2)
  if [ "$OOM_SCORE" -eq -500 ] 2>/dev/null; then
      echo "✔ [25%] Inmunidad forense al OOM Killer configurada correctamente ($OOM_SCORE)."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] El parámetro OOMScoreAdjust no está configurado en -500."
  fi

  # 2. Validar restricciones de recursos de bajo nivel
  LIMIT_NOFILE=$(systemctl show -p LimitNOFILE prod-api.service | cut -d= -f2)
  TASKS_MAX=$(systemctl show -p TasksMax prod-api.service | cut -d= -f2)
  
  if [ "$LIMIT_NOFILE" -eq 8192 ] 2>/dev/null && [ "$TASKS_MAX" -eq 64 ] 2>/dev/null; then
      echo "✔ [25%] Límites de recursos del Kernel aplicados (LimitNOFILE=8192, TasksMax=64)."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] Faltan o están incorrectos los parámetros LimitNOFILE o TasksMax."
  fi

  # 3. Validar políticas de Sandboxing del FileSystem
  P_TMP=$(systemctl show -p PrivateTmp prod-api.service | cut -d= -f2)
  P_HOME=$(systemctl show -p ProtectHome prod-api.service | cut -d= -f2)
  P_SYS=$(systemctl show -p ProtectSystem prod-api.service | cut -d= -f2)

  if [ "$P_TMP" = "yes" ] && [ "$P_HOME" = "yes" ] && [ "$P_SYS" = "yes" -o "$P_SYS" = "strict" ]; then
      echo "✔ [30%] Bastionado perimetral y aislamiento de sistema de archivos activo."
      PUNTOS=$((PUNTOS + 30))
  else
      echo "❌ [0%] Falló el sandboxing: Verifique PrivateTmp, ProtectHome y ProtectSystem=strict."
  fi

  # 4. Validar estado persistente y disponibilidad
  if systemctl is-active --quiet prod-api.service && systemctl is-enabled --quiet prod-api.service; then
      echo "✔ [20%] El servicio 'prod-api.service' está corriendo y configurado para el arranque."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] El servicio no está activo/running o no está habilitado (enabled)."
  fi

  echo "============================"
  echo "CALIFICACIÓN FINAL: $PUNTOS / 100"
  echo "============================"

---
[[Laboratorios del LFCS]]
