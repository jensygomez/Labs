


Se mantiene estrictamente tu **Regla de Oro**: Todo se ejecuta desde `node01`, se conecta a `node02` vía `sshpass`, y la evidencia se envía a `node03` vía pipeline.

---

### 🗺️ Ruta de Práctica: Operations Deployment (LFCS, RHCSA & DevOps Foundation)

#### **1. OD-001: El Arranque Fantasma – Recuperación de Boot y Gestión de Targets**
*   **Dificultad:** 6.5/10 | **Nivel:** L2
*   **Temas Operations Deployment:** Boot, Reboot, and Shutdown a System Safely; Boot or Change System Into Different Operating Modes; Manage Startup Process.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Tras una actualización fallida en `node02`, el servidor arranca en "Emergency Mode" o en un target incorrecto (ej. `rescue.target`), impidiendo el acceso a servicios de red. Desde `node01`, debes conectarte, identificar el target actual, cambiar el target por defecto a `multi-user.target` de forma persistente, realizar un reinicio seguro (`systemctl reboot`) y verificar que el sistema esté completamente operativo. Documenta el estado antes y después, y envía el reporte a `node03`.

#### **2. OD-002: El Servicio Zombi – Diagnóstico de Procesos y Creación de Units systemd**
*   **Dificultad:** 7.0/10 | **Nivel:** L2
*   **Temas Operations Deployment:** Diagnose and Manage Processes; Create systemd Services; Manage Startup Process and Services.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Una aplicación crítica en `node02` se cierra inesperadamente, dejando procesos huérfanos o "zombis" que consumen memoria. El script de inicio actual es un hack obsoleto. Debes identificar y matar los procesos residuales (usando `kill`, `pkill` o `systemctl kill`), crear un archivo de unidad `systemd` correcto (`.service`) con directivas de reinicio automático (`Restart=on-failure`), habilitarlo para el arranque y verificar su estado. Envía la salida de `systemctl status` y `ps aux` a `node03`.

#### **3. OD-003: Sintonizando el Núcleo – Parámetros del Kernel y Análisis Forense de Logs**
*   **Dificultad:** 7.5/10 | **Nivel:** L3
*   **Temas Operations Deployment:** Change Kernel Runtime Parameters (Persistent and Non-Persistent); Locate and Analyze System Log Files.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** `node02` está sufriendo caídas de red intermitentes y posibles OOM (Out of Memory) kills. Desde `node01`, debes analizar los logs (`journalctl -k` o `/var/log/messages`) para confirmar la causa. Luego, debes ajustar parámetros del kernel de forma no persistente para prueba inmediata (ej. `vm.swappiness`, `net.ipv4.ip_forward`, o `vm.panic_on_oom`) y, una vez validado, hacer el cambio persistente en `/etc/sysctl.d/`. Envía los logs filtrados y la configuración aplicada a `node03`.

#### **4. OD-004: Dependencias Huérfanas – Repositorios, Paquetes y Compilación desde Fuente**
*   **Dificultad:** 6/10 | **Nivel:** L2
*   **Temas Operations Deployment:** Manage Software with the Package Manager; Configure the Repositories; Install Software by Compiling Source Code; Verify Integrity.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** El repositorio oficial de `node02` está caído o no contiene una versión específica de una herramienta de monitoreo necesaria. Debes configurar un repositorio alternativo (local o espejo), instalar las dependencias de compilación (`gcc`, `make`, etc.), descargar el código fuente, compilarlo e instalarlo (`./configure`, `make`, `make install`). Finalmente, verifica la integridad del binario instalado (ej. con `ldd` o `hash`) y reporta el proceso a `node03`.

#### **5. OD-005: El Muro Invisible – Contextos SELinux y Políticas MAC**
*   **Dificultad:** 8.0/10 | **Nivel:** L3
*   **Temas Operations Deployment:** List and Identify SELinux File and Process Contexts; Create and Enforce MAC Using SELinux.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Un servicio web o de base de datos en `node02` se niega a iniciar o a leer archivos en un directorio no estándar (ej. `/opt/data`), a pesar de que los permisos POSIX (chmod/chown) son correctos. SELinux está en modo `Enforcing`. Está **prohibido** usar `setenforce 0`. Debes usar `audit2allow`, `semanage`, `chcon` o `restorecon` para identificar el contexto incorrecto, definir la política correcta y aplicar la etiqueta de seguridad adecuada para que el servicio funcione de forma segura. Envía el output de `sestatus` y `ls -Z` a `node03`.

#### **6. OD-006: La Tarea Desbocada – Programación de Tareas y Control de Ejecución**
*   **Dificultad:** 6.5/10 | **Nivel:** L2
*   **Temas Operations Deployment:** Schedule Tasks to Run at a Set Date and Time; Verify Integrity and Availability of Resources.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Una tarea programada (cron o at) en `node02` se está ejecutando en horas pico, causando picos de carga CPU. Debes auditar las tareas existentes (`crontab -l`, `/etc/cron.d/`), reprogramar la tarea para que se ejecute en una ventana de mantenimiento (ej. 3:00 AM), asegurarte de que la salida se redirija a un log específico (no al mail del root) y verificar que la sintaxis de `cron` sea válida. Reporta la configuración modificada a `node03`.

#### **7. OD-007: El Contenedor Efímero – Despliegue y Persistencia en Entornos Containerizados**
*   **Dificultad:** 8.5/10 | **Nivel:** L3
*   **Temas Operations Deployment:** Create and Manage Containers.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Un microservicio en `node02` se ejecuta en un contenedor (Podman/Docker), pero pierde sus datos al reiniciar y no arranca con el host. Debes desplegar un nuevo contenedor con las siguientes condiciones: mapeo de puertos específico, montaje de un volumen persistente en el host, límites de recursos (CPU/Memoria) y, crucialmente, generar una unidad `systemd` para que el contenedor inicie automáticamente como un servicio del sistema. Envía el estado del contenedor y del servicio a `node03`.

#### **8. OD-008: La Máquina Fantasma – Aprovisionamiento y Gestión de Virtualización (KVM/libvirt)**
*   **Dificultad:** 8.0/10 | **Nivel:** L3
*   **Temas Operations Deployment:** Manage and Configure Virtual Machines; Create and Boot a Virtual Machine; Installing an Operating System on a Virtual Machine.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Se requiere aprovisionar una nueva VM en `node02` (que actúa como hipervisor) de forma totalmente headless (sin interfaz gráfica). Debes usar `virt-install` (o `virsh`) para crear una VM con recursos específicos (vCPU, RAM), adjuntar una imagen ISO para la instalación del SO, configurar la red (NAT o Bridge) y asegurarte de que la VM esté configurada para `autostart` cuando el host `node02` se reinicie. Envía la salida de `virsh list --all` y la configuración XML a `node03`.

#### **9. OD-009: El Cuello de Botella – Verificación de Integridad y Límites de Recursos**
*   **Dificultad:** 7.5/10 | **Nivel:** L3
*   **Temas Operations Deployment:** Verify Integrity and Availability of Resources and Processes; Diagnose and Manage Processes.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Un usuario o servicio no crítico en `node02` está consumiendo todos los descriptores de archivo o memoria, afectando la disponibilidad del sistema. Debes diagnosticar el consumo actual y aplicar límites estrictos utilizando `limits.conf` (ulimit) para el usuario, o mejor aún, controles de recursos nativos de `systemd` (ej. `TasksMax`, `MemoryMax`, `CPUQuota`) en el archivo de servicio. Verifica que los límites se apliquen correctamente bajo carga. Reporta los límites aplicados a `node03`.

#### **10. OD-010: La Tormenta Perfecta – Despliegue Operativo Integral (Incidente Maestro)**
*   **Dificultad:** 9.5/10 | **Nivel:** L3 (Simulación de Examen / Producción)
*   **Temas Operations Deployment:** Boot, systemd, SELinux, Logs, Kernel Parameters, Package Management.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Tras una migración en `node02`, el sistema es inestable: 1) Un parámetro del kernel incorrecto causa advertencias en el arranque. 2) Un servicio personalizado falla al iniciar. 3) Los logs indican denegaciones de SELinux. 4) El espacio en `/var` está al 95% por logs no rotados. Desde `node01`, debes ejecutar un plan de remediación integral: corregir el parámetro del kernel (`sysctl`), limpiar/rotar logs, diagnosticar y corregir el contexto SELinux del servicio, y reparar el archivo `systemd`. El sistema debe quedar 100% operativo, seguro y persistente tras un reinicio. Envía un reporte ejecutivo consolidado a `node03`.

---
