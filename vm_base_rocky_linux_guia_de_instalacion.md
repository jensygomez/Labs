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

- Nombre: `rocky-ir-base-junior-v1`
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
- `/etc/nginx/conf.d/default.conf`

Contenido mínimo:
- Listen 80
- Página estática simple

Estado:
- **disabled**

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

Estado:
- **disabled**

---

### 6.3 Proxy TCP – HAProxy

```bash
dnf install -y haproxy
```

Configuración:
- Frontend TCP 3306
- Backend MariaDB real

Estado:
- **disabled**

---

## 7. Red y Direccionamiento Base

### 7.1 IP Primaria

- DHCP de libvirt
- Uso administrativo (SSH)

### 7.2 VIPs (NO asignadas por defecto)

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

- Enabled
- Zonas por defecto
- Puertos abiertos:
  - 22/tcp
  - 80/tcp
  - 3306/tcp

Estado:
- **Sano** (sin bloqueos)

### 8.2 SELinux

- Modo: Enforcing
- Booleanos necesarios habilitados
- Ninguna denegación activa

---

## 9. Estados Iniciales (MUY IMPORTANTE)

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

