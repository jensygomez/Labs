---
id: DK-005
title: Puertas Abiertas – Reverse Proxy y Exposición Segura de Puertos
difficulty: 6/10
level: L2
course: Transición Sysadmin a DevOps - Fundamentos de Docker
module: Container Optimization & Security
playground: DK-005
start_date: 2026-07-02
objective: |-
  - Aprobar LFCS y RHCSA
  - Pensar como Sysadmin Linux Pleno
  - Prepararme para DevOps Engineer y Kubernetes
  - Eliminar exposición directa de aplicaciones a internet
  - Implementar redes internas de Docker para aislamiento de servicios
  - Desplegar un Reverse Proxy (Nginx) como punto único de entrada seguro
topics: |-
  - Docker networks (bridge, internal networks, network isolation)
  - Port mapping security (-p vs expose vs sin mapeo)
  - Reverse Proxy con Nginx (proxy_pass, upstream, server blocks)
  - Docker Compose multi-container orchestration
  - Aislamiento de servicios y principio de mínimo privilegio
  - Resolución DNS interna entre contenedores de Docker
  - Gestión de tráfico HTTP/HTTPS
  - Seguridad perimetral en entornos containerizados
competencies: |-
  - Identificar aplicaciones expuestas directamente al host y evaluar sus riesgos
  - Crear redes internas de Docker (internal: true) para aislar contenedores
  - Configurar Nginx como Reverse Proxy dentro de un contenedor
  - Reestructurar docker-compose.yml para separar proxy y aplicación backend
  - Aplicar el principio de "solo el proxy expone puertos al host"
  - Verificar conectividad interna entre contenedores en la misma red Docker
  - Validar que la aplicación ya no es accesible directamente desde el host
scenario: |-
  Una aplicación web crítica está corriendo en Docker con su puerto mapeado 
  directamente al host (`-p 8080:80`). Esto expone la aplicación directamente a 
  internet sin ninguna capa de seguridad intermedia: sin TLS, sin rate limiting, 
  sin WAF, y sin capacidad de enrutar múltiples servicios desde un mismo punto.

  Debes reestructurar el entorno para:
  1. Eliminar el mapeo directo de puertos de la aplicación.
  2. Colocar la aplicación en una red interna de Docker (no accesible desde fuera).
  3. Desplegar un contenedor Nginx como Reverse Proxy conectado a esa misma red.
  4. Configurar Nginx para que reciba tráfico en el puerto 80 y lo redirija 
     internamente a la aplicación.
  5. Solo el contenedor Nginx debe tener puertos expuestos al host (80/443).
script: |-
  cat << 'EOF' > /tmp/setup-docker-lab-05.sh


  #!/bin/bash

  echo -e "\e[1;33m⏳ Preparando el escenario de Puertas Abiertas...\e[0m"

  # 0. Verificar si el puerto 8080 está ocupado
  echo -e "\e[1;33m🔍 Verificando disponibilidad del puerto 8080...\e[0m"
  if sudo lsof -i :8080 > /dev/null 2>&1; then
      echo -e "\e[1;31m⚠️  El puerto 8080 está ocupado. Intentando liberar...\e[0m"
      
      # Intentar detener contenedores que usen ese puerto
      CONTAINER_ID=$(docker ps -q --filter "publish=8080" 2>/dev/null)
      if [ ! -z "$CONTAINER_ID" ]; then
          echo -e "\e[1;33m   Deteniendo contenedor: $CONTAINER_ID\e[0m"
          docker stop $CONTAINER_ID > /dev/null 2>&1
          docker rm $CONTAINER_ID > /dev/null 2>&1
      fi
      
      # Esperar un momento
      sleep 2
      
      # Verificar de nuevo
      if sudo lsof -i :8080 > /dev/null 2>&1; then
          echo -e "\e[1;31m❌ ERROR: No se pudo liberar el puerto 8080\e[0m"
          echo -e "\e[1;31m   Ejecuta manualmente: sudo lsof -i :8080\e[0m"
          exit 1
      else
          echo -e "\e[1;32m✔ Puerto 8080 liberado exitosamente\e[0m"
      fi
  else
      echo -e "\e[1;32m✔ Puerto 8080 disponible\e[0m"
  fi

  # 1. Crear directorio de trabajo del laboratorio
  LAB_DIR="$HOME/docker-lab-05"
  rm -rf "$LAB_DIR"
  mkdir -p "$LAB_DIR"
  cd "$LAB_DIR"

  # 2. Crear aplicación web simple (página estática HTML)
  mkdir -p app
  cat > app/index.html << 'HTMLEOF'
  <!DOCTYPE html>
  <html lang="es">
  <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Aplicación Crítica - DK-005</title>
      <style>
          body {
              font-family: Arial, sans-serif;
              background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
              color: white;
              display: flex;
              justify-content: center;
              align-items: center;
              height: 100vh;
              margin: 0;
          }
          .container {
              text-align: center;
              background: rgba(0,0,0,0.3);
              padding: 40px;
              border-radius: 15px;
              box-shadow: 0 8px 32px rgba(0,0,0,0.3);
          }
          h1 { font-size: 3em; margin-bottom: 10px; }
          .status { 
              font-size: 1.5em; 
              color: #4ade80; 
              margin: 20px 0;
          }
          .info { 
              background: rgba(255,255,255,0.1); 
              padding: 15px; 
              border-radius: 8px;
              margin-top: 20px;
          }
      </style>
  </head>
  <body>
      <div class="container">
          <h1>🔒 Aplicación Crítica</h1>
          <div class="status">✅ Servicio Operativo</div>
          <div class="info">
              <p><strong>Contenedor:</strong> critical-app</p>
              <p><strong>Puerto interno:</strong> 80</p>
              <p><strong>Fecha:</strong> <script>document.write(new Date().toLocaleString())</script></p>
          </div>
      </div>
  </body>
  </html>
  HTMLEOF

  # 3. Crear configuración de nginx para la aplicación
  cat > app/nginx.conf << 'NGINXEOF'
  server {
      listen 80;
      server_name localhost;
      
      root /usr/share/nginx/html;
      index index.html;
      
      location / {
          try_files $uri $uri/ =404;
      }
      
      location /health {
          access_log off;
          return 200 "healthy\n";
          add_header Content-Type text/plain;
      }
  }
  NGINXEOF

  # 4. Crear Dockerfile para la aplicación
  cat > Dockerfile << 'INNEREOF'
  FROM nginx:alpine

  RUN rm /etc/nginx/conf.d/default.conf
  COPY app/nginx.conf /etc/nginx/conf.d/default.conf
  COPY app/index.html /usr/share/nginx/html/index.html

  EXPOSE 80

  CMD ["nginx", "-g", "daemon off;"]
  INNEREOF

  # 5. Crear docker-compose.yml CON EL PROBLEMA
  cat > docker-compose.yml << 'COMPOSEEOF'
  services:
    critical-app:
      build: .
      container_name: critical-app
      ports:
        - "8080:80"
      restart: unless-stopped
  COMPOSEEOF

  # 6. Construir y levantar el contenedor
  echo -e "\e[1;33m🔨 Construyendo imagen de la aplicación...\e[0m"
  docker-compose build 2>&1 | tail -10

  echo -e "\e[1;33m🚀 Levantando contenedor...\e[0m"
  docker-compose up -d

  # Esperar a que el servicio esté listo
  echo -e "\e[1;33m⏳ Esperando inicialización del servicio...\e[0m"
  sleep 3

  # Verificar que el contenedor está "Up"
  echo -e "\e[1;33m🔍 Verificando estado del contenedor...\e[0m"
  docker ps --filter "name=critical-app" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

  # Hacer una petición inicial
  echo -e "\e[1;33m🌐 Probando acceso directo (esto es el problema)...\e[0m"
  curl -s http://localhost:8080/ | grep -o "Aplicación Crítica" || echo "Servicio respondiendo"

  # 7. Preparar bóveda de gobernancia local
  sudo mkdir -p /opt/backup-vault
  sudo chown $(whoami):$(whoami) /opt/backup-vault

  # MOSTRAR EL TICKET (siempre se muestra, incluso si hubo errores arriba)
  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  TICKET INC-4025  │  Severidad: ALTA  │  Ambiente: PRODUCCIÓN\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m  ⚙️  DK-005-v1 — Puertas Abiertas\e[0m"
  echo -e "\e[1;36m  Módulo: Container Optimization & Security  │  Dificultad: 6/10  │  Nivel: L2\e[0m"
  echo -e "\e[1;36m --------------------------------------------------------------------------------\e[0m"
  echo -e " \e[1mUbicación de Control:\e[0m $HOSTNAME  (Estación del Administrador — \e[1;32m$(whoami)\e[0m)"
  echo -e "\e[1;36m --------------------------------------------------------------------------------\e[0m"
  echo ""
  echo -e "  \e[1;37m📋 REPORTE DE INCIDENTE:\e[0m"
  echo -e "  Fecha del reporte: \e[1m$(date '+%Y-%m-%d')\e[0m"
  echo -e "  Reportado por: Departamento de Seguridad (Security Operations)"
  echo -e "  Prioridad: \e[1;31mALTA\e[0m"
  echo ""
  echo -e "  \e[1;37m📝 DESCRIPCIÓN DEL INCIDENTE:\e[0m"
  echo -e "  La \e[1m'Aplicación Crítica'\e[0m está desplegada en Docker con una configuración"
  echo -e "  de red insegura que viola los estándares de seguridad de la organización."
  echo -e "  Durante la última auditoría de seguridad, se detectaron las siguientes vulnerabilidades:"
  echo ""
  echo -e "    \e[1;31m•\e[0m El contenedor tiene el puerto \e[1m8080\e[0m expuesto directamente al host"
  echo -e "    \e[1;31m•\e[0m La aplicación es accesible desde internet sin ninguna capa de seguridad"
  echo -e "    \e[1;31m•\e[0m No hay \e[1mReverse Proxy\e[0m que gestione el tráfico"
  echo -e "    \e[1;31m•\e[0m No existe \e[1maislamiento de red\e[0m entre servicios"
  echo -e "    \e[1;31m•\e[0m No hay capacidad de implementar TLS/SSL en el futuro"
  echo -e "    \e[1;31m•\e[0m No se pueden aplicar políticas de rate limiting o WAF"
  echo -e "    \e[1;31m•\e[0m Violación del estándar \e[1mSEC-DOCKER-STD-003\e[0m (Exposición de Puertos)"
  echo ""
  echo -e "  El equipo de seguridad ha determinado que esta configuración representa un"
  echo -e "  \e[1mriesgo crítico\e[0m para la organización y requiere remediación inmediata."
  echo ""
  echo -e "  \e[1;37m📂 UBICACIÓN DE ARTEFACTOS:\e[0m"
  echo -e "      \e[1;33m$HOME/docker-lab-05\e[0m"
  echo -e "      • Dockerfile: \e[1mDockerfile\e[0m"
  echo -e "      • Docker Compose: \e[1mdocker-compose.yml\e[0m"
  echo -e "      • Aplicación: \e[1mapp/\e[0m (HTML + nginx.conf)"
  echo ""
  echo -e "  \e[1;37m🎯 REQUERIMIENTOS DE REMEDIACIÓN:\e[0m"
  echo -e "  Se solicita al ingeniero de plataforma implementar las siguientes mejoras:"
  echo ""
  echo -e "    \e[1;32m1.\e[0m \e[1mEliminar el mapeo directo de puertos\e[0m de la aplicación"
  echo -e "       (remover \e[1mports: - \"8080:80\"\e[0m del docker-compose.yml)"
  echo ""
  echo -e "    \e[1;32m2.\e[0m Crear una \e[1mred interna de Docker\e[0m para aislar los servicios"
  echo -e "       (usar \e[1minternal: true\e[0m o red bridge sin exposición)"
  echo ""
  echo -e "    \e[1;32m3.\e[0m Desplegar un contenedor \e[1mNginx como Reverse Proxy\e[0m"
  echo -e "       conectado a la misma red interna"
  echo ""
  echo -e "    \e[1;32m4.\e[0m Configurar Nginx para que reciba tráfico en el puerto \e[1m80\e[0m"
  echo -e "       y lo redirija internamente a la aplicación (\e[1mproxy_pass\e[0m)"
  echo ""
  echo -e "    \e[1;32m5.\e[0m Solo el contenedor \e[1mNginx\e[0m debe tener puertos expuestos al host"
  echo -e "       (80/443), la aplicación debe ser inaccesible directamente"
  echo ""
  echo -e "  \e[1;37m💡 PISTAS PARA PRINCIPIANTES:\e[0m"
  echo -e "    • La aplicación escucha internamente en el puerto \e[1m80\e[0m"
  echo -e "    • Usa \e[1mexpose: [\"80\"]\e[0m en lugar de \e[1mports:\e[0m para la app"
  echo -e "    • En Nginx proxy: \e[1mproxy_pass http://critical-app:80;\e[0m"
  echo -e "    • Los contenedores en la misma red se resuelven por \e[1mnombre del servicio\e[0m"
  echo ""
  echo -e "\e[1;36m  ──────────────────────────────────────────────────────────────────────────\e[0m"
  echo -e "\e[1;33m  CRITERIOS DE ACEPTACIÓN (Nivel L2 - Dificultad 6/10)\e[0m"
  echo -e "\e[1;36m  ──────────────────────────────────────────────────────────────────────────\e[0m"
  echo ""
  echo -e "   \e[1;37m[ ]\e[0m Puerto 8080 \e[1mNO\e[0m es accesible directamente                     \e[0;35m→ 20%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Red interna de Docker creada correctamente                      \e[0;35m→ 15%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Contenedor Nginx desplegado como Reverse Proxy                  \e[0;35m→ 20%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Nginx configurado con \e[1mproxy_pass\e[0m correcto                    \e[0;35m→ 20%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Puerto 80 del host redirige correctamente a la app              \e[0;35m→ 15%\e[0m"
  echo -e "   \e[1;37m[ ]\e[0m Aplicación inaccesible directamente desde el host               \e[0;35m→ 10%\e[0m"
  echo ""
  echo -e "\e[1;31m  ⚠️  NOTA DE SEGURIDAD:\e[0m La configuración actual viola 3 estándares"
  echo -e "     críticos del documento SEC-DOCKER-STD-003. La remediación es obligatoria."
  echo ""
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""

  echo -e "\e[1;32m✔ Entorno de laboratorio configurado exitosamente.\e[0m"
  echo -e "📂 Directorio de trabajo: \e[1;33m$HOME/docker-lab-05\e[0m"
  echo -e "🐳 Contenedor: \e[1;33mcritical-app\e[0m (puerto 8080 expuesto - ESTO ES EL PROBLEMA)"
  echo -e "📝 Dockerfile: \e[1;33m$HOME/docker-lab-05/Dockerfile\e[0m"
  echo -e "📝 Compose a corregir: \e[1;33m$HOME/docker-lab-05/docker-compose.yml\e[0m"
  echo ""
  echo -e "\e[1;33m💡 TIP:\e[0m Prueba primero el acceso directo:"
  echo -e "   \e[1mcurl http://localhost:8080/\e[0m  ← Esto funciona (y NO debería)"
  echo ""
  echo -e "   Después de tu remediación, prueba:"
  echo -e "   \e[1mcurl http://localhost:8080/\e[0m  ← Esto debe FALLAR (conexión rechazada)"
  echo -e "   \e[1mcurl http://localhost/\e[0m       ← Esto debe FUNCIONAR (a través del proxy)"
  echo ""
  echo -e "\e[1;36m¡Éxito en la remediación, Ingeniero!\e[0m"
  EOF

  chmod +x /tmp/setup-docker-lab-05.sh
  bash /tmp/setup-docker-lab-05.sh
  rm -f /tmp/setup-docker-lab-05.sh
tags:
  - Docker
  - Laboratorios-del-LFCS
  - Reverse-Proxy
  - Seguridad-de-Red
  - Nginx
  - Docker-Networks
---
[[Laboratorios del LFCS]]

---

Recently at work, I had to remediate a security issue in a Dockerized application that was flagged during a security audit. The problem was that the app's port was directly exposed to the host, which meant it was reachable from the internet without any protection layer, no reverse proxy, no network isolation, and no way to enforce TLS or rate limiting in the future.

To fix this, I redesigned the Docker Compose setup. First, I removed the direct port mapping from the application container and switched it to `expose`, so it could only communicate with other containers on the same internal Docker network, not with the host. Then, I created an isolated bridge network and deployed an Nginx container as a reverse proxy, which was the only service allowed to publish a port to the host. I configured Nginx with a `proxy_pass` directive so it would forward incoming traffic to the application container internally, using Docker's service name resolution.

After deploying the changes, I validated everything methodically: I confirmed the application container had no exposed ports, verified both containers were correctly attached to the internal network using `docker network inspect`, and tested that requests through the proxy on port 80 successfully reached the application, while the original insecure port was no longer serving that application.

This task reinforced how important it is to apply network segmentation principles even in small containerized environments, and it gave me hands-on experience designing a reverse proxy architecture from scratch.