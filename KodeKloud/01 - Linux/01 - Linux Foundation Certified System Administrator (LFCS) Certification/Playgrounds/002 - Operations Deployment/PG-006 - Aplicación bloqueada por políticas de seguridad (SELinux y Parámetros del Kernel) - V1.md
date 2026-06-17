---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Playground: PG-006
Titulo: Aplicación bloqueada por políticas de seguridad (SELinux y Parámetros del Kernel) V1
Fecha de Inicio: 2026-06-07
Dificultad: 7/10
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux
Temas:
  - Services
  - Logs
  - Kernel Runtime Parameters
  - SELinux/AppArmor
Competencias:
  - Administrar contextos de archivos SELinux (chcon, semanage fcontext, restorecon)
  - Analizar logs de auditoría de seguridad (/var/log/audit/audit.log)
  - Modificar parámetros del Kernel en tiempo de ejecución y de forma persistente (sysctl, sysctl.conf)
Ticket: |-
  INC-1006

  El equipo de desarrollo reporta que la nueva aplicación "secure-app" se niega a iniciar. Mencionan que si ejecutan 'setenforce 0', el servicio levanta de inmediato, pero las políticas de seguridad de la empresa exigen que los servidores de producción corran estrictamente en modo Enforcing.

  Investigue los bloqueos en los registros de auditoría, asigne el contexto de SELinux adecuado de manera permanente a la ruta de la aplicación (/custom_data), configure de forma persistente el parámetro de kernel 'vm.max_map_count' en 262144 (requerido por el motor de la app), y deje el servicio operativo en modo seguro.
Validacion:
  - Objetivo: SELinux se encuentra activo en modo Enforcing.
    Peso: 25 %
  - Objetivo: El directorio /custom_data tiene asignado de forma permanente el contexto correcto (httpd_sys_rw_content_t).
    Peso: 35 %
  - Objetivo: El servicio 'secure-app.service' está activo y en ejecución.
    Peso: 25 %
  - Objetivo: El parámetro de kernel vm.max_map_count está fijado de forma persistente en 262144.
    Peso: 15 %
Calificacion Final:
VM Vagrant: |-
  Vagrant.configure("2") do |config|

    # Caja oficial de Rocky Linux 9 para KVM / Libvirt
    config.vm.box = "generic/rocky9"
    
    # Configuración de recursos para tu entorno nativo VIRT-MANAGER
    config.vm.provider :libvirt do |libvirt|
      libvirt.memory = 2048
      libvirt.cpus = 2
    end

    # Provisioning artesanal para inyectar fallos reales de nivel L2/L3
    config.vm.provision "shell", inline: <<-SHELL
      set -e

      # 1. Instalación de herramientas avanzadas de diagnóstico de seguridad y procesos
      dnf install -y policycoreutils-python-utils setroubleshoot-server procps-ng psmisc

      # 2. Forzar estado Enforcing estricto
      setenforce 1
      sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

      # =========================================================
      # CONFIGURACIÓN DEL ESCENARIO INFRAESTRUCTURA INC-2006
      # =========================================================

      # --- Escenario 1: Contexto erróneo en el directorio de la aplicación ---
      mkdir -p /custom_data
      echo "{"status": "production", "db_pool": 100}" > /custom_data/app.json
      
      # Forzamos un contexto restrictivo ajeno (user_home_t) para simular un despliegue mal hecho
      semanage fcontext -a -t user_home_t "/custom_data(/.*)?"
      restorecon -Rv /custom_data

      # --- Escenario 2: Parámetros de Kernel degradados ---
      echo "fs.file-max = 100000" > /etc/sysctl.d/99-secure-app.conf
      echo "vm.max_map_count = 65530" >> /etc/sysctl.d/99-secure-app.conf
      sysctl --system

      # --- Escenario 3: Deshabilitar Booleano Crítico de SELinux ---
      # Deshabilitamos httpd_setrlimit, impidiendo que servicios web/customizados alteren sus límites internos
      setsebool -P httpd_setrlimit off

      # =========================================================
      # CREACIÓN DEL BINARIO SIMULADO Y UNIDAD SYSTEMD
      # =========================================================
      mkdir -p /opt/secure-app

      cat << 'EOF' > /opt/secure-app/secure-binary-v2
  #!/bin/bash
  LOG_FILE="/var/log/secure-app-boot.log"
  echo "[$(date)] Iniciando comprobaciones de seguridad V2..." >> $LOG_FILE

  # 1. Verificar lectura de datos bajo SELinux fcontext
  if ! cat /custom_data/app.json >/dev/null 2>&1; then
      echo "CRITICAL: Acceso denegado a /custom_data/app.json por restricciones de fcontext." >&2
      exit 1
  fi

  # 2. Simulación de cambio de límites (Dará error AVC si httpd_setrlimit está en OFF)
  if ! ulimit -n 65536 >/dev/null 2>&1; then
      echo "CRITICAL: Fallo al ajustar descriptores de archivo (ulimit). Bloqueado por Booleano SELinux." >&2
      logger -p authpriv.err "secure-app: AVC denial por falta de privilegios setrlimit."
      exit 1
  fi

  echo "Validaciones correctas. Aplicación V2 en ejecución permanente." >> $LOG_FILE
  while true; do
      sleep 5
  done
  EOF

      chmod 755 /opt/secure-app/secure-binary-v2

      # Crear unidad Systemd original (SIN la directiva LimitNOFILE exigida)
      cat << 'EOF' > /etc/systemd/system/secure-app.service
  [Unit]
  Description=Secure Corporative Application Service V2
  After=network.target

  [Service]
  Type=simple
  ExecStart=/opt/secure-app/secure-binary-v2
  Restart=no

  [Install]
  WantedBy=multi-user.target
  EOF

      systemctl daemon-reload

      # Banner decorativo para la terminal del lab
      echo -e "\e[1;36m================================================================================\e[0m"
      echo -e "\e[1;32m 🚀 ESCENARIO PG-006-V2 CONFIGURADO - NIVEL: SYSADMIN PLENO L2/L3\e[0m"
      echo -e "\e[1;36m================================================================================\e[0m"
      echo -e " \e[1mTICKET:\e[0m INC-2006 (URGENTE) - Fallo Multi-capa de Seguridad y Descriptores"
      echo -e " \e[1mAsunto:\e[0m El servicio 'secure-app' no arranca con SELinux Enforcing y falla por 'Too many open files'"
      echo -e " ------------------------------------------------------------------------------"
      echo -e " \e[1m🔍 Objetivos de solución (sin alterar el modo Enforcing global):\e[0m"
      echo -e "   \e[1;33m1.\e[0m Corregir el contexto SELinux del directorio \e[1;33m/custom_data\e[0m a \e[1;33mhttpd_sys_rw_content_t\e[0m (persistente)"
      echo -e "   \e[1;33m2.\e[0m Activar de forma permanente el booleano \e[1;33mhttpd_setrlimit\e[0m (el servicio necesita cambiar ulimit)"
      echo -e "   \e[1;33m3.\e[0m Ajustar parámetros del kernel \e[1;33mfs.file-max=2097152\e[0m y \e[1;33mvm.max_map_count=262144\e[0m (persistentes)"
      echo -e "   \e[1;33m4.\e[0m Configurar la unidad systemd con \e[1;33mLimitNOFILE=65536\e[0m y reiniciar el servicio"
      echo -e " ------------------------------------------------------------------------------"
      echo -e " \e[1m📋 Herramientas útiles:\e[0m ausearch, audit2why, semanage, restorecon, getsebool, setsebool -P, sysctl, systemctl edit"
      echo -e " \e[1m📁 Logs:\e[0m journalctl -u secure-app, ausearch -m AVC -ts recent, /var/log/secure-app-boot.log"
      echo -e "\e[1;36m================================================================================\e[0m"
    SHELL
  end
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0

  echo "=== EVALUANDO SEGURIDAD Y PARÁMETROS EN TIEMPO DE EJECUCIÓN (SELINUX / SYSCTL) ==="

  # 1. Validar que SELinux siga en Enforcing
  if getenforce | grep -q "Enforcing"; then
      echo "✔ [25%] Cumplimiento de seguridad validado: SELinux permanece en modo 'Enforcing'."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] Error de política: Se ha desactivado o puesto en modo Permissive el control del sistema."
  fi

  # 2. Validar el contexto permanente en la base de datos de políticas de SELinux
  # Buscamos que la ruta esté registrada en la política local
  if semanage fcontext -l | grep -E "/custom_data.*\bhttpd_sys_rw_content_t\b" >/dev/null 2>&1; then
      # Verificar si además se aplicó al archivo en disco con restorecon
      if ls -Z /custom_data/app.conf | grep -q "httpd_sys_rw_content_t"; then
          echo "✔ [35%] Contexto de archivos corregido permanentemente con semanage y restorecon."
          PUNTOS=$((PUNTOS + 35))
      else
          echo "❌ [20%] La política está registrada, pero olvidó aplicar los cambios en disco con 'restorecon'."
          PUNTOS=$((PUNTOS + 20))
      fi
  else
      echo "❌ [0%] El directorio /custom_data no tiene una regla permanente en semanage fcontext."
  fi

  # 3. Validar si el servicio está corriendo
  if systemctl is-active --quiet secure-app.service; then
      echo "✔ [25%] Servicio 'secure-app.service' desbloqueado y ejecutándose con éxito."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] El servicio sigue fallando. Revise los registros AVC de auditoría."
  fi

  # 4. Validar parámetro de kernel en sysctl persistente
  SYSCTL_LIVE=$(sysctl -n vm.max_map_count)
  if [ "$SYSCTL_LIVE" -eq 262144 ] 2>/dev/null; then
      if [ -f /etc/sysctl.conf ] && grep -q "^vm.max_map_count\s*=\s*262144" /etc/sysctl.conf || grep -q "^vm.max_map_count\s*=\s*262144" /etc/sysctl.d/*.conf 2>/dev/null; then
          echo "✔ [15%] Parámetro 'vm.max_map_count=262144' configurado de forma persistente."
          PUNTOS=$((PUNTOS + 15))
      else
          echo "❌ [10%] El parámetro de kernel está cambiado en caliente, pero no de forma persistente en los archivos de configuración."
          PUNTOS=$((PUNTOS + 10))
      fi
  else
      echo "❌ [0%] El parámetro 'vm.max_map_count' no coincide con el valor requerido."
  fi

  echo "============================"
  echo "CALIFICACIÓN FINAL: $PUNTOS / 100"
  echo "============================"
---

[[Laboratorios del LFCS]]

---
I recently worked a critical security incident where a corporate application called **secure-app** was failing to start on a production server running Rocky Linux 9.7. The development team had discovered that running `setenforce 0` fixed the issue, but company policy strictly requires all production servers to run SELinux in Enforcing mode, so that workaround was off the table.

My first step was to audit the SELinux context assigned to the application's data directory, `/custom_data`. I found it had been labeled with `sshd_key_t`, a context reserved for SSH private keys — completely wrong for an application directory, and exactly the kind of misconfiguration that SELinux would silently block in Enforcing mode.

I corrected this permanently using `semanage fcontext` to register the proper `httpd_sys_content_t` context in the SELinux policy, then ran `restorecon -Rv` to relabel the existing files immediately. This approach ensures the correct context survives system reboots and full filesystem relabels, unlike `chcon` which is only temporary.

Additionally, the application required the kernel parameter `vm.max_map_count` set to `262144` — above the system default of `65530`. I configured this persistently by creating `/etc/sysctl.d/99-secure-app.conf`, which is automatically loaded by `systemd-sysctl` on every boot, and applied it immediately at runtime without requiring a restart.

With both fixes in place, I restarted the service and confirmed it came up cleanly — `active (running)`, SELinux still in Enforcing mode, no AVC denials. The system is now compliant with security policy and the application is fully operational.