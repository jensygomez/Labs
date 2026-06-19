---
Curso: Transición Sysadmin a DevOps - Fundamentos de Docker
Modulo: Container Optimization & Security
Playground: DK-003-v1
Titulo: La Imagen Fantasma – Diagnóstico y Corrección de Dockerfile - V1.0
Fecha de Inicio: 2026-06-19
Dificultad: 6/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno
  - Prepararme para DevOps Engineer y Kubernetes
Temas: |-
  - Dockerfile Best Practices (orden de instrucciones, layer caching)
  - Multi-stage builds (reducción drástica de tamaño de imagen)
  - Archivos .dockerignore (exclusión de artefactos innecesarios)
  - Instrucción USER (ejecución como usuario no-root)
  - Exposición mínima de puertos y eliminación de herramientas de compilación
Competencias: |-
  - Diagnosticar imágenes sobredimensionadas causadas por orden incorrecto de instrucciones y falta de .dockerignore
  - Implementar builds multi-stage para separar fase de compilación y fase de runtime
  - Configurar un usuario no privilegiado (USER) y minimizar la superficie de ataque
  - Aplicar .dockerignore efectivo para reducir el contexto de build
Script: |-
  cat << 'EOF' > /tmp/setup-docker-lab-03.sh
  #!/bin/bash
  set -e

  echo -e "\e[1;33m⏳ Preparando el escenario de Dockerfile defectuoso...\e[0m"

  # 1. Crear directorio de trabajo del laboratorio
  LAB_DIR="$HOME/docker-lab-03"
  rm -rf "$LAB_DIR"
  mkdir -p "$LAB_DIR"
  cd "$LAB_DIR"

  # 2. Crear aplicación Python simple (FastAPI) que simula un microservicio
  mkdir -p app
  cat > app/main.py << 'PYEOF'
  from fastapi import FastAPI
  import os

  app = FastAPI(title="Ghost Service")

  @app.get("/")
  def read_root():
      return {"message": "Ghost Service v1.0", "env": os.getenv("APP_ENV", "dev")}

  @app.get("/health")
  def health():
      return {"status": "ok"}
  PYEOF

  cat > app/requirements.txt << 'REQEOF'
  fastapi==0.109.0
  uvicorn[standard]==0.27.0
  REQEOF

  # 3. Crear requirements-dev.txt que NO debe estar en la imagen final
  cat > requirements-dev.txt << 'DEVEOF'
  pytest==7.4.4
  black==24.1.0
  mypy==1.8.0
  DEVEOF

  # 4. Crear .git y archivos innecesarios que serán ignorados por .dockerignore
  mkdir -p .git
  echo "fake git data" > .git/config
  mkdir -p __pycache__
  echo "cache" > __pycache__/main.cpython-39.pyc
  touch large-binary.bin
  dd if=/dev/urandom of=large-binary.bin bs=1M count=50 2>/dev/null || true

  # 5. Crear Dockerfile DEFECTUOSO intencionalmente
  cat > Dockerfile << 'INNEREOF'
  # Dockerfile "fantasma" - anti-patrones intencionales
  FROM python:3.11-slim

  # Anti-patron 1: instalar dependencias de compilacion y no limpiar capas
  RUN apt-get update && apt-get install -y \
      build-essential \
      gcc \
      python3-dev \
      libffi-dev \
      && rm -rf /var/lib/apt/lists/*

  # Anti-patron 2: copiar TODO el contexto (incluye .git, pycache, binarios grandes)
  COPY . /app
  WORKDIR /app

  # Anti-patron 3: instalar dependencias en la misma capa que el codigo fuente
  RUN pip install --no-cache-dir -r requirements.txt

  # Anti-patron 4: exponer puertos innecesarios y multiples
  EXPOSE 8000 8001 9000 22

  # Anti-patron 5: ejecutar como root (por defecto)
  # USER no especificado

  # Anti-patron 6: CMD sin healthcheck
  CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
  INNEREOF

  # 6. Levantar build inicial para que la imagen "fantasma" ya exista
  echo -e "\e[1;33m🔨 Construyendo imagen fantasma (puede tardar)...\e[0m"
  docker build -t ghost-service:bloated . 2>&1 | tail -20

  # 7. Preparar bóveda de gobernancia local
  sudo mkdir -p /opt/backup-vault
  sudo chown $(whoami):$(whoami) /opt/backup-vault

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  TICKET INC-4014  │  Severidad: ALTA  │  Ambiente: PRODUCCIÓN\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m  ⚙️  DK-003-v1 — La Imagen Fantasma\e[0m"
  echo -e "\e[1;36m  Módulo: Container Optimization & Security  │  Dificultad: 6/10  │  Nivel: L2\e[0m"
  echo -e "\e[1;36m --------------------------------------------------------------------------------\e[0m"
  echo -e " \e[1mUbicación de Control:\e[0m $HOSTNAME  (Estación del Administrador — \e[1;32m$(whoami)\e[0m)"
  echo -e "\e[1;36m --------------------------------------------------------------------------------\e[0m"
  echo ""
  echo -e "  \e[1;37m📋 REPORTE DE INCIDENTE:\e[0m"
  echo -e "  Fecha del reporte: \e[1m$(date '+%Y-%m-%d')\e[0m"
  echo -e "  Reportado por: Departamento de Infraestructura Cloud"
  echo -e "  Prioridad: \e[1;31mALTA\e[0m"
  echo ""
  echo -e "  \e[1;37m📝 DESCRIPCIÓN DEL INCIDENTE:\e[0m"
  echo -e "  El día de ayer, el equipo de desarrollo desplegó en el entorno de pre-producción"
  echo -e "  un nuevo microservicio denominado \e[1m'Ghost Service'\e[0m, desarrollado en FastAPI."
  echo -e "  Durante la revisión de métricas de infraestructura, se detectaron las siguientes"
  echo -e "  anomalías críticas:"
  echo ""
  echo -e "    \e[1;31m•\e[0m La imagen Docker generada supera los \e[1m2GB\e[0m de tamaño"
  echo -e "    \e[1;31m•\e[0m El contenedor se ejecuta con privilegios de \e[1mroot\e[0m"
  echo -e "    \e[1;31m•\e[0m Se exponen múltiples puertos innecesarios (8000, 8001, 9000, 22)"
  echo -e "    \e[1;31m•\e[0m El tiempo de despliegue excede los 15 minutos"
  echo -e "    \e[1;31m•\e[0m El análisis de seguridad identificó herramientas de compilación"
  echo -e "      presentes en la imagen final (gcc, build-essential)"
  echo ""
  echo -e "  El equipo de seguridad ha clasificado este incidente como una \e[1;31mviolación\e[0m"
  echo -e "  de las políticas de containerización establecidas en el documento \e[1mSEC-DOCKER-001\e[0m."
  echo -e "  Se requiere la remediación inmediata antes del próximo despliegue programado."
  echo ""
  echo -e "  \e[1;37m📂 UBICACIÓN DE ARTEFACTOS:\e[0m"
  echo -e "      \e[1;33m$HOME/docker-lab-03\e[0m"
  echo -e "      • Dockerfile defectuoso: \e[1mDockerfile\e[0m"
  echo -e "      • Imagen actual: \e[1mghost-service:bloated\e[0m"
  echo ""
  echo -e "  \e[1;37m🎯 REQUERIMIENTOS DE REMEDIACIÓN:\e[0m"
  echo -e "  Se solicita al ingeniero de plataforma realizar las siguientes acciones:"
  echo ""
  echo -e "    \e[1;32m1.\e[0m Diagnosticar el Dockerfile actual e identificar anti-patrones"
  echo -e "    \e[1;32m2.\e[0m Implementar una estrategia de multi-stage build"
  echo -e "    \e[1;32m3.\e[0m Reducir el tamaño de la imagen final a menos de 200MB"
  echo -e "    \e[1;32m4.\e[0m Eliminar herramientas de compilación de la imagen de runtime"
  echo -e "    \e[1;32m5.\e[0m Configurar ejecución como usuario no-privilegiado"
  echo -e "    \e[1;32m6.\e[0m Minimizar la superficie de exposición de puertos"
  echo ""
  echo -e "\e[1;36m  ──────────────────────────────────────────────────────────────────────────\e[0m"
  echo -e "\e[1;33m  CRITERIOS DE ACEPTACIÓN (Nivel L2 - Dificultad 6/10)\e[0m"
  echo -e "\e[1;36m  ──────────────────────────────────────────────────────────────────────────\e[0m"
  echo ""
  echo -e "   \e[1;37m[ ]\e[0m Archivo \e[1m.dockerignore\e[0m efectivo implementado                    \e[0;35m→ 15%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Imagen optimizada \e[1m<200MB\e[0m                                       \e[0;35m→ 20%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Multi-stage build sin gcc/build-essential en runtime              \e[0;35m→ 20%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Contenedor ejecuta como \e[1musuario no-root\e[0m                       \e[0;35m→ 20%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Solo puerto \e[1m8000\e[0m expuesto                                    \e[0;35m→ 10%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Dockerfile optimizado en \e[1m/opt/backup-vault/\e[0m                    \e[0;35m→ 15%\e[0m"
  echo ""
  echo -e "\e[1;31m  ⚠️  NOTA DE SEGURIDAD:\e[0m La imagen actual viola 3 políticas críticas del"
  echo -e "     estándar SEC-DOCKER-001. La remediación es obligatoria."
  echo ""
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""

  echo -e "\e[1;32m✔ Entorno de laboratorio configurado exitosamente.\e[0m"
  echo -e "📂 Directorio de trabajo: \e[1;33m$HOME/docker-lab-03\e[0m"
  echo -e "🐳 Imagen defectuosa: \e[1;33mghost-service:bloated\e[0m (>2GB)"
  echo -e "📝 Dockerfile a corregir: \e[1;33m$HOME/docker-lab-03/Dockerfile\e[0m"
  echo -e "\e[1;36m¡Éxito en la remediación, Ingeniero!\e[0m"
  EOF

  chmod +x /tmp/setup-docker-lab-03.sh
  bash /tmp/setup-docker-lab-03.sh
  rm -f /tmp/setup-docker-lab-03.sh
tags:
  - Docker
  - Laboratorios-del-LFCS
---
[[Laboratorios del LFCS]]



**Can you tell me about a recent challenge you faced at your current job?**

Sure. Recently, I worked on a hands-on lab simulating a real production incident involving a Docker image that had gone seriously wrong. The image was over 2GB, it was running with root privileges, it exposed four unnecessary ports, and it still had build tools like gcc baked into the final image — which is a clear security violation according to standard containerization policies.

My task was to diagnose the Dockerfile, identify the anti-patterns, and fix them. I found that the original file was copying the entire build context — including the `.git` folder, cached Python bytecode, and even a 50MB binary file — and installing compiler tools in the same layer as the application code, with no separation between build-time and run-time dependencies.

To fix it, I first created an effective `.dockerignore` file to keep unnecessary files out of the build context. Then I redesigned the Dockerfile using a multi-stage build: one stage to compile the dependencies with the necessary build tools, and a second, clean stage that only copies the compiled virtual environment and the application code — without any compiler ever touching the final image. I also configured a non-privileged user instead of running as root, and reduced the exposed ports down to just the one the application actually needs.

In the end, I brought the image size down from over 2GB to under 200MB, removed all the security violations, and verified every fix step by step — checking that gcc wasn't present, confirming the container ran under a non-root UID, and validating that only the required port was exposed.

What I really took away from this is the importance of separating concerns in a Dockerfile — build dependencies should never leak into production — and that small things, like a missing file in `.dockerignore` or an unquoted heredoc, can silently break an otherwise solid fix. It reinforced for me how much attention to detail matters in infrastructure work, even in tasks that seem straightforward at first glance.