---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Playground: PG-007-V2
Titulo: Contenedor web inaccesible (Podman, SELinux y Redes) - V2
Fecha de Inicio: 2026-06-03
Dificultad: 8/10
Level Escalation: L2/L3
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux
Temas:
  - Services (Systemd Unit Customization)
  - Logs y Troubleshooting Avanzado (Podman Logs)
  - SELinux (Contextos de Volumen y Políticas de Puertos de Red)
  - Containers and Network Security (Firewalld & Container Isolation)
Competencias:
  - Depurar e instanciar contenedores sin privilegios de root mediante Podman
  - Modificar y corregir archivos de unidad de Systemd para Podman (`ExecStart`)
  - Solucionar bloqueos AVC mediante banderas de volumen (:Z) o contextos explícitos
  - Administrar y registrar puertos restringidos en políticas de SELinux (`semanage port`)
  - Implementar reglas de aislamiento de red persistentes en Firewalld
Ticket: |-
  INC-2007 (CRÍTICO) - Falla de Despliegue en Microservicio Nginx con Podman V2

    El equipo de ingeniería ha desplegado la nueva versión de la aplicación web corporativa utilizando Podman y Systemd bajo la unidad 'container-webapp.service'. Los clientes reportan que la URL no carga y el balanceador de carga reporta caídas constantes.

    Tras una revisión preliminar, se identificaron múltiples fallas estructurales heredadas:
    1. SELinux bloquea el acceso de lectura al volumen `/opt/web_data`. El contenedor requiere acceso seguro sin romper las políticas 'Enforcing'.
    2. Los desarrolladores intentaron cambiar el puerto de escucha en el host al puerto 8443, pero el contenedor es incapaz de unirse correctamente al puerto o el cortafuegos está descartando los paquetes de manera silenciosa.
    3. La directiva del puerto interno en el comando de Podman está desalineada con el puerto nativo sin privilegios en el que corre la imagen base Red Hat UBI Nginx (el cual escucha internamente en el puerto 8080, no en el 80).

    Misión:
    1. Corrija los parámetros de arranque en la unidad de Systemd para mapear de forma correcta los puertos (Host: 8443 -> Contenedor: 8080).
    2. Asegure que el volumen montado posea el aislamiento de contexto SELinux permanente (bandera :Z).
    3. Registre el puerto 8443 en las políticas de red de SELinux para permitir que servicios HTTP operen en dicho puerto si el sistema lo requiere.
    4. Abra de manera permanente el puerto 8443/tcp en la zona activa de firewalld.
Validacion:
  - Objetivo: El volumen compartido posee la bandera :Z configurada correctamente en la unidad.
    Peso: 25 %
  - Objetivo: El puerto 8443 está registrado permanentemente en la política de SELinux para tráfico HTTP (`http_port_t`).
    Peso: 25 %
  - Objetivo: El puerto 8443/tcp se encuentra abierto y persistente en la configuración del Firewalld del Host.
    Peso: 25 %
  - Objetivo: Comprobación local con curl ('curl localhost:8443') responde con éxito (HTTP 200).
    Peso: 25 %
Calificacion Final:
Vagrant: |-
  Vagrant.configure("2") do |config|

      # Caja oficial de Rocky Linux 9 para KVM / Libvirt
      config.vm.box = "generic/rocky9"

      config.vm.provider :libvirt do |libvirt|
        libvirt.memory = 2048
        libvirt.cpus = 2
      end

      config.vm.provision "shell", inline: <<-SHELL
        set -e

        # 1. Instalar paquetería de administración de contenedores y auditoría de seguridad
        dnf install -y podman firewalld policycoreutils-python-utils setroubleshoot-server

        # 2. Forzar SELinux en modo Enforcing estricto
        setenforce 1
        sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

        # 3. Inicializar el Cortafuegos de producción
        systemctl enable --now firewalld

        # =========================================================
        # CONFIGURACIÓN DEL ESCENARIO DE FALLO AVANZADO (INC-2007)
        # =========================================================

        # --- Trampa 1: Volumen con contexto hostil (sshd_key_t) ---
        mkdir -p /opt/web_data
        echo "Despliegue Exitoso - Sysadmin Nivel L2/L3 Verificado" > /opt/web_data/index.html
        chcon -R -t sshd_key_t /opt/web_data

        # Pre-descarga de la imagen corporativa oficial RHEL UBI
        podman pull registry.access.redhat.com/ubi9/nginx-120:latest >/dev/null 2>&1 || true

        # --- Trampa 2: Unidad Systemd rota con mala configuración de puertos ---
        # La imagen interna de Red Hat UBI Nginx NO corre como root por seguridad,
        # por ende escucha en el puerto interno 8080. Mapear 8443:80 es un error fatal.
        cat << 'EOF' > /etc/systemd/system/container-webapp.service
    [Unit]
    Description=Podman Container - WebApp Engine V2
    Wants=network-online.target
    After=network-online.target

    [Service]
    Environment=PODMAN_SYSTEMD_UNIT=%n
    Restart=always
    ExecStartPre=-/usr/bin/podman rm -f webapp-container-v2
    # ERROR INTENCIONAL: Mapeo de puerto interno a 80 en vez de 8080 y falta la bandera :Z en el volumen
    ExecStart=/usr/bin/podman run --name webapp-container-v2 -p 8443:80 -v /opt/web_data:/opt/app-root/src:ro registry.access.redhat.com/ubi9/nginx-120:latest nginx -g 'daemon off;'
    ExecStop=/usr/bin/podman stop -t 10 webapp-container-v2
    ExecStopPost=-/usr/bin/podman rm -f webapp-container-v2
    Type=simple

    [Install]
    WantedBy=multi-user.target
    EOF

        # --- Trampa 3: Red y Puertos cerrados de forma explícita ---
        firewall-cmd --permanent --remove-port=8443/tcp 2>/dev/null || true
        firewall-cmd --reload

        # Asegurar que el puerto 8443 esté removido de los tipos HTTP de SELinux si existiese
        # (Por defecto no está, pero forzamos el entorno base limpio)
        
        # Recargar e intentar iniciar el entorno (fallará por contextos y puertos)
        systemctl daemon-reload
        systemctl start container-webapp.service 2>/dev/null || true

        # Banner de despliegue en la consola del laboratorio
        echo -e "\e[1;36m========================================================================\e[0m"
        echo -e "\e[1;31m 🚀 ESCENARIO PG-007-V2 CONFIGURADO - INFRAESTRUCTURA DE CONTENEDORES\e[0m"
        echo -e "\e[1;36m========================================================================\e[0m"
        echo -e " \e[1mTICKET DE INCIDENTE:\e[0m INC-2007"
        echo -e " \e[1mAsunto:\e[0m Microservicio Inaccesible - Puertos desalineados y SELinux Network\e[0m"
        echo -e " ------------------------------------------------------------------------------"
        echo -e " Use \e[1;33mpodman logs webapp-container-v2\e[0m para ver la denegación de puerto interno."
        echo -e " Verifique políticas de red con \e[1;33msemanage port -l | grep http\e[0m"
        echo -e "\e[1;36m========================================================================\e[0m"
      SHELL
    end
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash

    PUNTOS=0

    echo "=== INICIANDO VALIDACIÓN AUTOMÁTICA DEL ENTORNO DE CONTENEDORES V2 ==="

    # 1. Verificar bandera :Z en el volumen dentro de la unidad de Systemd
    if [ -f /etc/systemd/system/container-webapp.service ] && grep -E "\/opt\/web_data:\/opt\/app-root\/src:(ro,Z|Z,ro|Z)" /etc/systemd/system/container-webapp.service >/dev/null 2>&1; then
        echo "✔ [25%] Unidad Systemd: Volumen configurado de forma correcta con aislamiento persistente (:Z)."
        PUNTOS=$((PUNTOS + 25))
    else
        echo "❌ [0%] Unidad Systemd: El volumen no cuenta con el sufijo de contexto ':Z' necesario para el aislamiento de Podman."
    fi

    # 2. Verificar si el puerto 8443 fue agregado a la política HTTP de SELinux
    if semanage port -l | grep -E "http_port_t.*\b8443\b" >/dev/null 2>&1; then
        echo "✔ [25%] SELinux Red: Puerto 8443 registrado exitosamente en el tipo 'http_port_t'."
        PUNTOS=$((PUNTOS + 25))
    else
        echo "❌ [0%] SELinux Red: El puerto 8443 no está autorizado para tráfico HTTP en las políticas del Kernel."
    fi

    # 3. Puerto abierto en firewalld permanente
    if firewall-cmd --permanent --list-ports | grep -q "8443/tcp"; then
        echo "✔ [25%] Firewalld: Puerto 8443/tcp abierto de forma inmutable."
        PUNTOS=$((PUNTOS + 25))
    else
        echo "❌ [0%] Firewalld: El puerto 8443/tcp sigue bloqueado de forma persistente en el cortafuegos."
    fi

    # 4. Prueba de integración de extremo a extremo (End-to-End Curl)
    # Aplicamos un reinicio de control para certificar que todo sobrevive a cambios de Systemd
    systemctl daemon-reload
    systemctl restart container-webapp.service >/dev/null 2>&1
    sleep 2

    if curl -s --connect-timeout 3 http://localhost:8443 | grep -q "Sysadmin Nivel L2/L3"; then
        echo "✔ [25%] Integración Core: La aplicación web responde correctamente con HTTP 200 y contenido íntegro."
        PUNTOS=$((PUNTOS + 25))
    else
        echo "❌ [0%] Integración Core: Error al conectar. El contenedor está caído o el mapeo de puertos internos (8080) es erróneo."
    fi

    echo "=========================================="
    echo "CALIFICACIÓN FINAL DEL ENTORNO: $PUNTOS / 100"
    echo "=========================================="
---

[[Laboratorios del LFCS]]

---
