# SYSTECH-HA-001 — Enterprise Linux HA Infrastructure

Guía de referencia del laboratorio de alta disponibilidad sobre Proxmox VE,
gestionado con OpenTofu (IaC) y Ansible (configuración).

---

## 1. Instalación base de Proxmox

### 1.1 Instalación del hipervisor

Proxmox VE se instaló sobre hardware dedicado (nodo `homelab`), usando el
instalador oficial de Proxmox VE 7.x (Debian based). Configuración de red
inicial durante la instalación:

| Parámetro | Valor |
| :--- | :--- |
| IP de gestión (vmbr0) | `192.168.18.100/24` |
| Gateway | El de la red LAN (`192.168.18.1`) |
| Hostname del nodo | `homelab` |

Acceso a la interfaz web: `https://192.168.18.100:8006/`

### 1.2 Red NAT del laboratorio (vmbr1)

Para aislar las VMs/LXC del laboratorio de la red LAN doméstica, se creó un
segundo bridge dedicado con NAT, en vez de conectar todo directamente a
`vmbr0`. Esto simula una red interna de datacenter separada de la red de
administración.

**Pasos realizados en Proxmox (`Datacenter → homelab → Network`):**

1. Crear un nuevo **Linux Bridge**: `vmbr1`
2. Sin puerto físico asignado (`Bridge ports` vacío) — bridge interno, no
   conectado a la NIC física.
3. IP del bridge: `10.10.10.1/24` (actúa como gateway de la red de
   laboratorio).
4. Habilitar NAT/masquerade para que las VMs salgan a internet a través del
   nodo Proxmox:

```bash
# En el nodo Proxmox (vía shell), habilitar IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Reglas NAT (agregar a /etc/network/interfaces, dentro del bloque vmbr1)
post-up   iptables -t nat -A POSTROUTING -s '10.10.10.0/24' -o vmbr0 -j MASQUERADE
post-down iptables -t nat -D POSTROUTING -s '10.10.10.0/24' -o vmbr0 -j MASQUERADE
```

5. Reiniciar el servicio de red o el nodo para aplicar.

Resultado: `10.10.10.0/24` es una red privada donde viven las VMs y LXC del
laboratorio, con salida a internet vía NAT, pero **no accesible directamente**
desde la LAN salvo que el host tenga una ruta estática agregada (ver más
abajo).

### 1.3 Ruta estática en el host de administración (MXLinux)

Para que la máquina de trabajo (`jensyg@mx`, `192.168.18.8`) pueda llegar a
la red `10.10.10.0/24` sin pasar por NAT (acceso directo, no solo salida a
internet):

```bash
sudo nmcli connection modify "Wired connection 1" \
  +ipv4.routes "10.10.10.0/24 192.168.18.100"
sudo nmcli connection up "Wired connection 1"
```

Esto le dice al host: "para llegar a `10.10.10.0/24`, el siguiente salto es
Proxmox (`192.168.18.100`)", que actúa como router entre ambas redes.

### 1.4 Storage

En `Datacenter → Storage → local`, se habilitó el content type **Snippets**
(`Edit → Content → ✅ Snippets`), requisito para que OpenTofu pueda subir los
archivos de cloud-init.

---

## 2. Terraform / OpenTofu — Gestión de VMs y LXC

Todo el aprovisionamiento vive en `terraform/`. La filosofía del proyecto es:
**nunca edites el bloque `resource`, solo edita el mapa de variables**. Cada
entrada del mapa es una VM o un LXC independiente en el state — agregar,
quitar o renombrar es una operación aislada y segura.

### 2.1 Estructura

```
terraform/
├── providers.tf     # Provider bpg/proxmox
├── variables.tf      # Mapas cluster_nodes (VMs) y lxc_containers (LXC)
├── main.tf            # Recursos de las VMs (AlmaLinux)
├── lxc.tf              # Recursos de los LXC (Ubuntu) + creación de usuario ansible
└── outputs.tf         # IPs resultantes
```

### 2.2 Agregar, quitar o renombrar una VM

Editar el mapa `cluster_nodes` en `terraform/variables.tf`:

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

- **Agregar** una VM nueva → agrega una línea al mapa con un `vmid` e `ip`
  que no estén en uso.
- **Quitar** una VM → borra su línea. Tofu la destruye en el próximo apply,
  sin tocar las demás.
- **Renombrar** una VM → la *key* del mapa (`"server01"`) es el nombre. Si la
  cambias, Tofu la trata como una VM nueva (destruye la vieja, crea la
  nueva) porque el nombre está atado al hostname vía cloud-init.

El hostname y hardware siempre son 100% consistentes con lo que pongas en el
mapa, gracias a los dos snippets de cloud-init generados automáticamente por
`main.tf` (`cloud_user_config` para usuarios/paquetes, `cloud_meta_config`
para forzar el `local-hostname` correcto — ver sección de troubleshooting
más abajo sobre por qué esto es necesario).

### 2.3 Agregar, quitar o renombrar un LXC

Mismo patrón, en el mapa `lxc_containers`:

```hcl
variable "lxc_containers" {
  type = map(object({
    vmid      = number
    ip        = string
    cores     = number
    memory    = number
    disk_size = number
  }))
  default = {
    "lxc01" = { vmid = 301, ip = "10.10.10.31/24", cores = 1, memory = 512, disk_size = 8 }
    "lxc02" = { vmid = 302, ip = "10.10.10.32/24", cores = 1, memory = 512, disk_size = 8 }
  }
}
```

**Ejemplo — agregar un LXC llamado `zabbix`:**

```hcl
"zabbix" = { vmid = 303, ip = "10.10.10.33/24", cores = 2, memory = 1024, disk_size = 12 }
```

Solo agrega esa línea, corre `tofu plan -out=tfplan && tofu apply "tfplan"`,
y el contenedor se crea con hostname `zabbix`, IP `10.10.10.33`, y el
usuario `ansible` ya provisionado con sudo NOPASSWD (vía el `null_resource`
en `lxc.tf`) — listo para que Ansible lo tome sin configuración manual.

**Reglas para no chocar recursos:**

| Recurso | Rango sugerido |
| :--- | :--- |
| VMs (`cluster_nodes`) | vmid 201-299, IP `10.10.10.2x` |
| LXC (`lxc_containers`) | vmid 301-399, IP `10.10.10.3x` |

### 2.4 Comandos del día a día

```bash
tofu plan -out=tfplan        # Siempre revisar el plan antes de aplicar
tofu apply "tfplan"          # Aplicar el plan guardado
tofu output                  # Ver las IPs actuales de VMs y LXC
tofu destroy -auto-approve   # Destruir todo el laboratorio
```

### 2.5 Notas importantes

- **VMs (AlmaLinux):** el usuario `ansible` se crea vía cloud-init
  (`main.tf`, snippet `cloud_user_config`) en el primer boot.
- **LXC (Ubuntu):** el template LXC no soporta creación de usuarios vía
  cloud-init de la misma forma que las VMs. Por eso `lxc.tf` incluye un
  `null_resource` que se conecta como `root` (único usuario que trae el
  template) inmediatamente después de crear el contenedor, y crea el
  usuario `ansible` con la misma llave SSH y sudo NOPASSWD. Este paso se
  re-ejecuta automáticamente si el LXC se recrea (ver `triggers` en el
  recurso).
- **Hostname de VMs en `localhost`:** si alguna vez ves este bug de nuevo,
  la causa es que Proxmox autogenera un meta-data propio con
  `local-hostname: localhost` que pisa el `hostname:` del user-data. La
  solución ya está aplicada en `main.tf` vía el recurso
  `cloud_meta_config`, que fuerza un `local-hostname` explícito por VM.

---

## 3. Pendiente — Ansible: primer despliegue del rol `linux_baseline`

Con la infraestructura (VMs + LXC) ya desplegada y accesible por SSH como
usuario `ansible`, el siguiente paso es correr la primera configuración base
sobre todos los nodos.

### 3.1 Qué falta antes de ejecutar

- [ ] Actualizar `inventories/production/hosts.yml` con las IPs reales de
      `tofu output` (server01-03, lxc01-02, y cualquier LXC nuevo como
      `zabbix`).
- [ ] Revisar `inventories/production/group_vars/all/vault.yml` — confirmar
      que los secretos estén cifrados con `ansible-vault` antes de commitear.
- [ ] Confirmar conectividad SSH de Ansible hacia todos los nodos:
      ```bash
      ansible all -i inventories/production/hosts.yml -m ping
      ```

### 3.2 Ejecutar solo el rol `linux_baseline`

En vez de correr `site.yml` completo (que incluye haproxy, keepalived, app,
database, nginx), limitar el primer despliegue solo al baseline:

```bash
ansible-playbook site.yml \
  -i inventories/production/hosts.yml \
  --tags linux_baseline \
  --limit all
```

O bien, si `site.yml` no tiene tags definidos por rol todavía, crear un
playbook mínimo temporal (`baseline-only.yml`):

```yaml
- hosts: all
  become: true
  roles:
    - linux_baseline
```

```bash
ansible-playbook baseline-only.yml -i inventories/production/hosts.yml
```

### 3.3 Verificación post-despliegue

```bash
ansible all -i inventories/production/hosts.yml -m setup -a "filter=ansible_hostname"
```

Confirma que cada nodo reporte su hostname correcto (server01, server02,
server03, lxc01, lxc02, y cualquiera agregado después) — esto también sirve
como prueba final de que el fix del hostname en las VMs quedó bien aplicado
de forma persistente.

### 3.4 Siguientes roles (después de validar baseline)

Una vez que `linux_baseline` corra limpio en todos los nodos, continuar en
este orden con el resto de `site.yml`:

1. `haproxy` — load balancer
2. `keepalived` — failover VIP
3. `database` — MariaDB
4. `db_seed` — seed inicial de datos
5. `app` — aplicación Flask/Gunicorn
6. `nginx` — reverse proxy

---

*Última actualización: infraestructura de VMs y LXC funcional, hostname de
VMs corregido, usuario `ansible` provisionado en ambos tipos de recurso.
Pendiente: primer `ansible-playbook` run.*
