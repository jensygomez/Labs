# Hybrid Cloud Incident Labs

Laboratorio de incidentes de infraestructura híbrida (Linux + AWS simulado) para simulaciones de producción en tiempo real.

## 🎯 Objetivo

Simular incidentes de producción en un entorno híbrido que combina:
- **On-premise:** Contenedores LXD/LXC (AlmaLinux 9)
- **Cloud simulado:** FakeCloud (emulador local de AWS) corriendo como servicio systemd en el host
- **Monitoreo:** Prometheus + Node Exporter

Este laboratorio está diseñado para practicar triaje y remediación de incidentes como si fueras un SRE on-call en producción.

## 🏗️ Arquitectura

```
                        HOST (mx)
   CPU: Intel i3-6006U  |  RAM: 12GB  |  OS: MX Linux

   +---------------------------------------------------+
   |  FakeCloud Service (systemd, en el HOST)          |
   |  - Puerto: 0.0.0.0:4566                           |
   |  - Servicios: S3, IAM, RDS, Route53, CloudWatch   |
   |  - URL: http://10.45.223.1:4566                   |
   +---------------------------------------------------+
                               ^
                               |
   +---------------------------------------------------+
   |  LXD Bridge: lxdbr0                               |
   |  - Gateway: 10.45.223.1/24                        |
   |  - NAT hacia Internet  |  DHCP para contenedores  |
   +---------------------------------------------------+
                               |
           +-------------------+-------------------+
           |                   |                   |
           v                   v                   v
 +------------------+ +------------------+ +------------------+
 |   server01       | |   server02       | |   server03       |
 |   (LXC)          | |   (LXC)          | |   (LXC)          |
 | - AlmaLinux 9    | | - AlmaLinux 9    | | - AlmaLinux 9    |
 | - 512MB / 1vCPU  | | - 512MB / 1vCPU  | | - 512MB / 1vCPU  |
 | - Node Exporter  | | - Node Exporter  | | - Node Exporter  |
 | - AWS CLI        | | - AWS CLI        | | - AWS CLI        |
 +------------------+ +------------------+ +------------------+
           |                   |                   |
           |  Metricas :9100   |                   |
           +-------------------+-------------------+
                               |
                               v
                     +---------------------+
                     |  monitoring (LXC)   |
                     |  - Prometheus :9090 |
                     |  - Scrapea:         |
                     |    server0X:9100    |
                     |    FakeCloud:4566   |
                     +---------------------+
```

> **Nota:** FakeCloud es un **servicio systemd en el host**, NO un contenedor. Se accede desde los contenedores vía `http://10.45.223.1:4566` (el gateway del bridge).

## 🧱 Arquitectura de 3 capas (cómo se construye cada incidente)

| Capa | Herramienta | Responsabilidad | Idempotente |
|---|---|---|---|
| **1. Infraestructura** | Terraform (`main.tf`) | Contenedores, SSH, paquetes base, Node Exporter, Prometheus, `inventory.ini`. Se despliega UNA vez. | ✅ Sí |
| **2. Aplicación** | Ansible (`incidentes/inc-XXX/setup.yml`) | Despliega la app del incidente: scripts, unidades systemd, buckets S3, reglas de alerta. | ✅ Sí |
| **3. Inyección** | BASH (`incidentes/inc-XXX/inject-fault.sh`) | Rompe UNA cosa, escribe el MOTD, reinicia (si aplica), verifica en silencio. | ❌ No (a propósito) |

## 📋 Requisitos Previos

- **LXD** v5+ · **Terraform** v1+ · **Ansible** v2+ · **AWS CLI** v2 · **FakeCloud** (systemd activo en el host)
- **Bridge:** `lxdbr0` · **Subnet:** `10.45.223.0/24` · **Gateway:** `10.45.223.1`

### Imagen base
```bash
lxc image copy images:almalinux/9/cloud local: --alias almalinux9-cloud
lxc launch almalinux9-cloud cloudtest
lxc exec cloudtest -- cloud-init status --long
lxc delete cloudtest --force
```

## 📁 Estructura del Proyecto

```
lxd-pilot/
├── main.tf                 # Capa 1: infraestructura (Terraform)
├── inventory.tpl           # Plantilla del inventario Ansible
├── inventory.ini           # Inventario generado (no commit)
├── ansible.cfg
├── README.md
├── Promt-Maestro-FakeCloud.txt
└── incidentes/
    ├── inc-010/
    │   ├── setup.yml               # Capa 2
    │   ├── inject-fault.sh         # Capa 3
    │   ├── triage/                 # Tú lo creas
    │   └── remediation/            # Tú lo creas
    ├── inc-011/
    │   └── ...
    └── ...
```

## 🚀 Uso Rápido

```bash
# Capa 1: infraestructura (una vez)
terraform apply -auto-approve

# Capa 2: desplegar la app del incidente
ansible-playbook -i inventory.ini incidentes/inc-XXX/setup.yml

# Capa 3: inyectar el fallo
./incidentes/inc-XXX/inject-fault.sh

# ... tú triageas y remedias ...

# Limpiar
terraform destroy -auto-approve
```

### Verificación post-despliegue
```bash
lxc list
ansible all -i inventory.ini -m ping
ansible server01 -i inventory.ini -m shell -a "aws --endpoint-url http://10.45.223.1:4566 s3 ls"
```

## 🔧 Componentes Principales

### FakeCloud (AWS simulado)
- **Endpoint:** `http://10.45.223.1:4566` · **Credenciales:** `test`/`test` · **Región:** `us-east-1`
- Servicios: S3, IAM, RDS, Route53, CloudWatch

### Monitoreo
- Prometheus en `http://<IP_MONITORING>:9090`, scrapea `server0X:9100` y `10.45.223.1:4566`
- Node Exporter con **textfile collector** (`/var/lib/node_exporter/textfile_collector/*.prom`) para métricas custom de cada incidente

### Contenedores LXC
- 512MB / 1 vCPU · DHCP en `10.45.223.0/24` · AlmaLinux 9
- Preinstalado: python3, openssh-server, awscli, nginx, rsync, curl, Node Exporter · credenciales AWS configuradas

## 🎓 Flujo de Incidentes

1. **Inyección** — el script rompe una cosa + MOTD + verificación silenciosa
2. **Detección** — `ansible all -i inventory.ini -m shell -a "cat /etc/motd"`
3. **Triaje manual** — Linux tools + AWS CLI
4. **Playbooks** — `triage.yml` (detecta) + `remediation.yml` (arregla), idempotentes para 1000+ servidores
5. **Limpieza** — `terraform destroy && terraform apply`

## 🛠️ Comandos Útiles

```bash
# Terraform
terraform plan | apply | destroy | show

# LXD
lxc list
lxc exec server01 -- bash
lxc exec server01 -- journalctl -xe

# Ansible
ansible all -i inventory.ini -m ping
ansible app_fleet -i inventory.ini -m shell -a "uptime"
ansible-playbook -i inventory.ini playbook.yml --limit server01

# FakeCloud (AWS CLI)
aws --endpoint-url http://10.45.223.1:4566 s3 ls
aws --endpoint-url http://10.45.223.1:4566 s3 mb s3://mi-bucket
aws --endpoint-url http://10.45.223.1:4566 rds describe-db-instances
```

## ⚠️ Gotchas y Lecciones Aprendidas

Errores reales encontrados al construir el lab, y su solución:

| # | Problema | Causa raíz | Solución |
|---|----------|-----------|----------|
| 1 | SSH `Connection refused` | Imagen sin cloud-init | Usar `almalinux9-cloud` (variante `/cloud`) |
| 2 | Warnings de `lxd_container` | Recurso deprecado | Usar `lxd_instance` con `type = "container"` |
| 3 | `Address default is not a valid ip` | IPs estáticas vía `user.network-config` | Usar DHCP; no configurar IPs estáticas |
| 4 | `Unable to locate credentials` / `specify a region` | AWS CLI sin credenciales | Inyectar `/root/.aws/credentials` (test/test) y `config` (us-east-1) |
| 5 | `aws: command not found` | awscli no instalado | Agregar `awscli` a los paquetes base |
| 6 | Fallo de boot no se reproduce | LXD levanta la red al instante (no hay race) | Usar fallos **deterministas** (archivo faltante, config rota) |
| 7 | Ansible `unexpected char '$'` | `{{ $labels }}` de Prometheus leído como Jinja2 | Escapar `{{ '{{' }}` o usar `{% raw %}` |
| 8 | Warning "group and host with same name: localhost" | Grupo llamado `localhost` | Renombrar grupo a `[local]` |
| 9 | `templatefile` variable mismatch | `main.tf` e `inventory.tpl` desincronizados | Mantener variables consistentes al cambiar arquitectura |
| 10 | Contenedor fakecloud redundante | FakeCloud corre en el **host**, no en contenedor | No crear contenedor; usar `http://10.45.223.1:4566` |

### 🥇 Regla de oro para LXD
> En contenedores LXD la red está disponible **desde el instante del arranque**. Cualquier incidente basado en "race condition de red al boot" **no se reproduce**. Diseña siempre fallos **deterministas**: archivos faltantes, configs rotas, permisos, SELinux, firewall, LVM — cosas que fallen igual en cada reboot.

### 🥈 Limitaciones de LXD a revisar ANTES de construir
- **SELinux:** el host es MX Linux (AppArmor, SELinux deshabilitado). Los contenedores comparten el kernel → SELinux está `Disabled` dentro de LXC. Los incidentes SELinux necesitan **VM KVM**.
- **Swap:** es del host, no se configura por contenedor → usar límites cgroup (`MemoryMax=`).
- **LVM/bloques:** LXC no tiene discos reales → usar loop device + privileged, o VM.
- **Kernel/netfilter:** `nf_conntrack` y el naming de interfaces son del host.

## 🐛 Troubleshooting

```bash
# Terraform falla al crear contenedores
lxc image list | grep almalinux9-cloud

# Ansible no conecta
lxc exec server01 -- systemctl status sshd
ssh -i ~/.ssh/id_lxd_fleet root@<IP>

# FakeCloud no responde
systemctl status fakecloud
sudo journalctl -u fakecloud -f
```

## 📈 Próximos Pasos

Siguiente incidente: **inc-011-storage-lvm-growfs-missing** (Nivel 4/10)
- Problema: Volumen LVM extendido pero filesystem no crecido
- Dominio: Linux-only · Topología: 3 nodos + S3 para backup logs
- Environment: LXC privileged + loop device

---
**Autor:** Jensy · **Versión:** 2.0.0 · **Última actualización:** Agosto 2026
