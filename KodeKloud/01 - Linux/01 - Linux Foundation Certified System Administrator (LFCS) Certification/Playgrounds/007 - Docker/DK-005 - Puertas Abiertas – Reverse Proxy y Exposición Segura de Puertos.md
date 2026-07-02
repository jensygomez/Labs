---
id: DK-005
title: Puertas Abiertas – Reverse Proxy y Exposición Segura de Puertos
difficulty: 6/10
level: L2
course: Transición Sysadmin a DevOps - Fundamentos de Docker
module: Container Optimization & Security
playground: DK-005-v1
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

