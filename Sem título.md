


1. Usuarios, Permisos y SSH
        V1: Usuario student pierde acceso sudo (error de sintaxis en /etc/sudoers.d/).
        V2: Nginx da error 403 Forbidden porque los permisos de /var/www/html son 700 y pertenecen a root.
        V3: No se puede entrar por SSH al NS-SERVICES porque las llaves en .ssh/authorized_keys tienen permisos 777 (SSH las ignora por seguridad).
        V4: Usuario bloqueado por demasiados intentos fallidos (PAM modules).
        V5: El servicio SSH en el servidor se cambió al puerto 2222 y el firewall del Edge lo bloquea.

2. Gestión de Almacenamiento y LVM
        V1: La partición /var/log se llena al 100%, provocando que MariaDB no pueda escribir el log binario y se apague.
        V2: Agotamiento de Inodos: El disco tiene espacio, pero hay millones de archivos pequeños que impiden crear nuevos archivos.
        V3: Extender un volumen lógico (LVM) en caliente porque la base de datos se quedó sin espacio.
        V4: Sistema de archivos montado en Read-Only tras un error simulado.
        V5: Identificar qué proceso tiene "secuestrado" un archivo que no permite desmontar una partición (fuser / lsof).

3. Logs, Monitoreo y Procesos
        V1: Un proceso "zombie" o "runaway" consume el 100% de la CPU en NS-SERVICES.
        V2: journalctl no muestra logs recientes (servicio systemd-journald colgado).
        V3: Identificar una fuga de memoria (Memory Leak) usando top/htop antes de que el OOM Killer actúe.
        V4: Error en la rotación de logs (logrotate) que hace que los logs crezcan indefinidamente.
        V5: Rastrear qué está haciendo un proceso lento usando strace o lsof.

4. Sincronización de Tiempo (NTP/Chrony)
        V1: El servidor tiene un desfase de 10 minutos; los certificados SSL fallan al validar en el cliente.
        V2: El servicio chronyd no sincroniza porque el puerto UDP 123 está cerrado en el NS-EDGE.
        V3: Zona horaria incorrecta causando que los backups programados se ejecuten a la hora que no es.
        V4: Logs con marcas de tiempo incoherentes entre el Cliente y el Servidor.
        V5: Error de "Step time" vs "Slew time" en servidores de bases de datos sensibles.


5. Networking L3/L4 (Conectividad)
        V1: El NS-CLIENT pierde su "Default Gateway" y no llega a la red de servicios.
        V2: Problema de MTU: El ping funciona (paquetes pequeños), pero la web no carga (paquetes grandes se descartan).
        V3: Conflicto de IPs: Una interfaz dummy en el host tiene la misma IP que el NS-SERVICES.
        V4: El reenvío de paquetes (ip_forward) se desactivó en el NS-EDGE.
        V5: Interfaz de red en modo "Promiscuo" o con errores de colisión simulados.

6. DNS y Resolución de Nombres
        V1: El archivo /etc/resolv.conf en el cliente está vacío o apunta a 127.0.0.1.
        V2: El archivo /etc/hosts tiene una entrada vieja que sobreescribe al DNS real.
        V3: dnsmasq en el servidor solo escucha en 127.0.0.1 y no en la IP de la red.
        V4: Resolución recursiva fallida: El DNS interno funciona, pero no puede resolver google.com.
        V5: Orden de resolución incorrecto en /etc/nsswitch.conf.

7. Firewall (Iptables/Firewalld) y SELinux
        V1: SELinux bloquea a Nginx para leer archivos en una carpeta que no es /var/www/.
        V2: firewalld tiene la interfaz en la zona public en lugar de internal, bloqueando MySQL.
        V3: Una regla de Iptables en el NS-EDGE hace DROP silencioso, causando "Timeout" en lugar de "Connection Refused".
        V4: SELinux bloquea a Nginx para actuar como Proxy Inverso (httpd_can_network_connect).
        V5: Reglas de firewall "limpias" que se pierden tras reiniciar (falta el --permanent).

8. Servicios Web (Nginx)
        V1: Error de sintaxis en nginx.conf impide el reinicio (nginx -t).
        V2: El puerto 80 está ocupado por otro proceso (o por un Apache olvidado).
        V3: Error 502 Bad Gateway: Nginx funciona, pero el backend (PHP/App) está caído.
        V4: El servidor web no muestra el index.html por falta de permisos de ejecución en los directorios padres.
        V5: Certificado SSL autofirmado que el cliente rechaza.

9. Bases de Datos (MariaDB)
        V1: MariaDB configurado para escuchar solo en localhost (bind-address), impidiendo acceso externo.
        V2: Se perdió la contraseña de root de la base de datos (procedimiento de recuperación).
        V3: Error "Too many connections": Ajustar límites de archivos abiertos en el sistema (ulimits).
        V4: Corrupción de una tabla específica tras un apagado forzoso (uso de REPAIR TABLE).
        V5: Identificar una "Slow Query" que está bloqueando las demás tablas.

10. Backup, Actualizaciones y Recuperación
        V1: Un mysqldump falla porque el usuario de backup no tiene permisos de LOCK TABLES.
        V2: Tras un dnf update, el Kernel nuevo no arranca y hay que hacer rollback al anterior.
        V3: Restaurar un archivo de configuración crítico desde un backup comprimido .tar.gz.
        V4: Una tarea de cron de backup falló porque el script no tiene rutas absolutas (/usr/bin/).
        V5: Verificar la integridad de un archivo transferido entre namespaces usando sha256sum.
