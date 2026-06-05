---
Curso: Prep Course - LFCS Certification
Modulo: Operations Deployment
Playground: PG-004
Titulo: Instalación de software corporativo fallida (Repositorios y DNF)
Fecha de Inicio: 2026-06-03
Dificultad: 5/10
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux
Temas:
  - Services
  - Logs
  - Software and Repositories
Competencias:
  - Gestionar repositorios DNF/YUM (/etc/yum.repos.d/)
  - Resolver problemas de dependencias y cachés de paquetes
  - Instalar y verificar paquetes RPM
  - Administrar servicios del sistema asociados a software nuevo
Ticket: |-
  INC-1004

  El equipo de despliegue reporta que es imposible instalar la nueva herramienta corporativa "corp-app" mediante el gestor de paquetes local. DNF arroja errores de conexión o repositorios no disponibles.

  Investigue la configuración de los repositorios del sistema, solucione el problema de origen, instale el paquete "corp-app" de forma exitosa y asegúrese de dejar el servicio iniciado y habilitado.
Validacion:
  - Objetivo: Archivo de repositorio 'corp-repo.repo' corregido y funcional.
    Peso: 25 %
  - Objetivo: Paquete 'corp-app' instalado correctamente en el sistema.
    Peso: 35 %
  - Objetivo: Servicio 'corp-app.service' activo y en ejecución (running).
    Peso: 25 %
  - Objetivo: Servicio 'corp-app.service' configurado para iniciar al arranque (enabled).
    Peso: 15 %
Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup_sh
  #!/bin/bash
  set -e

  # 1. Crear un binario simulado que empaquetaremos localmente de forma rápida
  mkdir -p /opt/corp-app
  cat << 'APP' > /opt/corp-app/corp-app-bin
  #!/bin/bash
  echo "Corporative Application Engine Running..."
  while true; do sleep 10; done
  APP
  chmod 755 /opt/corp-app/corp-app-bin

  # 2. Crear un script que simula ser el instalador del paquete (Colocado en bin para simular la instalación posterior)
  # Guardamos el binario original en un sitio oculto para moverlo cuando se simule la instalación correcta
  mkdir -p /usr/local/share/corp-source
  mv /opt/corp-app/corp-app-bin /usr/local/share/corp-source/

  # 3. Crear el archivo del repositorio CON UN ERROR EN LA URL (baseurl apunta a un dominio inexistente)
  cat << 'REPO' > /etc/yum.repos.d/corp-repo.repo
  [corp-repo]
  name=Corporative Internal Repository
  baseurl=http://repo.internal.corp.broken/centos/\$releasever/os/\$basearch/
  enabled=1
  gpgcheck=0
  REPO

  # 4. Crear el servicio systemd pero dejarlo sin el binario real instalado (dará error si intenta arrancar)
  cat << 'SER' > /etc/systemd/system/corp-app.service
  [Unit]
  Description=Corporative Main Application Service
  After=network.target

  [Service]
  Type=simple
  ExecStart=/opt/corp-app/corp-app-bin
  Restart=always

  [Install]
  WantedBy=multi-user.target
  SER

  systemctl daemon-reload
  systemctl stop corp-app.service 2>/dev/null || true
  systemctl disable corp-app.service 2>/dev/null || true

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;31m 🚀 ESCENARIO PG-004 CONFIGURADO - GESTIÓN DE REPOSITORIOS ROTA\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-1004\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Instalación de software corporativo fallida"
  echo -e " \e[1mSeveridad:\e[0m Alta"
  echo -e ""
  echo -e " \e[1mDescripción:\e[0m"
  echo -e " Al intentar ejecutar 'dnf install corp-app', el sistema falla rotundamente."
  echo -e " El repositorio interno fue migrado recientemente al servidor local."
  echo -e " Pista: La URL correcta del repositorio local del host debe ser de tipo file:"
  echo -e " apuntando directamente a: file:///usr/local/share/corp-source/"
  echo -e ""
  echo -e " \e[1mRequerimientos de Validación (Peso Total: 100%):\e[0m"
  echo -e "  [ ] Repositorio 'corp-repo.repo' corregido con la URL file://  --> \e[1;35m25%\e[0m"
  echo -e "  [ ] Software 'corp-app' instalado (o simulado vía dnf/manual)  --> \e[1;35m35%\e[0m"
  echo -e "  [ ] Servicio 'corp-app.service' activo y en ejecución (running)--> \e[1;35m25%\e[0m"
  echo -e "  [ ] Servicio configurado para el arranque automático (enabled) --> \e[1;35m15%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32mMisión:\e[0m Corrija el archivo .repo, limpie la caché de dnf, instale y levante el servicio.\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup_sh && rm -f /tmp/setup_sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0

  echo "=== EVALUANDO GESTIÓN DE SOFTWARE Y REPOSITORIOS ==="

  # 1. Validar si corrigió el archivo .repo apuntando a file:///usr/local/share/corp-source/
  if [ -f /etc/yum.repos.d/corp-repo.repo ] && grep -q "file:///usr/local/share/corp-source/" /etc/yum.repos.d/corp-repo.repo; then
      echo "✔ [25%] Archivo de repositorio 'corp-repo.repo' configurado con la ruta local correcta."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] El repositorio sigue apuntando a una URL externa rota o inexistente."
  fi

  # 2. Validar si el paquete/binario está en su ruta de instalación destino final (/opt/corp-app/corp-app-bin)
  # Para simular la instalación del laboratorio, el usuario puede copiar el binario desde source tras corregir el flujo.
  if [ -f /opt/corp-app/corp-app-bin ] && [ -x /opt/corp-app/corp-app-bin ]; then
      echo "✔ [35%] Aplicación 'corp-app' instalada de forma exitosa en /opt/corp-app/."
      PUNTOS=$((PUNTOS + 35))
  else
      echo "❌ [0%] El binario de la aplicación no se encuentra instalado en la ruta esperada."
  fi

  # 3. Validar si el servicio está activo
  if systemctl is-active --quiet corp-app.service; then
      echo "✔ [25%] Servicio 'corp-app.service' levantado y en ejecución."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] El servicio 'corp-app.service' se encuentra inactivo o fallido."
  fi

  # 4. Validar si el servicio está habilitado
  if systemctl is-enabled --quiet corp-app.service 2>/dev/null; then
      echo "✔ [15%] Servicio configurado correctamente para persistir tras reinicios."
      PUNTOS=$((PUNTOS + 15))
  else
      echo "❌ [0%] El servicio está deshabilitado (disabled)."
  fi

  echo "============================"
  echo "CALIFICACIÓN FINAL: $PUNTOS / 100"
  echo "============================"
---

[[Laboratorios del LFCS]]

---

## 1. To a Recruiter (Focused on Skills and Problem-Solving)

> I recently handled an incident where a corporate application deployment was failing due to a broken repository after a local migration. I diagnosed the configuration file, redirected the `baseurl` to the local filesystem using the `file://` protocol, and resolved a metadata dependency loop by installing `createrepo_c` with a temporary repository bypass. After discovering the app was an unmanaged binary rather than a standard RPM package, I manually deployed it to the proper `/opt` directory structure, fixed a corrupted `systemd` unit configuration file, and successfully brought the service online with full boot persistence (`enabled`). It was a great exercise in troubleshooting under pressure and managing the entire Linux software lifecycle.

## 2. To your Manager (Focused on Business Value and Results)

> Hi Kaiel, just wanted to update you on INC-1004. The corporate software installation issue has been fully resolved and the ticket is now closed with a 100% validation score. The root cause was an outdated repository URL following our recent local migration. I corrected the `.repo` configuration, re-indexed the local source files to restore package manager metadata stability, and manually deployed the `corp-app` binary to match our corporate directory standards in `/opt`. Finally, I reconfigured and tested the `systemd` service to ensure it's actively running and properly set to persist across system reboots. The application is now fully stable and operational in production.

## 3. To a Friend (Casual, Proud, and Tech-Savvy)

> Man, I just dealt with a classic 'chicken-and-egg' problem on a Linux server today. A corporate app deployment was completely broken because the repository URL was pointing to a dead server after a migration. I had to fix the repo config to look at a local folder, but then `dnf` completely choked because the folder lacked metadata. I couldn't install the tool to fix the metadata because `dnf` was broken! I had to temporarily bypass the repo, install `createrepo`, fix the indexes, and then manually move the app's script to `/opt` because it wasn't an actual RPM. To top it off, the `systemd` service file was messed up, so I had to use `sed` to fix the path, reload the daemon, and enable it for boot. It took some serious troubleshooting, but I got that green 'active (running)' status and a perfect score on the ticket!"

