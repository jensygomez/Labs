# SYSTECH-HA-001 — Enterprise Linux Hybrid HA Infrastructure

## 1. Descripción

Proyecto práctico de **Systech Consulting** para diseñar, implementar y operar una infraestructura empresarial Linux de alta disponibilidad para un cliente ficticio, **ACME Corporation**.

El proyecto simula el trabajo de un **Junior Linux Systems Administrator / SRE**, con foco en:

- Administración Linux empresarial (AlmaLinux 9 + Ubuntu 24.04)
- Automatización con Ansible (roles, handlers, templates, group_vars)
- Alta disponibilidad (VIP flotante + balanceo de carga)
- Capa de persistencia segura (MariaDB) con automatización multi-OS e idempotencia
- Capa de aplicación (Python/Flask/Gunicorn) conectada a la base de datos
- Gestión de secretos con Ansible Vault
- Troubleshooting real, documentado como incidentes

La infraestructura se construye con **Ansible e idempotencia** como principios fundamentales, sobre un laboratorio **híbrido**: VMs KVM/libvirt para los nodos de aplicación/storage, y contenedores LXD para los nodos de borde (load balancers, base de datos).

> Nota: El diseño original contemplaba 5 VMs homogéneas en AlmaLinux. Durante la implementación se migró a una topología híbrida (VMs + LXC) para optimizar recursos de laboratorio, lo que introdujo el desafío real de mantener roles de Ansible compatibles con dos familias de SO (RedHat/Debian) — documentado en la sección 8.

---

## 2. Objetivo

Desplegar un stack web en alta disponibilidad con capa de persistencia relacional y capa de aplicación, con failover validado extremo a extremo (VIP → balanceador → backend de aplicación → base de datos), y documentar cada incidente de implementación real encontrado en el camino como parte del portfolio de troubleshooting.

---

## 3. Infraestructura actual

| Host | Plataforma | SO | Rol |
|---|---|---|---|
| `lb01` | LXD (contenedor) | Ubuntu 24.04 | Load Balancer — Keepalived + HAProxy (MASTER) |
| `lb02` | LXD (contenedor) | Ubuntu 24.04 | Load Balancer — Keepalived + HAProxy (BACKUP) |
| `server01` | KVM (VM) | AlmaLinux 9 | Backend de aplicación — Nginx + Flask/Gunicorn |
| `server02` | KVM (VM) | AlmaLinux 9 | Backend de aplicación — Nginx + Flask/Gunicorn |
| `server03` | KVM (VM) | AlmaLinux 9 | Backend de aplicación — Nginx + Flask/Gunicorn |
| `storage01` | KVM (VM) | AlmaLinux 9 | Reservado — sin rol asignado todavía (solo baseline) |
| `db01` | LXD (contenedor) | Ubuntu 24.04 | Base de Datos Relacional — MariaDB (seeding aplicado) |

Todos los nodos comparten la red `lxdbr0` (`10.45.223.0/24`).

---

## 4. Arquitectura actual

```text
                         ACME USERS
                              |
                              v
                    +-------------------+
                    |  VIP 10.45.223.250 |
                    |  Keepalived (VRRP) |
                    +----+-----------+---+
                         |           |
                      lb01 (M)   lb02 (B)
                    HAProxy     HAProxy
                    (roundrobin)
                         |
             +-----------+-----------+
             |           |           |
             v           v           v
        +---------+ +---------+ +---------+
        |server01 | |server02 | |server03 |
        |  Nginx  | |  Nginx  | |  Nginx  |
        | (proxy) | | (proxy) | | (proxy) |
        | Flask/  | | Flask/  | | Flask/  |
        | Gunicorn| | Gunicorn| | Gunicorn|
        +----+----+ +----+----+ +----+----+
             |           |           |
             +-----------+-----------+
                         |
                         v (TCP 3306)
                    +---------+
                    |  db01   |
                    | MariaDB |
                    | acme_db |
                    +---------+

        storage01  →  sin rol asignado (baseline únicamente)
```

> **Estado de integración (Fase 06 — cerrada):** flujo completo validado
> extremo a extremo: `VIP (Keepalived) → HAProxy → Nginx (proxy_pass) →
> Gunicorn → Flask → PyMySQL → MariaDB`. Rotación roundrobin confirmada
> entre los 3 backends con datos reales de `acme_db.customers`.

---

## 5. Tecnologías utilizadas hasta ahora

### Automatización

* Ansible (roles, handlers, templates Jinja2, `group_vars`, tags)
* Ansible Vault (gestión de secretos — passwords de MariaDB y app fuera de texto plano)
* Colección `community.mysql` (gestión idempotente de usuarios y bases de datos —
  deprecada, ver incidente #8)
* Inventario estático (`inventories/production/hosts.yml`)

### Sistemas operativos

* AlmaLinux 9 (VMs KVM/libvirt) — familia RedHat, `dnf`
* Ubuntu 24.04 (contenedores LXD) — familia Debian, `apt`

### Alta disponibilidad

* Keepalived (VRRP, VIP flotante, failover MASTER/BACKUP)
* HAProxy (balanceo `roundrobin`, `stats` en puerto 9000)

### Capa de Aplicación y Persistencia

* Nginx (backend de aplicación en 3 nodos)
* MariaDB 10.5+ (motor de base de datos relacional)
* Python3 + venv + Flask + Gunicorn (runtime de aplicación, gestionado por systemd)
* PyMySQL (driver de conexión Python → MariaDB)

---

## 6. Estructura actual del proyecto

```text
SYSTECH-HA-001/
├── README.md
├── site.yml
├── ansible.cfg
├── requirements.yml
│
├── inventories/
│   └── production/
│       ├── hosts.yml
│       ├── group_vars/
│       │   ├── all/
│       │   │   └── vault.yml       # secretos, encriptado con ansible-vault
│       │   └── lb_nodes.yml        # keepalived_vip (compartida entre roles)
│       └── host_vars/
│           ├── lb01.yml
│           └── lb02.yml
│
├── roles/
│   ├── linux_baseline/
│   ├── keepalived/
│   ├── haproxy/
│   ├── nginx/
│   ├── database/
│   ├── db_seed/         # Fase 06a — schema + datos de prueba + app_user
│   └── app/              # Fase 06b — Flask + Gunicorn + systemd
│
└── scripts/
    ├── deploy-lab_Hybrid.sh      # provisión VMs + LXC, genera hosts.yml
    └── destroy-lab.sh            # limpieza dinámica de todo lo desplegado
```

---

## 7. Fases completadas y validadas

| Fase | Comando | Hosts | Estado |
| --- | --- | --- | --- |
| 01 — Linux Baseline | `ansible-playbook site.yml --tags baseline` | `ha_nodes:storage_nodes` | ✅ Validado |
| 02 — Keepalived (VIP) | `ansible-playbook site.yml --tags keepalived` | `lb_nodes` | ✅ Validado, con test de failover real |
| 03 — HAProxy (LB) | `ansible-playbook site.yml --tags haproxy` | `lb_nodes` | ✅ Validado |
| 04 — Nginx (backend) | `ansible-playbook site.yml --tags nginx` | `ha_nodes` | ✅ Validado |
| 05 — MariaDB (Database) | `ansible-playbook site.yml --tags database` | `database_nodes` | ✅ Validado |
| 06a — DB Seeding | `ansible-playbook site.yml --tags db_seed` | `database_nodes` | ✅ Validado |
| 06b — App Layer (Flask/Gunicorn + Nginx proxy) | `ansible-playbook site.yml --tags app,nginx` | `ha_nodes` | ✅ Validado end-to-end vía VIP |

### Validación end-to-end realizada

1. **Balanceo Web (Fase 02-04):**
```bash
curl http://10.45.223.250
```
Respuesta `200 OK`, rotación confirmada entre `server01`/`server02`/`server03` (balanceo `roundrobin` funcionando).

2. **Acceso Remoto a Base de Datos (Fase 05):**
```bash
DB_IP=$(ansible-inventory --host db01 | grep -oP '(?<="ansible_host": ")[^"]+')
ansible server01 -m shell -a "mysql -u acme_user -pPassword123 -h $DB_IP -e 'SHOW DATABASES;'"
```
Respuesta exitosa devolviendo `acme_db` e `information_schema` directamente desde `server01` hacia `db01`.

3. **Capa de Aplicación + Balanceo End-to-End (Fase 06):**
```bash
for i in $(seq 1 9); do ansible lb01 -m command -a "curl -s http://10.45.223.250/" | grep served_by; done
```
Rotación roundrobin confirmada entre `server01`/`server02`/`server03`, cada respuesta con datos reales consultados en vivo desde `acme_db.customers`. Cadena completa validada: VIP → HAProxy → Nginx (proxy_pass) → Gunicorn → Flask → PyMySQL → MariaDB.

### Test de failover realizado

Se detuvo `keepalived` en `lb01` (MASTER) con tráfico HTTP activo contra la VIP:

* La VIP migró a `lb02` (BACKUP) correctamente.
* El servicio HTTP no tuvo interrupciones observables durante la transición (0 requests fallidos en el loop de validación).
* Al restaurar `lb01`, recuperó el rol MASTER por preemption (mayor `priority`).

---

## 8. Incidentes reales encontrados durante la implementación

Cada uno de estos fue un problema real de esta fase de construcción, no un ejercicio simulado — quedan documentados porque son la base del futuro catálogo de incidentes formal.

1. **Detección de IP de contenedores LXC fallaba silenciosamente** — el parsing de `lxc info` buscaba un patrón de texto que no coincidía con el formato real de salida. Resuelto migrando a `lxc list --format csv`.

2. **`linux_baseline` y `haproxy`/`keepalived` fallaban en los LXC** — los roles usaban `ansible.builtin.dnf` exclusivamente, incompatible con Ubuntu. Resuelto con tareas condicionadas por `ansible_facts['os_family']`.

3. **Error de sintaxis YAML** — comilla de cierre partida en dos líneas al editar `when:` a mano.

4. **`validate` de un fragmento de configuración de Nginx** — el módulo `template` requiere `%s` en `validate`, y no se puede validar un fragmento de config aislado (`conf.d/*.conf`) con `nginx -t`. Resuelto validando la configuración completa ya ensamblada, en una tarea separada.

5. **VIP en subred incorrecta** — `keepalived_vip` apuntaba a `192.168.122.0/24` (red `default` de libvirt), pero los nodos reales están en `10.45.223.0/24` (`lxdbr0`). La VIP quedaba asignada pero inalcanzable.

6. **Variables de un rol no visibles en otro rol/play** — `keepalived_vip` definida en `roles/keepalived/defaults/main.yml` no estaba disponible durante la play de `haproxy` (plays distintas = scope distinto). Resuelto centralizando la variable en `inventories/production/group_vars/lb_nodes.yml`, que persiste durante todo el playbook run. El mismo patrón de error reapareció en la Fase 06 (ver incidente #9) — confirma que es un error recurrente de diseño, no un caso aislado.

7. **Fallo de autenticación inicial de MariaDB en Ubuntu/LXC** — MariaDB utiliza el plugin `unix_socket` por defecto para `root` en la familia Debian, rechazando conexiones por clave TCP local (`Access denied for user 'root'@'localhost'`). Resuelto pasando `login_unix_socket` en la tarea inicial y generando `/root/.my.cnf` con permisos `0600` para garantizar idempotencia total en futuras ejecuciones.

8. **Depreciación del namespace de la colección MySQL** — `community.mysql.mysql_db` y `mysql_user` generan advertencias de deprecation (soporte de MariaDB se retira en la versión 6.0.0). Pendiente migrar a `community.mariadb` en una fase futura.

9. **Credenciales en texto plano en `defaults/main.yml`** — passwords de MariaDB y del usuario de aplicación estaban hardcodeadas (`Password123`) en archivos versionados. Resuelto migrando todos los secretos a `inventories/production/group_vars/all/vault.yml`, encriptado con `ansible-vault`. Se estableció la convención: las tasks de cada rol referencian variables `vault_*` directamente y nunca dependen de `defaults` de otro rol (mismo error de scope que el incidente #6, reaparecido en un contexto distinto).

10. **Variable auto-referenciada (bucle de recursión infinita)** — `app_db_user: "{{ app_db_user }}"` en `roles/app/defaults/main.yml` causó `Recursive loop detected in template: maximum recursion depth exceeded`. Ocurrió al intentar "heredar" el valor desde otro rol usando el mismo nombre de variable. Resuelto asignando el valor literal directamente.

11. **Typos en unit file de systemd rompieron la carga de variables de entorno** — `EnviromentFile` (faltaba la `n`) en `gunicorn.service.j2` no fue reconocido por systemd (`Unknown key name, ignoring`), por lo que Gunicorn arrancó sin `DB_HOST`/`DB_USER`/`DB_PASS`, y la app fallaba con `Can't connect to MySQL server on 'localhost'`. Buen recordatorio de que systemd ignora silenciosamente directivas desconocidas en vez de fallar — el error solo aparece en `journalctl`, no en el output de Ansible.

12. **SELinux bloqueaba la conexión de Nginx hacia Gunicorn (502 Bad Gateway)** — en AlmaLinux, el booleano `httpd_can_network_connect` viene desactivado por defecto, impidiendo que Nginx abra conexiones salientes incluso hacia `127.0.0.1`. El error solo aparece en `/var/log/nginx/error.log` (`connect() failed (13: Permission denied)`), no en el output del módulo `template`/`copy` de Ansible. Resuelto con el módulo `ansible.posix.seboolean` (`httpd_can_network_connect: true`, `persistent: true`), condicionado a `os_family == RedHat`.

---

## 9. Próximo paso

* **Rol de storage en `storage01`** (actualmente solo tiene el baseline aplicado, sin ningún servicio de almacenamiento en red como NFS o iSCSI).
* **Monitoring + alerting** (fase futura): LXC dedicada con Prometheus/Alertmanager o Zabbix, plantillas Jinja2 para el formato de alertas, y un endpoint receptor de "tickets".
* **Migrar `community.mysql` → `community.mariadb`** antes de la deprecation formal en la versión 6.0.0.
* **Client01** (LXC de demostración) ejecutando `curl` en bucle contra la VIP, como capa de observabilidad separada del flujo de validación técnica.

---

## Project ID

```text
SYSTECH-HA-001
```

## Client

```text
ACME Corporation
```
