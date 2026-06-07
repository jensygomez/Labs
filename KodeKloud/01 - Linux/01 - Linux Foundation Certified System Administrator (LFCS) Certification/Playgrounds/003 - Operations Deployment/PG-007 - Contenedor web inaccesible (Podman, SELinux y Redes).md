---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Playground: PG-007
Titulo: Contenedor web inaccesible (Podman, SELinux y Redes)
Fecha de Inicio: 2026-06-03
Dificultad: 8/10
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux
Temas:
  - Services
  - Logs
  - SELinux/AppArmor
  - Containers and VMs
Competencias:
  - Gestionar contenedores e imágenes con Podman
  - Integrar contenedores en Systemd (generación de archivos de unidad)
  - Solucionar bloqueos de SELinux en volúmenes montados (banderas de contexto :Z)
  - Configurar reglas de firewall básicas (firewalld) para abrir puertos
Ticket: |-
  INC-1007

  El equipo DevOps ha desplegado un microservicio web utilizando un contenedor Podman administrado por Systemd. Sin embargo, los usuarios reportan que la aplicación no responde (Connection Refused) y el servicio de Systemd entra en estado fallido repetidamente debido a errores de escritura en el volumen montado (/var/www/html).

  Investigue los logs del servicio, repare el bloqueo de seguridad del almacenamiento, asegúrese de que el puerto 8080 esté abierto en el firewall y deje el contenedor corriendo de forma persistente.
Validacion:
  - Objetivo: El almacenamiento compartido del host tiene los permisos y contexto SELinux adecuados (container_file_t o bandera :Z).
    Peso: 30 %
  - Objetivo: El servicio systemd 'container-webapp.service' está activo y corriendo sin caídas.
    Peso: 25 %
  - Objetivo: El puerto 8080 está abierto de forma permanente en el firewall local del host.
    Peso: 25 %
  - Objetivo: Verificación final exitosa del servicio mediante curl al puerto 8080.
    Peso: 20 %
Calificacion Final:
Vagrant: |-
  # Vagrantfile - PG-007: Contenedor web inaccesible (Podman, SELinux y Redes)
  # Basado en la estructura de PG-006 para Rocky Linux 9

  Vagrant.configure("2") do |config|
    config.vm.box = "generic/rocky9"

    config.vm.provider :libvirt do |libvirt|
      libvirt.memory = 2048
      libvirt.cpus = 2
    end

    config.vm.provision "shell", inline: <<-SHELL
      set -e

      # Instalación de paquetes necesarios
      dnf install -y podman firewalld policycoreutils-python-utils setroubleshoot-server

      # Asegurar SELinux en modo enforcing (persistente)
      setenforce 1
      sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

      # Habilitar e iniciar firewalld
      systemctl enable --now firewalld

      # =========================================================
      # CONFIGURACIÓN DEL ESCENARIO DE FALLO (INC-1007)
      # =========================================================

      # 1. Crear volumen del host con contexto SELinux restrictivo (sshd_key_t)
      mkdir -p /opt/web_data
      echo "Funcionando en el nivel 8!" > /opt/web_data/index.html
      chcon -R -t sshd_key_t /opt/web_data

      # 2. Descargar imagen base (nginx de Red Hat UBI)
      podman pull registry.access.redhat.com/ubi9/nginx-120:latest >/dev/null 2>&1 || true

      # 3. Crear unidad systemd con error: montaje SIN bandera :Z y puerto mapeado
      cat << 'EOF' > /etc/systemd/system/container-webapp.service
  [Unit]
  Description=Podman Container - WebApp Engine
  Wants=network-online.target
  After=network-online.target

  [Service]
  Environment=PODMAN_SYSTEMD_UNIT=%n
  Restart=always
  ExecStartPre=-/usr/bin/podman rm -f webapp-container
  ExecStart=/usr/bin/podman run --name webapp-container -p 8080:8080 -v /opt/web_data:/var/www/html:ro registry.access.redhat.com/ubi9/nginx-120:latest
  ExecStop=/usr/bin/podman stop -t 10 webapp-container
  ExecStopPost=-/usr/bin/podman rm -f webapp-container
  Type=simple

  [Install]
  WantedBy=multi-user.target
  EOF

      # 4. Cerrar el puerto 8080 en firewalld (bloquear acceso)
      firewall-cmd --permanent --remove-port=8080/tcp 2>/dev/null || true
      firewall-cmd --reload

      # 5. Recargar systemd e iniciar el servicio (que fallará)
      systemctl daemon-reload
      systemctl start container-webapp.service 2>/dev/null || true

      # Mensaje de bienvenida / instrucciones
      echo -e "\e[1;36m========================================================================\e[0m"
      echo -e "\e[1;31m 🚀 ESCENARIO PG-007 CONFIGURADO - CRISIS DE CONTENEDORES EN PRODUCCIÓN\e[0m"
      echo -e "\e[1;36m========================================================================\e[0m"
      echo -e "\e[1;33m TICKET DE INCIDENTE: INC-1007\e[0m"
      echo -e " ------------------------------------------------------------------------------"
      echo -e " \e[1mAsunto:\e[0m Contenedor web inaccesible (Connection Refused)"
      echo -e " \e[1mSeveridad:\e[0m Alta / Infraestructura DevOps"
      echo -e ""
      echo -e " \e[1mDescripción:\e[0m"
      echo -e " El servicio 'container-webapp.service' no puede inicializar el servidor web"
      echo -e " debido a fallas de políticas AVC de SELinux sobre /opt/web_data."
      echo -e " Adicionalmente, el tráfico externo no logra alcanzar el puerto 8080."
      echo -e ""
      echo -e " \e[1mRequerimientos de Validación (Peso Total: 100%):\e[0m"
      echo -e "  [ ] Corregir el montaje SELinux con la bandera ':Z' en la unidad -> \e[1;35m30%\e[0m"
      echo -e "  [ ] Servicio 'container-webapp.service' en estado Running       -> \e[1;35m25%\e[0m"
      echo -e "  [ ] Puerto 8080/tcp abierto permanentemente en firewalld      -> \e[1;35m25%\e[0m"
      echo -e "  [ ] 'curl localhost:8080' devuelve HTTP 200                    -> \e[1;35m20%\e[0m"
      echo -e " ------------------------------------------------------------------------------"
      echo -e " \e[1;32mMisión:\e[0m Inspeccione journalctl, arregle el montaje y abra la red.\e[0m"
      echo -e "\e[1;36m========================================================================\e[0m"
    SHELL
  end
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash

  # Validación para PG-007 (ejecutar como root después de resolver el laboratorio)

  PUNTOS=0

  echo "=== EVALUANDO INFRAESTRUCTURA DE CONTENEDORES Y REDES ==="

  # 1. Verificar contexto SELinux corregido (bandera :Z o contexto container_file_t)
  if [ -f /etc/systemd/system/container-webapp.service ] && grep -E "\/opt\/web_data:\/var\/www\/html:(ro,Z|Z,ro|Z)" /etc/systemd/system/container-webapp.service >/dev/null 2>&1; then
      echo "✔ [30%] Configuración de volumen corregida con la bandera :Z."
      PUNTOS=$((PUNTOS + 30))
  elif ls -Z /opt/web_data | grep -q "container_file_t"; then
      echo "✔ [30%] Contexto SELinux corregido manualmente a container_file_t."
      PUNTOS=$((PUNTOS + 30))
  else
      echo "❌ [0%] El contenedor sigue sin permisos por SELinux."
  fi

  # 2. Servicio activo
  if systemctl is-active --quiet container-webapp.service; then
      echo "✔ [25%] Servicio 'container-webapp.service' activo."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] El servicio está caído o en ciclo de fallos."
  fi

  # 3. Puerto abierto en firewalld (permanente)
  if firewall-cmd --permanent --list-ports | grep -q "8080/tcp"; then
      echo "✔ [25%] Puerto 8080/tcp abierto permanentemente en firewalld."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] El puerto 8080 sigue bloqueado por firewalld."
  fi

  # 4. Curl exitoso
  if curl -s --connect-timeout 2 http://localhost:8080 >/dev/null; then
      echo "✔ [20%] La aplicación web responde correctamente (HTTP 200)."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] La aplicación no responde en el puerto 8080."
  fi

  echo "============================"
  echo "CALIFICACIÓN FINAL: $PUNTOS / 100"
  echo "============================"
---

[[Laboratorios del LFCS]]

---
_I recently resolved a high-severity incident involving a containerized web application running on Rocky Linux 9. The service was failing to start due to SELinux AVC denials on a bind-mounted volume. I diagnosed the issue by inspecting journalctl logs and the systemd unit file, then corrected the volume mount by adding the `:Z` flag to allow proper SELinux relabeling._

_Beyond the documented issues, I identified two additional root causes that weren't part of the original ticket: the mount point was targeting the wrong directory inside the container, and the nginx process was missing the `daemon off` flag, causing it to exit immediately after launch. I discovered these by running the container manually outside of systemd to observe its raw output, then inspecting the nginx configuration directly inside the running container._

I also opened port 8080 permanently in firewalld and validated the full fix with curl, confirming an HTTP 200 response. The incident scored 100% on all validation checkpoints. This exercise reinforced my ability to work through layered infrastructure problems — SELinux, systemd, Podman, and firewalld — systematically and without relying on pre-written runbooks._