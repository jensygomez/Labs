Aquí tienes un `README.md` completo y estructurado como referencia de contexto para cualquier sesión de IA futura. Cubre todo lo que hemos construido hasta ahora.

```markdown
# SYSTECH-HA-001 — Enterprise Linux HA Infrastructure

## 📋 Resumen del Proyecto

Infraestructura de alta disponibilidad sobre **Proxmox VE** gestionada completamente con
**Infraestructura como Código (IaC)** usando **OpenTofu** (fork de Terraform) para el
aprovisionamiento y **Ansible** para la configuración. Todo se ejecuta desde un
**contenedor Podman** como nodo de control, sin instalar herramientas en el host.

---

## 🏗️ Topología de Infraestructura

```
┌─────────────────────────────────────────────────────────────────────┐
│  HOST: MXLinux (jensyg@mx)                                         │
│  IP: 192.168.18.8 / Red: 192.168.18.0/24                          │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  CONTENEDOR PODMAN: systech-control                           │  │
│  │  (OpenTofu + Ansible) --network host                          │  │
│  │  HOME=/workspace  |  WORKDIR=/workspace/terraform             │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                          │                                          │
│                          │ SSH / API (puerto 8006)                  │
│                          ▼                                          │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  PROXMOX VE: homelab (192.168.18.100)                        │  │
│  │  ┌─────────────────────────────────────────────────────────┐  │  │
│  │  │  vmbr0 → 192.168.18.0/24 (Red LAN)                     │  │  │
│  │  │  vmbr1 → 10.10.10.0/24   (Red Laboratorio HA)          │  │  │
│  │  │                                                         │  │  │
│  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐              │  │  │
│  │  │  │ server01 │  │ server02 │  │ server03 │              │  │  │
│  │  │  │ VMID 201 │  │ VMID 202 │  │ VMID 203 │              │  │  │
│  │  │  │ Alma 9   │  │ Alma 9   │  │ Alma 9   │              │  │  │
│  │  │  │.10.10.21 │  │.10.10.22 │  │.10.10.23 │              │  │  │
│  │  │  └──────────┘  └──────────┘  └──────────┘              │  │  │
│  │  │                                                         │  │  │
│  │  │  [PENDIENTE] LXC containers                             │  │  │
│  │  └─────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

### Ruta estática en el host MXLinux

Para que el host alcance la red `10.10.10.0/24` de las VMs:

```bash
# Configurar con NetworkManager (permanente)
sudo nmcli connection modify "Wired connection 1" \
  +ipv4.routes "10.10.10.0/24 192.168.18.100"
sudo nmcli connection up "Wired connection 1"
```

---

## 🔐 Gestión de Claves SSH (SECCIÓN CRÍTICA)

### Llaves existentes en el host

| Archivo | Tipo | Uso |
| :--- | :--- | :--- |
| `~/.ssh/id_lxd_fleet` | ed25519 (privada) | Flota LXD + Proxmox + VMs del laboratorio |
| `~/.ssh/id_lxd_fleet.pub` | ed25519 (pública) | Inyectada en VMs vía cloud-init |
| `~/.ssh/id_github` | ed25519 (privada) | Solo para GitHub |
| `~/.ssh/config` | Config SSH | Reglas por host/subred |

### Llave pública del laboratorio

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN+gsGnVlOOJXtW6Wz87hc1CPhOz++T2lCoB6F3Eksbg jensyg@lxd-fleet
```

### Configuración SSH del host (`~/.ssh/config`)

```ssh-config
# --- GitHub ---
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_github
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new

# --- Flota LXD (nodos node-1 a node-10) ---
Host node-*
    User root
    IdentityFile ~/.ssh/id_lxd_fleet
    IdentitiesOnly yes
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

# --- Acceso genérico a la subred de laboratorio LXD ---
Host 10.45.223.*
    User root
    IdentityFile ~/.ssh/id_lxd_fleet
    IdentitiesOnly yes
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

# --- Laboratorio HA Proxmox (SYSTECH-HA-001) ---
Host 10.10.10.*
    User ansible
    IdentityFile ~/.ssh/id_lxd_fleet
    IdentitiesOnly yes
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

### ⚠️ Problema conocido: SSH dentro del contenedor

Dentro del contenedor Podman, SSH expande `~` incorrectamente cuando el
working directory es `/workspace/terraform`. La llave está en
`/workspace/.ssh/id_lxd_fleet` pero SSH busca en
`/workspace/terraform/.ssh/id_lxd_fleet`.

**Workaround actual:**
```bash
# Ejecutar SSH desde /workspace en lugar de /workspace/terraform
cd /workspace
ssh -F /workspace/.ssh/config 10.10.10.21 hostname
```

**Alternativas exploradas:**
- `sed -i 's|~\.ssh|/workspace/.ssh|g'` → No funcionó porque el config
  se monta desde el host y los cambios no persisten.
- Montar archivos individuales con `:ro` → Falló porque SSH necesita
  escribir `known_hosts`.
- Montar toda la carpeta `.ssh` sin `:ro` → Funciona pero SSH aún
  expande `~` incorrectamente desde subdirectorios.

**Opciones pendientes para resolver definitivamente:**
1. Crear un `Dockerfile` que copie el config SSH y reemplace `~` por
   rutas absolutas durante el build.
2. Usar un script de entrada (`entrypoint.sh`) que haga `sed` al
   arrancar el contenedor.
3. Generar un config SSH dedicado para contenedores con rutas absolutas
   y montarlo como archivo separado.
4. Usar `ANSIBLE_SSH_ARGS="-i /workspace/.ssh/id_lxd_fleet"` para
   forzar la ruta de la llave en Ansible sin depender del config.

### Autenticación SSH en Proxmox (para el provider de Tofu)

El provider `bpg/proxmox` usa SSH internamente para subir snippets.
La llave `id_lxd_fleet.pub` fue autorizada en Proxmox:

```bash
ssh-copy-id -i ~/.ssh/id_lxd_fleet.pub root@192.168.18.100
```

El contenido de la llave privada se pasa como variable de entorno:
```bash
export TF_VAR_proxmox_ssh_private_key="$(cat $HOME/.ssh/id_lxd_fleet)"
```

---

## 🖥️ Proxmox VE

| Parámetro | Valor |
| :--- | :--- |
| Nodo | `homelab` |
| IP API | `https://192.168.18.100:8006/` |
| Versión | 7.0.14-12-pve (Debian based) |
| Usuario API | `root@pam!tofu-token` |
| SSL | Certificado autofirmado (requiere `insecure = true`) |
| Storage `local` | ISO, Snippets habilitados |
| Storage `local-lvm` | Disk images |
| Bridge `vmbr0` | Red LAN 192.168.18.0/24 |
| Bridge `vmbr1` | Red laboratorio 10.10.10.0/24 |

### Limitaciones de esta versión de Proxmox

- `qm agent <vmid> exec-command` **NO está soportado**.
  Comandos disponibles: `get-users`, `network-get-interfaces`,
  `get-host-name`, `ping`, `info`, etc.
- `proxmox_virtual_environment_download_file` está **deprecado**.
  Usar `proxmox_download_file` en su lugar.
- La descarga de archivos `.qcow2` requiere extensión `.iso` en
  `file_name` (Proxmox valida la extensión).

---

## 🐳 Nodo de Control: Contenedor Podman

### Características

| Parámetro | Valor |
| :--- | :--- |
| Runtime | Podman (rootless) |
| Imagen | `systech-control` (Ubuntu 22.04) |
| Red | `--network host` (comparte red del host) |
| User namespace | `--userns=keep-id` (UID 1000) |
| HOME | `/workspace` |
| WORKDIR | `/workspace/terraform` |
| Usuario interno | `jensyg` (UID 1000, NO root) |
| Ciclo de vida | Efímero (`--rm`) |

### Software instalado en la imagen

- OpenTofu (última versión vía script oficial)
- Ansible + ansible-lint (vía pip)
- Python 3, curl, jq, git, openssh-client, iputils-ping

### Script de lanzamiento: `dockerfile/control.sh`

```bash
#!/bin/bash
set -e

# Variables de entorno para OpenTofu
export TF_VAR_proxmox_api_url="https://192.168.18.100:8006/"
export TF_VAR_proxmox_api_token="root@pam!tofu-token=6e1122a5-702d-439f-95f0-b206be6e6a10"
export TF_VAR_proxmox_ssh_private_key="$(cat $HOME/.ssh/id_lxd_fleet)"
export TF_VAR_ssh_public_key="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN+gsGnVlOOJXtW6Wz87hc1CPhOz++T2lCoB6F3Eksbg jensyg@lxd-fleet"

IMAGE_NAME="systech-control"
CONTAINER_NAME="systech-ha-control"

if ! podman image inspect $IMAGE_NAME >/dev/null 2>&1; then
    podman build -t $IMAGE_NAME -f dockerfile/Dockerfile .
fi

podman run -it --rm \
    --name $CONTAINER_NAME \
    --network host \
    --userns=keep-id \
    -v "$(pwd):/workspace:Z" \
    -v "$HOME/.ssh:/workspace/.ssh" \
    -w "/workspace/terraform" \
    -e HOME=/workspace \
    -e TF_VAR_proxmox_api_url \
    -e TF_VAR_proxmox_api_token \
    -e TF_VAR_ssh_public_key \
    -e TF_VAR_proxmox_ssh_private_key \
    -e ANSIBLE_HOST_KEY_CHECKING=False \
    -e ANSIBLE_CONFIG=/workspace/ansible.cfg \
    -e ANSIBLE_SSH_ARGS="-F /workspace/.ssh/config -o IdentitiesOnly=yes" \
    -e ANSIBLE_SSH_COMMON_ARGS="-F /workspace/.ssh/config" \
    $IMAGE_NAME \
    /bin/bash
```

### Variables de entorno clave dentro del contenedor

| Variable | Propósito |
| :--- | :--- |
| `HOME=/workspace` | SSH busca config en `/workspace/.ssh/config` |
| `TF_VAR_*` | Inyectan secretos a OpenTofu sin archivos en disco |
| `ANSIBLE_SSH_ARGS` | Fuerzan el config SSH para Ansible |
| `ANSIBLE_HOST_KEY_CHECKING=False` | Evita prompts de host key |

---

## ⚙️ OpenTofu / Terraform

### Provider

```hcl
# terraform/providers.tf
provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = var.proxmox_api_token
  insecure  = true  # Certificado autofirmado

  ssh {
    agent       = false
    username    = "root"
    private_key = var.proxmox_ssh_private_key  # Contenido, no ruta
  }
}
```

### Recursos actuales

| Recurso | Tipo | Estado |
| :--- | :--- | :--- |
| `proxmox_download_file.almalinux_cloud_image` | ISO AlmaLinux 9 | ✅ Creado |
| `proxmox_virtual_environment_file.cloud_user_config` | Snippet cloud-init | ✅ Creado (1 por VM) |
| `proxmox_virtual_environment_vm.almalinux_cluster` | 3 VMs | ✅ Creadas |

### Imagen base

```
URL: https://repo.almalinux.org/almalinux/9/cloud/x86_64/images/AlmaLinux-9-GenericCloud-latest.x86_64.qcow2
file_name: almalinux-9-cloudinit.iso  (extensión .iso requerida por Proxmox)
```

### Variables del cluster (`terraform/variables.tf`)

```hcl
variable "cluster_nodes" {
  type = map(object({
    vmid   = number
    ip     = string
    cores  = number
    memory = number
  }))
  default = {
    "server01" = { vmid = 201, ip = "10.10.10.21/24", cores = 1, memory = 1536 }
    "server02" = { vmid = 202, ip = "10.10.10.22/24", cores = 1, memory = 1536 }
    "server03" = { vmid = 203, ip = "10.10.10.23/24", cores = 1, memory = 1536 }
  }
}
```

### Cloud-Init (snippet por VM)

Crea usuario `ansible` con sudo sin contraseña e inyecta la llave SSH.
Incluye `hostname` y `preserve_hostname: false` para forzar el nombre.

### Comandos OpenTofu

```bash
tofu init                    # Inicializar providers
tofu plan -out=tfplan        # Planificar (siempre con -out)
tofu apply tfplan            # Aplicar plan guardado
tofu destroy -auto-approve   # Destruir todo
tofu output                  # Ver outputs
tofu refresh                 # Refrescar estado
```

### ⚠️ Notas importantes de OpenTofu

- `terraform.tfvars` tiene **MAYOR prioridad** que variables de entorno
  `TF_VAR_*`. Nunca dejar placeholders en tfvars.
- El archivo `tfplan` queda **obsoleto** si cambia la configuración del
  provider. Regenerar con `tofu plan -out=tfplan`.
- El provider `bpg/proxmox` usa SSH internamente para snippets. La llave
  privada debe pasarse como **contenido** (string), no como ruta de archivo.
- `content_type = "snippets"` debe estar habilitado en el storage `local`
  de Proxmox (Datacenter → Storage → local → Content → Snippets).

---

## 📁 Estructura del Proyecto

```
SYSTECH-HA-001—Enterprise_Linux_HA_Infrastructure/
├── ansible.cfg
├── dockerfile/
│   ├── control.sh              # Script de lanzamiento del contenedor
│   └── Dockerfile              # Imagen del nodo de control
├── inventories/
│   └── production/
│       ├── group_vars/
│       │   ├── all/vault.yml   # Secretos cifrados con ansible-vault
│       │   └── lb_nodes.yml
│       ├── hosts.yml
│       └── host_vars/
│           ├── lb01.yml
│           └── lb02.yml
├── README.md                   # ← Este archivo
├── requirements.yml            # Roles/galaxy de Ansible
├── roles/
│   ├── app/                    # Aplicación Flask/Gunicorn
│   ├── database/               # MariaDB
│   ├── db_seed/                # Seed de base de datos
│   ├── haproxy/                # Load balancer HAProxy
│   ├── keepalived/             # VIP failover con VRRP
│   ├── linux_baseline/         # Configuración base del SO
│   └── nginx/                  # Reverse proxy
├── scripts/
│   ├── deploy-lab_Hybrid.sh
│   ├── deploy-lab.sh
│   └── destroy-lab.sh
├── site.yml                    # Playbook principal de Ansible
├── terraform/
│   ├── cloud-init/user-data.yml
│   ├── main.tf                 # Recursos de Proxmox
│   ├── outputs.tf              # IPs del cluster
│   ├── providers.tf            # Provider bpg/proxmox
│   ├── terraform.tfvars        # Variables (NO subir a git con secretos)
│   ├── terraform.tfvars.example
│   └── variables.tf            # Definición de variables
└── variables_del_proyecto.txt
```

---

## 📊 Estado Actual del Proyecto

### ✅ Completado

- [x] Host MXLinux configurado con ruta estática a 10.10.10.0/24
- [x] Proxmox accesible vía API y SSH
- [x] Llave SSH `id_lxd_fleet` autorizada en Proxmox (root)
- [x] Contenedor Podman como nodo de control (OpenTofu + Ansible)
- [x] OpenTofu inicializado con provider `bpg/proxmox v0.111.1`
- [x] Imagen AlmaLinux 9 descargada en Proxmox
- [x] Snippets cloud-init creados (1 por VM con hostname)
- [x] 3 VMs creadas: server01 (201), server02 (202), server03 (203)
- [x] IPs estáticas asignadas: 10.10.10.21, .22, .23
- [x] Usuario `ansible` creado en las VMs con sudo NOPASSWD
- [x] Llave SSH inyectada en las VMs vía cloud-init
- [x] SSH funcional desde el contenedor a las 3 VMs
- [x] QEMU Guest Agent activo en las VMs

### 🔧 En progreso / Con warnings

- [ ] Hostname de VMs reporta `localhost` (corregido en snippet, pendiente recrear)
- [ ] Warning "no such identity" en SSH dentro del contenedor
  (SSH expande `~` como `/workspace/terraform` en lugar de `/workspace`)

### 📋 Pendiente

- [ ] Recrear VMs con snippet corregido (hostname + llave correcta)
- [ ] Crear contenedores LXC adicionales en Proxmox
- [ ] Verificar inventario Ansible (`hosts.yml`) contra IPs reales
- [ ] Ejecutar `ansible-playbook site.yml` (roles: baseline, haproxy,
      keepalived, app, database, db_seed, nginx)
- [ ] Configurar `ansible-vault` para secretos de producción
- [ ] Probar failover de keepalived (VIP)
- [ ] Probar balanceo de HAProxy
- [ ] Documentar procedimientos de disaster recovery

---

## 🐛 Troubleshooting

### Error: `tls: failed to verify certificate`
**Causa:** Proxmox usa certificado autofirmado.
**Solución:** Añadir `insecure = true` en el bloque `provider "proxmox"`.

### Error: `wrong file extension` al descargar qcow2
**Causa:** Proxmox valida extensión según `content_type`.
**Solución:** Usar `file_name = "archivo.iso"` aunque sea qcow2.

### Error: `datastore does not support content type "snippets"`
**Causa:** Storage `local` no tiene Snippets habilitado.
**Solución:** Proxmox GUI → Datacenter → Storage → local → Edit → Content → ✅ Snippets.

### Error: `unable to authenticate user "root" over SSH`
**Causa:** Llave pública no autorizada en Proxmox.
**Solución:** `ssh-copy-id -i ~/.ssh/id_lxd_fleet.pub root@192.168.18.100`

### Error: `Permission denied` al leer archivos en contenedor
**Causa:** `--userns=keep-id` mapea UID pero SELinux/permisos interfieren.
**Solución:** Montar archivos individuales sin `:Z` en MXLinux (no usa SELinux).

### Error: `Saved plan is stale`
**Causa:** El estado cambió después de crear el plan.
**Solución:** Regenerar con `tofu plan -out=tfplan`.

### Error: `no such identity: /workspace/terraform/.ssh/id_lxd_fleet`
**Causa:** SSH expande `~` usando el working directory actual.
**Solución temporal:** Ejecutar SSH desde `/workspace`, no desde subdirectorios.
**Solución definitiva:** Pendiente (ver sección SSH).

### Warning: `REMOTE HOST IDENTIFICATION HAS CHANGED`
**Causa:** VM recreada con nueva host key.
**Solución:** `ssh-keygen -f "/workspace/.ssh/known_hosts" -R "10.10.10.21"`

---

## 🔑 Alternativas de Gestión de Secretos

| Método | Uso actual | Notas |
| :--- | :--- | :--- |
| Variables de entorno `TF_VAR_*` | ✅ Tokens y llaves de Tofu | Efímero, no toca disco |
| `terraform.tfvars` | ⚠️ Con precaución | Mayor prioridad que env vars |
| `ansible-vault` | ✅ Secretos de Ansible | `inventories/production/group_vars/all/vault.yml` |
| HashiCorp Vault | ❌ No usado | Overkill para laboratorio |
| SOPS + age/GPG | ❌ No usado | Alternativa moderna a ansible-vault |

---

## 📝 Convenciones

- **Usuario de despliegue:** `ansible` (sudo NOPASSWD)
- **Llave SSH:** `id_lxd_fleet` (ed25519)
- **Red de laboratorio:** `10.10.10.0/24` (gateway `10.10.10.1` = Proxmox vmbr1)
- **Red LAN:** `192.168.18.0/24`
- **SO de VMs:** AlmaLinux 9 GenericCloud
- **SO de Proxmox:** Debian (PVE 7.x)
- **SO del host:** MXLinux (Debian-based, sin SELinux, con AppArmor)
- **Runtime de contenedores:** Podman (rootless, sin Docker)
```

Este documento captura todo el contexto técnico, las decisiones tomadas, los problemas resueltos y los pendientes. Cualquier IA que lo lea podrá continuar exactamente donde lo dejamos. 🎯

¿Quieres que ajuste alguna sección o añada algo más antes de los LXC?
