# VM BASE – Rocky Linux 9.x

## Documento Canónico del Ecosistema de Laboratorios Junior (NOC / Sysadmin Linux)

---

## 1. Propósito del Documento

Este documento define **de forma exhaustiva y autoritativa** la creación, configuración y estado esperado de la **VM Base** utilizada por **todos** los laboratorios Junior (J01, J02, J03, …).

Este archivo es la **única fuente de verdad** para:
- Qué existe en el sistema
- Qué está configurado
- Qué está permitido romper
- Qué NO debe modificarse en variantes

Cualquier laboratorio que asuma algo **no descrito aquí** está incorrecto.

---

## 2. Filosofía del Diseño

- Simulación de **entorno corporativo Linux realista**
- Infraestructura **preexistente** (nada se instala durante incidentes)
- Los fallos son **cambios de estado**, no malas instalaciones
- cloud-init **solo altera estados**, nunca construye servicios

---

## 3. Topología Base del Ecosistema

### 3.1 Infraestructura

- **Host físico**: Laptop del estudiante (simula CLIENT01)
- **Hipervisor**: libvirt / KVM
- **Red**: libvirt NAT (192.168.122.0/24)

### 3.2 Máquinas

#### VM Base (única)

- Nombre: `vm-base-rocky9-noc.eu.corp`
- Rol: Servidor multi-servicio (Europa)
- SO: Rocky Linux 9.x

No se crean múltiples VMs para laboratorios Junior.
La complejidad está en **estados**, no en cantidad de nodos.

---

## 4. Creación de la VM Base

### 4.1 ISO recomendada

- Rocky Linux 9.x – **Minimal ISO**

Motivo:
- Control total de paquetes
- Menor ruido
- Más realista para servidores

### 4.2 Recursos de la VM

- vCPU: 2
- RAM: 2 GB (mínimo viable)
- Disco: 20 GB (qcow2)
- NIC: virtio, red default libvirt

### 4.3 Instalación del SO

Durante instalación:
- Idioma: Inglés
- Timezone: UTC
- SELinux: Enforcing
- Firewall: Enabled
- Particionado: Automático
- Perfil: Minimal Install

---


## 4,5. Nombre de la maquina y FQDN
hostnamectl set-hostname vm-base-rocky9-noc.eu.corp

hostnamectl
vim /etc/hosts
127.0.0.1   localhost
192.168.122.20 vm-base-rocky9-noc.eu.corp vm-base-rocky9-noc

## 4,6. SSH

sudo mkdir -p /home/student/.ssh
sudo chmod 700 /home/student/.ssh
sudo chown student:student /home/student/.ssh
ssh-copy-id -i /home/jensy/Labs/.ssh/id_rhcsalabs.pub student@192.168.122.20
o desde el host: ssh-copy-id -i /home/jensy/Labs/.ssh/id_rhcsalabs.pub student@192.168.122.20


ajustar permisos


sudo chmod 600 /home/student/.ssh/authorized_keys
sudo chown student:student /home/student/.ssh/authorized_keys

Editar /etc/ssh/sshd_config:

PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no

sudo systemctl reload sshd

ssh -i /home/jensy/Labs/.ssh/id_rhcsalabs student@192.168.122.20





## 5. Configuración Inicial Post-Instalación

### 5.1 Actualización del sistema

```bash
dnf update -y
```

### 5.2 Paquetes base de administración

```bash
dnf install -y \
  vim \
  nano \
  curl \
  wget \
  net-tools \
  iproute \
  bind-utils \
  traceroute \
  tcpdump \
  lsof \
  bash-completion \
  policycoreutils-python-utils
```

---

## 6. Servicios Corporativos Instalados (SIEMPRE)

Estos paquetes **siempre existen**, aunque el laboratorio no los use.

### 6.1 Web – Nginx

```bash
dnf install -y nginx
```

Configuración:
- `/etc/nginx/nginx.conf`
cat << 'EOF' > /etc/nginx/conf.d/default.conf
server {
    listen 80 default_server;
    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

- `/etc/nginx/conf.d/default.conf`
cat << 'EOF' > /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html>
<head>
  <title>NOC Junior Lab</title>
</head>
<body>
  <h1>NOC Junior – VM Base</h1>
  <p>Static content baseline</p>
</body>
</html>
EOF


Contenido mínimo:
- Listen 80
- Página estática simple

Estado:
- **disabled**
systemctl disable --now nginx
systemctl status nginx

---

### 6.2 Base de Datos – MariaDB

```bash
dnf install -y mariadb-server
```

Configuración:
- DB: `appdb`
- Usuario: `appuser`
- Password: `app_pass`
- Bind: `0.0.0.0`

vim /etc/my.cnf.d/mariadb-server.cnf
[mysqld]
bind-address = 0.0.0.0
systemctl start mariadb
mysql << 'EOF'
CREATE DATABASE appdb;
CREATE USER 'appuser'@'%' IDENTIFIED BY 'app_pass';
GRANT ALL PRIVILEGES ON appdb.* TO 'appuser'@'%';
FLUSH PRIVILEGES;
EOF

systemctl stop mariadb



Estado:
- **disabled**
systemctl disable mariadb
systemctl status mariadb
---

### 6.3 Proxy TCP – HAProxy

```bash
dnf install -y haproxy
```
vim /etc/haproxy/haproxy.cfg
global
    log /dev/log local0
    maxconn 4096
    daemon

defaults
    mode tcp
    timeout connect 10s
    timeout client  1m
    timeout server  1m

frontend mariadb_front
    bind *:3306
    default_backend mariadb_back

backend mariadb_back
    server db1 127.0.0.1:3306 check




Configuración:
- Frontend TCP 3306
- Backend MariaDB real

Estado:
- **disabled**
systemctl disable --now haproxy

---

## 7. Red y Direccionamiento Base

### 7.1 IP Primaria

- DHCP de libvirt
- Uso administrativo (SSH)

### 7.2 VIPs (NO asignadas por defecto)
nmcli device status
nmcli connection shownmcli connection modify "enp1s0" \
  ipv4.method manual \
  ipv4.addresses 192.168.122.20/24 \
  ipv4.gateway 192.168.122.1 \
  ipv4.dns 192.168.122.1


nmcli connection down "enp1s0"
nmcli connection up "enp1s0"
ip a show enp1s0
ip route



Reservadas para laboratorios:

| Servicio | IP |
|-------|----|
| Web | 192.168.122.50 |
| MariaDB | 192.168.122.60 |
| HAProxy | 192.168.122.70 |

Las VIPs **solo se asignan vía cloud-init**.

---

## 8. Firewall y SELinux (Baseline)

### 8.1 Firewalld
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-port=3306/tcp
firewall-cmd --reload

firewall-cmd --list-all


- Enabled
- Zonas por defecto
- Puertos abiertos:
  - 22/tcp
  - 80/tcp
  - 3306/tcp

Estado:
- **Sano** (sin bloqueos)

Declaración de arquitectura (queda grabada)

El cliente nunca se conecta directo a MariaDB

El flujo es:

CLIENTE → VIP HAProxy (192.168.122.70:3306)
        → HAProxy
        → MariaDB (real)

        ncluso cuando:

MariaDB esté en la misma VM

El laboratorio sea “simple”

### 8.2 SELinux
getenforcesetsebool -P httpd_can_network_connect on


- Modo: Enforcing
- Booleanos necesarios habilitados
- Ninguna denegación activa

---

## 9. Estados Iniciales (MUY IMPORTANTE)


systemctl is-enabled nginx mariadb haproxy firewalld
getenforce
ip a

| Componente | Estado |
|---------|-------|
| nginx | disabled |
| mariadb | disabled |
| haproxy | disabled |
| firewalld | enabled |
| selinux | enforcing |
| VIPs | no asignadas |

Este es el **punto cero** de todos los laboratorios.

---

## 10. cloud-init – Rol y Límites

cloud-init se usa **exclusivamente** para:
- Asignar VIPs
- Encender servicios
- Introducir fallos

cloud-init **NO**:
- Instala paquetes
- Crea configuraciones
- Define negocio

---

## 11. Relación con Laboratorios

Cada laboratorio Junior:
- Parte de esta VM base
- Aplica **una variante** vía cloud-init
- Genera un incidente controlado

Ejemplo:
- J01: red / conectividad
- J02: firewall / selinux
- J03: servicios
- J04: recursos

---

## 12. Nombre Oficial de la VM Base

**`vm-base-rocky9-noc`**

Este nombre no debe cambiar.
Es la imagen dorada del ecosistema.

---

## 13. Regla de Oro

> Si algo no está definido en este documento, **no existe** en el laboratorio.

Este archivo protege la coherencia, justicia y realismo del framework.

