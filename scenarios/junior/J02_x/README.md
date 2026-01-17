# J02: Troubleshooting Firewalld y SELinux

## Laboratorio Junior 02

**Título**: Diagnóstico de problemas de conectividad por seguridad
**Dificultad**: Junior → Intermedio
**Duración estimada**: 90 minutos
**VMs**: 1 Server (192.168.122.20) | Host como Client

## Objetivos de Aprendizaje

- Identificar bloqueos de firewalld por puerto/servicio/zona
- Diagnosticar denegaciones SELinux con `sealert` y `audit.log`
- Diferenciar soluciones temporales vs permanentes
- Aplicar rich rules vs servicios tradicionales
- Validar conectividad desde host (curl, telnet, nc)


## Requisitos Previos

```
Host (tu máquina): curl, telnet, nc instalados
VM Server IP fija: 192.168.122.20
Servicios: firewalld, SELinux (enforcing), nginx, mariadb
```


## Estructura de Escenarios

| Variante | Problema Principal | Herramientas | Solución Esperada |
| :-- | :-- | :-- | :-- |
| **V01** | Firewalld bloquea HTTP (80) | `firewall-cmd --list-all` | `--add-service=http` |
| **V02** | Firewalld bloquea MySQL (3306) + zona | `firewall-cmd --get-zone` | `--zone=internal` |
| **V03** | SELinux bloquea Nginx | `sealert -a /var/log/audit.log` | `restorecon` |
| **V04** | SELinux MariaDB + Rich Rule | `ausearch -m avc` | `semanage fcontext` + rich rule |

## Comandos de Diagnóstico Maestros

### Firewalld

```bash
# Estado general
sudo firewall-cmd --list-all
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --info-service=http

# Zonas y servicios
sudo firewall-cmd --zone=public --list-all
sudo firewall-cmd --get-zone-of-interface=eth0

# Rich rules
sudo firewall-cmd --list-rich-rules
```


### SELinux

```bash
# Estado
sestatus

# Últimos errores
sudo sealert -a /var/log/audit/audit.log
sudo ausearch -m avc -ts recent

# Contextos
ls -Z /usr/share/nginx/html/
ls -Z /var/lib/mysql/
```


## Testing desde Host (Client)

```bash
# Desde tu host, apuntando a la VM
curl -I http://192.168.122.20
curl http://192.168.122.20:3306
telnet 192.168.122.20 80
nc -zv 192.168.122.20 3306
```


## Escenarios Detallado

### 🟡 V01 - Firewalld HTTP Básico

```
🔴 PROBLEMA: curl http://192.168.122.20 → Connection refused
✅ Nginx corriendo: systemctl status nginx → active
❓ firewalld: puerto 80 bloqueado
```

**Tareas**:

1. `firewall-cmd --list-all` → http NO permitido
2. `firewall-cmd --add-service=http --permanent`
3. `firewall-cmd --reload`
4. Test: `curl http://192.168.122.20` desde host

### 🟡 V02 - Firewalld MySQL + Zonas

```
🔴 PROBLEMA: MySQL puerto 3306 bloqueado
❓ Zona "public" activa en eth0
✅ Client (host) está en misma red → debería ser "internal"
```

**Tareas**:

1. Cambiar zona: `firewall-cmd --zone=internal --add-interface=eth0 --permanent`
2. O servicio directo: `firewall-cmd --add-service=mysql --permanent`
3. Test: `nc -zv 192.168.122.20 3306`

### 🔴 V03 - SELinux Nginx

```
🔴 PROBLEMA: Nginx no sirve página
✅ Puerto 80 abierto
❓ SELinux deniega acceso a /usr/share/nginx/html
```

**Diagnóstico**:

```bash
sudo sealert -a /var/log/audit/audit.log | grep nginx
ls -Z /usr/share/nginx/html/  # Debe ser httpd_sys_content_t
```

**Solución**:

```bash
sudo restorecon -Rv /usr/share/nginx/html/
sudo systemctl restart nginx
```


### 🔴 V04 - Combo SELinux + Rich Rules

```
🔴 PROBLEMA: MariaDB puerto custom 3307
❓ SELinux bloquea /data/mysql/
❓ Rich rule mal escrita
```

**Rich Rule Correcta**:

```bash
firewall-cmd --permanent --add-rich-rule='
  rule family="ipv4" 
  source address="192.168.122.0/24" 
  port port="3307" protocol="tcp" accept'
firewall-cmd --reload
```


## Checklist de Validación

| ✓ Tarea | V01 | V02 | V03 | V04 |
| :-- | :-- | :-- | :-- | :-- |
| Servicios corriendo | nginx | mariadb | nginx | mariadb |
| Puerto accesible | 80 | 3306 | 80 | 3307 |
| Firewalld correcto | service | zone | ✓ | rich |
| SELinux contexto | ✓ | ✓ | restorecon | semanage |
| Test desde host | curl | nc | curl | nc |

## Consejos Pro

```
# Temporal (debugging)
firewall-cmd --add-port=80/tcp
setenforce 0  # ¡CUIDADO! Solo testing

# Permanente (producción)
firewall-cmd --add-service=... --permanent
semanage fcontext -a -t httpd_sys_content_t "/data/web(/.*)?"
restorecon -Rv /data/web
```


## Métricas de Éxito

```
⏱️ Tiempo esperado: 20min por variante
🎯 Éxito: 4/4 escenarios resueltos
📚 Aprendizaje: dominar sealert + firewall-cmd --list-all
```


