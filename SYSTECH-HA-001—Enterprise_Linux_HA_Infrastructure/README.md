# SYSTECH-HA-001 — Enterprise Linux HA Infrastructure

## 📋 Resumen del Proyecto

Infraestructura de alta disponibilidad sobre **Proxmox VE** gestionada completamente con
**Infraestructura como Código (IaC)** usando **OpenTofu** (fork de Terraform) para el
aprovisionamiento y **Ansible** para la configuración. Todo se ejecuta desde un
**contenedor Podman rootless "Zero-Trust"** como nodo de control, sin instalar
herramientas ni guardar secretos en el host.

---

## 🏗️ Topología de Infraestructura
```
┌─────────────────────────────────────────────────────────────────────┐
│  HOST: MXLinux (jensygomez@mx)                                         │
│  IP: 192.168.18.8 / Red: 192.168.18.0/24                          │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  CONTENEDOR PODMAN: systech-control (Zero-Trust)               │  │
│  │  (OpenTofu + Ansible) --network host                          │  │
│  │  HOME=/workspace  |  WORKDIR=/workspace/terraform             │  │
│  │  Secretos inyectados en runtime desde Ansible Vault           │  │
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
│  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐              │  │  │
│  │  │  │  lxc01   │  │  lxc02   │  │  zabbix  │              │  │  │
│  │  │  │ VMID 301 │  │ VMID 302 │  │ VMID 401 │              │  │  │
│  │  │  │ Ubuntu   │  │ Ubuntu   │  │ Ubuntu   │              │  │  │
│  │  │  │.10.10.31 │  │.10.10.32 │  │.10.10.40 │              │  │  │
│  │  │  └──────────┘  └──────────┘  └──────────┘              │  │  │
│  │  └─────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

### Estado actual (✅ funcional al 100%)

- 3 VMs AlmaLinux 9 (`server01/02/03`) creadas y accesibles por SSH con el
  usuario `ansible`.
- 2 LXC Ubuntu 24.04 (`lxc01`, `lxc02`) creados, con usuario `ansible`
  provisionado vía `null_resource` + `remote-exec`.
- Autenticación API de Proxmox funcional vía token con ACL correcta.
- Todo el ciclo (`control.sh` → `entrypoint.sh` → `tofu apply`) reproducible
  en una laptop nueva siguiendo el checklist de este documento.
- Servidor de Monitoreo Zabbix Server 7.0 LTS (zabbix - 10.10.10.40) provisionado y funcional con Nginx, PHP 8.3-FPM y PostgreSQL 16 (UTF-8).

---

## 🐳 Arquitectura del Nodo de Control: Contenedor Zero-Trust

Esta sección es **nueva** — no existía en la versión anterior del README y
documenta el rediseño completo tras el formateo de la laptop.

### Filosofía

> **Cero secretos en el host. Cero secretos en Git en texto plano. Todo
> vive cifrado en un Ansible Vault y se inyecta de forma efímera solo
> dentro de la memoria del contenedor, en cada arranque.**

### Componentes

| Archivo | Rol |
| :--- | :--- |
| `dockerfile/Dockerfile` | Define la imagen `systech-control` (Ubuntu 22.04 + OpenTofu + Ansible + herramientas de red). Usuario no-root `jensyg` (UID 1000), `HOME=/workspace`. |
| `dockerfile/entrypoint.sh` | Se ejecuta al arrancar el contenedor. Desencripta `secrets/systech-secrets.yml` con `ansible-vault view --ask-vault-pass`, escribe la llave privada SSH en `~/.ssh/id_systech_control`, genera `~/.ssh/config`, y exporta `TF_VAR_*` para OpenTofu. |
| `dockerfile/bootstrap.sh` | Script de **inicialización única**: genera el par de llaves SSH `id_systech_control`, pide el token de Proxmox, arma el YAML en texto plano y lo cifra con `ansible-vault encrypt`, dejando `secrets/systech-secrets.yml`. Solo se corre una vez (o al rotar credenciales). |
| `dockerfile/control.sh` | Script de uso diario: construye la imagen si no existe y lanza el contenedor con `podman run`, montando el proyecto y pasando las variables de entorno no-secretas (`TF_VAR_proxmox_api_url`). |
| `secrets/systech-secrets.yml` | Vault cifrado con `ansible-vault`. Contiene `proxmox_api_token`, `ssh_private_key`, `ssh_public_key`. **Seguro de subir a Git** porque está cifrado. |

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

Se abandonó el uso de la llave genérica `id_lxd_fleet` (compartida con la
flota LXD del host) para el nodo de control. Ahora existe una identidad
**exclusiva y efímera**: `id_systech_control` (ed25519), generada una sola
vez por `bootstrap.sh`, autorizada en Proxmox (`authorized_keys` de root) e
inyectada en las VMs/LXC vía cloud-init (`var.ssh_public_key`).

La llave privada **nunca toca el disco del host** — solo existe dentro del
filesystem efímero del contenedor (`--rm`), escrita por `entrypoint.sh` en
cada arranque y destruida al salir.

---

## 🐛 Troubleshooting de esta sesión (post-formateo de laptop)

Registro completo de los 4 problemas encontrados al recuperar el entorno
en la laptop reformateada, en el orden en que aparecieron.

### 1. Error 401 en la API de Proxmox — Token sin ACL (Privilege Separation)

**Síntoma:** `curl` al endpoint `/api2/json/nodes` devolvía 401 o vacío,
pese a que la conexión SSH directa a Proxmox funcionaba perfectamente.

**Causa raíz:** en Proxmox, los tokens de API tienen **Privilege
Separation (`privsep`) activado por defecto**. Esto significa que un
token **no hereda automáticamente** los permisos del usuario que lo creó
(ni siquiera si es `root@pam`) — necesita su **propia entrada ACL**.
`pveum acl list` estaba completamente vacío: cero ACLs en todo el sistema.

**Diagnóstico (vía SSH, sin tocar la GUI):**
```bash
ssh root@192.168.18.100 "pveum user token list root@pam"
ssh root@192.168.18.100 "pveum acl list"
ssh root@192.168.18.100 "cat /etc/pve/user.cfg | grep -i token"
```

**Solución:**
```bash
ssh root@192.168.18.100 \
  "pveum acl modify / --tokens 'root@pam!<nombre-token>' --roles Administrator"
```

**Nota de portabilidad:** esta corrección vive en `/etc/pve/user.cfg`
**dentro del servidor Proxmox**, no en la laptop. No hay que repetirla al
formatear o cambiar de PC, solo si se reinstala Proxmox o se borra el
token.

### 2. Desajuste de nombres entre el Vault y el token real en Proxmox

**Síntoma:** tras arreglar la ACL, seguía fallando. El `echo
"$TF_VAR_proxmox_api_token"` mostraba `root@pam!systech-vault-token=...`
pero el token con ACL configurada se llamaba `token-proxmox`.

**Causa raíz:** el Vault tenía guardado el nombre de un token que nunca
se creó con ACL, o que ya no coincidía con lo que existía en Proxmox
(múltiples intentos previos habían dejado nombres inconsistentes:
`tofu-token`, `token-proxmox`, `systech-vault-token`).

**Solución:** se creó un token nuevo con el nombre exacto que ya tenía el
Vault, se le asignó la ACL, y se actualizó el UUID en el Vault:
```bash
ssh root@192.168.18.100 \
  "pveum user token add root@pam systech-vault-token --privsep 1"
ssh root@192.168.18.100 \
  "pveum acl modify / --tokens 'root@pam!systech-vault-token' --roles Administrator"
ansible-vault edit secrets/systech-secrets.yml --ask-vault-pass
# actualizar proxmox_api_token con el UUID nuevo
```

**Lección clave:** Proxmox valida el par `nombre_token + uuid` como una
unidad indivisible. Un UUID correcto con un nombre de token equivocado
sigue dando 401.

**Tarea pendiente de limpieza:** queda un token huérfano (`token-proxmox`)
con permisos de Administrator. Eliminarlo cuando se confirme estabilidad:
```bash
ssh root@192.168.18.100 "pveum user token remove root@pam token-proxmox"
```

### 3. `terraform.tfvars` pisando silenciosamente al Vault

**Síntoma:** aun con el Vault y las ACLs perfectos, `tofu plan` seguía
fallando.

**Causa raíz:** `terraform.tfvars` tenía **hardcodeados** un
`proxmox_api_token` con un tercer nombre de token que nunca existió
(`tofu-token`) y una `ssh_public_key` vieja (`jensyg@lxd-fleet`, del host,
no la del contenedor). OpenTofu da **mayor prioridad a `terraform.tfvars`
que a las variables de entorno `TF_VAR_*`**, así que estos valores
fantasma ganaban siempre, sin importar lo que inyectara `entrypoint.sh`.

**Solución:** se limpió `terraform.tfvars` dejando solo los valores no
secretos:
```hcl
proxmox_api_url = "https://192.168.18.100:8006/"
target_node     = "homelab"
```
Los secretos (`proxmox_api_token`, `ssh_public_key`,
`proxmox_ssh_private_key`) quedan exclusivamente a cargo de las variables
`TF_VAR_*` inyectadas desde el Vault.

**Lección clave — "fuente de verdad duplicada":** tener el mismo secreto
guardado en dos lugares (Vault + `.tfvars`) garantiza que un día se
desincronicen. Un secreto vive en un solo lugar; todo lo demás lo
referencia dinámicamente.

**Archivos auditados y confirmados limpios** (sin hardcodeo, usan
`var.ssh_public_key` / `var.proxmox_ssh_private_key` correctamente):
`main.tf`, `lxc.tf`, `providers.tf`, `variables.tf`. El archivo
`cloud-init/user-data.yml` está vacío/sin uso — el cloud-init real se
genera inline en `main.tf` vía `source_raw`.

### 4. Ruta estática al laboratorio perdida tras el formateo (`no route to host`)

**Síntoma:** las VMs y LXC se crearon exitosamente en Proxmox (visibles en
la GUI), pero el SSH desde el contenedor fallaba con:
```
ssh: connect to host 10.10.10.21 port 22: No route to host
```
Nótese que es `no route to host`, distinto a `timeout` o `connection
refused` — señal de un problema de enrutamiento, no de firewall/SSH.

**Causa raíz:** el contenedor corre con `--network host`, así que comparte
la tabla de rutas completa de la laptop MX Linux. La ruta estática hacia
`10.10.10.0/24` (documentada desde el README original) es configuración
de **NetworkManager del sistema operativo host** — no vive en el repo, ni
en el Vault, ni en ningún archivo versionado. Se perdió al formatear.

**Solución:**
```bash
# En el HOST (no dentro del contenedor)
nmcli connection show                     # confirmar nombre de la conexión activa
sudo nmcli connection modify "<nombre-conexion>" \
  +ipv4.routes "10.10.10.0/24 192.168.18.100"
sudo nmcli connection up "<nombre-conexion>"
ip route | grep 10.10.10                  # verificar
```
Como el contenedor usa `--network host`, no requiere reinicio — ve la
ruta nueva inmediatamente.

**Resultado final:** `tofu apply -destroy` + `tofu apply` recreó los 2 LXC
que habían fallado, y el SSH conectó correctamente:
```
[ansible@server01 ~]$
```

---

## ✅ Checklist: Recuperar el entorno en una laptop nueva o formateada

A diferencia de un setup tradicional, la mayoría del estado vive en el
**servidor Proxmox** o en el **Vault cifrado** (portable). Solo estos
elementos viven **fuera** del repo y deben rehacerse manualmente en cada
máquina nueva:

1. **Clonar/copiar el repositorio completo**, incluyendo
   `secrets/systech-secrets.yml` cifrado (seguro de llevar en Git).
2. **Tener la contraseña del Ansible Vault** (gestor de contraseñas, no
   texto plano). Sin ella, `entrypoint.sh` no puede desencriptar nada.
3. **Instalar Podman** en el host nuevo. No se necesita instalar
   OpenTofu, Ansible, ni configurar SSH manualmente — todo vive dentro
   de la imagen del contenedor.
4. **Agregar la ruta estática** hacia `10.10.10.0/24` vía `192.168.18.100`
   con `nmcli` (ver sección 4 de troubleshooting arriba). **Este paso se
   perdió una vez y costó tiempo de debugging — no saltárselo.**
5. **Ejecutar `control.sh`**. Construye la imagen si no existe, pide la
   contraseña del Vault, e inyecta todos los secretos automáticamente.
6. **Verificar** con `echo "$TF_VAR_proxmox_api_token"` y un `tofu plan`
   antes de asumir que todo está listo.

**No hace falta repetir:** la corrección de ACL del token en Proxmox (vive
en el servidor), ni la autorización de la llave pública (también vive en
el servidor, en `authorized_keys`), ni reconstruir la imagen del
contenedor (`podman build`) — eso solo aplica si cambia el `Dockerfile` o
`entrypoint.sh`, no cuando cambian secretos o se cambia de laptop.

**Pendiente de agregar a este checklist más adelante:** estrategia para
`terraform.tfstate` (actualmente solo local — si no viaja con el repo,
OpenTofu "olvidará" que las VMs ya existen en una laptop nueva y podría
intentar recrearlas).

---

## 🔐 Gestión de Claves SSH

### Llaves relevantes

| Archivo | Tipo | Uso |
| :--- | :--- | :--- |
| `id_systech_control` (dentro del Vault) | ed25519 | Identidad exclusiva y efímera del nodo de control. Autorizada en Proxmox e inyectada vía cloud-init en VMs/LXC del laboratorio. |
| `~/.ssh/id_lxd_fleet` (host) | ed25519 | Flota LXD original — **ya no se usa para este proyecto**, mantener solo si otros proyectos la necesitan. |
| `~/.ssh/id_github` (host) | ed25519 | Solo para GitHub, sin relación con este proyecto. |

### ⚠️ Problema histórico (ya resuelto): expansión de `~` en SSH dentro del contenedor

Documentado en versiones anteriores de este README. **Resuelto** al migrar
a la arquitectura Zero-Trust: `entrypoint.sh` escribe la llave y el config
SSH directamente en `$HOME/.ssh` (con `HOME=/workspace` fijado por el
Dockerfile), eliminando la ambigüedad de rutas relativas.

---

## 🖥️ Proxmox VE

| Parámetro | Valor |
| :--- | :--- |
| Nodo | `homelab` |
| IP API | `https://192.168.18.100:8006/` |
| Usuario API | `root@pam!systech-vault-token` |
| SSL | Certificado autofirmado (requiere `insecure = true`) |
| Bridge `vmbr0` | Red LAN 192.168.18.0/24 |
| Bridge `vmbr1` | Red laboratorio 10.10.10.0/24 |

### Limitaciones conocidas de esta versión de Proxmox

- `qm agent <vmid> exec-command` **NO está soportado**.
- `proxmox_virtual_environment_download_file` está **deprecado** → usar
  `proxmox_download_file`.
- Descarga de `.qcow2` requiere extensión `.iso` en `file_name`.
- **Los tokens de API requieren ACL propia si `privsep=1`** (ver
  troubleshooting #1).

---

## ⚙️ OpenTofu / Terraform

### Comandos de referencia

```bash
tofu init                    # Inicializar providers
tofu plan -out=tfplan        # Planificar (siempre con -out)
tofu apply tfplan            # Aplicar plan guardado
tofu destroy -auto-approve   # Destruir todo
tofu output                  # Ver outputs
```

### ⚠️ Notas importantes

- `terraform.tfvars` tiene **MAYOR prioridad** que `TF_VAR_*`. Mantener
  este archivo **solo con valores no secretos** (URL, nombre del nodo).
  Ver troubleshooting #3.
- El archivo `tfplan` queda **obsoleto** si cambia la configuración del
  provider. Regenerar con `tofu plan -out=tfplan`.
- `content_type = "snippets"` debe estar habilitado en el storage `local`
  de Proxmox.

---

## 📁 Estructura del Proyecto (actualizada)

```
SYSTECH-HA-001—Enterprise_Linux_HA_Infrastructure/
├── ansible.cfg
├── dockerfile/
│   ├── bootstrap.sh             # Inicialización única: genera llave + cifra Vault
│   ├── control.sh                # Uso diario: construye imagen + lanza contenedor
│   ├── entrypoint.sh             # Desencripta Vault e inyecta secretos en runtime
│   └── Dockerfile                # Imagen del nodo de control (Zero-Trust)
├── inventories/
│   └── production/
│       ├── group_vars/
│       │   ├── all/vault.yml     # Vault de Ansible (candidato a consolidar, ver Pendientes)
│       │   └── lb_nodes.yml
│       ├── hosts.yml
│       └── host_vars/
├── README.md                     # ← Este archivo
├── requirements.yml
├── roles/
│   ├── app/
│   ├── database/
│   ├── db_seed/
│   ├── haproxy/
│   ├── keepalived/
│   ├── linux_baseline/
│   ├── nginx/
│   └── zabbix_server/
├── secrets/
│   └── systech-secrets.yml       # Vault cifrado: token API + llave SSH del control node
├── site.yml
├── terraform/
│   ├── cloud-init/user-data.yml  # Sin uso actualmente (cloud-init generado inline en main.tf)
│   ├── lxc.tf                    # Recursos LXC (template + cluster + provisioning de usuario)
│   ├── main.tf                   # Recursos VM (imagen, snippets cloud-init, cluster de 3 VMs)
│   ├── outputs.tf
│   ├── providers.tf
│   ├── terraform.tfstate         # ⚠️ Local únicamente — ver Pendientes
│   ├── terraform.tfvars          # Solo valores NO secretos
│   ├── terraform.tfvars.example
│   └── variables.tf
└── variables_del_proyecto.txt
```

---

## 📊 Estado Actual del Proyecto

### ✅ Completado

- [x] Arquitectura Zero-Trust del nodo de control (bootstrap + entrypoint + control.sh) probada y recuperada tras formateo.
- [x] Token API de Proxmox con ACL correcta (`systech-vault-token`).
- [x] Secretos consolidados en Ansible Vault (`secrets/systech-secrets.yml`).
- [x] `terraform.tfvars` limpio de secretos hardcodeados.
- [x] Ruta estática host → laboratorio documentada como paso obligatorio de re-bootstrap.
- [x] 3 VMs AlmaLinux 9 + 2 LXC Ubuntu 24.04 + 1 Node Zabbix Server creados y accesibles por SSH con llave `systech-control` y usuario `ansible`.
- [x] **Fase 01: Linux Baseline exitoso:** Aplicado en todos los nodos (usuarios, SSH hardening, repositorios y paquetes base).
- [x] **Fase 02: Zabbix Server 7.0 LTS instalado y operativo:**
  - Automatizado vía Ansible (`roles/zabbix_server`).
  - Stack: **PostgreSQL 16 (UTF-8 via template0)** + **Nginx** + **PHP 8.3-FPM** en Ubuntu 24.04.
  - Generación de locales `en_US.UTF-8` e integración de esquemas e interfaz web.

### 📋 Próxima Tarea

- [ ] **Despliegue e integración de Zabbix Agent 2 (`roles/zabbix_agent`):**
  - Crear e implementar el rol de Ansible para instalar `zabbix-agent2` en `server01`, `server02`, `server03`, `lxc01` y `lxc02`.
  - Configurar los agentes para comunicar métricas activas/pasivas hacia el servidor Zabbix (`10.10.10.40`).
- [ ] Ejecutar `ansible-playbook site.yml` (roles pendientes: haproxy, keepalived, app, database, db_seed, nginx).
- [ ] Definir estrategia para `terraform.tfstate` (actualmente local; no viaja con el repo entre laptops).
- [ ] Eliminar el token huérfano `token-proxmox` en Proxmox.
- [ ] Probar failover de keepalived (VIP) y balanceo de HAProxy.

---

## 🐛 Troubleshooting — Referencia rápida (errores previos, ya resueltos)

### Error: `tls: failed to verify certificate`
**Solución:** `insecure = true` en el bloque `provider "proxmox"`.

### Error: `wrong file extension` al descargar qcow2
**Solución:** usar `file_name = "archivo.iso"` aunque el contenido sea qcow2.

### Error: `datastore does not support content type "snippets"`
**Solución:** Proxmox GUI → Datacenter → Storage → local → Content → ✅ Snippets.

### Error: `unable to authenticate user "root" over SSH`
**Solución:** `ssh-copy-id -i ~/.ssh/id_systech_control.pub root@192.168.18.100`

### Error: `Saved plan is stale`
**Solución:** regenerar con `tofu plan -out=tfplan`.

### Warning: `REMOTE HOST IDENTIFICATION HAS CHANGED`
**Solución:** `ssh-keygen -f "/workspace/.ssh/known_hosts" -R "10.10.10.21"`

### Error: `401` en la API de Proxmox pese a token/UUID correctos
**Ver troubleshooting completo arriba — sección 1 y 2.**

### Error: `event not found` al usar `curl` con un token que contiene `!`
**Causa:** expansión de historial de bash con comillas dobles.
**Solución:** usar comillas simples: `curl -H 'Authorization: PVEAPIToken=...'`

### Error: `no route to host` hacia la red 10.10.10.0/24
**Ver troubleshooting completo arriba — sección 4.**

---

## 🔑 Gestión de Secretos

| Método | Uso actual | Notas |
| :--- | :--- | :--- |
| `secrets/systech-secrets.yml` (Ansible Vault) | ✅ Token API + llave SSH del control node | Cifrado, seguro en Git, desencriptado en runtime por `entrypoint.sh` |
| Variables de entorno `TF_VAR_*` | ✅ Inyección efímera hacia OpenTofu | Nunca tocan disco fuera del contenedor |
| `terraform.tfvars` | ✅ Solo valores NO secretos | Ver troubleshooting #3 — nunca poner secretos aquí |
| `inventories/.../vault.yml` (Ansible) | ⚠️ Vault separado, pendiente de evaluar consolidación | Ver Pendientes |

---

## 📝 Convenciones

- **Usuario de despliegue:** `ansible` (sudo NOPASSWD)
- **Llave SSH del control node:** `id_systech_control` (ed25519, dentro del Vault)
- **Red de laboratorio:** `10.10.10.0/24` (gateway `10.10.10.1` = Proxmox vmbr1)
- **Red LAN:** `192.168.18.0/24`
- **SO de VMs:** AlmaLinux 9 GenericCloud
- **SO de LXC:** Ubuntu 24.04
- **SO de Proxmox:** Debian (PVE 7.x)
- **SO del host:** MXLinux (Debian-based, sin SELinux, con AppArmor)
- **Runtime de contenedores:** Podman (rootless, sin Docker)
