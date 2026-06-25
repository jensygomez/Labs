---
PROMT: |-
  Actúa como un Sysadmin Senior / SRE creando un escenario de TICKET REAL para 
  un junior que acaba de ser promovido de NOC L1 a un rol de Sysadmin Jr., y 
  está resolviendo su primer incidente de scripting en un entorno de PRODUCCIÓN 
  simulado (no es un curso, no es un ejercicio académico — es trabajo real).

  ## CONTEXTO DEL ESCENARIO
  - Situación: [DESCRIBIR EL INCIDENTE, ej: "el cron de rotación de logs falló 
    anoche y /var está al 95%", "un proceso huérfano está consumiendo memoria 
    en el servidor de facturación"]
  - Ambiente simulado: Playground - Ubuntu 20.04 Multi Node. We have user bob with passowrd: caleston123 on all the VMs. There are 3 nodes with hostname: node01, node02, node03.
  - Dificultad objetivo: 3 a 5 sobre 10
  - Rol del junior: acaba de recibir el ticket escalado, tiene que resolverlo 
    él mismo (sin un L2/L3 a quien escalar en este ejercicio)

  ## REGLAS DE FORMATO OBLIGATORIAS

  1. **Formato de ticket real, no de "ejercicio"**: el escenario se presenta 
     como llegaría en Jira/ServiceNow: título, severidad, síntoma reportado, 
     impacto al negocio, y la tarea esperada. Sin lenguaje de "vamos a practicar X".

  2. **El script ya existe a medias, como lo dejó "alguien más"**: simula que 
     el junior heredó un script incompleto o roto (no uno diseñado para enseñar). 
     Puede incluir un comentario tipo `# TODO: terminar esto antes del próximo 
     mantenimiento - Carlos` para reforzar la sensación de entorno real.

  3. **Indentación real y visible**, nunca todo en una línea.

  4. **Marcador único y grep-able** para las partes a completar: 
     `# >>> COMPLETAR AQUÍ <<<` — pero el comentario alrededor describe el 
     PROBLEMA A RESOLVER, no "aprende esto". Ej: en vez de "TODO: aprende a usar 
     df", usar "// Necesitamos saber si hay espacio antes de continuar o vamos 
     a llenar el disco igual que ayer".

  5. **Pistas con flags long-form** (--verbose, --create, etc.), nunca el 
     comando completo armado.

  6. **Incluir al menos un elemento de riesgo real de producción**, elige uno 
     o combina máximo dos:
     - posibilidad de borrar/sobrescribir datos si la lógica está mal
     - necesidad de logging para auditoría (qué se hizo y cuándo)
     - manejo de exit codes para que un monitoreo externo (Nagios/Zabbix) lo 
       detecte correctamente
     - idempotencia (si el script se corre dos veces, no debe romper nada)

  7. **Mensajes de salida estilo log de producción real** (timestamps, niveles 
     tipo [INFO]/[ERROR]/[WARN], no solo emojis decorativos — aunque los emojis 
     pueden complementar, no reemplazar el formato de log serio).

  8. **Sección final separada del código:**

     ### 📋 Definición de "Resuelto" (Definition of Done)
     (criterios concretos de cuándo el ticket se puede cerrar)

     ### ⚠️ Qué pasa si esto sale mal en producción real
     (1-2 líneas de consecuencia real, para generar conciencia de riesgo)

     ### 💡 Pistas progresivas (si se traba)
     (2-3 pistas, de menos a más explícitas)

  ## ENTREGABLES
  1. El script/ticket tal como "lo heredó" el junior, con TODOs en formato 
     de problema-a-resolver


  No expliques tu razonamiento.
---

### 🗺️ Ruta Maestra: Del NOC al DevOps Engineer (20 Laboratorios)
*Arquitectura base: `host-admin` (Tu estación de trabajo/CI-CD), `rhel-node-01` y `rhel-node-02` (Servidores Linux para Sysadmin), `k8s-master` y `k8s-worker` (Clúster de Kubernetes).*

---

### 🟢 BLOQUE 1: Bash Scripting "Pierde el Miedo" (5 Laboratorios)
*Enfocado 100% en automatización de tareas reales de Sysadmin, sin algoritmos abstractos.*

#### **1. BS-001: El Eco Silencioso – Variables y Redirecciones**
*   **Dificultad:** 2/10 | **Nivel:** L1
*   **Temas Bash:** Variables de entorno, redirección estándar (`>`, `>>`, `2>&1`), permisos de ejecución (`chmod +x`).
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Necesitas un reporte diario del estado del servidor, pero estás cansado de ejecutar los mismos 5 comandos (`df -h`, `free -m`, `uptime`) manualmente. Debes crear un script básico que guarde la salida de estos comandos en un archivo de texto con la fecha actual en el nombre, asegurándote de que los errores también se capturen en el archivo.

#### **2. BS-002: El Portero Lógico – Condicionales y Validaciones**
*   **Dificultad:** 3/10 | **Nivel:** L1
*   **Temas Bash:** Condicionales (`if/elif/else`), operadores de comparación, test de existencia de archivos/directorios (`-d`, `-f`).
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Antes de hacer un respaldo, el script debe "pensar". Debes crear un script que verifique si el directorio de destino existe y tiene al menos 1GB libre. Si no existe, debe crearlo; si no tiene espacio, debe abortar con un mensaje de error; si todo está bien, debe proceder a comprimir una carpeta específica.

#### **3. BS-003: La Fábrica de Usuarios – Bucles y Archivos**
*   **Dificultad:** 4/10 | **Nivel:** L2
*   **Temas Bash:** Bucles (`for`, `while`), lectura de archivos línea por línea (`while read`), manipulación de cadenas.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Recursos Humanos te entrega un archivo `.csv` con 50 nuevos empleados (formato: `nombre,apellido,departamento`). Debes escribir un script que lea el archivo, cree el usuario en el sistema (usando `useradd`), le asigne un grupo secundario basado en su departamento y genere una contraseña aleatoria inicial, registrando todo en un log.

#### **4. BS-004: El Cazador de Logs – Parseo con Grep y Awk**
*   **Dificultad:** 5/10 | **Nivel:** L2
*   **Temas Bash:** Tuberías (`|`), `grep` (expresiones regulares básicas), `awk` (extracción de columnas), `sort` y `uniq`.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** El servidor está recibiendo intentos de fuerza bruta por SSH. Debes crear un script que analice `/var/log/secure` (o `auth.log`), extraiga las direcciones IP que tengan más de 5 intentos fallidos, y las añada automáticamente a las reglas de `firewalld` o `iptables` para bloquearlas temporalmente.

#### **5. BS-005: El Guardián del Cron – Automatización y Manejo de Errores**
*   **Dificultad:** 5/10 | **Nivel:** L3
*   **Temas Bash:** Manejo de errores (`set -e`, `trap`), logging con marcas de tiempo, integración con `cron`.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** El script de backup de la base de datos falló silenciosamente y nadie se enteró hasta tres días después. Debes refactorizar tu script de backup para que use `set -e` (abortar si algo falla), atrape señales de error con `trap`, escriba logs con fechas exactas, y programarlo en `cron` para que se ejecute a las 2:00 AM diariamente.

---

### 🔵 BLOQUE 2: Linux Sysadmin Pleno - LFCS & RHCSA (7 Laboratorios)
*Enfocado en los temas más críticos y difíciles de los exámenes de certificación y el día a día de un Sysadmin Senior.*

#### **6. LX-001: El Laberinto del Arranque – Boot Process y Rescue Mode**
*   **Dificultad:** 6/10 | **Nivel:** L2
*   **Temas Linux:** GRUB2, systemd targets, `rescue.target`, `emergency.target`, reparación de fstab.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Una modificación incorrecta en `/etc/fstab` ha dejado el servidor incapaz de arrancar, cayendo en `emergency mode`. Debes intervenir en el prompt de GRUB, modificar los parámetros del kernel para obtener una shell de root, montar el sistema de archivos en modo lectura/escritura, corregir el fstab y lograr que el servidor arranque normalmente.

#### **7. LX-002: La Bóveda Cifrada – LVM y LUKS**
*   **Dificultad:** 7/10 | **Nivel:** L3
*   **Temas Linux:** LVM (Physical Volumes, Volume Groups, Logical Volumes), LUKS encryption, `crypttab`.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** La política de seguridad exige que los datos de la base de datos estén cifrados en reposo. Debes añadir un nuevo disco, inicializarlo con LUKS, crear un grupo de volúmenes LVM encima, formatearlo en XFS, y configurarlo en `/etc/crypttab` y `/etc/fstab` para que se desbloquee e monte automáticamente al reiniciar.

#### **8. LX-003: El Muro de Fuego – Firewalld y SELinux**
*   **Dificultad:** 7/10 | **Nivel:** L3
*   **Temas Linux:** `firewalld` (rich rules, zones), SELinux (booleans, contexts, `audit2allow`, `semanage`).
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Desplegaste un servidor web (Nginx) escuchando en el puerto 8080, pero no es accesible. No puedes desactivar SELinux ni el Firewall. Debes usar `semanage` para decirle a SELinux que el puerto 8080 es válido para http, y configurar `firewalld` con una "rich rule" para permitir el tráfico solo desde la subred de la oficina, manteniendo la seguridad estricta.

#### **9. LX-004: La Red Fantasma – Network Manager y Bonding**
*   **Dificultad:** 6/10 | **Nivel:** L2
*   **Temas Linux:** `nmcli`, Network Bonding (active-backup/802.3ad), rutas estáticas persistentes.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** El servidor tiene dos interfaces de red físicas y no puede permitirse perder conectividad. Debes configurar un enlace agregado (Network Bonding) en modo `active-backup` usando `nmcli`, asignar una IP estática al interfaz lógico resultante, y añadir una ruta estática persistente hacia la red de administración.

#### **10. LX-005: El Reloj Maestro – NTP, Chrony y Timezones**
*   **Dificultad:** 5/10 | **Nivel:** L2
*   **Temas Linux:** `chronyd`, `timedatectl`, configuración de NTP pools, drift.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Los logs entre el servidor de aplicaciones y la base de datos no coinciden en tiempo, rompiendo la trazabilidad. Debes configurar `rhel-node-01` como servidor NTP interno (usando Chrony) para sincronizar a `rhel-node-02`, asegurando que ambos tengan la misma zona horaria y que la deriva (drift) sea menor a 10 milisegundos.

#### **11. LX-006: La Sombra del Acceso – PAM y Sudoers Avanzado**
*   **Dificultad:** 8/10 | **Nivel:** L3
*   **Temas Linux:** PAM (Pluggable Authentication Modules), `/etc/sudoers` (aliases, defaults), endurecimiento de SSH.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Un auditor pide que los desarrolladores puedan reiniciar el servicio de la aplicación, pero no puedan obtener root ni leer logs sensibles. Debes crear un grupo `app-ops`, configurar reglas de `sudoers` granulares (usando `Cmnd_Alias`) y ajustar PAM para limitar los intentos de login fallidos a 3 antes de bloquear la cuenta por 5 minutos.

#### **12. LX-007: El Contenedor de Servicios – Systemd Custom Units**
*   **Dificultad:** 7/10 | **Nivel:** L3
*   **Temas Linux:** systemd unit files, targets, `journalctl`, límites de recursos vía systemd.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Tienes una aplicación en Python/Go que se ejecuta con un script manual. Debes integrarla nativamente al sistema creando un `systemd service` personalizado. Debes configurarla para que inicie en el arranque, se reinicie si falla (`Restart=on-failure`), limite su uso de CPU/RAM desde la propia unit, y centralice sus logs en `journald`.

---

### 🟣 BLOQUE 3: DevOps & Kubernetes Engineer (8 Laboratorios)
*El salto final. Dejar de gestionar el sistema operativo manualmente y empezar a gestionar la infraestructura como código y contenedores.*

#### **13. DV-001: La Imagen Perfecta – Dockerfile Multi-stage y Seguridad**
*   **Dificultad:** 7/10 | **Nivel:** L3
*   **Temas Docker:** Multi-stage builds, non-root user, `.dockerignore`, imágenes Distroless/Alpine.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Desarrollo te entregó un Dockerfile que compila una app en Go/Node, pero la imagen final pesa 1.5GB y corre como root. Debes refactorizarlo usando "multi-stage builds" para que la imagen final solo contenga el binario compilado (peso < 50MB), añadir un `.dockerignore` y asegurar que el proceso corra con un usuario no privilegiado.

#### **14. DV-002: El Orquestador Ciego – Docker Compose y Redes**
*   **Dificultad:** 7/10 | **Nivel:** L3
*   **Temas Docker:** Docker Compose, custom networks, healthchecks, volúmenes nombrados.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Debes desplegar un stack de 3 capas (Frontend Nginx, Backend API, Base de Datos PostgreSQL) en `host-admin`. Debes crear un `docker-compose.yml` que use redes personalizadas (la BD no debe ser accesible desde el Frontend, solo desde la API), configurar healthchecks para cada servicio y usar volúmenes para persistir los datos de la BD.

#### **15. DV-003: El Primer Escalón – Instalación y Arquitectura de K8s**
*   **Dificultad:** 7/10 | **Nivel:** L3
*   **Temas K8s:** `kubeadm`, Container Runtime (containerd), CNI (Container Network Interface), pre-requisitos del OS.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Nada de clusters manejados (EKS/GKE). Debes levantar un clúster de Kubernetes "bare-metal" (usando tus nodos RHEL) desde cero. Debes configurar `containerd` correctamente (habilitando el plugin `cri`), desactivar swap, abrir puertos en el firewall, e inicializar el cluster con `kubeadm`, uniendo luego el nodo worker.

#### **16. DV-004: La Carga Efímera – Pods, Deployments y ReplicaSets**
*   **Dificultad:** 7/10 | **Nivel:** L3
*   **Temas K8s:** Workloads, Rolling Updates, Rollbacks, Resource Requests/Limits, Liveness/Readiness Probes.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Desplegar una aplicación web con 3 réplicas. Debes definir límites estrictos de CPU y Memoria (Requests/Limits). Luego, simularás un fallo de la aplicación (rompiendo el endpoint de salud) y demostrarás cómo Kubernetes detecta el fallo mediante Readiness/Liveness probes y reinicia el Pod automáticamente.

#### **17. DV-005: El Traductor de Tráfico – Services e Ingress**
*   **Dificultad:** 8/10 | **Nivel:** L4
*   **Temas K8s:** ClusterIP, NodePort, Ingress Controllers (Nginx), TLS termination, enrutamiento basado en Host.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Tu aplicación está corriendo, pero solo es accesible internamente. Debes exponerla al mundo. Primero crearás un Service `ClusterIP`, y luego desplegarás un Ingress Controller (Nginx). Configurarás reglas de Ingress para que el tráfico hacia `app.local` vaya al Frontend y `api.app.local` vaya al Backend, terminando el TLS con un certificado autofirmado.

#### **18. DV-006: La Memoria del Clúster – ConfigMaps y Secrets**
*   **Dificultad:** 7/10 | **Nivel:** L3
*   **Temas K8s:** ConfigMaps, Secrets, inyección vía variables de entorno (`envFrom`) y montaje de volúmenes.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Tu aplicación necesita la URL de la base de datos y las credenciales de acceso, pero no pueden estar en el código ni en el Dockerfile. Debes crear un ConfigMap para la configuración y un Secret para las contraseñas, inyectándolos en el Deployment de la API. Debes demostrar que al actualizar el ConfigMap, la aplicación puede recargar la configuración sin reconstruir la imagen.

#### **19. DV-007: El Almacenamiento Elástico – Persistent Volumes y Claims**
*   **Dificultad:** 8/10 | **Nivel:** L4
*   **Temas K8s:** Persistent Volumes (PV), Persistent Volume Claims (PVC), StorageClasses, Dynamic Provisioning.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Desplegaste una base de datos en K8s, pero al reiniciarse el Pod, los datos se perdieron. Debes configurar un provisionador de almacenamiento dinámico (puedes usar un NFS server o un hostpath provisioner). Crearás una `StorageClass` para que, al desplegar la BD con un `PVC`, Kubernetes asigne y formatee el volumen automáticamente.

#### **20. DV-008: El Examen Final – Despliegue Full-Stack con Gobernanza**
*   **Dificultad:** 9/10 | **Nivel:** L4 (Examen Final)
*   **Temas K8s:** Helm Charts, Network Policies, RBAC (Role-Based Access Control), Namespaces.
*   **Objetivo:** Prepararme para aprobar el LFCS, RHCSA, Para Sysadmin Linux Pleno, DevOps Engineer y Sysadmin Kubernetes.
*   **Escenario:** Un "Capture The Flag" operativo en tu clúster. Se te entrega un manifiesto de una app de 3 capas que es un desastre de seguridad: todo corre en el namespace `default`, la BD es accesible desde cualquier Pod, y los desarrolladores tienen acceso total al clúster. Debes: 1) Mover todo a un namespace `produccion`. 2) Empaquetar la app en un **Helm Chart**. 3) Aplicar **Network Policies** para que solo el Backend pueda hablar con la BD. 4) Crear roles **RBAC** para que el equipo de desarrollo solo pueda ver los logs de sus Pods, sin acceso a Secrets ni nodos.

---

### ⏱️ Estimación de Tiempo para estos 20 Laboratorios
*   **Tiempo por laboratorio:** Entre **6 a 8 horas** de práctica intensa (investigación, ejecución, errores y documentación).
*   **Tiempo total:** **120 a 160 horas** en total.
*   **Ritmo sugerido:** Si practicas **1 hora diaria** (o 2 horas los fines de semana), terminarás esta ruta completa en unos **4 a 5 meses**.

Esta lista cubre exactamente lo que necesitas: pierdes el miedo a Bash, dominas Linux a nivel de certificación (LFCS/RHCSA) y terminas orquestando contenedores como un verdadero DevOps/K8s Engineer. 

¿Te parece bien esta estructura de 20 laboratorios para empezar? Si estás de acuerdo, dime y **recién ahí** te redacto el **Laboratorio BS-001** con el paso a paso, los comandos base y los "retos" que debes resolver.