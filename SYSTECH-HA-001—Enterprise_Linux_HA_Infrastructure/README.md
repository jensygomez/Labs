¡Te entiendo perfectamente y tienes toda la razón! El contenedor control node Zero-Trust y la integración con Proxmox son **piezas clave de tu arquitectura** que no podemos omitir.

El `README.md` incluye la arquitectura Zero-Trust, el archivo `Dockerfile`, los scripts `entrypoint.sh` / `control.sh` / `bootstrap.sh`, la gestión del token de API con ACLs en Proxmox y el flujo con Ansible Vault.

Aquí tienes el **`README.md` definitivo e integral**, combinando la documentación de **Proxmox VE + Contenedor de Control Zero-Trust** con el nuevo enfoque de **Roles de Troubleshooting**:

---

```markdown
# SYSTECH-HA-001 — Enterprise Linux HA Infrastructure & Troubleshooting Lab

## 📋 Resumen del Proyecto

Infraestructura de alta disponibilidad y plataforma de **Troubleshooting en Linux (Nivel Mid / P2)** sobre **Proxmox VE**[cite: 1]. Gestionado completamente con **Infraestructura como Código (IaC)** usando **OpenTofu** (fork de Terraform) para el aprovisionamiento de virtualización y **Ansible** para la configuración[cite: 1].

Todo se ejecuta desde un **contenedor Podman rootless "Zero-Trust"** como nodo de control[cite: 1], sin instalar herramientas ni guardar secretos en el host o en texto plano dentro de Git[cite: 1].

---

## 🏗️ Topología de Infraestructura


```

┌─────────────────────────────────────────────────────────────────────────┐
│  HOST: MXLinux (jensygomez@mx)                                          │
│  IP: 192.168.18.8 / Red: 192.168.18.0/24                                │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  CONTENEDOR PODMAN: systech-control (Zero-Trust)                   │  │
│  │  (OpenTofu + Ansible) --network host                              │  │
│  │  HOME=/workspace  |  WORKDIR=/workspace/terraform                 │  │
│  │  Secretos inyectados en runtime desde Ansible Vault               │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                          │                                              │
│                          │ SSH / API (puerto 8006)                      │
│                          ▼                                              │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  PROXMOX VE: homelab (192.168.18.100)                             │  │
│  │  ┌─────────────────────────────────────────────────────────────┐  │  │
│  │  │  vmbr0 → 192.168.18.0/24 (Red LAN)                         │  │  │
│  │  │  vmbr1 → 10.10.10.0/24   (Red Laboratorio HA)              │  │  │
│  │  │                                                             │  │  │
│  │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │  │  │
│  │  │  │  app01 (VM)  │  │  app02 (VM)  │  │  app03 (VM)  │       │  │  │
│  │  │  │ VMID 201     │  │ VMID 202     │  │ VMID 203     │       │  │  │
│  │  │  │ AlmaLinux 9  │  │ AlmaLinux 9  │  │ AlmaLinux 9  │       │  │  │
│  │  │  │ 10.10.10.21  │  │ 10.10.10.22  │  │ 10.10.10.23  │       │  │  │
│  │  │  └──────────────┘  └──────────────┘  └──────────────┘       │  │  │
│  │  │                                                             │  │  │
│  │  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │  │  │
│  │  │  │  lb01 (LXC)  │  │  lb02 (LXC)  │  │ client (LXC) │       │  │  │
│  │  │  │ VMID 301     │  │ VMID 302     │  │ VMID 303     │       │  │  │
│  │  │  │ Ubuntu 24.04 │  │ Ubuntu 24.04 │  │ Ubuntu 24.04 │       │  │  │
│  │  │  │ 10.10.10.31  │  │ 10.10.10.32  │  │ 10.10.10.33  │       │  │  │
│  │  │  └──────────────┘  └──────────────┘  └──────────────┘       │  │  │
│  │  │                                                             │  │  │
│  │  │  ┌──────────────────────────────────────────────────┐       │  │  │
│  │  │  │  storage01 (VM)                                  │       │  │  │
│  │  │  │  VMID 204 | AlmaLinux 9 | 10.10.10.50            │       │  │  │
│  │  │  └──────────────────────────────────────────────────┘       │  │  │
│  │  └─────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘

```

---

## 🎯 Matriz de Roles y Simulación de Tráfico

El laboratorio opera bajo un enfoque de **Roles de Ansible Independientes**. Cada rol configura un escenario técnico y mantiene un flujo de validación extremo a extremo:

| Rol de Ansible | Aplicación en Cluster (VMs `app01-03`) | Función del Storage (`storage01`) | Tráfico Cliente (`client01`) |
| :--- | :--- | :--- | :--- |
| **`role_nfs_lvm_storage`** | Servidor Web Apache (`httpd`) / Nginx. | Exporta volumen LVM vía NFS (`/mnt/shared_webdata`) montado en `/var/www/html`. | Script en loop enviando peticiones HTTP constantes registrando HTTP 200. |
| **`role_systemd_custom_app`** | Microservicio Backend empaquetado como Unit `/etc/systemd/system/backend.service`. | Montaje NFS en `/var/log/remote_app/` para logs de auditoría y transacciones. | Script Python enviando peticiones `POST` tipo API REST con payloads JSON. |
| **`role_haproxy_keepalived`** | Aplicación Web redundante devolviendo el Hostname/IP del nodo activo. | Montaje NFS en `/var/www/app_sessions` para almacenar sesiones compartidas. | Pruebas de concurrencia/failover con `wrk` o `ab` contra la VIP (`10.10.10.100`). |
| **`role_selinux_security`** | API escuchando en puerto no estándar (`8443`) con directorio personalizado (`/opt/secure_app/`). | Recursos NFS etiquetados con booleanos y contextos SELinux (`httpd_use_nfs`). | Peticiones HTTP continuas verificando si SELinux bloquea sockets o archivos. |
| **`role_pam_sudoers_users`** | Daemons / Timers administrados por usuarios no privilegiados dedicados (`appworker`). | Montaje NFS centralizado `/home/shared_users/` para Homes y claves SSH públicas. | Conexiones automáticas por SSH validando el uso seguro de `sudo` sin contraseña. |
| **`role_firewalld_nftables`** | Base de Datos (PostgreSQL / MariaDB) ajustando parámetros en `/etc/sysctl.d/`. | Servidor iSCSI / NFS exclusivo para datos DB (`/var/lib/pgsql` o `/var/lib/mysql`). | Generador de consultas SQL continuas comprobando puertos, drops o bottlenecks. |

---

## 🐳 Arquitectura del Nodo de Control: Contenedor Zero-Trust

### Filosofía

> **Cero secretos en el host. Cero secretos en Git en texto plano. Todo vive cifrado en un Ansible Vault y se inyecta de forma efímera solo dentro de la memoria del contenedor, en cada arranque.**[cite: 1]

### Componentes

| Archivo | Rol |
| :--- | :--- |
| `dockerfile/Dockerfile` | Define la imagen `systech-control` (Ubuntu 22.04 + OpenTofu + Ansible + herramientas de red). Usuario no-root `jensyg` (UID 1000), `HOME=/workspace`.[cite: 1] |
| `dockerfile/entrypoint.sh` | Se ejecuta al arrancar el contenedor. Desencripta `secrets/systech-secrets.yml` con `ansible-vault view --ask-vault-pass`, escribe la llave privada SSH en `~/.ssh/id_systech_control`, genera `~/.ssh/config`, y exporta `TF_VAR_*` para OpenTofu.[cite: 1] |
| `dockerfile/bootstrap.sh` | Script de **inicialización única**: genera el par de llaves SSH `id_systech_control`, pide el token de Proxmox, arma el YAML en texto plano y lo cifra con `ansible-vault encrypt`, dejando `secrets/systech-secrets.yml`. Solo se corre una vez (o al rotar credenciales).[cite: 1] |
| `dockerfile/control.sh` | Script de uso diario: construye la imagen si no existe y lanza el contenedor con `podman run`, montando el proyecto y pasando las variables de entorno no-secretas (`TF_VAR_proxmox_api_url`).[cite: 1] |
| `secrets/systech-secrets.yml` | Vault cifrado con `ansible-vault`. Contiene `proxmox_api_token`, `ssh_private_key`, `ssh_public_key`. **Seguro de subir a Git** porque está cifrado.[cite: 1] |

### Flujo de arranque


```

control.sh
└─ podman run (imagen systech-control, --network host, --userns=keep-id)
└─ entrypoint.sh (ENTRYPOINT del Dockerfile)
├─ ansible-vault view --ask-vault-pass secrets/systech-secrets.yml
├─ escribe ~/.ssh/id_systech_control (0600)
├─ escribe ~/.ssh/config
├─ exporta TF_VAR_proxmox_api_token
├─ exporta TF_VAR_proxmox_ssh_private_key
├─ exporta TF_VAR_ssh_public_key
└─ exec "$@"  (normalmente /bin/bash)

```

### Identidad SSH dedicada

Se utiliza una identidad **exclusiva y efímera**: `id_systech_control` (ed25519), generada por `bootstrap.sh`, autorizada en Proxmox (`authorized_keys` de root) e inyectada en las VMs/LXC vía cloud-init (`var.ssh_public_key`)[cite: 1].

La llave privada **nunca toca el disco del host** — solo existe dentro del filesystem efímero del contenedor (`--rm`), escrita por `entrypoint.sh` en cada arranque y destruida al salir[cite: 1].

---

## 🖥️ Proxmox VE & Especificaciones

| Parámetro | Valor |
| :--- | :--- |
| Nodo Proxmox | `homelab`[cite: 1] |
| IP API Proxmox | `https://192.168.18.100:8006/`[cite: 1] |
| Usuario API | `root@pam!systech-vault-token`[cite: 1] |
| Bridge `vmbr0` | Red LAN 192.168.18.0/24[cite: 1] |
| Bridge `vmbr1` | Red laboratorio 10.10.10.0/24[cite: 1] |
| SO Máquinas Virtuales | AlmaLinux 9 GenericCloud[cite: 1] |
| SO Contenedores LXC | Ubuntu 24.04[cite: 1] |

> **Nota de Seguridad en Proxmox:** Los tokens de API requieren su propia entrada ACL activa en `/etc/pve/user.cfg` con Privilege Separation (`privsep=1`) deshabilitada o asociada expresamente al rol Administrator (`pveum acl modify / --tokens 'root@pam!systech-vault-token' --roles Administrator`)[cite: 1].

---

## 🔑 Gestión de Secretos y Cero Hardcodeo

| Método | Uso | Notas |
| :--- | :--- | :--- |
| `secrets/systech-secrets.yml` | ✅ Token API + llaves SSH | Cifrado con Ansible Vault, seguro en Git, desencriptado en runtime por `entrypoint.sh`[cite: 1]. |
| Variables de entorno `TF_VAR_*` | ✅ Inyección efímera a OpenTofu | Cero secretos en disco fuera del contenedor[cite: 1]. |
| `terraform.tfvars` | ✅ Solo parámetros NO secretos | Contiene únicamente `proxmox_api_url` y `target_node`[cite: 1]. |
| `group_vars/all/vars.yml` | ✅ Variables globales no sensibles | Redes, nombres de usuarios, rutas de montaje. |
| `group_vars/all/vault.yml` | ✅ Secretos de Ansible | Passwords de usuarios, credenciales de DB. |

---

## 📁 Estructura del Proyecto


```

SYSTECH-HA-001—Enterprise_Linux_HA_Infrastructure/
├── ansible.cfg
├── dockerfile/
│   ├── bootstrap.sh             # Inicialización única: genera llave + cifra Vault
│   ├── control.sh               # Uso diario: construye imagen + lanza contenedor
│   ├── entrypoint.sh            # Desencripta Vault e inyecta secretos en runtime
│   └── Dockerfile               # Imagen del nodo de control (Zero-Trust)
├── inventories/
│   └── production/
│       ├── group_vars/
│       │   ├── all/
│       │   │   ├── vars.yml     # Variables no secretas de Ansible
│       │   │   └── vault.yml    # Secretos cifrados para los playbooks
│       │   └── lb_nodes.yml
│       └── hosts.yml
├── README.md                     # ← Este archivo
├── roles/
│   ├── role_lb_ha/                   # ROL BASE: Ingress HAProxy + Keepalived + Traffic Generator
│   ├── role_nfs_lvm_storage/         # Módulo 1: Storage NFS/LVM + Web Apache
│   ├── role_systemd_custom_app/      # Módulo 2: Custom Systemd Unit + Logs NFS
│   ├── role_network_kernel_tuning/   # Módulo 3: Kernel Parameters (sysctl) + Sockets Tuning
│   ├── role_selinux_security/        # Módulo 4: SELinux Policies + Custom Ports
│   ├── role_pam_sudoers_users/       # Módulo 5: PAM + SSH Hardening + NFS Homes
│   └── role_firewalld_nftables/      # Módulo 6: Firewalld + NFTables + DB Storage
├── secrets/
│   └── systech-secrets.yml       # Vault principal: Token Proxmox + SSH Key
├── site.yml
└── terraform/
├── lxc.tf                    # Recursos LXC (lb01, lb02, client)
├── main.tf                   # Recursos VM (app01, app02, app03, storage01)
├── outputs.tf
├── providers.tf
├── terraform.tfvars          # Solo parámetros NO secretos
└── variables.tf

```

---

## ✅ Checklist: Recuperar el entorno en una PC nueva

1. Clonar el repositorio manteniendo `secrets/systech-secrets.yml` cifrado[cite: 1].
2. Configurar la ruta estática hacia la red del laboratorio en el Host:
   ```bash
   sudo nmcli connection modify "<nombre-conexion>" +ipv4.routes "10.10.10.0/24 192.168.18.100"
   sudo nmcli connection up "<nombre-conexion>"

```

3. Ejecutar `./dockerfile/control.sh` e ingresar la contraseña del Vault.


4. Ejecutar el aprovisionamiento IaC:
```bash
tofu init
tofu apply

```



```

---


```
