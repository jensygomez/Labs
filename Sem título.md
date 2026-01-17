CLIENT01 (192.168.122.21)
↓ /etc/hosts
Server_EU (192.168.122.22 - SSH/Admin)
├─ 192.168.122.50:80 ← www.paginaweb.com (Nginx) ✅
└─ 192.168.122.60:3306 ← basededatos (MariaDB) ✅

text

## 🔑 CLIENT01 CONFIGURACIÓN

**IP**: `192.168.122.21`
**/etc/hosts**:

127.0.0.1 localhost
192.168.122.50 www.paginaweb.com
192.168.122.60 basededatos

text

**Tests**:
```bash
ping -c 2 www.paginaweb.com    # 192.168.122.50 ✓
ping -c 2 basededatos          # 192.168.122.60 ✓
curl http://www.paginaweb.com  # Página web ✓
nc -zv basededatos 3306        # DB puerto ✓

🖥️ SERVER_EU CONFIGURACIÓN

IP Admin: 192.168.122.22 (SSH)
VIPs activas:

text
enp1s0:
├── 192.168.122.22/24  (Admin/MariaDB)
├── 192.168.122.50/24  (Nginx Web) 
└── 192.168.122.60/24  (MariaDB VIP)

Servicios corriendo:

text
nginx        → systemctl status nginx      # Port 80 (VIP .50)
mariadb      → systemctl status mariadb    # Port 3306 (VIP .60)
firewalld    → firewall-cmd --list-all

🗝️ BASE DE DATOS CREDENCIALES

text
Usuario: user_prueba
Password: Pass1234!
Database: db_prueba
Host: basededatos (192.168.122.60)
Puerto: 3306

Test completo:

bash
mysql -u user_prueba -pPass1234! -h basededatos -P 3306 -e "SHOW DATABASES;"

=========================================
=========================================




1. Redes y conectividad
        Variante V01 – ICMP / Rutas bloqueadas (Firewall)
        Variante V02 – DNS roto (resolución incorrecta)
        Variante V03 – Puerto cerrado (Firewall / Servicio)
        Variante V04 – Latencia / pérdida de paquetes (tc)

2. Troubleshooting de firewalls y SELinux

Objetivo: Aprender a detectar problemas de conectividad por seguridad.

Subtemas / escenarios:

Firewalld bloqueando puerto HTTP o MySQL.

SELinux en modo enforcing bloqueando Nginx o MariaDB.

Reglas ricas vs zonas (public, internal).

Permitir temporalmente puerto y verificar acceso.



3. Servicios Web (Nginx/Apache)

Objetivo: Diagnosticar problemas de web server y contenido dinámico.

Subtemas / escenarios:

Nginx no inicia → error de puerto ocupado o configuración malformada.

Página no carga → problema de permisos o root incorrecto.

Logs (error.log / access.log) mostrando errores.

Redirecciones incorrectas o certificados SSL faltantes.

VMs necesarias: 1 (SERVER_EU con .50)
Servicios necesarios: Nginx, opcional PHP o contenido estático

4. Bases de datos (MariaDB/MySQL)

Objetivo: Diagnosticar conexión, permisos y rendimiento.

Subtemas / escenarios:

Cliente no puede conectar → firewall, puerto o VIP incorrecto.

Credenciales incorrectas → Access denied for user.

Base corrupta o tabla bloqueada → uso de mysqlcheck.

Consumo de recursos → detectar procesos lentos o locks.

VMs necesarias: 1 (SERVER_EU con .60)
Servicios necesarios: MariaDB

5. Administración de usuarios y permisos

Objetivo: Resolver problemas de acceso a archivos y servicios.

Subtemas / escenarios:

Usuario no puede escribir/leer logs de Nginx o MariaDB.

sudo no funciona por configuración incorrecta.

Problemas de grupos y permisos en /var/www/html.

Archivos críticos de configuración con permisos root-only.

VMs necesarias: 1-2
Servicios necesarios: Nginx, MariaDB, SSH

6. Logs y monitoreo

Objetivo: Localizar errores a partir de logs y métricas.

Subtemas / escenarios:

Nginx o MariaDB caído → revisar logs (journalctl, /var/log/).

Detectar saturación de CPU/memoria.

Monitorización de conexiones TCP usando ss o netstat.

Crear alertas manuales simulando un incidente.

VMs necesarias: 2
Servicios necesarios: todos los servicios instalados, journalctl, top, htop, ss

7. Problemas de DNS y resolución de nombres

Objetivo: Diagnosticar fallas de resolución interna y externa.

Subtemas / escenarios:

/etc/hosts incorrecto → curl/nc fallan.

DNS caching roto → systemd-resolve --flush-caches.

Conexión externa bloqueada por firewall pero interna funciona.

Simular subdominio faltante.

VMs necesarias: 2 (CLIENT01 + SERVER_EU)
Servicios necesarios: Nginx, MariaDB, resolvers locales (opcional BIND)

8. Backup y restauración de servicios

Objetivo: Resolver problemas de pérdida de datos o configuración.

Subtemas / escenarios:

Restaurar MariaDB desde dump (mysqldump).

Restaurar configuración de Nginx corrupta.

Verificar integridad de archivos con md5sum / sha256sum.

Simulación de caída de servidor y recuperación en otra VM.

VMs necesarias: 2 (CLIENT01 + SERVER_EU)
Servicios necesarios: MariaDB, Nginx, SCP/RSYNC

9. Actualizaciones y parches

Objetivo: Resolver problemas tras actualización de paquetes.

Subtemas / escenarios:

Nginx/MariaDB falla tras yum update.

Kernel nuevo y servicios que no arrancan.

Dependencias faltantes → librerías faltantes en logs.

Rollback de paquetes y testing.

VMs necesarias: 1-2
Servicios necesarios: todos los servicios

10. Troubleshooting de conectividad avanzada / redes corporativas

Objetivo: Resolver problemas que simulan entornos corporativos complejos.

Subtemas / escenarios:

Multi-VIP, cliente accede a la IP equivocada.

Redirección NAT simulada con iptables → HTTP o DB no responde.

Proxy inverso mal configurado → Nginx → Backend MariaDB.

Pruebas con herramientas de red: tcpdump, iptables -L, traceroute.

VMs necesarias: 2-3
Servicios necesarios: todos los servicios, firewalld, tcpdump
