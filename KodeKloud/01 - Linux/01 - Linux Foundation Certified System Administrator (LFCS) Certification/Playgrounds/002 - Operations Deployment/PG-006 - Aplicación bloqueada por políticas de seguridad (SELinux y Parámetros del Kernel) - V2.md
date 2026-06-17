---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Playground: PG-006-V2
Titulo: Aplicación bloqueada por políticas de seguridad (SELinux, Booleanos y Límites del Kernel) V2
Fecha de Inicio: 2026-06-07
Dificultad: 7/10
Level Escalation: L2/L3
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux Pleno L2/L3
Temas:
  - Services (Systemd Resource Limits)
  - Logs y Auditoría Avanzada (AVC Denials Avanzados)
  - Kernel Runtime Parameters & Persistencia
  - SELinux (Contextos y Booleanos Lógicos)
Competencias:
  - Administrar contextos de archivos SELinux (`semanage fcontext`, `restorecon`)
  - Identificar y modificar parámetros lógicos de SELinux (`getsebool`, `setsebool -P`)
  - Analizar registros de auditoría complejos (`ausearch -m AVC`, `audit2why`)
  - Configurar parámetros del Kernel persistentes bajo `/etc/sysctl.d/`
  - Gestionar restricciones de descriptores de archivos a nivel proceso en Systemd (`LimitNOFILE`)
Ticket: |-
  INC-2006 (URGENTE) - Fallo Multi-capa de Seguridad y Descriptores en Servidor de Aplicación V2

  El equipo de DevOps ha desplegado la versión 2 de "secure-app" en el servidor de pruebas internas (Rocky Linux 9 bajo KVM). El servicio se niega a iniciar por completo si SELinux está activo. Los desarrolladores reclaman que modificando la directiva global a Permissive funciona, pero el Oficial de Seguridad (CISO) prohíbe categóricamente esta práctica en producción.

  Adicionalmente, la nueva arquitectura de la aplicación procesa una alta cantidad de hilos concurrentes y lecturas de archivos. Reportan que bajo carga el sistema arroja errores de "Too many open files", por lo que se requiere ajustar de forma persistente el parámetro de kernel 'fs.file-max' a 2097152, el parámetro 'vm.max_map_count' a 262144 y asegurar que la unidad de Systemd sea capaz de heredar y procesar al menos 65536 descriptores de archivos simultáneos.

  Misión:
  1. No altere el modo Enforcing global de SELinux.
  2. Identifique mediante los registros de auditoría qué bloquea el acceso al directorio de datos `/custom_data` (Cambiar fcontext erróneo).
  3. Identifique qué booleano lógico del sistema impide que el servicio realice operaciones del sistema/red internas (revisar denegaciones AVC ocultas).
  4. Aplique las configuraciones de kernel de forma persistente y configure la unidad de Systemd para cumplir con los requisitos de descriptores de archivos.
Validacion:
  - Objetivo: SELinux se encuentra activo en modo Enforcing de forma ininterrumpida.
    Peso: 20 %
  - Objetivo: El directorio /custom_data y sus archivos poseen el fcontext permanente corregido (`httpd_sys_rw_content_t`).
    Peso: 25 %
  - Objetivo: El booleano de SELinux necesario para servicios (`httpd_setrlimit`) está activado de manera persistente.
    Peso: 20 %
  - Objetivo: Los parámetros sysctl (`fs.file-max` y `vm.max_map_count`) están configurados de forma persistente con los valores exigidos.
    Peso: 15 %
  - Objetivo: La unidad de Systemd tiene configurada de forma correcta la directiva de límites de archivos (`LimitNOFILE=65536`) y el servicio está activo.
    Peso: 20 %
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
      echo '{"status": "production", "db_pool": 100}' > /custom_data/app.json
      
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
      echo -e " \e[1mTICKET:\e[0m INC-2006 (URGENTE)"
      echo -e " \e[1mAsunto:\e[0m Fallo multi-capa: SELinux + límites de kernel + descriptores de archivo"
      echo -e " ------------------------------------------------------------------------------"
      echo -e " \e[1;33m🔧 Objetivos de solución (no desactivar SELinux Enforcing):\e[0m"
      echo -e "   \e[1;32m1.\e[0m Corregir el contexto SELinux de \e[1;33m/custom_data\e[0m a \e[1;33mhttpd_sys_rw_content_t\e[0m (persistente)"
      echo -e "   \e[1;32m2.\e[0m Activar el booleano \e[1;33mhttpd_setrlimit\e[0m de forma permanente (para que el servicio pueda hacer ulimit)"
      echo -e "   \e[1;32m3.\e[0m Configurar parámetros del kernel persistentes: \e[1;33mfs.file-max=2097152\e[0m y \e[1;33mvm.max_map_count=262144\e[0m"
      echo -e "   \e[1;32m4.\e[0m Agregar \e[1;33mLimitNOFILE=65536\e[0m a la unidad systemd y reiniciar el servicio"
      echo -e " ------------------------------------------------------------------------------"
      echo -e " \e[1;34m📌 Herramientas útiles:\e[0m ausearch, audit2why, semanage, restorecon, getsebool, setsebool -P, sysctl, systemctl edit"
      echo -e " \e[1;34m📁 Logs:\e[0m journalctl -u secure-app, ausearch -m AVC, /var/log/secure-app-boot.log"
      echo -e "\e[1;36m================================================================================\e[0m"
    SHELL
  end
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0

  echo "=== INICIANDO AUDITORÍA TÉCNICA DE VALIDACIÓN V2 ==="

  # 1. Validar SELinux Enforcing
  if getenforce | grep -q "Enforcing"; then
      echo "✔ [20%] Cumplimiento Global: SELinux está activo y protegiendo el sistema en modo Enforcing."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] INCUMPLIMIENTO: El modo Enforcing global ha sido alterado o desactivado."
  fi

  # 2. Validar fcontext permanente y aplicado en disco
  if semanage fcontext -l | grep -E "/custom_data.*\bhttpd_sys_rw_content_t\b" >/dev/null 2>&1; then
      if ls -Z /custom_data/app.json | grep -q "httpd_sys_rw_content_t"; then
          echo "✔ [25%] SELinux Fcontext: Regla permanente aplicada con éxito en /custom_data."
          PUNTOS=$((PUNTOS + 25))
      else
          echo "❌ [10%] Fcontext parcial: La regla está en la base de datos pero olvidó aplicar 'restorecon'."
          PUNTOS=$((PUNTOS + 10))
      fi
  else
      echo "❌ [0%] SELinux Fcontext: No existe una regla permanente para /custom_data asociada a httpd_sys_rw_content_t."
  fi

  # 3. Validar Booleano de SELinux permanente
  if getsebool httpd_setrlimit | grep -q "on"; then
      echo "✔ [20%] SELinux Booleano: 'httpd_setrlimit' se encuentra habilitado de manera persistente."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] SELinux Booleano: El servicio no puede modificar sus rlimits. Falta activar el booleano 'httpd_setrlimit'."
  fi

  # 4. Validar Sysctl tanto en caliente como en persistente
  SYSCTL_MAX=$(sysctl -n fs.file-max)
  SYSCTL_MAP=$(sysctl -n vm.max_map_count)

  if [ "$SYSCTL_MAX" -eq 2097152 ] && [ "$SYSCTL_MAP" -eq 262144 ]; then
      if grep -E -q "^fs.file-max\s*=\s*2097152" /etc/sysctl.conf /etc/sysctl.d/*.conf 2>/dev/null && \
         grep -E -q "^vm.max_map_count\s*=\s*262144" /etc/sysctl.conf /etc/sysctl.d/*.conf 2>/dev/null; then
          echo "✔ [15%] Sysctl: Parámetros de kernel modificados y persistentes ante reinicios."
          PUNTOS=$((PUNTOS + 15))
      else
          echo "❌ [5%] Sysctl: Los valores coinciden en runtime, pero no están guardados de forma persistente en /etc/sysctl.d/."
          PUNTOS=$((PUNTOS + 5))
      fi
  else
      echo "❌ [0%] Sysctl: Los valores en tiempo de ejecución del kernel no son los solicitados en el ticket."
  fi

  # 5. Validar Systemd unidad y servicio vivo
  if systemctl cat secure-app.service 2>/dev/null | grep -E -iq "LimitNOFILE\s*=\s*65536"; then
      systemctl daemon-reload
      systemctl restart secure-app.service >/dev/null 2>&1
      
      if systemctl is-active --quiet secure-app.service; then
          echo "✔ [20%] Systemd: Unidad configurada con los límites correctos y servicio en ejecución estable."
          PUNTOS=$((PUNTOS + 20))
      else
          echo "❌ [0%] Systemd: El servicio sigue fallando tras el reinicio de control. Revise logs internos."
      fi
  else
      echo "❌ [0%] Systemd: Falta la directiva 'LimitNOFILE=65536' dentro de la sección [Service] de la unidad."
  fi

  echo "=========================================="
  echo "RESULTADO DE LA EVALUACIÓN V2: $PUNTOS / 100"
  echo "=========================================="
---
[[Laboratorios del LFCS]]
----
