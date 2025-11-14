# Laboratorio RHCSA: Gestión de Usuarios, Grupos y Permisos con SELinux

> **Tiempo estimado**: 45 minutos **Puntos**: 40 **Sistema**: RHEL 9 (mínima instalación) **Acceso**: root

----------

## Objetivo

Configurar usuarios, grupos, permisos avanzados (incluyendo ACL y SGID) y ajustar el contexto de **SELinux** para un directorio compartido de desarrollo.

----------

## Escenario

Eres administrador de un servidor devserver.lab.example.com. El equipo de desarrollo necesita un área compartida para colaborar en proyectos Python.

----------

## Tareas

### 1. Configuración del sistema base (5 pts)

1.  Cambia el hostname a devserver.lab.example.com (persistente).
2.  Asegúrate de que el sistema arranque en modo **multi-user.target**.

bash

```
# Verificación
hostnamectl status
systemctl get-default
```

----------

### 2. Creación de grupos y usuarios (15 pts)

1.  Crea el grupo developers con GID **10000**.
2.  Crea los usuarios:
    -   diana → UID: 1101, grupo primario: developers, shell: /bin/bash
    -   mike → UID: 1102, grupo primario: developers, sin directorio home
3.  Establece la contraseña de diana como: DevSecure2025!
4.  Expira la contraseña de diana en **15 días**.

bash

```
# Verificación
getent group developers
id diana
id mike
chage -l diana
```

----------

### 3. Directorio compartido con SGID y permisos (15 pts)

1.  Crea el directorio /opt/devprojects con propietario root y grupo developers.
2.  Aplica **SGID** al directorio para que todos los nuevos archivos hereden el grupo developers.
3.  Establece permisos 2770 (solo grupo puede escribir, nuevos archivos heredan grupo).
4.  Crea un archivo de prueba: /opt/devprojects/app.py (propietario diana, grupo developers, permisos 660).

bash

```
# Verificación
ls -ld /opt/devprojects
ls -l /opt/devprojects/app.py
```

> Prueba creando un archivo como mike:
> 
> bash
> 
> ```
> su - mike -c "touch /opt/devprojects/test.txt"
> ls -l /opt/devprojects/test.txt
> ```

----------

### 4. Configuración de ACL y SELinux (5 pts)

1.  Da a mike permisos de **lectura y escritura** sobre app.py usando **ACL** (sin cambiar propietario).
2.  Ajusta el contexto SELinux del directorio /opt/devprojects para que sea accesible por **httpd** si se sirve en el futuro:
    
    text
    
    ```
    httpd_sys_content_t
    ```
    
3.  Aplica el contexto **recursivamente**.

bash

```
# Verificación
getfacl /opt/devprojects/app.py
ls -Zd /opt/devprojects
```

----------

## Comandos de verificación final (copia y pega)

bash

```
#!/bin/bash
echo "=== VERIFICACIÓN FINAL ==="
echo "1. Hostname:"
hostnamectl status | grep "Static hostname"

echo -e "\n2. Usuarios y grupos:"
getent group developers
id diana
id mike
chage -l diana

echo -e "\n3. Directorio y permisos:"
ls -ld /opt/devprojects
ls -l /opt/devprojects/app.py
stat /opt/devprojects/app.py | grep Gid

echo -e "\n4. ACL:"
getfacl /opt/devprojects/app.py

echo -e "\n5. SELinux:"
ls -Zd /opt/devprojects
```

----------

## Solución esperada (para autocorrección)

bash

```
# Tarea 1
hostnamectl set-hostname devserver.lab.example.com
systemctl set-default multi-user.target

# Tarea 2
groupadd -g 10000 developers
useradd -u 1101 -g developers -s /bin/bash diana
useradd -u 1102 -g developers -M mike
echo "diana:DevSecure2025!" | chpasswd
chage -M 15 diana

# Tarea 3
mkdir -p /opt/devprojects
chown root:developers /opt/devprojects
chmod 2770 /opt/devprojects
touch /opt/devprojects/app.py
chown diana:developers /opt/devprojects/app.py
chmod 660 /opt/devprojects/app.py

# Tarea 4
setfacl -m u:mike:rw /opt/devprojects/app.py
semanage fcontext -a -t httpd_sys_content_t "/opt/devprojects(/.*)?"
restorecon -Rv /opt/devprojects
```
