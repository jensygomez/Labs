---
Curso: Transición Sysadmin a DevOps - Fundamentos de Docker
Modulo: Containerization & Persistent Data
Playground: DK-001-v1
Titulo: El Contenedor Reincidente Fallo de Persistencia y Entorno
Fecha de Inicio: 2026-06-11
Dificultad: 5/10
Level Escalation: L1/L2
Objetivo: |2-
    - Aprobar LFCS y RHCSA
    - Pensar como Sysadmin Linux Pleno
    - Prepararme para Devops Enginner y Kubernets
Temas: |-
  - Docker Compose (sintaxis, variables de entorno, restart policies)
  - Docker Volumes (Bind Mounts). 
  - Permisos y Propiedad en Linux (chmod, chown, UID/GID).
  - Diagnóstico de contenedores en estado "Restarting" o "Exited".
Competencias: |-
  - Diagnosticar por qué un contenedor entra en bucle de reinicio (CrashLoop).
  - Resolver conflictos de permisos en volúmenes montados sin recurrir a malas prácticas (ej. chmod 777).
  - Corregir archivos de configuración declarativa para estabilizar el servicio de forma persistente.
Script: |-
  cat << 'EOF' > /tmp/setup-docker-lab.sh
  #!/bin/bash
  set -e

  echo -e "\e[1;33m⏳ Preparando el escenario de fallo en Docker Playground...\e[0m"

  # 1. Crear directorio de trabajo del laboratorio
  LAB_DIR="$HOME/docker-lab-01"
  rm -rf "$LAB_DIR"
  mkdir -p "$LAB_DIR"
  cd "$LAB_DIR"

  # 2. Inyección de Fallo 1: Permisos restrictivos en el Host
  # El directorio pertenece a root y tiene permisos 700. 
  # El contenedor correrá como usuario '1000' y fallará al escribir.
  mkdir -p "$LAB_DIR/app-data"
  sudo chown root:root "$LAB_DIR/app-data"
  sudo chmod 700 "$LAB_DIR/app-data"

  # 3. Inyección de Fallo 2: docker-compose.yml con configuración defectuosa
  cat << 'COMPOSE' > docker-compose.yml
  version: '3.8'
  services:
    data-processor:
      image: alpine:latest
      # Fallo intencional: Se fuerza a correr como usuario no-root (UID 1000)
      user: "1000:1000"
      # Fallo intencional: Falta la variable de entorno APP_MODE requerida por el script
      # environment:
      #   - APP_MODE=production
      volumes:
        - ./app-data:/data
      # Fallo intencional: Política de reinicio ausente o inadecuada para producción
      restart: "no"
      command: >
        sh -c '
          echo "[INFO] Iniciando procesador de datos...";
          if [ -z "$$APP_MODE" ]; then
            echo "[ERROR] Variable de entorno APP_MODE no configurada. Abortando." >&2;
            exit 1;
          fi;
          echo "[INFO] Modo $$APP_MODE activado. Intentando escribir en /data...";
          touch /data/heartbeat.log 2>/dev/null || { echo "[ERROR] Permiso denegado en /data" >&2; exit 1; };
          while true; do
            echo "$$(date -Iseconds) - Heartbeat OK" >> /data/heartbeat.log;
            sleep 5;
          done
        '
  COMPOSE

  # 4. Inyección de Fallo 3: Levantar el stack para que el estudiante lo encuentre roto
  docker compose up -d

  # 5. Preparar bóveda de gobernancia local (simulando backup externo)
  sudo mkdir -p /opt/backup-vault
  sudo chown $(whoami):$(whoami) /opt/backup-vault

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  TICKET INC-4012  │  Severidad: ALTA  │  Ambiente: DOCKER PLAYGROUND\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m  ⚙️  DK-001-v1 — El Contenedor Reincidente (Docker Compose)\e[0m"
  echo -e "\e[1;36m  Módulo: Containerization  │  Dificultad: 4/10  │  Nivel: L1/L2\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mUbicación:\e[0m  Directorio local: \e[1;32m$HOME/docker-lab-01\e[0m"
  echo -e " \e[1mEstado actual:\e[0m El stack fue desplegado, pero el servicio no se mantiene en pie."
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mContexto del Incidente:\e[0m"
  echo -e "  El equipo de desarrollo desplegó el microservicio \e[1mdata-processor\e[0m usando"
  echo -e "  docker-compose. El contenedor entra en bucle de reinicio o sale con error."
  echo -e "  Debes diagnosticar la causa raíz (pistas: logs, permisos del volumen, entorno)."
  echo -e " "
  echo -e " \e[1mParámetros Técnicos Obligatorios:\e[0m"
  echo -e " "
  echo -e "  \e[1;31m1. Diagnóstico y Corrección de Permisos (Host)\e[0m"
  echo -e "     Asegura que el directorio \e[1mapp-data\e[0m permita la escritura al usuario"
  echo -e "     del contenedor (UID 1000). \e[1mNO uses chmod 777\e[0m. Usa chown o ACLs."
  echo -e " "
  echo -e "  \e[1;31m2. Corrección del docker-compose.yml\e[0m"
  echo -e "     - Agrega la variable de entorno: \e[1mAPP_MODE=production\e[0m"
  echo -e "     - Cambia la política de reinicio a: \e[1mrestart: always\e[0m (o unless-stopped)"
  echo -e " "
  echo -e "  \e[1;31m3. Estabilización del Servicio\e[0m"
  echo -e "     Aplica los cambios y reinicia el stack. Verifica que el estado sea 'Up'."
  echo -e " "
  echo -e "  \e[1;31m4. Resguardo de Configuración\e[0m"
  echo -e "     Copia el \e[1mdocker-compose.yml\e[0m corregido a \e[1m/opt/backup-vault/docker-compose.bak\e[0m"
  echo -e " "
  echo -e " \e[1mCriterios de Aceptación:\e[0m"
  echo -e "  [ ] Contenedor 'data-processor' en estado 'running' (Up)       --> \e[1;35m30%\e[0m"
  echo -e "  [ ] Variable APP_MODE=production presente en compose           --> \e[1;35m20%\e[0m"
  echo -e "  [ ] Política 'restart: always' (o unless-stopped) configurada  --> \e[1;35m20%\e[0m"
  echo -e "  [ ] Archivo heartbeat.log existe en app-data y es legible      --> \e[1;35m15%\e[0m"
  echo -e "  [ ] Copia de seguridad en /opt/backup-vault/docker-compose.bak --> \e[1;35m15%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32m🚨 REGLA DE ORO:\e[0m Usa 'docker compose logs data-processor' para ver el error real."
  echo -e "               Diagnóstico de permisos: 'ls -ln app-data' (busca UID 1000)"
  echo -e "\e[1;36m================================================================================\e[0m"
  EOF

  chmod +x /tmp/setup-docker-lab.sh
  bash /tmp/setup-docker-lab.sh
  rm -f /tmp/setup-docker-lab.sh
tags:
  - Laboratorios-del-LFCS
  - Docker
---
[[Laboratorios del LFCS]]

-------



In my recent hands-on experience, I successfully resolved a high-severity containerization incident regarding a broken data-processing microservice deployed via Docker Compose. The service was stuck in a crash loop due to a combination of misconfigured environment variables and permission denials on the host volume. To tackle this, I conducted a root cause analysis by auditing the container logs and checking the directory structure on the host, which allowed me to pinpoint exactly why the application was failing to initialize and write data.

To stabilize the stack, I focused on infrastructure resilience and security best practices. I refactored the `docker-compose.yml` file by injecting the required production environment variables, cleaning up obsolete attributes, and configuring a proper restart policy to guarantee high availability. Furthermore, I resolved the volume restriction by shifting the host directory's ownership to match the container's non-root user (UID 1000), strictly avoiding insecure workarounds like `chmod 777`. Finally, I secured the deployment by implementing a configuration backup procedure in a designated vault. As a result, the platform's automated auditor verified that the container achieved a one-hundred percent stability score with flawless data persistence.
