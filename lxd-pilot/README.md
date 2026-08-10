---

# Hybrid Cloud Incident Labs

Laboratorio de incidentes de infraestructura híbrida (Linux + AWS simulado) para simulaciones de producción en tiempo real.

## Objetivo

Simular incidentes de producción en un entorno híbrido que combina:
- **On-premise**: Contenedores LXD/LXC (AlmaLinux 9)
- **Cloud simulado**: FakeCloud (emulador local de AWS)
- **Monitoreo**: Prometheus + Node Exporter

Este laboratorio está diseñado para practicar triaje y remediación de incidentes como si fueras un SRE on-call en producción.

## Arquitectura

```
                        HOST (mx)
  CPU: Intel i3-6006U  |  RAM: 12GB  |  OS: MX Linux
  
  +---------------------------------------------------+
  |  FakeCloud Service (systemd)                      |
  |  - Puerto: 0.0.0.0:4566                           |
  |  - Servicios: S3, IAM, RDS, Route53, CloudWatch   |
  |  - URL: http://10.45.223.1:4566                   |
  +---------------------------------------------------+
                              ^
                              |
  +---------------------------------------------------+
  |  LXD Bridge: lxdbr0                               |
  |  - Gateway: 10.45.223.1/24                        |
  |  - NAT hacia Internet                             |
  +---------------------------------------------------+
                              |
          +-------------------+-------------------+
          |                   |                   |
          v                   v                   v
+------------------+ +------------------+ +------------------+
|   server01       | |   server02       | |   server03       |
|   (LXC)          | |   (LXC)          | |   (LXC)          |
|                  | |                  | |                  |
| - AlmaLinux 9    | | - AlmaLinux 9    | | - AlmaLinux 9    |
| - 512MB RAM      | | - 512MB RAM      | | - 512MB RAM      |
| - 1 vCPU         | | - 1 vCPU         | | - 1 vCPU         |
| - Node Exporter  | | - Node Exporter  | | - Node Exporter  |
| - AWS CLI        | | - AWS CLI        | | - AWS CLI        |
+------------------+ +------------------+ +------------------+
          |                   |                   |
          |  Metricas :9100   |                   |
          +-------------------+-------------------+
                              |
                              v
                    +---------------------+
                    |  monitoring         |
                    |  (LXC)              |
                    |                     |
                    |  - Prometheus       |
                    |    :9090            |
                    |  - Scrapea:         |
                    |    - server01:9100  |
                    |    - server02:9100  |
                    |    - server03:9100  |
                    |    - FakeCloud:4566 |
                    +---------------------+
```

## Requisitos Previos

### Software Requerido

- **LXD**: v5.x o superior
- **Terraform**: v1.x o superior
- **Ansible**: v2.x o superior
- **AWS CLI**: v2.x (para interactuar con FakeCloud)
- **FakeCloud**: Servicio systemd activo en el host

### Configuración de Red

- Bridge LXD: `lxdbr0`
- Subnet: `10.45.223.0/24`
- Gateway: `10.45.223.1`

### Imagen Base

```bash
# Copiar la imagen cloud de AlmaLinux 9
lxc image copy images:almalinux/9/cloud local: --alias almalinux9-cloud

# Verificar que tiene cloud-init
lxc launch almalinux9-cloud cloudtest
lxc exec cloudtest -- cloud-init status --long
lxc delete cloudtest --force
```

## Estructura del Proyecto

```
lxd-pilot/
├── main.tf                 # Definicion de infraestructura (Terraform)
├── inventory.tpl           # Plantilla para inventario Ansible
├── inventory.ini           # Inventario generado (no commit)
├── terraform.tfstate       # Estado de Terraform (no commit)
├── .terraform/             # Providers de Terraform
├── ansible.cfg             # Configuracion de Ansible
└── incidentes/             # Scripts de inyeccion de incidentes
    ├── inc-011-storage-lvm-growfs-missing.sh
    ├── inc-012-network-resolv-conf-overwritten.sh
    └── ...
```

## Uso Rapido

### 1. Crear la Infraestructura

```bash
# Inicializar Terraform (solo la primera vez)
terraform init

# Crear todos los recursos
terraform apply -auto-approve
```

**Tiempo estimado**: 2-3 minutos

**Lo que se crea**:
- 3 contenedores LXC (server01, server02, server03)
- 1 contenedor LXC para monitoreo (Prometheus)
- 1 perfil LXD llamado "fleet"
- Inventario Ansible dinamico

### 2. Verificar que Todo Funciona

```bash
# Ver contenedores
lxc list

# Probar conectividad con Ansible
ansible all -i inventory.ini -m ping

# Probar FakeCloud (AWS simulado)
ansible server01 -i inventory.ini -m shell -a "aws --endpoint-url http://10.45.223.1:4566 s3 ls"
```

### 3. Ejecutar un Incidente

```bash
# Ejecutar el script de inyeccion
./incidentes/inc-011-storage-lvm-growfs-missing.sh
```

El script:
1. Inyecta el fallo en uno de los 3 servidores
2. Escribe el ticket en `/etc/motd`
3. Verifica silenciosamente que el fallo esta activo

### 4. Triaje y Remediacion

```bash
# Conectarte a un servidor
ssh -i ~/.ssh/id_lxd_fleet root@<IP_DEL_SERVIDOR>

# Usar Ansible para diagnostico
ansible app_fleet -i inventory.ini -m shell -a "df -h"

# Crear playbooks de triaje y remediacion
nano triage.yml
nano remediation.yml

# Ejecutar playbooks
ansible-playbook -i inventory.ini triage.yml
ansible-playbook -i inventory.ini remediation.yml
```

### 5. Destruir y Recrear

```bash
# Destruir todo el entorno
terraform destroy -auto-approve

# Recrear desde cero
terraform apply -auto-approve
```

## Componentes Principales

### FakeCloud (AWS Simulado)

**Servicios disponibles**:
- **S3**: Almacenamiento de objetos
- **IAM**: Gestion de identidades y accesos
- **RDS**: Bases de datos relacionales
- **Route53**: DNS privado
- **CloudWatch**: Metricas y alarmas

**Endpoint**: `http://10.45.223.1:4566`

**Credenciales**: `test` / `test` (configuradas automaticamente en todos los nodos)

### Monitoreo con Prometheus

**URL**: `http://<IP_DE_MONITORING>:9090`

**Targets configurados**:
- `server01:9100` (Node Exporter)
- `server02:9100` (Node Exporter)
- `server03:9100` (Node Exporter)
- `10.45.223.1:4566` (FakeCloud)

### Contenedores LXC

**Recursos por contenedor**:
- CPU: 1 vCPU
- RAM: 512 MB
- Disco: Asignado por LXD (pool `default`)
- Red: DHCP en subnet `10.45.223.0/24`

**Software preinstalado**:
- AlmaLinux 9
- Python 3
- OpenSSH Server
- AWS CLI
- Node Exporter (en servidores de aplicacion)
- Credenciales AWS configuradas

## Flujo de Incidentes

### Fase 1: Inyeccion

El script de inyeccion:
1. Selecciona aleatoriamente uno de los 3 servidores
2. Aplica el fallo especifico del incidente
3. Escribe el ticket en `/etc/motd`
4. Verifica que el fallo esta activo

### Fase 2: Deteccion

Lee el ticket en `/etc/motd`:
```bash
ansible all -i inventory.ini -m shell -a "cat /etc/motd"
```

### Fase 3: Triaje Manual

Usa herramientas Linux y AWS CLI para:
1. Identificar el servidor afectado
2. Diagnosticar la causa raiz
3. Validar que el problema es reproducible

### Fase 4: Playbooks de Ansible

Crea dos playbooks diseñados para 1000+ servidores:

**Triage Playbook** (`triage.yml`):
- Identifica servidores afectados usando `when:` conditions
- Minimo output, maximo diagnostico
- Idempotente (no modifica el sistema)

**Remediation Playbook** (`remediation.yml`):
- Aplica la solucion solo a servidores afectados
- Idempotente (puede ejecutarse multiples veces)
- Verifica que el problema esta resuelto

### Fase 5: Limpieza

```bash
terraform destroy -auto-approve
terraform apply -auto-approve
```

## Comandos Utiles

### Terraform

```bash
# Ver plan antes de aplicar
terraform plan

# Aplicar cambios
terraform apply

# Destruir todo
terraform destroy

# Ver estado
terraform show
```

### LXD

```bash
# Listar contenedores
lxc list

# Ejecutar comando en contenedor
lxc exec server01 -- hostname

# Conectarse a shell del contenedor
lxc exec server01 -- bash

# Ver logs de un contenedor
lxc exec server01 -- journalctl -xe
```

### Ansible

```bash
# Probar conectividad
ansible all -i inventory.ini -m ping

# Ejecutar comando en todos los servidores
ansible app_fleet -i inventory.ini -m shell -a "uptime"

# Ejecutar playbook
ansible-playbook -i inventory.ini playbook.yml

# Limitar a un host especifico
ansible-playbook -i inventory.ini playbook.yml --limit server01
```

### FakeCloud (AWS CLI)

```bash
# Listar buckets S3
aws --endpoint-url http://10.45.223.1:4566 s3 ls

# Crear bucket
aws --endpoint-url http://10.45.223.1:4566 s3 mb s3://mi-bucket

# Subir archivo a S3
aws --endpoint-url http://10.45.223.1:4566 s3 cp archivo.txt s3://mi-bucket/

# Listar instancias RDS
aws --endpoint-url http://10.45.223.1:4566 rds describe-db-instances
```

## Troubleshooting

### Terraform falla al crear contenedores

```bash
# Verificar que la imagen existe
lxc image list | grep almalinux9-cloud

# Si no existe, crearla
lxc image copy images:almalinux/9/cloud local: --alias almalinux9-cloud
```

### Ansible no puede conectarse a los servidores

```bash
# Verificar que SSH esta corriendo
lxc exec server01 -- systemctl status sshd

# Verificar que la llave existe
ls -la ~/.ssh/id_lxd_fleet

# Probar SSH manualmente
ssh -i ~/.ssh/id_lxd_fleet root@<IP_DEL_SERVIDOR>
```

### FakeCloud no responde

```bash
# Verificar que el servicio esta corriendo
systemctl status fakecloud

# Reiniciar el servicio
sudo systemctl restart fakecloud

# Ver logs
sudo journalctl -u fakecloud -f
```

## Proximos Pasos

Tu infraestructura base esta lista. El siguiente paso es ejecutar tu primer incidente:

**inc-011-storage-lvm-growfs-missing** (Nivel 4/10)
- Problema: Volumen LVM extendido pero filesystem no crecido
- Dominio: Linux-only
- Topologia: 3 nodos + S3 para backup logs

---

**Autor**: Jensy  
**Version**: 1.0.0  
**Ultima actualizacion**: Agosto 2026

---

Guarda este contenido como `README.md` en tu directorio `lxd-pilot/`. El documento está completo, profesional y sirve como referencia tanto para ti como para futuros aprendizajes. Cuando estés listo, podemos proceder con **inc-011**.
