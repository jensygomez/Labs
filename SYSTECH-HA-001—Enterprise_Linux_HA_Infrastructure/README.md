# SYSTECH-HA-001 — Enterprise Linux HA Infrastructure

## 1. Descripción

Proyecto práctico de **Systech Consulting** para diseñar, implementar y operar una infraestructura empresarial Linux de alta disponibilidad para un cliente ficticio, **ACME Corporation**.

El proyecto simula el trabajo de un **Junior Linux Systems Administrator / Engineer**, con énfasis en:

- Administración Linux empresarial
- Automatización con Ansible
- Alta disponibilidad
- Storage
- Networking
- Seguridad
- Monitoring
- Logging
- Backup
- Troubleshooting
- Resolución de incidentes de producción

La infraestructura será construida desde el principio con **Ansible e idempotencia** como principios fundamentales.

---

## 2. Objetivo

Diseñar y desplegar una plataforma Linux altamente disponible capaz de soportar aplicaciones empresariales, almacenamiento compartido, monitoreo y servicios de infraestructura.

El objetivo no es solamente instalar servicios, sino desarrollar una metodología completa:

```text
DESIGN
  ↓
AUTOMATE
  ↓
DEPLOY
  ↓
VALIDATE
  ↓
BREAK
  ↓
TROUBLESHOOT
  ↓
FIX
  ↓
AUTOMATE THE FIX
  ↓
VALIDATE IDEMPOTENCY
```

---

## 3. Infraestructura

### Application / HA Nodes

```text
server01
server02
server03
```

Funciones previstas:

- Linux application node
- Nginx
- HAProxy
- Keepalived
- Pacemaker
- Corosync
- Application services
- Monitoring agents
- Centralized logging agents

### Storage Nodes

```text
storage01
storage02
```

Funciones previstas:

- NFS
- Samba
- iSCSI
- RAID
- LVM
- Filesystems
- Storage replication / redundancy
- Backup repositories

---

## 4. Arquitectura conceptual

```text
                         ACME USERS
                              |
                              v
                    +-------------------+
                    |     HAProxy       |
                    |    Keepalived     |
                    |       VIP         |
                    +---------+---------+
                              |
             +----------------+----------------+
             |                |                |
             v                v                v
        +---------+      +---------+      +---------+
        |server01 |      |server02 |      |server03 |
        | HA/App  |      | HA/App  |      | HA/App  |
        +----+----+      +----+----+      +----+----+
             |                |                |
             +----------------+----------------+
                              |
                       STORAGE NETWORK
                              |
                  +-----------+-----------+
                  |                       |
                  v                       v
             +----------+            +----------+
             |storage01 |            |storage02 |
             | NFS      |            | NFS      |
             | Samba    |            | Samba    |
             | iSCSI    |            | iSCSI    |
             +----------+            +----------+
```

---

## 5. Administración

La infraestructura será administrada mediante un **Ansible Control Node**.

```text
                  +------------------+
                  | Ansible Control  |
                  |      Node        |
                  +--------+---------+
                           |
             +-------------+-------------+
             |             |             |
             v             v             v
         server01      server02      server03
             |             |             |
             +-------------+-------------+
                           |
                     storage01
                     storage02
```

El Control Node puede ser el host de laboratorio o una máquina Linux dedicada.

---

## 6. Tecnologías

### Operating System

- Rocky Linux 9 / RHEL-compatible Linux

### Automation

- Ansible
- YAML
- Jinja2
- Ansible Roles
- Ansible Handlers
- Ansible Vault
- Idempotency
- Inventory management

### Linux Administration

- systemd
- journald
- SSH
- sudo
- users/groups
- permissions
- ACLs
- SELinux
- firewalld/nftables
- cron/systemd timers
- package management

### Networking

- IPv4
- DNS
- NTP/Chrony
- routing
- TCP/UDP
- sockets
- troubleshooting with:
  - `ss`
  - `ip`
  - `dig`
  - `getent`
  - `tcpdump`
  - `ping`
  - `traceroute`

### Storage

- RAID
- LVM
- XFS
- ext4
- NFS
- Samba
- iSCSI
- mount management
- `/etc/fstab`

### High Availability

- HAProxy
- Keepalived
- Pacemaker
- Corosync
- VIP / floating IP
- resource management
- failover testing

### Applications

- Nginx
- Apache HTTPD
- PHP-FPM
- MariaDB
- PostgreSQL
- Redis

### Monitoring

- Prometheus
- Node Exporter
- Grafana

### Logging

- rsyslog
- journald
- Loki

### Backup

- Backup repository
- Database backups
- Configuration backups
- Restore testing

---

# 7. Project Structure

```text
SYSTECH-HA-001/
│
├── README.md
├── CHANGELOG.md
├── LICENSE
│
├── ansible.cfg
├── site.yml
├── requirements.yml
│
├── inventories/
│   └── production/
│       ├── hosts.yml
│       ├── group_vars/
│       │   ├── all.yml
│       │   ├── ha.yml
│       │   ├── app.yml
│       │   └── storage.yml
│       │
│       └── host_vars/
│           ├── server01.yml
│           ├── server02.yml
│           ├── server03.yml
│           ├── storage01.yml
│           └── storage02.yml
│
├── playbooks/
│   ├── site.yml
│   ├── baseline.yml
│   ├── networking.yml
│   ├── security.yml
│   ├── storage.yml
│   ├── ha.yml
│   ├── applications.yml
│   ├── monitoring.yml
│   └── backup.yml
│
├── roles/
│   ├── linux_baseline/
│   ├── networking/
│   ├── dns/
│   ├── chrony/
│   ├── ssh_hardening/
│   ├── firewall/
│   ├── selinux/
│   ├── lvm/
│   ├── raid/
│   ├── nfs/
│   ├── samba/
│   ├── iscsi/
│   ├── haproxy/
│   ├── keepalived/
│   ├── pacemaker/
│   ├── nginx/
│   ├── database/
│   ├── monitoring/
│   ├── logging/
│   └── backup/
│
├── templates/
├── files/
├── vars/
├── handlers/
│
├── docs/
│   ├── architecture.md
│   ├── network.md
│   ├── storage.md
│   ├── ha-design.md
│   └── operations.md
│
├── tests/
│   ├── connectivity/
│   ├── idempotency/
│   └── validation/
│
└── incidents/
    ├── INC-1001-nfs-mount/
    ├── INC-1002-vip-failover/
    ├── INC-1003-haproxy-backend/
    ├── INC-1004-selinux/
    └── ...
```

> El árbol representa el estado objetivo del proyecto. Los componentes se crearán progresivamente durante las fases de implementación.

---

# 8. Implementation Phases

## Phase 01 — Project Foundation

**Objetivo:** crear la estructura inicial del proyecto Ansible.

Actividades:

- Git repository
- `ansible.cfg`
- inventory
- `site.yml`
- project documentation
- connectivity validation

---

## Phase 02 — Ansible Foundation

**Objetivo:** establecer una base Ansible reutilizable.

Conceptos:

- inventories
- groups
- host variables
- group variables
- roles
- handlers
- templates
- variables
- facts
- tags
- check mode
- diff mode
- idempotency

---

## Phase 03 — Linux Baseline

Configurar automáticamente:

- hostname
- packages
- users
- groups
- sudo
- SSH
- timezone
- chrony
- basic system configuration

---

## Phase 04 — Networking

Implementar y validar:

- management network
- application network
- storage network
- DNS
- NTP
- routes
- connectivity

---

## Phase 05 — Security Baseline

Implementar:

- SSH hardening
- firewalld/nftables
- SELinux
- sudo policies
- file permissions
- service restrictions

---

## Phase 06 — Storage Foundation

Implementar:

- disks
- partitions
- RAID
- LVM
- filesystems
- mount points
- `/etc/fstab`

---

## Phase 07 — Shared Storage

Implementar:

- NFS
- Samba
- storage permissions
- ACLs
- shared application directories

---

## Phase 08 — iSCSI

Implementar:

- iSCSI target
- iSCSI initiators
- sessions
- persistent storage
- filesystem creation
- troubleshooting

---

## Phase 09 — High Availability

Implementar:

- HAProxy
- Keepalived
- VIP
- Pacemaker
- Corosync
- resource management
- failover testing

---

## Phase 10 — Application Stack

Implementar:

- Nginx
- Apache
- PHP-FPM
- application service
- application shared storage

---

## Phase 11 — Database

Implementar:

- MariaDB and/or PostgreSQL
- database configuration
- backup
- restore
- connectivity
- basic performance validation

---

## Phase 12 — Monitoring

Implementar:

- Prometheus
- Node Exporter
- Grafana
- CPU monitoring
- RAM monitoring
- disk monitoring
- filesystem monitoring
- service availability

---

## Phase 13 — Centralized Logging

Implementar:

- rsyslog
- journald
- centralized log collection
- application logs
- authentication logs
- troubleshooting workflow

---

## Phase 14 — Backup

Implementar:

- configuration backups
- application backups
- database backups
- storage backups
- retention
- restore tests

---

## Phase 15 — Automation Hardening

Objetivo:

```text
Run #1 → changes applied
Run #2 → changed=0
Run #3 → changed=0
```

Validar:

- idempotency
- check mode
- handlers
- failure handling
- safe re-runs
- configuration drift

---

# 9. Production Incident Simulation

Una vez que la infraestructura esté estable, Systech comenzará a generar incidentes controlados.

El objetivo es simular un entorno real de operaciones.

## Incident Catalog

```text
INC-1001 - NFS mount fails after reboot
INC-1002 - VIP not moving between nodes
INC-1003 - HAProxy backend DOWN
INC-1004 - SELinux blocks application
INC-1005 - Disk reaches 100%
INC-1006 - LVM filesystem not mounted
INC-1007 - NFS permissions incorrect
INC-1008 - iSCSI session disconnected
INC-1009 - MariaDB service fails
INC-1010 - DNS resolution broken
INC-1011 - Chrony synchronization failure
INC-1012 - SSH authentication failure
INC-1013 - Firewall blocking application
INC-1014 - Nginx returns 502
INC-1015 - High CPU
INC-1016 - High load average
INC-1017 - Memory exhaustion
INC-1018 - RAID degraded
INC-1019 - Backup failure
INC-1020 - Node unavailable
```

Cada incidente debe contener:

```text
Ticket ID
Priority
Description
Impact
Symptoms
Environment
Initial evidence
Troubleshooting
Root cause
Resolution
Validation
Preventive action
Ansible improvement
```

---

# 10. Incident Philosophy

Los incidentes no deben proporcionar directamente la solución.

El objetivo es desarrollar un workflow de troubleshooting:

```text
OBSERVE
   ↓
COLLECT EVIDENCE
   ↓
FORM HYPOTHESIS
   ↓
TEST
   ↓
IDENTIFY ROOT CAUSE
   ↓
FIX
   ↓
VALIDATE
   ↓
DOCUMENT
   ↓
AUTOMATE
```

Cuando sea posible, la corrección definitiva debe incorporarse a Ansible.

---

# 11. Idempotency Standard

Todo componente automatizado debe poder ejecutarse repetidamente sin producir cambios innecesarios.

Ejemplo:

```bash
ansible-playbook site.yml
```

Primera ejecución:

```text
changed > 0
```

Segunda ejecución:

```text
changed=0
```

Si una ejecución posterior vuelve a producir cambios sin una modificación intencional de configuración, debe investigarse.

---

# 12. Validation

Cada fase debe tener criterios de aceptación.

Ejemplos:

### Linux

```bash
systemctl --failed
```

Resultado esperado:

```text
0 failed units
```

### Networking

```bash
ping
ss
ip
dig
```

### Storage

```bash
lsblk
vgs
lvs
df -h
mount
```

### HA

Simular:

```text
server01 DOWN
```

y comprobar:

```text
VIP → server02
```

### Ansible

Ejecutar dos veces:

```bash
ansible-playbook site.yml
ansible-playbook site.yml
```

La segunda ejecución debe ser idempotente.

---

# 13. Estimated Lab Hours

Objetivo inicial:

| Phase | Hours |
|---|---:|
| 01. Project Foundation | 4 h |
| 02. Ansible Foundation | 8 h |
| 03. Linux Baseline | 8 h |
| 04. Networking + DNS + NTP | 6 h |
| 05. Security Baseline | 8 h |
| 06. LVM + RAID + Filesystems | 8 h |
| 07. NFS + Samba | 8 h |
| 08. iSCSI | 6 h |
| 09. HAProxy + Keepalived | 8 h |
| 10. Pacemaker + Corosync | 8 h |
| 11. Application Stack | 6 h |
| 12. Database | 4 h |
| 13. Monitoring + Logging | 6 h |
| 14. Backup | 4 h |
| 15. Automation Hardening | 4 h |
| 16. Production Incidents | 12 h |
| **TOTAL** | **104 h** |

---

# 14. Project Status

```text
Project: SYSTECH-HA-001
Status: Not Started

Target:
104 laboratory hours

Implementation:
0 / 92 h

Incident Response:
0 / 12 h

Overall:
0 / 104 h
```

---

# 15. Success Criteria

El proyecto será considerado completado cuando:

- [ ] Los 5 servidores estén correctamente configurados.
- [ ] La infraestructura sea administrable mediante Ansible.
- [ ] Los playbooks sean idempotentes.
- [ ] Linux baseline esté automatizado.
- [ ] Networking esté validado.
- [ ] DNS y NTP funcionen correctamente.
- [ ] Security baseline esté implementado.
- [ ] Storage esté correctamente configurado.
- [ ] NFS esté operativo.
- [ ] Samba esté operativo.
- [ ] iSCSI esté operativo.
- [ ] HAProxy esté operativo.
- [ ] Keepalived/VIP esté operativo.
- [ ] Pacemaker/Corosync esté operativo.
- [ ] La aplicación esté disponible.
- [ ] Database esté disponible.
- [ ] Monitoring esté funcionando.
- [ ] Centralized logging esté funcionando.
- [ ] Backup esteja funcionando.
- [ ] Restore haya sido probado.
- [ ] Los 20 incidentes hayan sido resueltos.
- [ ] Las soluciones permanentes relevantes hayan sido automatizadas.
- [ ] Se hayan realizado pruebas de failover.
- [ ] Se haya validado la idempotencia de Ansible.
- [ ] La documentación técnica esté completa.

---

# 16. Skills Developed

Al finalizar este proyecto se espera haber desarrollado experiencia práctica en:

```text
Linux Administration
Networking
DNS
NTP
SSH
Security
SELinux
Firewalls
LVM
RAID
Filesystems
NFS
Samba
iSCSI
HAProxy
Keepalived
Pacemaker
Corosync
Nginx
MariaDB/PostgreSQL
Monitoring
Logging
Backup
Ansible
YAML
Jinja2
Troubleshooting
Incident Management
Root Cause Analysis
```

---

# 17. Project Principle

> **Don't just configure it. Automate it, break it, troubleshoot it, fix it, and make the fix reproducible.**

Este proyecto representa una simulación de trabajo real de un **Linux Systems Administrator / Engineer** dentro de Systech Consulting.

---

## Project ID

```text
SYSTECH-HA-001
```

## Client

```text
ACME Corporation
```

## Project Type

```text
Enterprise Linux Infrastructure
High Availability
Automation
Storage
Operations
Incident Response
```

## Target Lab Time

```text
104 hours
```
