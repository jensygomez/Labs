# RHCSA Official Lab Scenario (Versión 1.0)

## 1. Nombre del Laboratorio
**LAB-RHCSA-ROCKY9**

---

## 2. Servidor Principal
**Nombre del servidor:** `server1.lab.local`

**Sistema Operativo:** Rocky Linux 9.6 (Minimal Install)

### Recursos recomendados
- **CPU:** 2 vCPUs
- **RAM:** 4 GB
- **Disco 1:** 40 GB
- **Disco 2:** 10 GB (para prácticas de LVM)

### Configuración de red (estática)
- **Interfaz:** `enp1s0`
- **IP:** `192.168.122.50`
- **Máscara:** `/24 → 255.255.255.0`
- **Gateway:** `192.168.122.1`
- **DNS:** `1.1.1.1`
- **Hostname:** `server1.lab.local`

### Servicios iniciales requeridos
- SELinux: **enforcing**
- firewalld: **activo**
- SSH server: **activo y habilitado**
- NetworkManager: **activo**
- Cockpit: *opcional*

---

## 3. Estructura base del sistema
Creada en `/root/` para todas las tareas:

```
/root/
   admin/
      logs/
      scripts/
```

---

## 4. Usuario inicial de práctica
Este usuario se utilizará en tareas de los Bloques 1–4.

- **Usuario:** `student`
- **Home:** `/home/student`
- **Password:** `redhat`

---

## 5. Paquetes básicos requeridos
Instalar en Rocky Linux:

```bash
sudo dnf install -y vim tmux tree wget curl tar zip unzip bind-utils net-tools policycoreutils-python-utils lsof
```

---

## 6. Snapshot recomendado
Crear en Virt-Manager un snapshot llamado:

**`RHCSA-BASE-CLEAN`**

Este snapshot será el punto cero del laboratorio.

---

## 7. Método de estudio recomendado
Cada día de práctica:
1. Cargar el laboratorio o snapshot previo.
2. Revisar este archivo de progreso.
3. Completar 1–3 tareas tipo examen.
4. Guardar nuevo snapshot si es necesario.

---

## 8. Inicio del Bloque 1
🔵 BLOQUE 1 – Navegación, permisos y usuarios (15 tareas)
1. Navegación y exploración

	Ver ruta actual y navegar entre directorios
	Crear, mover, copiar y borrar archivos
	Buscar archivos con find por nombre, tamaño, tipo y permisos
	Usar grep para filtrar contenido de archivos
	
	### ✔️ Comandos utilizados


    	# Crear directorios iniciales
    	    sudo mkdir /root/admin/scripts
    	    sudo mkdir /root/admin/testing
        
        # Crear archivos de prueba
	        sudo touch /root/admin/testing/file1.txt
	        sudo touch /root/admin/testing/file2.txt
        
        # Añadir contenido a los archivos
	        sudo bash -c 'echo "Este es un archivo de prueba creaado por student" > /root/admin/testing/file1.txt'
	        sudo bash -c 'echo "Linux exam preparation" > /root/admin/testing/file2.txt'
        
        # Crear archivo system.log en logs
	        sudo touch /root/admin/logs/system.log
        
        # Copiar archivo
	        sudo cp /root/admin/logs/system.log /root/admin/scripts/system_backup.log
        
        # Mover archivo
	        sudo mv /root/admin/logs/system.log /root/admin/
        
        ]# Borrar archivo
	        sudo rm /root/admin/scripts/system_backup.log
        
        # Buscar archivos (find)
	        sudo find /root/admin -size +0b -type f -name "file*"
        
        # Buscar texto dentro de archivos (grep)
	        sudo grep -R "student" /root/admin
	        sudo grep -R "Linux" /root/admin
=======================

2. Permisos
	Cambiar permisos con chmod
	Cambiar dueño y grupo con chown
	Configurar permisos especiales: SUID, SGID, Sticky Bit
	Configurar ACLs (setfacl, getfacl)

3. Usuarios y Grupos
	Crear usuarios con contraseña expirable
	Crear usuarios con directorio home personalizado
	Crear grupos y asignar usuarios
	Bloquear y desbloquear cuentas (passwd -l, passwd -u)
	Configurar expiring password policies (chage)

4. sudo
	Dar privilegios sudo a un usuario
	Crear regla sudo personalizada con /etc/sudoers o /etc/sudoers.d/

2. Permisos
Cambiar permisos con chmod
Cambiar dueño y grupo con chown
Configurar permisos especiales: SUID, SGID, Sticky Bit
Configurar ACLs (setfacl, getfacl)

3. Usuarios y Grupos
Crear usuarios con contraseña expirable
Crear usuarios con directorio home personalizado
Crear grupos y asignar usuarios
Bloquear y desbloquear cuentas (passwd -l, passwd -u)
Configurar expiring password policies (chage)

4. sudo
Dar privilegios sudo a un usuario
Crear regla sudo personalizada con /etc/sudoers o /etc/sudoers.d/

🟣 BLOQUE 2 – Storage & LVM (15 tareas)
1. Discos y particiones
Agregar un disco nuevo en Virt-Manager
Crear partición con fdisk o parted
Formatear partición con XFS
Montar disco manualmente con mount

2. LVM
Crear Physical Volumes (PV)
Crear Volume Groups (VG)
Crear Logical Volumes (LV)
Formatear y montar LV

3. Gestión y expansión
Extender LV en caliente
Reducir LV (seguro, paso a paso)
Crear un filesystem y montarlo

4. Montaje persistente
Añadir entradas a /etc/fstab
Verificar automontaje tras reinicio
Usar UUID para montaje estable
Hacer troubleshooting de errores en /etc/fstab

🔴 BLOQUE 3 – Servicios & Systemd (10 tareas)

Iniciar, detener y reiniciar servicios con systemctl
Habilitar y deshabilitar servicios al arranque
Ver logs con journalctl
Filtrar logs por servicio y por tiempo
Crear un servicio systemd manual (.service)
Crear un timer systemd tipo cron
Enmascarar y desenmascarar servicios
Cambiar targets (graphical, multi-user)
Configurar variables de entorno persistentes para servicios
Hacer troubleshooting de fallas en systemd

🟠 BLOQUE 4 – Red y FirewallD (15 tareas)
1. Configuración de red
Configurar IP estática en /etc/NetworkManager/system-connections/
Reiniciar NetworkManager sin perder conexión
Configurar hostname persistente
Probar conectividad con ping, ss, dig, traceroute
2. SSH
Instalar y habilitar SSH
Configurar login con claves públicas
Deshabilitar login por contraseña
Limitar acceso SSH por grupo (AllowGroups)

3. FirewallD
Activar firewalld
Permitir servicios (http, ssh, dhcp, dns)
Abrir puertos específicos
Crear servicios personalizados
Asignar interfaces a zonas
Hacer permanent y runtime cambios
Bloquear tráfico y verificar bloqueo

4. SELinux
Poner SELinux en enforcing
Ver logs de SELinux con sealert
Arreglar booleans SELinux para servicios

🟢 BLOQUE 5 – Web Server (10 tareas)
Instalar Apache y habilitarlo
Configurar DocumentRoot personalizado
Crear virtual hosts (vhosts)
Configurar permisos y SELinux para vhost
Cambiar el puerto de Apache
Permitir nuevo puerto en firewalld
Forzar HTTPS (solo configuración básica)
Instalar NGINX como alternativa
Crear index HTML para testing
Hacer troubleshooting de webserver (SELinux + firewall + permisos)

🟡 BLOQUE 6 – Automatización básica (5 tareas)
Crear script con variables
Script que recibe parámetros $1 $2
Script que usa loops for y while
Script que revisa estado de un servicio
Script que crea usuarios desde archivo CSV

🧩 BONUS – Troubleshooting Real (10 tareas)
Servicio que no inicia (analizar con systemctl status)
Apache sin permisos SELinux
Firewall bloqueando tráfico sin darse cuenta
fstab causando boot failure
IP mal configurada en NetworkManager
Usuario no puede hacer sudo
Permisos de directorios incorrectos para NGINX o Apache

