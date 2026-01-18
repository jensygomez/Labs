A continuación tienes un **resumen operativo claro y autosuficiente** del estado de la VM **Base Sana**, pensado para que **cualquier persona** (aunque no haya participado en el diseño) pueda entender **qué servicios existen, cómo están conectados internamente, qué IP usa cada uno y cómo validarlos desde la perspectiva del cliente**.

---

# 📌 RESUMEN OPERATIVO – VM BASE SANA

**Plataforma:** Rocky Linux 10
**Modelo:** Múltiples servicios simulados por IPs internas (interfaces dummy)
**Objetivo:** Laboratorio de Incident Response / Troubleshooting

---

## 🧱 ARQUITECTURA GENERAL

Todos los servicios se ejecutan en **una sola VM**, pero cada uno **simula un servidor independiente** mediante una IP dedicada.

```
CLIENTE
   |
   | DNS → Proxy → Web
   |          |
   |          └── DB
```

No hay contenedores.
No hay dependencias externas.
Todo el tráfico es interno y controlado.

---

## 🌐 MAPA DE SERVICIOS E IPs

| Servicio | Rol     | IP            | Puerto |
| -------- | ------- | ------------- | ------ |
| WEB      | Nginx   | `10.10.10.10` | 80     |
| DB       | MariaDB | `10.10.20.10` | 3306   |
| PROXY    | Squid   | `10.10.30.10` | 3128   |
| DNS      | dnsmasq | `10.10.40.10` | 53     |

Interfaces internas (dummy):

```
dummy-web
dummy-db
dummy-proxy
dummy-dns
```

---

## 🔎 SERVICIOS ACTIVOS

### ✔ DNS – Resolución de nombres

* Servicio: `dnsmasq`
* Resuelve nombres internos del laboratorio
* Ejemplo:

  ```
  web.lab.local → 10.10.10.10
  ```

---

### ✔ Proxy – Salida HTTP controlada

* Servicio: `squid`
* IP dedicada: `10.10.30.10`
* Todo acceso web del cliente pasa por aquí

---

### ✔ Web – Aplicación simulada

* Servicio: `nginx`
* Página de prueba:

  ```
  WEB OK - Base Sana
  ```

---

### ✔ Base de Datos – Backend

* Servicio: `mariadb`
* Contiene datos de estado de servicios
* Acceso remoto habilitado

---

## 🧪 PRUEBAS DESDE LA PERSPECTIVA DEL CLIENTE

> Estas pruebas simulan lo que haría un **usuario / cliente / sysadmin** al validar el entorno.

---

### 1️⃣ Verificar DNS

```bash
dig @10.10.40.10 web.lab.local
```

Resultado esperado:

```
web.lab.local.  A  10.10.10.10
```

---

### 2️⃣ Verificar Proxy

```bash
ss -lntp | grep 3128
```

Resultado esperado:

```
10.10.30.10:3128  LISTEN
```

---

### 3️⃣ Acceder al sitio WEB (vía Proxy)

```bash
export http_proxy=http://10.10.30.10:3128
curl http://web.lab.local
```

Resultado esperado:

```
WEB OK - Base Sana
```

---

### 4️⃣ Verificar Base de Datos

```bash
mysql -u labuser -plabpass -h 10.10.20.10 labdb \
-e "SELECT * FROM incidents;"
```

Resultado esperado:

```
+----+---------+--------+
| id | service | status |
+----+---------+--------+
|  1 | WEB     | UP     |
|  2 | DB      | UP     |
|  3 | DNS     | UP     |
|  4 | PROXY   | UP     |
+----+---------+--------+
```

---

### 5️⃣ Verificar servicios activos

```bash
systemctl is-active nginx
systemctl is-active squid
systemctl is-active dnsmasq
systemctl is-active mariadb
```

Resultado esperado:

```
active
```

---

## 🔐 FIREWALL Y PERSISTENCIA

* Firewall activo pero **no bloquea tráfico interno**
* Interfaces dummy persistentes tras reboot

```bash
systemctl is-enabled lab-dummy-net
```

Resultado:

```
enabled
```

---

## 🟢 ESTADO FINAL

**Estado del entorno:**
✅ **TOTALMENTE FUNCIONAL**
✅ **LISTO PARA SNAPSHOT**
✅ **BASE ESTABLE PARA CLONAR E INYECTAR FALLOS**

---

Este documento puede guardarse como:

```
BASE_SANA_OVERVIEW.md
```

Cuando quieras, pasamos al **diseño del V01** y decidimos **qué romper primero** (DNS, Proxy, Firewall, SELinux, DB o combinación realista).
