---

### 📝 Creación de `roles/role_lb_ha/README.md`

Ejecuta este comando en tu terminal para generar la documentación de infraestructura:

```bash
# ⚖️ Rol Base: Ingress & Traffic Generator (`role_lb_ha`)

Este rol es un **módulo utilitario e infraestructura base** de la plataforma. Su objetivo es mantener desplegado y operativo el punto de entrada de Alta Disponibilidad (VIP + HAProxy) y el servicio de tráfico sintético en el nodo cliente.

Servirá como la **capa de soporte fija** sobre la cual se ejecutarán los laboratorios de troubleshooting de los demás módulos (`role_nfs_lvm_storage`, `role_systemd_custom_app`, etc.).

---

## 📐 Arquitectura del Rol

El rol distribuye sus funciones según el grupo de hosts asignado en el inventario:

```text
               [ client ] (Ubuntu)
                   │
                   ├── Service: infinite-scroll.service
                   └── Script: /usr/local/bin/generate_traffic.sh
                           │
                           │  HTTP GET / (1 req/sec)
                           ▼
             VIP: 10.10.10.30 (Keepalived VRRP)
                           │
               ┌───────────┴───────────┐
               ▼                       ▼
      [ lb01 ] (MASTER)       [ lb02 ] (BACKUP)
      10.10.10.11             10.10.10.12
       - Keepalived            - Keepalived
       - HAProxy (Port 80)     - HAProxy (Port 80)
               │                       │
               └───────────┬───────────┘
                           │
                           ▼ (Backends)
             [ app01 ] [ app02 ] [ app03 ]

```

### Funcionalidades:

1. **Nodos Balanceadores (`lb01`, `lb02`):**
* Configura `Keepalived` para sostener la VIP flotante `10.10.10.30`.
* Habilita en el kernel el binding no local (`net.ipv4.ip_nonlocal_bind = 1`).
* Configura `HAProxy` como balanceador L7 repartiendo tráfico hacia la granja de nodos web (`app01..03`).


2. **Nodo Cliente (`client`):**
* Despliega el script `/usr/local/bin/generate_traffic.sh`.
* Crea y habilita el servicio de systemd `infinite-scroll.service`.
* Genera un flujo de tráfico constante (`sleep 1`) guardando registros de disponibilidad en `/var/log/infinite_scroll.log`.



---

## 📁 Estructura Interna del Rol

```text
roles/role_lb_ha/
├── files/
│   └── generate_traffic.sh          # Script bash de peticiones en bucle
├── handlers/
│   └── main.yml                     # Handlers para reiniciar HAProxy/Keepalived
├── tasks/
│   ├── main.yml                     # Enrutador principal de tareas según el host
│   └── client_traffic.yml           # Tareas exclusivas para el nodo cliente
└── templates/
    ├── haproxy.cfg.j2               # Plantilla de configuración de HAProxy
    ├── infinite-scroll.service.j2   # Unidadd systemd para el cliente
    └── keepalived.conf.j2           # Plantilla VRRP de Keepalived

```

---

## ⚙️ Integración en Playbooks (`site.yml`)

Para aplicar este rol base en toda la infraestructura:

```yaml
---
- name: "Despliegue de Infraestructura Base Ingress y Tráfico"
  hosts: loadbalancers:clients
  become: true
  roles:
    - role_lb_ha

```

---

## 📊 Verificación y Diagnóstico del Rol

Una vez aplicado este rol, puedes verificar que la infraestructura base está sana con estos dos comandos:

### 1. Estado de la VIP en los Balanceadores

```bash
# En lb01 (debe mostrar la VIP 10.10.10.30/24):
ip a show eth0

# Verificar el estado de los servicios:
systemctl status keepalived haproxy

```

### 2. Monitoreo de Tráfico Sintético en el Cliente

```bash
# En client (debe responder STATUS: 200 OK de forma continua):
tail -f /var/log/infinite_scroll.log

```

---
