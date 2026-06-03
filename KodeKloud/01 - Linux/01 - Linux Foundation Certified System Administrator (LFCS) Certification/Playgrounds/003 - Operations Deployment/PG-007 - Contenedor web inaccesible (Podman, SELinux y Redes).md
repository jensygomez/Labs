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
Script: |-
  cat << 'EOF' > /tmp/setup_sh
  #!/bin/bash
  set -e

  # 1. Asegurar instalación de Podman y Firewall
  dnf install -y podman firewalld 2>/dev/null || true
  systemctl enable --now firewalld

  # 2. Configurar volumen del host con contexto restrictivo (Rompe SELinux para el contenedor)
  mkdir -p /opt/web_data
  echo "Funcionando en el nivel 8!" > /opt/web_data/index.html
  chcon -t sshd_key_t /opt/web_data
  chcon -t sshd_key_t /opt/web_data/index.html

  # 3. Descargar imagen base ligera de forma silenciosa para el ejercicio
  podman pull registry.access.redhat.com/ubi9/nginx-120:latest >/dev/null 2>&1 || true

  # 4. Crear el archivo de unidad de Systemd que arranca el contenedor de forma errónea
  # El error está en que monta el volumen sin la bandera ':Z' obligatoria para que Podman reetiquete SELinux,
  # y mapea internamente un puerto pero el firewall del host está cerrado.
  cat << 'SER' > /etc/systemd/system/container-webapp.service
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
  SER

  # 5. Cerrar el puerto en el firewall (Asegurar que esté bloqueado)
  firewall-cmd --permanent --remove-port=8080/tcp 2>/dev/null || true
  firewall-cmd --reload

  # 6. Cargar y arrancar en estado roto
  systemctl daemon-reload
  systemctl start container-webapp.service 2>/dev/null || true

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;31m 🚀 ESCENARIO PG-007 CONFIGURADO - CRISIS DE CONTENEDORES EN PRODUCCIÓN\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-1007\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Contenedor web inaccesible"
  echo -e " \e[1mSeveridad:\e[0m Alta / Infraestructura DevOps"
  echo -e ""
  echo -e " \e[1mDescripción:\e[0m"
  echo -e " El servicio 'container-webapp.service' no puede inicializar el servidor web"
  echo -e " interno debido a fallas de políticas AVC de SELinux sobre /opt/web_data."
  echo -e " Adicionalmente, el tráfico externo no logra alcanzar el puerto de la aplicación."
  echo -e ""
  echo -e " \e[1mRequerimientos de Validación (Peso Total: 100%):\e[0m"
  echo -e "  [ ] Modificar la unidad para usar la opción de montaje ':Z' en el volumen -> \e[1;35m30%\e[0m"
  echo -e "  [ ] Servicio 'container-webapp.service' en estado Running            --> \e[1;35m25%\e[0m"
  echo -e "  [ ] Puerto 8080/tcp permitido permanentemente en firewalld          --> \e[1;35m25%\e[0m"
  echo -e "  [ ] Ejecución de 'curl localhost:8080' devuelve código HTTP 200     --> \e[1;35m20%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32mMisión:\e[0m Inspeccione con journalctl, arregle el montaje del contenedor y abra la red.\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup_sh && rm -f /tmp/setup_sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0

  echo "=== EVALUANDO INFRAESTRUCTURA DE CONTENEDORES Y REDES ==="

  # 1. Validar si corrigió la unidad agregando la bandera :Z (mayúscula o minúscula) para el reetiquetado automático
  if [ -f /etc/systemd/system/container-webapp.service ] && grep -E "\/opt\/web_data:\/var\/www\/html:(ro,Z|Z,ro|Z)" /etc/systemd/system/container-webapp.service >/dev/null 2>&1; then
      echo "✔ [30%] Configuración de volumen corregida con la política dinámica :Z de SELinux."
      PUNTOS=$((PUNTOS + 30))
  elif ls -Z /opt/web_data | grep -q "container_file_t"; then
      echo "✔ [30%] Contexto SELinux corregido manualmente en el host a container_file_t."
      PUNTOS=$((PUNTOS + 30))
  else
      echo "❌ [0%] El contenedor sigue sin permisos de lectura/escritura en el volumen por culpa de SELinux."
  fi

  # 2. Validar si el servicio de Systemd está corriendo
  if systemctl is-active --quiet container-webapp.service; then
      echo "✔ [25%] Servicio de orquestación de systemd 'container-webapp.service' activo."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] El servicio del contenedor está caído o ciclando en errores."
  fi

  # 3. Validar si el puerto está abierto en Firewalld de forma permanente
  if firewall-cmd --permanent --list-ports | grep -q "8080/tcp"; then
      echo "✔ [25%] Regla de Firewall validada: Puerto 8080/tcp abierto permanentemente."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] El puerto 8080/tcp sigue bloqueado por las reglas del firewall local."
  fi

  # 4. Validar disponibilidad real de la aplicación
  if curl -s --connect-timeout 2 http://localhost:8080 >/dev/null; then
      echo "✔ [20%] ¡Éxito total! La aplicación web responde correctamente con HTTP 200."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] La aplicación no responde en el puerto 8080 (Fallo de conectividad final)."
  fi

  echo "============================"
  echo "CALIFICACIÓN FINAL: $PUNTOS / 100"
  echo "============================"
---

[[Laboratorios del LFCS]]

---
