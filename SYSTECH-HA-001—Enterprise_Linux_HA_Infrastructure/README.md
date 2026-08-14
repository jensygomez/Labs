Aquí tienes el **`README.md` principal completamente reconstruido, actualizado y unificado**, listo para reemplazar tu versión actual. Incluye la **Fase 05 (MariaDB)**, los nuevos incidentes reales encontrados, la adición del paquete `mariadb` en los *backends*, y la actualización de la arquitectura general.

---

```markdown
# SYSTECH-HA-001 — Enterprise Linux Hybrid HA Infrastructure

## 1. Descripción

Proyecto práctico de **Systech Consulting** para diseñar, implementar y operar una infraestructura empresarial Linux de alta disponibilidad para un cliente ficticio, **ACME Corporation**[cite: 1].

El proyecto simula el trabajo de un **Junior Linux Systems Administrator / SRE**, con foco en:

- Administración Linux empresarial (AlmaLinux 9 + Ubuntu 24.04)[cite: 1]
- Automatización con Ansible (roles, handlers, templates, group_vars)[cite: 1]
- Alta disponibilidad (VIP flotante + balanceo de carga)[cite: 1]
- Capa de persistencia segura (MariaDB) con automatización multi-OS e idempotencia[cite: 1]
- Troubleshooting real, documentado como incidentes[cite: 1]

La infraestructura se construye con **Ansible e idempotencia** como principios fundamentales, sobre un laboratorio **híbrido**: VMs KVM/libvirt para los nodos de aplicación/storage, y contenedores LXD para los nodos de borde (load balancers, base de datos)[cite: 1].

> Nota: El diseño original contemplaba 5 VMs homogéneas en AlmaLinux. Durante la implementación se migró a una topología híbrida (VMs + LXC) para optimizar recursos de laboratorio, lo que introdujo el desafío real de mantener roles de Ansible compatibles con dos familias de SO (RedHat/Debian) — documentado en la sección 8[cite: 1].

---

## 2. Objetivo

Desplegar un stack web en alta disponibilidad con capa de persistencia relacional[cite: 1], con failover validado extremo a extremo (VIP → balanceador → backend de aplicación → base de datos)[cite: 1], y documentar cada incidente de implementación real encontrado en el camino como parte del portfolio de troubleshooting[cite: 1].

---

## 3. Infraestructura actual

| Host | Plataforma | SO | Rol |
|---|---|---|---|
| `lb01` | LXD (contenedor) | Ubuntu 24.04 | Load Balancer — Keepalived + HAProxy (MASTER)[cite: 1] |
| `lb02` | LXD (contenedor) | Ubuntu 24.04 | Load Balancer — Keepalived + HAProxy (BACKUP)[cite: 1] |
| `server01` | KVM (VM) | AlmaLinux 9 | Backend de aplicación — Nginx + Cliente MariaDB |
| `server02` | KVM (VM) | AlmaLinux 9 | Backend de aplicación — Nginx + Cliente MariaDB |
| `server03` | KVM (VM) | AlmaLinux 9 | Backend de aplicación — Nginx + Cliente MariaDB |
| `storage01` | KVM (VM) | AlmaLinux 9 | Reservado — sin rol asignado todavía (solo baseline)[cite: 1] |
| `db01` | LXD (contenedor) | Ubuntu 24.04 | Base de Datos Relacional — MariaDB |

Todos los nodos comparten la red `lxdbr0` (`10.45.223.0/24`)[cite: 1].

---

## 4. Arquitectura actual (validada)

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
        +----+----+ +----+----+ +----+----+
             |           |           |
             +-----------+-----------+
                         |
                         v (TCP 3306)
                    +---------+
                    |  db01   |
                    | MariaDB |
                    +---------+

        storage01  →  sin rol asignado (baseline únicamente)

```

---

## 5. Tecnologías utilizadas hasta ahora

### Automatización

* Ansible (roles, handlers, templates Jinja2, `group_vars`, tags)


* Colección `ansible.mysql` (gestión idempotente de usuarios y bases de datos)
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
* Cliente `mariadb` (utilitario de diagnóstico en nodos de aplicación)

---

## 6. Estructura actual del proyecto

```text
SYSTECH-HA-001/
├── README.md
├── site.yml
│
├── inventories/
│   └── production/
│       ├── hosts.yml
│       └── group_vars/
│           └── lb_nodes.yml      # keepalived_vip (compartida entre roles)
│
├── roles/
│   ├── linux_baseline/
│   ├── keepalived/
│   ├── haproxy/
│   ├── nginx/
│   └── database/
│
└── scripts/
    ├── deploy-lab_Hybrid.sh      # provisión VMs + LXC, genera hosts.yml
    └── destroy-lab.sh            # limpieza dinámica de todo lo desplegado

```

---

## 7. Fases completadas y validadas

| Fase | Comando | Hosts | Estado |
| --- | --- | --- | --- |
| 01 — Linux Baseline | `ansible-playbook site.yml --tags baseline` | `ha_nodes:storage_nodes` | ✅ Validado

 |
| 02 — Keepalived (VIP) | `ansible-playbook site.yml --tags keepalived` | `lb_nodes` | ✅ Validado, con test de failover real

 |
| 03 — HAProxy (LB) | `ansible-playbook site.yml --tags haproxy` | `lb_nodes` | ✅ Validado

 |
| 04 — Nginx (backend) | `ansible-playbook site.yml --tags nginx` | `ha_nodes` | ✅ Validado

 |
| 05 — MariaDB (Database) | `ansible-playbook site.yml --tags database` | `database_nodes` | ✅ Validado |

### Validación end-to-end realizada

1. **Balanceo Web (Fase 02-04):**
```bash
curl [http://10.45.223.250](http://10.45.223.250)

```


Respuesta `200 OK`, rotación confirmada entre `server01`/`server02`/`server03` (balanceo `roundrobin` funcionando).


2. **Acceso Remoto a Base de Datos (Fase 05):**
```bash
DB_IP=$(ansible-inventory --host db01 | grep -oP '(?<="ansible_host": ")[^"]+')
ansible server01 -m shell -a "mysql -u acme_user -pPassword123 -h $DB_IP -e 'SHOW DATABASES;'"

```


Respuesta exitosa devolviendo `acme_db` e `information_schema` directamente desde `server01` hacia `db01`.

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


4. **`validate` de un fragmento de configuración de Nginx** — el módulo `template` requiere `%s` en `validate`, y no se puede validar un fragmento de config aislado (`conf.d/*.conf`) with `nginx -t`. Resuelto validando la configuración completa ya ensamblada, en una tarea separada.


5. **VIP en subred incorrecta** — `keepalived_vip` apuntaba a `192.168.122.0/24` (red `default` de libvirt), pero los nodos reales están en `10.45.223.0/24` (`lxdbr0`). La VIP quedaba asignada pero inalcanzable.


6. **Variables de un rol no visibles en otro rol/play** — `keepalived_vip` definida en `roles/keepalived/defaults/main.yml` no estaba disponible durante la play de `haproxy` (plays distintas = scope distinto). Resuelto centralizando la variable en `inventories/production/group_vars/lb_nodes.yml`, que persiste durante todo el playbook run.


7. **Fallo de autenticación inicial de MariaDB en Ubuntu/LXC** — MariaDB utiliza el plugin `unix_socket` por defecto para `root` en la familia Debian, rechazando conexiones por clave TCP local (`Access denied for user 'root'@'localhost'`). Resuelto pasando `login_unix_socket` en la tarea inicial y generando `/root/.my.cnf` con permisos `0600` para garantizar idempotencia total en futuras ejecuciones.
8. **Depreciación del Namespace de la Colección MySQL** — `community.mysql` generó advertencias de *deprecation*. Resuelto migrando las tareas a los módulos de la colección oficial `ansible.mysql` (`mysql_user` y `mysql_db`).

---

## 9. Próximo paso

* **Rol de storage en `storage01**` (actualmente solo tiene el baseline aplicado, sin ningún servicio de almacenamiento en red como NFS o iSCSI).



---

## Project ID

```text
SYSTECH-HA-001

```

## Client

```text
ACME Corporation

```

```

```
