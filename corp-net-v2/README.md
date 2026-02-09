Para que un proyecto de este tamaño no se convierta en "código espagueti", el **README** debe ser tu brújula. No solo dirá qué hace el script, sino cómo debe ser tu mentalidad de Sysadmin al usarlo.

Aquí tienes el diseño del `README.md` para tu nueva infraestructura **CorpNet-v2**.

---

# 🚀 CorpNet-v2: Empresa en un Servidor

> **Objetivo:** Simular una infraestructura empresarial real mediante Namespaces de Linux para entrenamiento de Sysadmin Junior/Pleno.

## 🏗️ Arquitectura de la Red

El diseño sigue un modelo **Hub-and-Spoke**. Todo el tráfico entre departamentos pasa por un Router Central (`CORE-GW`), permitiendo practicar firewalls, ruteo y segmentación.

---

## 📂 Estructura del Proyecto

```text
corp-net-v2/
├── topology/           # DATOS: La "verdad" de la red
│   ├── nodes.conf      # Definición de Nodos (Nombre, Rol, IP)
│   └── links.conf      # Mapa de conexiones (Cables veth)
├── lib/                # LÓGICA: El cerebro (scripts reutilizables)
│   ├── core.sh         # Gestión de Namespaces y Veth
│   ├── network.sh      # Configuración de IPs, Rutas y Forwarding
│   └── security.sh     # Implementación de Firewalls (UFW)
├── services/           # SERVICIOS: Configuración de Apps
│   ├── web/            # Nginx / Apache
│   ├── dns/            # Bind9 / Dnsmasq
│   └── db/             # MariaDB / PostgreSQL
├── engine.sh           # ORQUESTADOR: El script que ejecuta todo
└── README.md           # Esta guía

```

---

## 🛠️ Principios de Diseño (Tu "Código de Honor")

1. **Separación de Datos y Lógica:** Si quieres agregar un usuario, **NUNCA** toques `engine.sh`. Solo agrega una línea en `topology/nodes.conf`.
2. **Idempotencia:** Puedes ejecutar `./engine.sh` diez veces y el resultado siempre debe ser el mismo (sin errores de "el archivo ya existe").
3. **Visibilidad:** Cada fase debe informar qué está haciendo. Si algo falla, el motor debe detenerse (`set -e`).

---

## 🔍 Mapa de Entrenamiento (Troubleshooting)

Este laboratorio está diseñado para que "rompas" cosas y las arregles:

| Nivel | Desafío de Sysadmin | Herramienta Clave |
| --- | --- | --- |
| **Junior** | El usuario no tiene internet (falta Gateway). | `ip route` |
| **Junior** | El servicio web no responde (puerto cerrado). | `ufw status` |
| **Pleno** | Conectividad intermitente (MTU Mismatch). | `ip link` / `ping -s` |
| **Pleno** | El router está saturado (Análisis de Conntrack). | `conntrack -L` |

---

## 🚦 Comandos Rápidos

* **Levantar todo:** `sudo ./engine.sh --up`
* **Limpiar laboratorio:** `sudo ./engine.sh --clean`
* **Entrar a un nodo:** `sudo ip netns exec [NOMBRE_NODO] bash`
* **Ver tráfico en vivo:** `sudo ip netns exec CORE-GW tcpdump -i any`

---

## 🛡️ Configuración del Firewall (UFW)

Cada nodo tendrá su propio firewall independiente.

* Los **Usuarios** (`USR-RH`) tendrán por defecto `deny incoming`.
* Los **Servidores** solo abrirán los puertos necesarios (80, 53, 3306).
* El **Core Gateway** manejará el NAT y las políticas de tránsito.

---
