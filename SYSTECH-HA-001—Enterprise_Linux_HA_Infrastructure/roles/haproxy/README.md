# Ansible Role: HAProxy (High Availability Load Balancer)

Este rol de Ansible instala, configura y gestiona **HAProxy** en nodos Enterprise Linux (RHEL / Rocky Linux / AlmaLinux) dentro de un entorno de Alta Disponibilidad (HA).

Se integra sobre la capa de red gestionada por **Keepalived**, permitiendo hacer binding a una **IP Virtual Flotante (VIP)** compartida, realizando balanceo de carga en Capa 7 (HTTP) y exponiendo una interfaz de métricas en tiempo real.

---

## 🛠️ Arquitectura y Flujo de Trabajo

1. **Kernel Tuning (`sysctl`):** Habilita `net.ipv4.ip_nonlocal_bind = 1` para permitir que el servicio HAProxy se inicie y escuche en una VIP que puede no estar asignada localmente al nodo pasivo.
2. **Gestión de Paquetes y Servicio:** Instala el paquete `haproxy`, habilita y asegura el arranque del servicio mediante `systemctl`.
3. **Configuración Dinámica (Jinja2):** Genera `/etc/haproxy/haproxy.cfg` utilizando los hosts definidos en la variable de inventario `ansible_host` para mapear los backends de forma automática.
4. **Monitoreo & Telemetría:** Habilita el socket local y la interfaz web de estadísticas (*Stats Page*) en el puerto `:9000`.

---

## 📋 Requisitos Previos

* **Inventario de Ansible:** El grupo `ha_nodes` debe definir la variable `ansible_host` para cada nodo.
* **Integración de Red:** Idealmente ejecutado tras el rol de `keepalived` (Fase 09a).

---

## ⚙️ Variables del Rol (`defaults/main.yml`)

```yaml
# Puerto donde escucha el frontend de HAProxy
haproxy_frontend_port: 80

# Puerto de los servidores backend
haproxy_backend_port: 80

# Algoritmo de balanceo (roundrobin, leastconn, source)
haproxy_backend_balance: roundrobin

# Configuración de la VIP (fallback si no se define en group_vars)
keepalived_vip: "192.168.122.250"
