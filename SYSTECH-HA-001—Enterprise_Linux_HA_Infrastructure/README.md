# SYSTECH-HA-001 — Enterprise Linux Hybrid HA Infrastructure

## 1. Descripción

Proyecto práctico de **Systech Consulting** para diseñar, implementar y operar una infraestructura empresarial Linux de alta disponibilidad para un cliente ficticio, **ACME Corporation**.

El proyecto simula el trabajo de un **Junior Linux Systems Administrator / SRE**, con foco en:

- Administración Linux empresarial (AlmaLinux 9 + Ubuntu 24.04)
- Automatización con Ansible (roles, handlers, templates, group_vars)
- Alta disponibilidad (VIP flotante + balanceo de carga)
- Troubleshooting real, documentado como incidentes

La infraestructura se construye con **Ansible e idempotencia** como principios fundamentales, sobre un laboratorio **híbrido**: VMs KVM/libvirt para los nodos de aplicación/storage, y contenedores LXD para los nodos de borde (load balancers, base de datos).

> Nota: el diseño original contemplaba 5 VMs homogéneas en AlmaLinux. Durante la implementación se migró a una topología híbrida (VMs + LXC) para optimizar recursos de laboratorio, lo que introdujo el desafío real de mantener roles de Ansible compatibles con dos familias de SO (RedHat/Debian) — documentado en la sección 8.

---

## 2. Objetivo

Desplegar un stack web en alta disponibilidad, con failover validado extremo a extremo (VIP → balanceador → backend de aplicación), y documentar cada incidente de implementación real encontrado en el camino como parte del portfolio de troubleshooting.

---

## 3. Infraestructura actual

| Host | Plataforma | SO | Rol |
|---|---|---|---|
| `lb01` | LXD (contenedor) | Ubuntu 24.04 | Load Balancer — Keepalived + HAProxy (MASTER) |
| `lb02` | LXD (contenedor) | Ubuntu 24.04 | Load Balancer — Keepalived + HAProxy (BACKUP) |
| `server01` | KVM (VM) | AlmaLinux 9 | Backend de aplicación — Nginx |
| `server02` | KVM (VM) | AlmaLinux 9 | Backend de aplicación — Nginx |
| `server03` | KVM (VM) | AlmaLinux 9 | Backend de aplicación — Nginx |
| `storage01` | KVM (VM) | AlmaLinux 9 | Reservado — sin rol asignado todavía |
| `db01` | LXD (contenedor) | Ubuntu 24.04 | Reservado — sin rol asignado todavía |

Todos los nodos comparten la red `lxdbr0` (`10.45.223.0/24`).

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
        +---------+ +---------+ +---------+

        storage01  →  sin rol asignado (baseline únicamente)
        db01       →  sin rol asignado (pendiente de definir)
```

---

## 5. Tecnologías utilizadas hasta ahora

### Automatización
- Ansible (roles, handlers, templates Jinja2, `group_vars`, tags)
- Inventario estático (`inventories/production/hosts.yml`)

### Sistemas operativos
- AlmaLinux 9 (VMs KVM/libvirt) — familia RedHat, `dnf`
- Ubuntu 24.04 (contenedores LXD) — familia Debian, `apt`

### Alta disponibilidad
- Keepalived (VRRP, VIP flotante, failover MASTER/BACKUP)
- HAProxy (balanceo `roundrobin`, `stats` en puerto 9000)

### Aplicación
- Nginx (backend de aplicación, 3 nodos)

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
│   └── nginx/
│
└── scripts/
    ├── deploy-lab_Hybrid.sh      # provisión VMs + LXC, genera hosts.yml
    └── destroy-lab.sh            # limpieza dinámica de todo lo desplegado
```

---

## 7. Fases completadas y validadas

| Fase | Comando | Hosts | Estado |
|---|---|---|---|
| 01 — Linux Baseline | `ansible-playbook site.yml --tags baseline` | `ha_nodes:storage_nodes` | ✅ Validado |
| 02 — Keepalived (VIP) | `ansible-playbook site.yml --tags keepalived` | `lb_nodes` | ✅ Validado, con test de failover real |
| 03 — HAProxy (LB) | `ansible-playbook site.yml --tags haproxy` | `lb_nodes` | ✅ Validado |
| 04 — Nginx (backend) | `ansible-playbook site.yml --tags nginx` | `ha_nodes` | ✅ Validado |

### Validación end-to-end realizada

```bash
curl http://10.45.223.250
```

Respuesta `200 OK`, rotación confirmada entre `server01`/`server02`/`server03` (balanceo `roundrobin` funcionando).

### Test de failover realizado

Se detuvo `keepalived` en `lb01` (MASTER) con tráfico HTTP activo contra la VIP:

- La VIP migró a `lb02` (BACKUP) correctamente.
- El servicio HTTP no tuvo interrupciones observables durante la transición (0 requests fallidos en el loop de validación).
- Al restaurar `lb01`, recuperó el rol MASTER por preemption (mayor `priority`).

---

## 8. Incidentes reales encontrados durante la implementación

Cada uno de estos fue un problema real de esta fase de construcción, no un ejercicio simulado — quedan documentados porque son la base del futuro catálogo de incidentes formal.

1. **Detección de IP de contenedores LXC fallaba silenciosamente** — el parsing de `lxc info` buscaba un patrón de texto que no coincidía con el formato real de salida. Resuelto migrando a `lxc list --format csv`.
2. **`linux_baseline` y `haproxy`/`keepalived` fallaban en los LXC** — los roles usaban `ansible.builtin.dnf` exclusivamente, incompatible con Ubuntu. Resuelto con tareas condicionadas por `ansible_facts['os_family']`.
3. **Error de sintaxis YAML** — comilla de cierre partida en dos líneas al editar `when:` a mano.
4. **`validate` de un fragmento de configuración de Nginx** — el módulo `template` requiere `%s` en `validate`, y no se puede validar un fragmento de config aislado (`conf.d/*.conf`) con `nginx -t`. Resuelto validando la configuración completa ya ensamblada, en una tarea separada.
5. **VIP en subred incorrecta** — `keepalived_vip` apuntaba a `192.168.122.0/24` (red `default` de libvirt), pero los nodos reales están en `10.45.223.0/24` (`lxdbr0`). La VIP quedaba asignada pero inalcanzable.
6. **Variables de un rol no visibles en otro rol/play** — `keepalived_vip` definida en `roles/keepalived/defaults/main.yml` no estaba disponible durante la play de `haproxy` (plays distintas = scope distinto). Resuelto centralizando la variable en `inventories/production/group_vars/lb_nodes.yml`, que persiste durante todo el playbook run.

---

## 9. Próximo paso

Todavía sin definir cuál de las siguientes dos opciones se implementa primero:

- **MariaDB en `db01`** (nodo único, sin HA — decisión consciente de dejar la replicación de base de datos como proyecto futuro separado).
- **Rol de storage en `storage01`** (actualmente solo tiene el baseline aplicado, sin ningún servicio).

---

## Project ID

```text
SYSTECH-HA-001
```

## Client

```text
ACME Corporation
```
