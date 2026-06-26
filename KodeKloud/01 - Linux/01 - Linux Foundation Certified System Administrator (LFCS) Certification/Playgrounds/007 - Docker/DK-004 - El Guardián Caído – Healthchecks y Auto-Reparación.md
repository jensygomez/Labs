---
id: DK-004
title: El Guardián Caído – Healthchecks y Auto-Reparación
difficulty: 6/10
level: L2
course: Transición Sysadmin a DevOps - Fundamentos de Docker
module: Container Optimization & Security
playground: DK-004-v1
start_date: 2026-06-25
objective: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno
  - Prepararme para DevOps Engineer y Kubernetes
  - Implementar healthchecks efectivos para detectar aplicaciones en estado degradado
  - Configurar políticas de reinicio automáticas para recuperación ante fallos
topics: |-
  - Docker HEALTHCHECK (instrucción en Dockerfile y docker-compose)
  - Restart Policies (no, on-failure, always, unless-stopped)
  - Container State monitoring (healthy, unhealthy, starting)
  - HTTP health endpoints y comandos de verificación
  - Intervalos de verificación (interval, timeout, retries, start_period)
  - Diagnóstico de contenedores en estado "Up" pero con aplicación fallida
competencies: |-
  - Diagnosticar contenedores que aparecen "Up" pero tienen aplicaciones en deadlock o estado degradado
  - Implementar instrucciones HEALTHCHECK válidas en Dockerfile o docker-compose.yml
  - Configurar políticas de reinicio apropiadas según el caso de uso
  - Ajustar parámetros de healthcheck (interval, timeout, retries, start_period)
  - Verificar el estado de salud de contenedores con docker inspect y docker ps
  - Automatizar la recuperación de servicios sin intervención manual
scenario: |-
  Un contenedor de un servidor web aparece como "Up" en `docker ps`, pero la aplicación 
  interna ha entrado en un estado de bloqueo (deadlock) y responde con errores HTTP 500 
  o timeouts. Docker no se entera y no lo reinicia.

  Debes implementar una instrucción `HEALTHCHECK` válida en el Dockerfile o compose 
  (ej. `curl -f http://localhost/health || exit 1`) y configurar una política de reinicio 
  (`restart: unless-stopped` o `on-failure`) para que el demonio de Docker recicle el 
  contenedor automáticamente cuando falle la salud.
script: |-
  cat << 'EOF' > /tmp/setup-docker-lab-04.sh

  #!/bin/bash
  set -e

  echo -e "\e[1;33m⏳ Preparando el escenario del Guardián Caído...\e[0m"

  # 1. Crear directorio de trabajo del laboratorio
  LAB_DIR="$HOME/docker-lab-04"
  rm -rf "$LAB_DIR"
  mkdir -p "$LAB_DIR"
  cd "$LAB_DIR"

  # 2. Crear aplicación Python (Flask) que simula un servicio con deadlock potencial
  mkdir -p app
  cat > app/main.py << 'PYEOF'
  from flask import Flask, jsonify
  import time
  import threading
  import os

  app = Flask(__name__)

  # Variable global que simula el estado interno del servicio
  service_state = {
      "healthy": True,
      "start_time": time.time(),
      "deadlock_triggered": False
  }

  @app.route("/")
  def index():
      return jsonify({
          "service": "Guardian Service",
          "version": "1.0.0",
          "status": "running",
          "uptime": int(time.time() - service_state["start_time"])
      })

  @app.route("/health")
  def health():
      # Simular deadlock después de 30 segundos de ejecución
      current_time = time.time() - service_state["start_time"]
      
      if current_time > 30 and not service_state["deadlock_triggered"]:
          service_state["deadlock_triggered"] = True
          service_state["healthy"] = False
          print(f"[ALERT] Deadlock detectado en el servicio después de {int(current_time)}s")
      
      if service_state["healthy"]:
          return jsonify({"status": "healthy", "checks": {"database": "ok", "cache": "ok"}}), 200
      else:
          return jsonify({
              "status": "unhealthy", 
              "error": "Internal deadlock detected",
              "checks": {"database": "timeout", "cache": "unreachable"}
          }), 500

  @app.route("/force-fail", methods=["POST"])
  def force_fail():
      """Endpoint para forzar fallo manual (útil para testing)"""
      service_state["healthy"] = False
      return jsonify({"message": "Service marked as unhealthy"}), 200

  @app.route("/recover", methods=["POST"])
  def recover():
      """Endpoint para recuperar el servicio manualmente"""
      service_state["healthy"] = True
      service_state["deadlock_triggered"] = False
      return jsonify({"message": "Service recovered"}), 200

  if __name__ == "__main__":
      app.run(host="0.0.0.0", port=5000, debug=False)
  PYEOF

  cat > app/requirements.txt << 'REQEOF'
  flask==3.0.0
  gunicorn==21.2.0
  REQEOF

  # 3. Crear Dockerfile SIN HEALTHCHECK (defectuoso para el laboratorio)
  cat > Dockerfile << 'INNEREOF'
  FROM python:3.11-slim

  WORKDIR /app

  # Instalar dependencias
  COPY app/requirements.txt .
  RUN pip install --no-cache-dir -r requirements.txt

  # Copiar aplicación
  COPY app/ .

  # Exponer puerto
  EXPOSE 5000

  # NOTA: No hay HEALTHCHECK definido - este es el problema principal
  # NOTA: El contenedor aparecerá "Up" aunque la app esté en deadlock

  # Ejecutar con gunicorn para producción
  CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "main:app"]
  INNEREOF

  # 4. Crear docker-compose.yml SIN restart policy adecuada (defectuoso)
  cat > docker-compose.yml << 'COMPOSEEOF'
  version: '3.8'

  services:
    guardian-service:
      build: .
      container_name: guardian-service
      ports:
        - "5000:5000"
      # PROBLEMA: No hay restart policy definida
      # PROBLEMA: No hay healthcheck definido
      # PROBLEMA: Si la app falla internamente, Docker no lo sabe
      environment:
        - FLASK_ENV=production
      networks:
        - guardian-net

  networks:
    guardian-net:
      driver: bridge
  COMPOSEEOF

  # 5. Construir y levantar el contenedor
  echo -e "\e[1;33m🔨 Construyendo imagen del servicio...\e[0m"
  docker-compose build 2>&1 | tail -15

  echo -e "\e[1;33m🚀 Levantando contenedor...\e[0m"
  docker-compose up -d

  # Esperar a que el servicio esté listo
  echo -e "\e[1;33m⏳ Esperando inicialización del servicio...\e[0m"
  sleep 5

  # Verificar que el contenedor está "Up"
  echo -e "\e[1;33m🔍 Verificando estado del contenedor...\e[0m"
  docker ps --filter "name=guardian-service" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

  # Hacer una petición inicial para confirmar que funciona
  echo -e "\e[1;33m🌐 Probando endpoint inicial...\e[0m"
  curl -s http://localhost:5000/ | jq . || echo "Servicio respondiendo"

  # 6. Preparar bóveda de gobernancia local
  sudo mkdir -p /opt/backup-vault
  sudo chown $(whoami):$(whoami) /opt/backup-vault

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  TICKET INC-4024  │  Severidad: CRÍTICA  │  Ambiente: PRODUCCIÓN\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m  ⚙️  DK-004-v1 — El Guardián Caído\e[0m"
  echo -e "\e[1;36m  Módulo: Container Optimization & Security  │  Dificultad: 6/10  │  Nivel: L2\e[0m"
  echo -e "\e[1;36m --------------------------------------------------------------------------------\e[0m"
  echo -e " \e[1mUbicación de Control:\e[0m $HOSTNAME  (Estación del Administrador — \e[1;32m$(whoami)\e[0m)"
  echo -e "\e[1;36m --------------------------------------------------------------------------------\e[0m"
  echo ""
  echo -e "  \e[1;37m📋 REPORTE DE INCIDENTE:\e[0m"
  echo -e "  Fecha del reporte: \e[1m$(date '+%Y-%m-%d')\e[0m"
  echo -e "  Reportado por: Departamento de SRE (Site Reliability Engineering)"
  echo -e "  Prioridad: \e[1;31mCRÍTICA\e[0m"
  echo ""
  echo -e "  \e[1;37m📝 DESCRIPCIÓN DEL INCIDENTE:\e[0m"
  echo -e "  El servicio \e[1m'Guardian Service'\e[0m, desplegado en contenedor Docker, está"
  echo -e "  experimentando fallos intermitentes no detectados por el orquestador."
  echo -e "  Durante las últimas 24 horas, se han registrado las siguientes anomalías:"
  echo ""
  echo -e "    \e[1;31m•\e[0m El contenedor aparece como \e[1m'Up'\e[0m en \e[1mdocker ps\e[0m"
  echo -e "    \e[1;31m•\e[0m La aplicación interna entra en estado de \e[1mdeadlock\e[0m"
  echo -e "    \e[1;31m•\e[0m Los endpoints responden con \e[1mHTTP 500\e[0m o \e[1mtimeouts\e[0m"
  echo -e "    \e[1;31m•\e[0m Docker \e[1mNO reinicia\e[0m el contenedor automáticamente"
  echo -e "    \e[1;31m•\e[0m Los usuarios finales experimentan interrupciones del servicio"
  echo -e "    \e[1;31m•\e[0m No hay alertas automáticas cuando el servicio degrada"
  echo ""
  echo -e "  El equipo de SRE ha identificado que el contenedor carece de mecanismos de"
  echo -e "  \e[1mauto-reparación\e[0m y \e[1mmonitoreo de salud\e[0m, violando los estándares"
  echo -e "  de confiabilidad definidos en el documento \e[1mSRE-DOCKER-STD-002\e[0m."
  echo ""
  echo -e "  \e[1;37m📂 UBICACIÓN DE ARTEFACTOS:\e[0m"
  echo -e "      \e[1;33m$HOME/docker-lab-04\e[0m"
  echo -e "      • Dockerfile: \e[1mDockerfile\e[0m"
  echo -e "      • Docker Compose: \e[1mdocker-compose.yml\e[0m"
  echo -e "      • Aplicación: \e[1mapp/\e[0m"
  echo ""
  echo -e "  \e[1;37m🎯 REQUERIMIENTOS DE REMEDIACIÓN:\e[0m"
  echo -e "  Se solicita al ingeniero de plataforma implementar las siguientes mejoras:"
  echo ""
  echo -e "    \e[1;32m1.\e[0m Implementar \e[1mHEALTHCHECK\e[0m en Dockerfile o docker-compose.yml"
  echo -e "    \e[1;32m2.\e[0m Configurar política de reinicio \e[1mrestart: unless-stopped\e[0m o \e[1mon-failure\e[0m"
  echo -e "    \e[1;32m3.\e[0m Ajustar parámetros de healthcheck (\e[1minterval, timeout, retries, start_period\e[0m)"
  echo -e "    \e[1;32m4.\e[0m Verificar que el contenedor se reinicie automáticamente al fallar"
  echo -e "    \e[1;32m5.\e[0m Documentar el estado de salud con \e[1mdocker inspect\e[0m"
  echo -e "    \e[1;32m6.\e[0m Probar el endpoint \e[1m/force-fail\e[0m para simular fallos"
  echo ""
  echo -e "\e[1;36m  ──────────────────────────────────────────────────────────────────────────\e[0m"
  echo -e "\e[1;33m  CRITERIOS DE ACEPTACIÓN (Nivel L2 - Dificultad 6/10)\e[0m"
  echo -e "\e[1;36m  ──────────────────────────────────────────────────────────────────────────\e[0m"
  echo ""
  echo -e "   \e[1;37m[ ]\e[0m HEALTHCHECK implementado en Dockerfile o compose              \e[0;35m→ 25%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Restart policy configurada correctamente                      \e[0;35m→ 20%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Parámetros de healthcheck ajustados (interval, retries)       \e[0;35m→ 15%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Contenedor se reinicia automáticamente al fallar              \e[0;35m→ 20%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Estado de salud visible con \e[1mdocker ps\e[0m y \e[1mdocker inspect\e[0m    \e[0;35m→ 10%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Archivos optimizados en \e[1m/opt/backup-vault/\e[0m                  \e[0;35m→ 10%\e[0m"
  echo ""
  echo -e "\e[1;31m  ⚠️  NOTA OPERACIONAL:\e[0m El servicio actual viola 2 estándares críticos"
  echo -e "     del documento SRE-DOCKER-STD-002. La remediación es obligatoria."
  echo ""
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""

  echo -e "\e[1;32m✔ Entorno de laboratorio configurado exitosamente.\e[0m"
  echo -e "📂 Directorio de trabajo: \e[1;33m$HOME/docker-lab-04\e[0m"
  echo -e "🐳 Contenedor: \e[1;33mguardian-service\e[0m (puerto 5000)"
  echo -e "📝 Dockerfile a corregir: \e[1;33m$HOME/docker-lab-04/Dockerfile\e[0m"
  echo -e "📝 Compose a corregir: \e[1;33m$HOME/docker-lab-04/docker-compose.yml\e[0m"
  echo ""
  echo -e "\e[1;33m💡 TIP:\e[0m Espera 30 segundos y prueba: \e[1mcurl http://localhost:5000/health\e[0m"
  echo -e "   Verás cómo el servicio entra en estado de fallo automáticamente."
  echo ""
  echo -e "\e[1;36m¡Éxito en la remediación, Ingeniero!\e[0m"
  EOF

  chmod +x /tmp/setup-docker-lab-04.sh
  bash /tmp/setup-docker-lab-04.sh
  rm -f /tmp/setup-docker-lab-04.sh
tags:
  - Docker
  - Laboratorios-del-LFCS
  - Healthcheck
  - Auto-Reparación
---
[[Laboratorios del LFCS]]

---
