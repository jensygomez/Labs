¡Excelente idea! Actualizar el `README.md` es fundamental para que tu portafolio refleje con precisión la arquitectura real (todo en LXC con almacenamiento centralizado NFS) y, sobre todo, para documentar el valor agregado de los **4 simuladores de tráfico con comportamiento humano**, que son el corazón de tus laboratorios de troubleshooting.

Aquí tienes el `README.md` actualizado. He modificado la topología, la matriz de almacenamiento y agregado una sección dedicada a explicar qué hace cada cliente.

---

### 📄 `README.md` (Actualizado)

```markdown
# SYSTECH-HA-001 — Enterprise Linux HA Infrastructure & Multi-Tier Lab

## 📋 Resumen del Proyecto
Infraestructura Enterprise de Alta Disponibilidad y plataforma de **Linux Systems Administration & Architecture** sobre **Proxmox VE**. El ciclo de vida completo de la infraestructura está automatizado mediante **Infraestructura como Código (IaC)** utilizando **OpenTofu** (aprovisionamiento de virtualización) y **Ansible** (orquestación y configuración de servicios).

El entorno incluye balanceo L7 (HAProxy + Keepalived), aplicación web dinámica (Apache/PHP), base de datos de alto rendimiento (PostgreSQL) y un esquema de **almacenamiento centralizado 100% NFSv4 en `storage01`** para todos los nodos de cómputo. 

Todo el control se ejecuta de manera aislada desde un **contenedor Podman Rootless Zero-Trust** como Nodo de Control, permitiendo el despliegue y la administración remota a través de **ZeroTier**, sin importar la red local donde se encuentre el Host o Proxmox.

---

## 🏗️ Topología de Infraestructura y Redes
El laboratorio utiliza un esquema de red desacoplado donde la gestión y el tráfico interno están segmentados. **Todos los nodos de cómputo (Apps y DB) corren como contenedores LXC** para optimizar recursos, delegando la persistencia de datos a un nodo de almacenamiento dedicado.

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ HOST DE CONTROL / DESARROLLO (PC Local / Laptop)                                      │
│  • Contenedor Podman: [ systech-control ] (Zero-Trust Control Node)                   │
│  • Cliente ZeroTier unido a la Overlay Network (IP: 10.147.17.X)                       │
└───────────────────────────────────────────┬────────────────────────────────────────────┘
                                            │
                                            │ SSH / Proxmox API via ZeroTier Overlay (10.147.17.0/24)
                                            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│ PROXMOX VE HYPERVISOR (Red Lab Intranet: 10.10.10.0/24 | ZeroTier: 10.147.17.100)      │
│                                                                                        │
│  ┌──────────────────────────────────────────────────────────────────────────────────┐  │
│  │ 🟢 INGRESS / ALTA DISPONIBILIDAD (LXC Containers - Ubuntu 24.04)                  │  │
│  │  • VIP Floating: 10.10.10.30 (Keepalived VRRP)                                   │  │
│  │  • lb01 (10.10.10.21) & lb02 (10.10.10.22) → HAProxy L7 Load Balancer              │  │
│  └────────────────────────────────────────┬─────────────────────────────────────────┘  │
│                                           │ (HTTP Round-Robin / Port 80)               │
│                                           ▼                                            │
│  ┌──────────────────────────────────────────────────────────────────────────────────┐  │
│  │ 🔵 APPLICATIVE CLUSTER (LXC Containers - AlmaLinux 9)                             │  │
│  │  • app01 (10.10.10.31), app02 (10.10.10.32), app03 (10.10.10.33)                   │  │
│  │  • Web Server: Apache (httpd) + PHP Engine + php-pgsql                           │  │
│  │  • App Mount: /var/www/html ◄─── (NFSv4) ───┐                                    │  │
│  └────────────────────────────────────────┬────┼────────────────────────────────────┘  │
│                                           │    │                                       │
│                (Consultas SQL TCP/5432)   │    │ (Código y Evidencias /var/www/html)   │
│                                           ▼    │                                       │
│  ┌───────────────────────────────────────────┐ │  ┌─────────────────────────────────┐  │
│  │ 🟣 DATABASE TIER (LXC Container)         │ │  │ 🔴 HYBRID STORAGE (AlmaLinux 9) │  │
│  │  • db01 (10.10.10.40)                     │ │  │  • storage01 (10.10.10.50)       │  │
│  │  • Engine: PostgreSQL 15                  │ │  │  • Volume Group: vg_storage     │  │
│  │  • Data Dir: /var/lib/pgsql/data ◄────────┼─┼──┼─ Target NFS: /exports/pgdata    │  │
│  │    (Montado sobre NFSv4 desde storage01)  │ │  │                                 │  │
│  └───────────────────────────────────────────┘ │  │  • Target NFS: /exports/webdata │  │
│                                                └──┼──── (Código y uploads de apps)  │  │
│                                                   └─────────────────────────────────┘  │
│                                                                                        │
│  ┌──────────────────────────────────────────────────────────────────────────────────┐  │
│  │ 🟡 TEST CLIENTS (LXC Containers - Ubuntu 24.04)                                   │  │
│  │  • client01..04 (10.10.10.11..14) → Generadores de tráfico con comportamiento    │  │
│  │    humano realista (duración variable, pausas, consolidación y rotación).        │  │
│  └──────────────────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Simuladores de Tráfico y Comportamiento Humano (Los 4 Clientes)
Para validar la Alta Disponibilidad y practicar troubleshooting real, el entorno no usa un simple `curl` infinito. Cuenta con **4 generadores de tráfico independientes** que simulan patrones de uso humano realista (ocupación variable del servidor + tiempos de descanso aleatorios), dejando evidencia tangible en el storage compartido:

| Cliente | Rol Simulado | Comportamiento y Evidencia en Storage (`/var/www/html/uploads`) |
| :--- | :--- | :--- |
| **Client01** | **Usuario Interactivo** | Ejecuta consultas SQL a PostgreSQL. Ocupa el nodo de aplicación un tiempo variable (simulando procesamiento) y deja un archivo `.txt` con los resultados de la consulta como evidencia de transacción exitosa. |
| **Client02** | **Proceso en Segundo Plano** | Simula tareas de sincronización o subida de archivos. Escribe directamente en el directorio compartido NFS con tiempos de ocupación y descanso aleatorios, generando archivos de log de escritura. |
| **Client03** | **Reporte Analítico Pesado** | Simula un usuario ejecutando reportes complejos (ej. `GROUP BY`, `AVG`). Genera carga sostenida en la DB y en el nodo de aplicación, dejando un reporte tabulado por departamento en el storage NFS. |
| **Client04** | **Consolidador Batch + Rotación** | Simula un proceso de mantenimiento/auditoría. Lee **todos** los archivos de evidencia generados por los clientes 01, 02 y 03, los empaqueta en un único archivo `audit_consolidated_*.txt` y aplica **rotación** (borrando los archivos fuente más antiguos) para mantener el storage limpio. |

> 💡 **Ventaja para Laboratorios:** Esta variabilidad en los tiempos de ocupación y descanso permite que HAProxy distribuya la carga de forma natural (round-robin real). Además, la dependencia de Client04 con los otros tres crea relaciones causales perfectas para escenarios de troubleshooting (ej. *"¿Por qué el consolidado está vacío?"* → Porque Client01/02/03 están fallando).

---

## 💾 Matriz de Almacenamiento & Integración de Servicios
El nodo `storage01` consolida **todas** las necesidades de persistencia del clúster de cómputo a través de un único protocolo (NFSv4), simplificando la administración y los puntos de falla:

| Tipo de Almacenamiento | Protocolo | Recurso Origen (Storage01) | Punto de Consumo | Propósito |
| :--- | :--- | :--- | :--- | :--- |
| **Shared File System (Web)** | NFSv4 | `/dev/vg_storage/lv_webdata` | `/var/www/html` en `app01..03` | Sincronización transparente del código web PHP y directorio de uploads/evidencias entre los nodos del cluster. |
| **Shared File System (DB)** | NFSv4 | `/dev/vg_storage/lv_pgdata` | `/var/lib/pgsql/data` en `db01` | Almacenamiento centralizado para los datos de PostgreSQL, permitiendo snapshots y backups centralizados en el nodo de storage. |



## ⚙️ Estructura del Role de Ansible
El aprovisionamiento de Ansible se encuentra unificado bajo un único rol modular con tareas divididas por capas:
- `storage_setup.yml` (`storage_nodes`): Crea LVMs y configura las exportaciones NFSv4 (`webdata` y `pgdata`) habilitando `firewalld`.
- `database_setup.yml` (`db_nodes`): Monta el volumen NFS en `/var/lib/pgsql/data`, aplica contextos SELinux (`postgresql_db_t`) e inicializa PostgreSQL.
- `web_app_setup.yml` (`app_nodes`): Monta NFSv4 en `/var/www/html`, habilita booleanos SELinux (`httpd_use_nfs`, `httpd_can_network_connect_db`) y despliega la aplicación PHP.
- `lb_setup.yml` (`lb_nodes`): Inyecta sysctl (`net.ipv4.ip_nonlocal_bind=1`), desplegando HAProxy y Keepalived para la VIP (`10.10.10.30`).
- `client_setup.yml` / `client0X.yml` (`client_nodes`): Configura los servicios systemd que ejecutan los patrones de tráfico realista descritos anteriormente.



---

## 🐳 Arquitectura del Nodo de Control: Contenedor Zero-Trust

### Filosofía de Seguridad

> **Cero secretos en el host. Cero credenciales en Git en texto plano.** Todo secreto o clave privada se mantiene cifrado en un repositorio Ansible Vault y se inyecta exclusivamente en la memoria efímera del contenedor Podman durante su arranque.

### Componentes del Nodo de Control

| Archivo / Componente | Función |
| --- | --- |
| **`dockerfile/Dockerfile`** | Define la imagen `systech-control` (Ubuntu 22.04 + OpenTofu + Ansible + Net Tools). Instala dependencias y configura un usuario no-root (`jensyg`, UID 1000) con `HOME=/workspace`. |
| **`dockerfile/entrypoint.sh`** | Punto de entrada del contenedor. Solicita el passphrase del Vault, desencripta `secrets/systech-secrets.yml` en memoria, genera dinámicamente `~/.ssh/id_systech_control`, crea `~/.ssh/config` y exporta las variables de entorno `TF_VAR_*`. |
| **`dockerfile/bootstrap.sh`** | Script de **inicialización única**: genera la identidad SSH dedicada (`id_systech_control`), solicita el API Token de Proxmox y empaqueta las credenciales en el Vault cifrado. |
| **`dockerfile/control.sh`** | Script de operaciones diarias: compila la imagen Podman si no existe y lanza el contenedor con `--network host` y `--userns=keep-id` montando el directorio del proyecto. |
| **`secrets/systech-secrets.yml`** | Ansible Vault principal. Contiene `proxmox_api_token`, `ssh_private_key` y `ssh_public_key`. Es completamente seguro subirlo a Git. |

### Flujo de Arranque Seguro

```text
control.sh
 └─ podman run (systech-control, --network host, --userns=keep-id)
     └─ entrypoint.sh
         ├─ ansible-vault view --ask-vault-pass secrets/systech-secrets.yml
         ├─ Genera en memoria efímera ~/.ssh/id_systech_control (0600)
         ├─ Configura ~/.ssh/config con la identidad generada
         ├─ Exporta TF_VAR_proxmox_api_token
         └─ Lanza la shell interactiva /bin/bash

```

---

## 🌐 Conectividad Remota y Mapeo de Redes (ZeroTier)

Para garantizar la independencia de la red física local (por si te mueves de casa, cambias de router o formateas el equipo), el entorno utiliza **ZeroTier** como capa de transporte de gestión:

1. **Overlay Network:** El hypervisor Proxmox VE y el host de desarrollo forman parte de la misma red ZeroTier (p. ej. `10.147.17.0/24`).
2. **Acceso Proxmox API:** OpenTofu se comunica con la API de Proxmox (`https://10.147.17.100:8006/api2/json`) a través de la interfaz virtual de ZeroTier, haciendo la infraestructura agnóstica a la IP LAN real del host.
3. **Ruta Estática al Laboratorio:** Para alcanzar la red del laboratorio (`10.10.10.0/24`) desde el contenedor de control en el Host, se configura un enrutamiento a través del nodo Proxmox:

```bash
# Enrutamiento en el Host para redirigir el tráfico del Lab a través de ZeroTier
sudo ip route add 10.10.10.0/24 via 10.147.17.100 dev zt2lrxxxxx

```

---

## 💾 Matriz de Almacenamiento & Integración de Servicios

El nodo `storage01` consolida las necesidades de almacenamiento en dos modalidades:

| Tipo de Almacenamiento | Protocolo | Recurso Origen | Punto de Consumo | Propósito |
| --- | --- | --- | --- | --- |
| **Shared File System** | NFSv4 (`nfs-server`) | `/dev/vg_storage/lv_webdata` | `/var/www/html` en `app01..03` | Sincronización transparente del código web PHP entre los nodos del cluster. |
| **SAN / Raw Block** | iSCSI (`targetcli` / LIO) | `/dev/vg_storage/lv_db_iscsi` | `/var/lib/pgsql/data` en `db01` | Almacenamiento de bloques dedicado, formateado en XFS en `db01` para PostgreSQL. |

---

## ⚙️ Estructura del Role `role_nfs_lvm_storage`

El aprovisionamiento de Ansible se encuentra unificado bajo un único rol modular con tareas divididas por capas:

* **`storage_setup.yml` (`storage_nodes`):** Crea LVMs, configura el export NFSv4 y el Target iSCSI LIO (IQN, LUNs, ACLs) habilitando firewalld (`3260/tcp`, `2049/tcp`).
* **`database_setup.yml` (`db_nodes`):** Realiza login iSCSI (`iscsid`), detecta el dispositivo, formatea en XFS, aplica SELinux contexts (`postgresql_db_t`) e inicializa PostgreSQL.
* **`web_app_setup.yml` (`app_nodes`):** Monta NFSv4 en `/var/www/html`, habilita booleanos SELinux (`httpd_use_nfs`, `httpd_can_network_connect_db`) y despliega la aplicación PHP.
* **`lb_setup.yml` (`lb_nodes`):** Inyecta sysctl (`net.ipv4.ip_nonlocal_bind=1`), desplegando HAProxy y Keepalived para la VIP (`10.10.10.30`).
* **`client_setup.yml` (`client_nodes`):** Configura un servicio systemd que ejecuta peticiones HTTP continuas a la VIP para validar el estado del cluster.

---

## 🔄 Disaster Recovery: Procedimiento de Reconstrucción desde Cero

Si formateas tu equipo o levantas el entorno en otra máquina o red, sigue estos pasos para recuperar la infraestructura completa en minutos:

### 1. Clonar el Repositorio

```bash
git clone [https://github.com/tu-usuario/SYSTECH-HA-001.git](https://github.com/tu-usuario/SYSTECH-HA-001.git)
cd SYSTECH-HA-001

```

### 2. Verificar Conectividad ZeroTier

Asegúrate de que tu PC host esté unida a la red ZeroTier y tenga ruta hacia la red del laboratorio:

```bash
sudo zerotier-cli join <NETWORK_ID>
sudo ip route add 10.10.10.0/24 via 10.147.17.100

```

### 3. Iniciar el Nodo de Control Zero-Trust

Lanza el contenedor de control. Te pedirá el passphrase para desencriptar el Vault:

```bash
./dockerfile/control.sh

```

*(A partir de este punto, todas las herramientas se ejecutan dentro del contenedor).*

### 4. Reconstruir la Infraestructura

```bash
# Entrar al directorio de OpenTofu y desplegar VMs/LXCs en Proxmox
cd /workspace/terraform
tofu init
tofu apply -auto-approve

# Entrar al directorio de Ansible y aprovisionar los servicios
cd /workspace/ansible
ansible-playbook -i inventories/production/hosts.yml site.yml --ask-vault-pass

```

### 5. Validar la Operación

Conéctate al cliente para verificar el tráfico continuo hacia la VIP:

```bash
ssh ansible@10.10.10.11
/usr/local/bin/infinite_traffic.sh

```
# Plan de Laboratorios de Troubleshooting — SYSTECH-HA-001
### 100 horas · Nivel L1 (Junior) → L2 (Mid) · Preparación RHCSA / LFCS / entrevistas Sysadmin

---

## Metodología

Cada laboratorio sigue el mismo ciclo: la IA (o tú mismo con un script) introduce **una falla controlada y reproducible** sobre la infraestructura ya desplegada y funcionando (`tofu apply` + `site.yml` limpio), sin decirte qué rompió. Tú actúas como el nivel de escalamiento correspondiente:

- **Nivel L1 (Junior):** diagnóstico de síntoma único, en un solo servicio/nodo, con evidencia directa en logs o `systemctl status`. Es lo que un NOC L1 con acceso a servidor SÍ podría resolver.
- **Nivel L2 (Mid):** fallas multi-causa, multi-nodo, o silenciosas (no rompen el servicio pero corrompen datos o degradan HA), que requieren correlacionar logs entre nodos, entender la arquitectura completa (LB→App→NFS/→DB) y a veces recuperar estado, no solo reiniciar un servicio.

Recomendación de conteo:

| Nivel | Horas | Dificultad | Nº de laboratorios | Duración promedio |
|---|---|---|---|---|
| L1 – Junior | 30 h | 3/10 – 5/10 | **15 laboratorios** | ~2 h c/u |
| L2 – Mid | 70 h | 6/10 – 8/10 | **20 laboratorios** | ~3.5 h c/u |

15 labs en L1 te da suficiente repetición de patrón (leer logs, `systemctl`, permisos, red) sin volverse mecánico. 20 labs en L2 es el número mínimo para cubrir cada área grande del temario RHCSA/LFCS (storage, red, seguridad, HA, base de datos, recuperación) al menos una vez con profundidad real, sin que ningún tema se sienta repetido dos laboratorios seguidos.

---

## NIVEL L1 — Junior / Escalamiento L1 (30 horas, dificultad 3–5/10)

| # | Título del incidente | Dificultad | Duración | Qué romperá la IA |
|---|---|---|---|---|
| 1 | Apache no arranca tras "mantenimiento" | 3/10 | 2h | Cambia el puerto de escucha de httpd sin ajustar el contexto SELinux del puerto, o lo deja en un puerto ya ocupado. |
| 2 | Disco lleno en `/var/log` | 3/10 | 2h | Genera logs masivos (bucle de escritura) hasta llenar la partición; servicios empiezan a fallar al escribir. |
| 3 | Sitio web devuelve 403 Forbidden | 3/10 | 2h | Cambia permisos/propietario de `/var/www/html` tras un "despliegue manual" simulado. |
| 4 | Servicio no vuelve tras reinicio del nodo | 3/10 | 2h | Deja un servicio activo pero sin `systemctl enable`; tras reboot no persiste. |
| 5 | Cliente no resuelve nombres de dominio | 4/10 | 2h | Corrompe `/etc/resolv.conf` o fuerza un override de NetworkManager que lo sobrescribe. |
| 6 | Job de cron "no hace nada" | 4/10 | 2h | Rompe el `PATH` dentro del script de cron para que falle silenciosamente (sin log de error visible a simple vista). |
| 7 | No puedo entrar por SSH con mi llave | 4/10 | 2h | Cambia permisos de `~/.ssh` o `authorized_keys` a valores que SSH rechaza por política de seguridad. |
| 8 | Nuevo servicio inaccesible desde la red | 4/10 | 2h | Instala/activa un servicio sin abrir el puerto correspondiente en `firewalld`. |
| 9 | Filesystem montado en modo solo lectura | 4/10 | 2h | Simula un error de disco que fuerza remount `ro`; requiere `fsck` y entender por qué el kernel lo protegió. |
| 10 | Usuario no puede autenticarse aunque la contraseña es correcta | 4/10 | 2h | Expira la cuenta o la contraseña vía `chage`, o bloquea el usuario con `passwd -l`. |
✅ 11 — Apps no pueden leer/escribir en el share compartido (stale NFS)
Alineación: PERFECTA
Los app_nodes montan /exports/webdata desde storage01 vía NFSv4.
Si storage01 se reinicia abruptamente, los mounts quedan en estado "Stale file handle".
El L1 debe: identificar con df -h / mount | grep nfs, hacer umount -f + mount -a, verificar.
Dificultad 5/10: correcta, porque requiere entender NFS y no es un simple systemctl.
✅ 12 — Un nodo de aplicación va lentísimo (proceso zombie/saturación CPU)
Alineación: PERFECTA
app02 es LXC AlmaLinux 9.
El L1 debe: usar top/htop/ps auxf, identificar el proceso, matarlo, entender por qué quedó huérfano.
Dificultad 5/10: correcta.
✅ 13 — La app no logra conectarse a la base de datos
Alineación: PERFECTA
db01 corre PostgreSQL 15 con pg_hba.conf + listen_addresses + firewalld puerto 5432.
El L1 debe: probar con psql desde app01, revisar pg_hba.conf, listen_addresses, firewalld, logs de PostgreSQL.
Dificultad 5/10: correcta.
✅ 14 — Actualización de paquete rompe un servicio
Alineación: PERFECTA
AlmaLinux 9 usa dnf. Puede ser httpd, php, php-pgsql con conflicto de dependencias.
El L1 debe: usar dnf history, rpm -Va, journalctl -u httpd, identificar el paquete roto, hacer downgrade.
Dificultad 5/10: correcta.
15 - "Apache devuelve 500 Internal Server Error"
Qué rompe la IA: Introduce un error de sintaxis en /var/www/html/index.php (PHP compartido vía NFS) o deshabilita el módulo php-pgsql.
Diagnóstico L1: Revisar /var/log/httpd/error_log, identificar el error PHP, corregir.
Alineación: ✅ Perfecta, aprovecha el stack PHP+PostgreSQL+Apache ya desplegado.
---

## NIVEL L2 — Mid / Escalamiento L2 (70 horas, dificultad 6–8/10)

*(Estos son los incidentes que L1 no pudo resolver o ni siquiera diagnosticó — llegan escalados con síntomas ambiguos, a veces sin caída total del servicio.)*

| # | Título del incidente | Dificultad | Duración | Qué romperá la IA |
|---|---|---|---|---|
| 16 | La VIP aparece en ambos load balancers a la vez | 6/10 | 3h | Desincroniza la prioridad VRRP de Keepalived entre `lb01`/`lb02`, provocando split-brain en la VIP `10.10.10.100`. |
| 17 | Las escrituras a los archivos web se corrompen intermitentemente | 6/10 | 3h | Rompe la configuración de locking NFS entre los tres app nodes, causando escrituras concurrentes conflictivas. |
| 18 | Sospecha de acceso SSH no autorizado | 6/10 | 3h | Configura fail2ban de forma laxa (umbral alto, whitelist mal puesta) que permite fuerza bruta pasar desapercibida. |
| 19 | Varios servicios fallan tras una "restauración" de sistema | 6/10 | 3h | Aplica un `restorecon`/relabel de SELinux incompleto que deja contextos incorrectos en múltiples directorios. |
| 20 | HAProxy sigue enviando tráfico a un nodo caído | 6/10 | 3h | Configura mal el healthcheck de HAProxy (endpoint equivocado o intervalo excesivo) para que no detecte `app0X` caído. |
| 21 | Los certificados dejan de validar justo a medianoche | 7/10 | 3.5h | Desincroniza chrony/NTP en un nodo, rompiendo validación de TLS y timestamps de logs de auditoría. |
| 22 | La sesión iSCSI de la base de datos se cae y vuelve sola | 7/10 | 3.5h | Introduce flapping de red intermitente entre `db01` y `storage01` sin multipath configurado. |
| 23 | Un usuario de bajo privilegio logra hacer cambios que no debería | 7/10 | 3.5h | Deja una entrada de `sudoers` demasiado permisiva (wildcard o NOPASSWD mal alcanzado) sin auditoría. |
| 24 | PostgreSQL se reinicia solo bajo carga | 7/10 | 3.5h | Genera presión de memoria en `db01` hasta que el OOM killer mata el proceso `postgres`. |
| 25 | El sitio empieza a rechazar conexiones en hora pico | 7/10 | 3.5h | Baja el `ulimit`/`nofile` de HAProxy para que agote descriptores de archivo bajo tráfico simulado alto. |
| 26 | La aplicación se congela por completo sin caerse | 7/10 | 3.5h | Genera una transacción abierta en PostgreSQL que produce un deadlock, bloqueando queries posteriores. |
| 27 | El firewall "funciona" pero el servicio a veces no responde | 7/10 | 3.5h | Desincroniza reglas runtime vs. permanentes en `firewalld`, causando comportamiento intermitente tras reinicios parciales. |
| 28 | Un disco se cae de storage01 y el Volume Group queda inconsistente | 8/10 | 4h | Simula remoción en caliente de un PV del VG, requiriendo `pvck`/`vgcfgrestore` para recuperar sin perder datos. |
| 29 | Todo el clúster se vuelve lento a la vez, sin causa obvia en un solo nodo | 8/10 | 4h | Satura I/O en `storage01`, degradando NFS e iSCSI simultáneamente — requiere diagnóstico cruzado en varios nodos. |
| 30 | Un solo app node consume todo el ancho de banda del storage | 8/10 | 4h | Simula un "noisy neighbor": proceso en `app02` generando tráfico masivo hacia `storage01`, ahogando a `app01`/`app03`. |
| 31 | El failover planeado de mantenimiento no funciona como se esperaba | 8/10 | 4h | Rompe la preemption/priority de Keepalived para que la VIP no regrese al nodo primario tras el mantenimiento. |
| 32 | Los datos de una tabla aparecen corruptos tras un corte eléctrico simulado | 8/10 | 4h | Fuerza un `kill -9` a PostgreSQL en medio de una escritura, requiriendo recovery point-in-time desde backup. |
| 33 | Los servicios internos dejan de confiar entre sí | 8/10 | 4h | Rompe la cadena de confianza de certificados internos entre nodos (CA no reconocida / cert vencido en un eslabón intermedio). |
| 34 | El clúster completo deja de responder bajo un pico de tráfico agresivo | 8/10 | 4h | Simula una saturación de conexiones a nivel de todo el stack (LB + App + DB) que agota recursos compartidos. |
| 35 | **Capstone — Desastre total en storage01** | 8/10 | 4h | Destruye el nodo `storage01` por completo (VG perdido). Debes restaurar NFS + iSCSI + datos de PostgreSQL desde backup, definiendo y cumpliendo un RTO/RPO. |

*(Suma aproximada: ~71.5h — ajustable ±2h según cuánto profundices en la documentación del RCA de cada laboratorio, lo cual también es parte deseable de la práctica.)*

---

## Alineación con certificaciones y entrevistas

- **RHCSA (EX200):** labs 1, 3, 4, 9, 10, 13, 14 (L1) y 13, 17, 19, 20, 28, 32 (L2) cubren gestión de storage/LVM, permisos, SELinux, systemd y usuarios — el núcleo del examen.
- **Linux Foundation LFCS:** labs de red, cron, procesos y troubleshooting de servicios (5, 6, 8, 12) más los de HA/almacenamiento en L2 cubren los dominios de "Essential Commands", "Operation of Running Systems" y "User and Group Management".
- **Entrevistas Sysadmin/DevOps:** documenta cada laboratorio como un mini-RCA (síntoma → hipótesis → comandos de diagnóstico → causa raíz → fix → prevención). Esa documentación es exactamente lo que un reclutador espera ver como evidencia de experiencia real, compensando la falta de acceso a herramientas de monitoreo en tu rol actual de NOC L1 en Accenture.


