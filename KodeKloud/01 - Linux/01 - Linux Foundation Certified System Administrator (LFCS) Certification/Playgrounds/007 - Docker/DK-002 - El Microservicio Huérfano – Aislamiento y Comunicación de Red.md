---
Curso: Transición Sysadmin a DevOps - Fundamentos de Docker
Modulo: Containerization & Networking
Playground: DK-002-v1
Titulo: El Microservicio Huérfano Aislamiento y Comunicación de Red
Fecha de Inicio: 2026-06-11
Dificultad: 6/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno
  - Prepararme para DevOps Engineer y Kubernetes
Temas: |-
  - Redes de Docker (Bridge por defecto vs. Bridge personalizado).
  - Resolución de nombres DNS interna en Docker (Embedded DNS).
  - Aislamiento de redes y conectividad entre contenedores (`docker network connect`).
  - Diagnóstico de conectividad dentro de contenedores (`ping`, `curl`, `nslookup`, `ip a`).
Competencias: |-
  - Diagnosticar fallos de comunicación entre microservicios debido al aislamiento de la red `bridge` por defecto.
  - Crear y gestionar redes personalizadas en Docker para habilitar la resolución DNS automática por nombre de contenedor.
  - Conectar contenedores en ejecución a nuevas redes sin perder su estado, evitando el uso de IPs hardcodeadas.
Script: |-
  cat << 'EOF' > /tmp/setup-docker-lab-02.sh

  #!/bin/bash
  set -e

  echo -e "\e[1;33m⏳ Preparando el escenario de fallo de Red en Docker Playground...\e[0m"

  # 1. Crear directorio de trabajo del laboratorio
  LAB_DIR="$HOME/docker-lab-02"
  rm -rf "$LAB_DIR"
  mkdir -p "$LAB_DIR"
  cd "$LAB_DIR"

  # 2. Inyección de Fallo 1: docker-compose.yml con aislamiento de red defectuoso
  # Los contenedores se levantarán en la red 'bridge' por defecto.
  # En esta red, Docker NO resuelve nombres de contenedor a IP automáticamente.
  cat << 'COMPOSE' > docker-compose.yml
  version: '3.8'
  services:
    backend-db:
      image: redis:alpine
      container_name: backend-db
      # Fallo intencional: No se define una red personalizada. 
      # Cae en la red 'bridge' por defecto del daemon.
      
    frontend-app:
      image: alpine:latest
      container_name: frontend-app
      depends_on:
        - backend-db
      # Fallo intencional: El script intenta conectar usando el NOMBRE del servicio ('backend-db').
      # En la red 'bridge' por defecto, esto fallará con "bad address" o "could not resolve host".
      command: >
        sh -c '
          echo "[INFO] Iniciando frontend-app...";
          while true; do
            # Intentamos resolver el nombre y conectar al puerto 6379
            if getent hosts backend-db > /dev/null 2>&1; then
              echo "[OK] DNS Resuelto. Conectando a backend-db...";
              nc -z -w 2 backend-db 6379 && echo "[OK] Conexión a Redis exitosa" || echo "[ERROR] Puerto 6379 cerrado";
            else
              echo "[ERROR CRÍTICO] Fallo de Resolución DNS: El nombre \"backend-db\" no se encuentra.";
            fi;
            sleep 3;
          done
        '
  COMPOSE

  # 3. Levantar el stack para que el estudiante lo encuentre roto
  docker compose up -d

  # Esperar 3 segundos para que el contenedor de la app intente conectar y genere el primer log de error
  sleep 3

  # 4. Preparar bóveda de gobernancia local (simulando backup externo)
  sudo mkdir -p /opt/backup-vault
  sudo chown $(whoami):$(whoami) /opt/backup-vault

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  TICKET INC-4013  │  Severidad: ALTA  │  Ambiente: DOCKER PLAYGROUND\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m  ⚙️  DK-002-v1 — El Microservicio Huérfano (Networking & DNS)\e[0m"
  echo -e "\e[1;36m  Módulo: Containerization  │  Dificultad: 6/10  │  Nivel: L2\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mUbicación:\e[0m  Directorio local: \e[1;32m$HOME/docker-lab-02\e[0m"
  echo -e " \e[1mEstado actual:\e[0m El stack está 'Up', pero la aplicación reporta errores de conexión."
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mContexto del Incidente:\e[0m"
  echo -e "  El equipo de despliegue levantó un frontend y una base de datos (Redis)."
  echo -e "  El frontend intenta conectarse a la BD usando su \e[1mnombre de servicio\e[0m,"
  echo -e "  pero los logs muestran fallos de resolución de nombres o timeout."
  echo -e " "
  echo -e " \e[1mParámetros Técnicos Obligatorios:\e[0m"
  echo -e " "
  echo -e "  \e[1;31m1. Diagnóstico de Red\e[0m"
  echo -e "     Inspecciona la red de ambos contenedores (\e[1mdocker inspect\e[0m o \e[1mdocker network ls\e[0m)."
  echo -e "     Confirma que están en la red 'bridge' por defecto y que el DNS no resuelve."
  echo -e " "
  echo -e "  \e[1;31m2. Corrección Declarativa (DevOps Way)\e[0m"
  echo -e "     Modifica el \e[1mdocker-compose.yml\e[0m para:"
  echo -e "     - Crear una red personalizada de tipo \e[1mbridge\e[0m (ej: \e[1mapp-network\e[0m)."
  echo -e "     - Asignar ambos servicios a esta nueva red."
  echo -e "     \e[1mNO\e[0m uses la IP interna del contenedor (es dinámica y mala práctica)."
  echo -e " "
  echo -e "  \e[1;31m3. Estabilización y Verificación\e[0m"
  echo -e "     Aplica los cambios (\e[1mdocker compose up -d\e[0m). Verifica que el frontend"
  echo -e "     ahora resuelve el nombre 'backend-db' y conecta exitosamente."
  echo -e " "
  echo -e "  \e[1;31m4. Resguardo de Configuración\e[0m"
  echo -e "     Copia el \e[1mdocker-compose.yml\e[0m corregido a \e[1m/opt/backup-vault/docker-compose-net.bak\e[0m"
  echo -e " "
  echo -e " \e[1mCriterios de Aceptación:\e[0m"
  echo -e "  [ ] Existe una red personalizada (no 'bridge' default) en el compose --> \e[1;35m30%\e[0m"
  echo -e "  [ ] Ambos contenedores están conectados a dicha red personalizada      --> \e[1;35m30%\e[0m"
  echo -e "  [ ] El comando 'docker exec frontend-app getent hosts backend-db'      --> \e[1;35m20%\e[0m"
  echo -e "      devuelve una IP válida (ej: 172.x.x.x)"
  echo -e "  [ ] Copia de seguridad en /opt/backup-vault/docker-compose-net.bak     --> \e[1;35m20%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32m🚨 PISTA:\e[0m Usa 'docker compose logs frontend-app' para ver el fallo de DNS."
  echo -e "         Usa 'docker network inspect <nombre_red>' para ver quién está conectado."
  echo -e "\e[1;36m================================================================================\e[0m"
  EOF

  chmod +x /tmp/setup-docker-lab-02.sh
  bash /tmp/setup-docker-lab-02.sh
  rm -f /tmp/setup-docker-lab-02.sh
tags:
  - Laboratorios-del-LFCS
  - Docker
---
[[Laboratorios del LFCS]]

---
