# VM BASE – Rocky Linux 9.x

## Documento Canónico del Ecosistema de Laboratorios Junior (NOC / Sysadmin Linux)

**Última actualización:** 2026-01-14

---

## 1. Propósito del Documento

Este documento define **de forma exhaustiva y autoritativa** la creación, configuración y estado esperado de la **VM Base** utilizada por todos los laboratorios Junior (J01, J02, J03…).  

Es la **única fuente de verdad** para:

- Qué existe en el sistema
- Qué está configurado
- Qué está permitido romper
- Qué **no** debe modificarse en variantes

> **Nota:** cualquier laboratorio que asuma algo **no descrito aquí** está incorrecto.

---

## 2. Filosofía del Diseño

- Simulación de **entorno corporativo Linux realista**  
- Infraestructura **preexistente** (nada se instala durante incidentes)  
- Los fallos son **cambios de estado**, no malas instalaciones  
- cloud-init **solo altera estados**, nunca construye servicios ni instala paquetes  

> Esto asegura que los laboratorios sean **repetibles, coherentes y seguros**.

---

## 3. Topología Base del Ecosistema

### 3.1 Infraestructura

- **Host físico:** Laptop del estudiante (simula CLIENT01)  
- **Hipervisor:** libvirt / KVM  
- **Red:** libvirt NAT (192.168.122.0/24)  

### 3.2 Máquinas

#### VM Base (única)

- Nombre: `vm-base-rocky9-noc.eu.corp`  
- Rol: Servidor multi-servicio (Europa)  
- SO: Rocky Linux 9.x  

> Solo se crea **una VM base**. La complejidad está en los **estados** de servicios y red, no en la cantidad de nodos.

---

## 4. Creación de la VM Base

### 4.1 ISO recomendada

- Rocky Linux 9.x – **Minimal ISO**  

**Motivo:**

- Control total de paquetes  
- Menor ruido  
- Más realista para servidores  

### 4.2 Recursos de la VM

| Recurso | Valor |
|---------|-------|
| vCPU    | 2     |
| RAM     | 2 GB  |
| Disco   | 20 GB (qcow2) |
| NIC     | virtio, red default libvirt |

### 4.3 Instalación del SO

Durante la instalación:

- Idioma: Inglés  
- Timezone: UTC  
- SELinux: Enforcing  
- Firewall: Enabled  
- Particionado: Automático  
- Perfil: Minimal Install  

> No se agregan paquetes ni servicios adicionales en esta fase.

---

## 4.4 Nombre de la máquina y FQDN


    hostnamectl set-hostname vm-base-rocky9-noc.eu.corp

Archivo /etc/hosts:

    127.0.0.1   localhost
    192.168.122.20 vm-base-rocky9-noc.eu.corp vm-base-rocky9-noc

IP 192.168.122.20 es la IP administrativa fija, usada para SSH y gestión.
El FQDN asegura consistencia en logs y certificados internos.

4.5 SSH – Acceso seguro solo por claves
---
Preparar usuario y carpeta .ssh

    sudo mkdir -p /home/student/.ssh
    sudo chmod 700 /home/student/.ssh
    sudo chown student:student /home/student/.ssh

Instalar clave pública existente

    ssh-copy-id -i /home/jensy/Labs/.ssh/id_rhcsalabs.pub student@192.168.122.20

Ajustar permisos

    sudo chmod 600 /home/student/.ssh/authorized_keys
    sudo chown student:student /home/student/.ssh/authorized_keys

Configurar SSHD

Archivo /etc/ssh/sshd_config:

    PasswordAuthentication no
    PubkeyAuthentication yes
    PermitRootLogin no

Aplicar cambios:

    sudo systemctl reload sshd

Verificar conexión

    ssh -i /home/jensy/Labs/.ssh/id_rhcsalabs student@192.168.122.20

   Garantiza acceso seguro, evitando contraseñas y promoviendo buenas prácticas corporativas.

## 5. Configuración Inicial Post-Instalación
### 5.1 Actualización del sistema


    dnf update -y

### 5.2 Paquetes base de administración

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

   Indispensables para troubleshooting y administración.

## 6. Servicios Corporativos Instalados (SIEMPRE)

Estado inicial: disabled, se activan solo vía cloud-init.
### 6.1 Web – Nginx

    dnf install -y nginx

Archivo virtual host mínimo:

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

Página estática:

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

Deshabilitar servicio:

    systemctl disable --now nginx
    systemctl status nginx

### 6.2 Base de Datos – MariaDB

    dnf install -y mariadb-server

Archivo /etc/my.cnf.d/mariadb-server.cnf:

    [mysqld]
    bind-address = 0.0.0.0

Inicializar DB y usuario:
    
    systemctl start mariadb
    
    mysql << 'EOF'
    CREATE DATABASE appdb;
    CREATE USER 'appuser'@'%' IDENTIFIED BY 'app_pass';
    GRANT ALL PRIVILEGES ON appdb.* TO 'appuser'@'%';
    FLUSH PRIVILEGES;
    EOF
    
    systemctl stop mariadb
    systemctl disable mariadb
    systemctl status mariadb

Bind a 0.0.0.0 permite tests de red/control remoto vía HAProxy.

### 6.3 Proxy TCP – HAProxy

`dnf install -y hapro`xy

Archivo /etc/haproxy/haproxy.cfg:

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

Deshabilitar:

    systemctl disable --now haproxy

# 7. Red y Direccionamiento Base
### 7.1 IP Primaria fija (administrativa)

    nmcli device status
    nmcli connection show
    
    nmcli connection modify "enp1s0" \
      ipv4.method manual \
      ipv4.addresses 192.168.122.20/24 \
      ipv4.gateway 192.168.122.1 \
      ipv4.dns 192.168.122.1
    
    nmcli connection down "enp1s0"
    nmcli connection up "enp1s0"
    ip a show enp1s0
    ip route

### 7.2 VIPs (solo asignadas vía cloud-init)
Servicio	IP

    Web	192.168.122.50
    MariaDB	192.168.122.60
    HAProxy	192.168.122.70

Nunca configurar VIPs manualmente, siempre cloud-init.

# 8. Firewall y SELinux
### 8.1 Firewalld

    firewall-cmd --permanent --add-service=ssh
    firewall-cmd --permanent --add-service=http
    firewall-cmd --permanent --add-port=3306/tcp
    firewall-cmd --reload
    firewall-cmd --list-all

Estado esperado: Enabled, puertos 22/tcp, 80/tcp, 3306/tcp.
### 8.2 SELinux

    getenforce
    setsebool -P httpd_can_network_connect on

Estado esperado: Enforcing, booleanos necesarios habilitados.

   Declaración de arquitectura: el cliente nunca conecta directo a MariaDB, siempre vía HAProxy.

# 9. Estados Iniciales (Punto Cero)

    systemctl is-enabled nginx mariadb haproxy firewalld
    getenforce
    ip a

Componente	Estado

    nginx	disabled
    mariadb	disabled
    haproxy	disabled
    firewalld	enabled
    selinux	enforcing
    VIPs	no asignadas

   Todos los laboratorios Junior parten de este punto cero.

# 10. cloud-init – Rol y límites

cloud-init solo:

    Asignar VIPs
    Encender servicios
    Introducir fallos controlados

cloud-init NO:

    Instala paquetes
    Modifica configuraciones críticas
    Define reglas de negocio



# 11. Nombre Oficial de la VM Base

    vm-base-rocky9-noc

Imagen dorada del ecosistema, no debe cambiar.

# 12. Regla de Oro

Si algo no está definido en este documento, no existe en el laboratorio.


---




