---

### Documentación: `roles/keepalived/README.md`

```markdown
# Keepalived HA Role — SYSTECH-HA-001

## Descripción
Este rol despliega y configura **Keepalived** mediante el protocolo **VRRP** (Virtual Router Redundancy Protocol) en el grupo de nodos `ha_nodes` (`server01`, `server02`, `server03`). 

Proporciona una **IP Virtual (VIP)** flotante y compartida que conmuta automáticamente entre los nodos en caso de fallo, garantizando alta disponibilidad a nivel de capa de red.

---

## Arquitectura de Red y Prioridades

| Host | Rol VRRP | Prioridad | Interfaz | IP Asignada (DHCP) | IP Virtual (VIP) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **server01** | MASTER | 101 | eth0 | Dynamic | `192.168.122.250/24` |
| **server02** | BACKUP | 100 | eth0 | Dynamic | Flotante |
| **server03** | BACKUP | 99 | eth0 | Dynamic | Flotante |

---

## Estructura del Rol

```text
roles/keepalived/
├── defaults/
│   └── main.yml          # Variables base (VIP, router_id, credenciales)
├── handlers/
│   └── main.yml          # Reinicio del servicio keepalived
├── tasks/
│   └── main.yml          # Instalación de paquetes, templateo y servicio
└── templates/
    └── keepalived.conf.j2 # Plantilla Jinja2 del archivo de configuración VRRP

```

---

## Variables del Rol

Definidas en `defaults/main.yml`:

```yaml
keepalived_interface: "eth0"
keepalived_vip: "192.168.122.250"
keepalived_vip_cidr: "24"
keepalived_router_id: 51
keepalived_auth_pass: "ACME_HA_SECRET"
keepalived_role: "BACKUP"
keepalived_priority: 90

```

Definidas por host en `inventories/production/host_vars/`:

* `server01.yml`: `keepalived_role: MASTER`, `keepalived_priority: 101`
* `server02.yml`: `keepalived_role: BACKUP`, `keepalived_priority: 100`
* `server03.yml`: `keepalived_role: BACKUP`, `keepalived_priority: 99`

---

## Despliegue y Ejecución

Para aplicar únicamente el rol de Keepalived mediante Ansible:

```bash
ansible-playbook site.yml --tags keepalived

```

---

## Verificación y Validaciones

### 1. Comprobar la asignación de la VIP

Verificar qué nodo ostenta actualmente la IP flotante:

```bash
ansible ha_nodes -m command -a "ip addr show eth0"

```

*Resultado esperado:* Únicamente el nodo activo con mayor prioridad (`server01`) debe mostrar la interfaz secundaria `192.168.122.250/24`.

### 2. Prueba de Failover (Simulación de Incidente)

Detener el servicio en el nodo principal para forzar la conmutación:

```bash
ansible server01 -m systemd -a "name=keepalived state=stopped"
ansible ha_nodes -m command -a "ip addr show eth0"

```

*Resultado esperado:* La VIP migra automáticamente a `server02` (Priority 100).

Restablecer el servicio:

```bash
ansible server01 -m systemd -a "name=keepalived state=started"
ansible ha_nodes -m command -a "ip addr show eth0"

```

*Resultado esperado:* `server01` reclama la VIP (*preemption*).

```

```
