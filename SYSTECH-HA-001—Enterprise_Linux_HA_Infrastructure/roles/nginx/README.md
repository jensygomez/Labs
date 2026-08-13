# Ansible Role: Nginx (Web Backend Layer)

Este rol de Ansible instala, configura y gestiona **Nginx** como capa de **backend web** en nodos Enterprise Linux (RHEL / Rocky Linux / AlmaLinux) dentro del clúster HA `SYSTECH-HA-001`.

Se ejecuta sobre el grupo `ha_nodes`, detrás de **HAProxy** (que balancea sobre la VIP gestionada por **Keepalived**). Cada nodo del clúster corre su propia instancia de Nginx en un puerto no privilegiado, sirviendo una página identificadora que permite verificar visualmente hacia qué backend está enrutando el balanceador.

---

## 🛠️ Arquitectura y Flujo de Trabajo

1. **Instalación:** instala el paquete `nginx` vía `dnf`/`package`.
2. **Configuración global (`nginx.conf`):** este rol **gestiona el archivo `/etc/nginx/nginx.conf` completo**, reemplazando la configuración de fábrica del paquete RPM. Esto es intencional — ver la sección de *Lecciones Aprendidas* más abajo.
3. **Configuración del servidor (`conf.d/default.conf`):** define el `server` block real, escuchando en `nginx_port` (por defecto `8080`), separado del 80 que ocupa HAProxy en la VIP.
4. **Contenido:** despliega una página `index.html` dinámica que muestra `inventory_hostname` y `ansible_host`, útil para confirmar el balanceo de HAProxy en tiempo real.
5. **SELinux:** si el nodo tiene SELinux en modo `enforcing`, agrega `nginx_port` al contexto `http_port_t` mediante `community.general.seport`, para soportar puertos no estándar sin bloqueos.
6. **Validación de sintaxis:** ambas plantillas (`nginx.conf` y `default.conf`) se validan con `nginx -t` **antes** de escribirse en disco, evitando dejar el servicio en un estado roto.

---

## 📋 Requisitos Previos

* **Inventario de Ansible:** el grupo `ha_nodes` debe estar poblado (mismo grupo que `keepalived` y `haproxy`).
* **Colección `community.general`** instalada en el nodo de control (para el módulo `seport`):
  ```bash
  ansible-galaxy collection install community.general
  ```
* **Paquete `policycoreutils-python-utils`** en los nodos gestionados (provisto por el rol `linux_baseline`).
* **Orden de ejecución:** este rol asume que `keepalived` y `haproxy` ya están desplegados y ocupando el puerto 80 sobre la VIP — Nginx nunca debe competir por ese puerto.

---

## ⚙️ Variables del Rol (`defaults/main.yml`)

```yaml
nginx_port: 8080
nginx_web_root: "/usr/share/nginx/html"
nginx_service_state: "started"
nginx_service_enabled: true
```

---

## Estructura del Rol

```text
roles/nginx/
├── defaults/
│   └── main.yml           # Variables base (puerto, web root, estado del servicio)
├── handlers/
│   └── main.yml           # Reinicio del servicio nginx
├── tasks/
│   └── main.yml           # Instalación, templateo, SELinux, servicio
└── templates/
    ├── nginx.conf.j2       # Configuración global (sin server block de fábrica)
    ├── default.conf.j2     # Server block real, en nginx_port
    └── index.html.j2       # Página identificadora de nodo
```

---

## Despliegue y Ejecución

Para aplicar únicamente el rol de Nginx:

```bash
ansible-playbook site.yml --tags nginx
```

---

## Verificación y Validaciones

### 1. Confirmar que el servicio está activo y en el puerto correcto

```bash
ansible ha_nodes -m command -a "systemctl is-active nginx" -b
ansible ha_nodes -m shell -a "ss -tlnp | grep nginx" -b
```

*Resultado esperado:* `active`, escuchando en `0.0.0.0:8080` (no en `:80`).

### 2. Confirmar que HAProxy sigue dueño del puerto 80 en la VIP

```bash
ansible ha_nodes -m shell -a "ss -tlnp | grep ':80 '" -b
```

*Resultado esperado:* únicamente `haproxy` bindeado a la VIP en el 80 — Nginx no debe aparecer ahí.

### 3. Prueba de balanceo end-to-end (vía VIP)

```bash
for i in {1..12}; do curl -s http://192.168.122.250/ | grep -i "Nodo:"; done
```

*Resultado esperado:* las respuestas rotan entre `server01`, `server02` y `server03` según el algoritmo de balanceo configurado en HAProxy.

---

## 🧩 Lecciones Aprendidas (Incidente documentado)

**Síntoma:** al desplegar el rol por primera vez, Nginx fallaba al arrancar con:
```
nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
```

**Diagnóstico erróneo inicial:** se sospechó de SELinux bloqueando el puerto — descartado tras revisar `journalctl`, que mostró un conflicto de *bind*, no de permisos.

**Causa raíz real:** el paquete RPM de `nginx` en Rocky Linux instala un `nginx.conf` de fábrica que incluye **su propio `server { listen 80; }` embebido**, independiente de lo que el rol despliega en `conf.d/`. El rol original solo gestionaba `conf.d/default.conf` (correctamente apuntando a `8080`), pero nunca tocaba `nginx.conf`, dejando vivo ese segundo `server` block en el puerto 80 — el mismo puerto que ocupa HAProxy sobre la VIP.

**Solución:** se llevó `nginx.conf` bajo gestión de Ansible (`nginx.conf.j2`), eliminando el `server` block de fábrica y dejando solo la configuración global (`http`, `events`, `include conf.d/*.conf`). El `server` block real quedó exclusivamente en `default.conf.j2`, en el puerto `nginx_port`.

**Takeaway:** al auditar un servicio que "no debería" competir por un puerto, verificar **todos** los archivos de configuración que el paquete carga por defecto — no asumir que el `conf.d/` es la única fuente de verdad. Confirmar con evidencia (`ss -tlnp`, `journalctl`) antes de asumir la causa (en este caso, se sospechó de SELinux y el problema era otro).
