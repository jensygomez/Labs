

---

### 🗺️ Ruta de Práctica: Contenedores y Orquestación Docker (DevOps & Sysadmin)
*Arquitectura base: `host-admin` (Estación de Admin/CI-CD), `node-docker-01` (Servidor Docker Principal/Producción), `node-registry` (Registro de Imágenes Privado/Vault de Secretos).*

#### **1. DK-001: El Contenedor Reincidente – Fallo de Persistencia y Entorno**
*   **Dificultad:** 5/10 | **Nivel:** L2
*   **Temas Docker:** Docker Volumes, Environment Variables, Container Lifecycle.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Un contenedor de base de datos (ej. PostgreSQL) se reinicia tras una actualización, pero todos los datos creados previamente han desaparecido. Además, la aplicación falla al arrancar porque usa credenciales por defecto en lugar de las variables de entorno esperadas. Debes diagnosticar el uso de volúmenes efímeros vs. nombrados, crear un volumen persistente (`docker volume`), y asegurar que las variables de entorno se inyecten correctamente mediante un archivo `.env` o flags `-e`, verificando la persistencia tras un `docker rm` y `docker run`.

#### **2. DK-002: El Microservicio Huérfano – Aislamiento y Comunicación de Red**
*   **Dificultad:** 6/10 | **Nivel:** L2
*   **Temas Docker:** Docker Networks (Bridge, Custom), DNS resolution in Docker.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Tienes dos contenedores (una API y una Base de Datos) corriendo en la red `bridge` por defecto. La API no puede conectarse a la BD usando el nombre del contenedor como hostname, solo funciona si usas la IP interna (que cambia al reiniciar). Debes crear una red de puente personalizada (`docker network create`), conectar ambos contenedores a ella y demostrar que la resolución de nombres DNS interna de Docker funciona correctamente.

#### **3. DK-003: La Imagen Fantasma – Diagnóstico y Corrección de Dockerfile**
*   **Dificultad:** 6/10 | **Nivel:** L2
*   **Temas Docker:** Dockerfile Best Practices, Multi-stage builds, Layer caching, .dockerignore.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** El equipo de desarrollo entregó un `Dockerfile` que genera una imagen de más de 2GB para una aplicación simple de Node.js/Python. La imagen se ejecuta como `root`, expone puertos innecesarios y deja herramientas de compilación (como `gcc` o `make`) en la capa final. Debes refactorizar el `Dockerfile` usando una construcción en múltiples etapas (multi-stage build), añadir un archivo `.dockerignore` y asegurar que el proceso final corra con un usuario no privilegiado (`USER`).

#### **4. DK-004: El Guardián Caído – Healthchecks y Auto-Reparación**
*   **Dificultad:** 6/10 | **Nivel:** L2
*   **Temas Docker:** Docker HEALTHCHECK, Restart Policies, Container State.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Un contenedor de un servidor web aparece como "Up" en `docker ps`, pero la aplicación interna ha entrado en un estado de bloqueo (deadlock) y responde con errores HTTP 500 o timeouts. Docker no se entera y no lo reinicia. Debes implementar una instrucción `HEALTHCHECK` válida en el Dockerfile o compose (ej. `curl -f http://localhost/health || exit 1`) y configurar una política de reinicio (`restart: unless-stopped` o `on-failure`) para que el demonio de Docker recicle el contenedor automáticamente cuando falle la salud.

#### **5. DK-005: Puertas Abiertas – Reverse Proxy y Exposición Segura de Puertos**
*   **Dificultad:** 7/10 | **Nivel:** L3
*   **Temas Docker:** Docker Compose, Reverse Proxy (Nginx/Traefik), Port Mapping Security.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Una aplicación crítica tiene su puerto mapeado directamente al host (`-p 8080:80`), exponiéndola directamente a internet sin capa de seguridad. Debes eliminar esta exposición directa, colocar la aplicación en una red interna de Docker y desplegar un contenedor de Nginx (o Traefik) que actúe como Reverse Proxy. Solo el proxy debe tener los puertos 80/443 expuestos al host, gestionando el tráfico hacia el contenedor interno.

#### **6. DK-006: Secretos a la Vista – Gestión de Credenciales y Entorno**
*   **Dificultad:** 7/10 | **Nivel:** L3
*   **Temas Docker:** Docker Secrets, Environment Files, Image Security.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Una auditoría revela que las contraseñas de la base de datos y las API Keys están hardcodeadas en el `Dockerfile` (visibles en `docker history`) o pasadas directamente en la línea de comandos (visibles en `docker inspect`). Debes remediar esto extrayendo las credenciales a un archivo `.env` seguro (con permisos `600`) o utilizando Docker Secrets (si usas Swarm), montándolos como archivos de solo lectura dentro del contenedor, garantizando que no queden rastros en los metadatos de la imagen.

#### **7. DK-007: El Disco Lleno – Límites de Recursos y Limpieza (Pruning)**
*   **Dificultad:** 6/10 | **Nivel:** L2
*   **Temas Docker:** Resource Limits (CPU/Memory), Docker System Prune, Log Rotation.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** El servidor `node-docker-01` reporta "No space left on device". El diagnóstico muestra gigas de imágenes huérfanas (dangling), contenedores detenidos y, críticamente, archivos de log de un contenedor que crecieron sin control. Además, un contenedor está consumiendo el 100% de la CPU. Debes ejecutar una limpieza segura (`docker system prune`), configurar la rotación de logs en `daemon.json` (`max-size`, `max-file`) y aplicar límites estrictos de CPU y Memoria (`--cpus`, `--memory`) al contenedor problemático.

#### **8. DK-008: Despliegue Ciego – Rollback y Versionado de Imágenes**
*   **Dificultad:** 8/10 | **Nivel:** L3
*   **Temas Docker:** Image Tagging, Docker Compose Versioning, Rollback Strategies.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Un despliegue de producción usó la etiqueta `latest`. La nueva imagen contiene un bug crítico. Al intentar revertir, te das cuenta de que no sabes qué versión exacta funcionaba antes, ya que `latest` fue sobrescrita. Debes establecer una política de versionado semántico estricto (ej. `v1.2.3`), simular el despliegue fallido y ejecutar un procedimiento de rollback ordenado modificando el archivo de compose a la última etiqueta estable conocida y reiniciando los servicios.

#### **9. DK-009: El Cron Job Perdido – Tareas Programadas en Contenedores**
*   **Dificultad:** 7/10 | **Nivel:** L2/L3
*   **Temas Docker:** Cron inside containers vs. Host, Lightweight schedulers, Volume mounts.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Un script de respaldo dentro de un contenedor de aplicación dejó de ejecutarse. Al investigar, se descubre que el demonio `cron` no arrancó correctamente tras un reinicio, o que la zona horaria del contenedor no coincide con la del host. Como buena práctica de DevOps, no se debe ejecutar cron dentro del contenedor de la app. Debes crear un contenedor dedicado, ligero (ej. Alpine + cron), que monte los volúmenes necesarios y ejecute la tarea, o configurar el cron del `host-admin` para disparar un `docker exec`.

#### **10. DK-010: El Examen Final – Despliegue Full-Stack con Gobernanza**
*   **Dificultad:** 9/10 | **Nivel:** L3 (Examen Final)
*   **Temas Docker:** Full Docker Compose Stack, Security, Networking, Persistence, Monitoring.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Un "Capture The Flag" operativo. Se te entrega un archivo `docker-compose.yml` de una aplicación de 3 capas (Frontend, Backend API, Redis/DB) que es un desastre de seguridad y rendimiento. Usa etiquetas `latest`, expone el puerto de la BD al host, no tiene límites de recursos, carece de healthchecks y los logs llenan el disco. Debes refactorizar el archivo completo a estándares de producción: red personalizada, inyección segura de variables, healthchecks, límites de recursos, usuarios no-root y un reverse proxy. Finalmente, debes levantar el stack, verificar su funcionamiento y documentar las correcciones.

---

