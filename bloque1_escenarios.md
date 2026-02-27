# Bloque 1 — Fundamentos del sistema
> Estilo de ejercicio: escenario real → tú decides el comando → yo verifico
> ★ = aparece en LFCS y RHCSA

---

## Navegación filesystem ★

| Nivel | Escenario de examen |
|-------|-------------------|
| Básico | "Lista el contenido de /etc mostrando permisos, propietario y fecha de modificación" |
| Básico | "Encuentra todos los archivos .conf en /etc modificados en los últimos 7 días y guarda la lista en /tmp/recientes.txt" |
| Intermedio | "Encuentra todos los archivos .log en /var/log mayores de 10MB y muestra cuántas líneas tiene cada uno" |
| Intermedio | "Muestra el inode, propietario y fecha de último acceso del archivo /etc/hostname" |
| Avanzado | "Encuentra todos los archivos en /etc que sean mayores de 100 bytes, tengan extensión .conf sin distinguir mayúsculas, y pertenezcan al usuario root" |
| Avanzado | "Encuentra todos los archivos en /var que no hayan sido accedidos en más de 30 días y elimínalos" |
| Troubleshooting | "Un archivo fue eliminado pero el proceso que lo usa sigue corriendo y ocupando espacio en disco. Encuéntralo y libera el espacio sin matar el proceso" |

---

## Permisos estándar ★

| Nivel | Escenario de examen |
|-------|-------------------|
| Básico | "Crea el archivo /tmp/reporte.txt y asígnale permisos 644" |
| Básico | "Cambia el propietario de /opt/app al usuario deploy y al grupo developers" |
| Intermedio | "Configura el directorio /data para que el propietario pueda leer y escribir, el grupo solo leer, y otros no tengan ningún acceso" |
| Intermedio | "Establece un umask de 027 para el usuario juan de forma persistente" |
| Avanzado | "Configura /etc/app/config.conf para que solo root pueda leerlo, el servicio appd lo pueda leer pero no modificar, y nadie más tenga acceso" |
| Avanzado | "Todos los archivos nuevos creados en /srv/compartido deben heredar los permisos del directorio automáticamente" |
| Troubleshooting | "El servicio httpd no puede leer /var/www/html/index.html aunque el archivo existe. Diagnostica y corrige sin cambiar el propietario del archivo" |

---
Escenario de Examen:
Contexto: 
Tarea: 
Requerimientos técnicos:

## Permisos especiales ★

| Nivel | Escenario de examen |
|-------|-------------------|
| Básico | "Explica qué hace el bit SUID en /usr/bin/passwd y por qué es necesario" |
| Básico | "Aplica el sticky bit al directorio /tmp/compartido para que cada usuario solo pueda borrar sus propios archivos" |
| Intermedio | "Configura el directorio /proyectos/dev para que cualquier archivo creado dentro herede automáticamente el grupo developers" |
| Intermedio | "Encuentra todos los binarios en /usr/bin que tengan SUID activo" |
| Avanzado | "Audita el sistema y lista todos los archivos con SUID o SGID que no pertenezcan a root" |
| Avanzado | "Crea un script que solo pueda ser ejecutado con los privilegios del propietario sin usar sudo" |
| Troubleshooting | "Un usuario reporta que puede borrar archivos de otros usuarios en /var/tmp. Identifica el problema y corrígelo" |

---

## ACLs ★

| Nivel | Escenario de examen |
|-------|-------------------|
| Básico | "Muestra las ACLs actuales del directorio /var/www/html" |
| Básico | "Agrega permisos de lectura al usuario maria sobre el archivo /opt/reporte.csv sin cambiar el propietario ni los permisos estándar" |
| Intermedio | "Configura /proyectos para que cualquier archivo nuevo creado dentro otorgue automáticamente permisos de lectura al grupo auditores" |
| Intermedio | "Agrega permisos de lectura y escritura al usuario deploy sobre /var/www/html y que se hereden a todos los archivos nuevos" |
| Avanzado | "Configura ACLs en /data/contabilidad para que el usuario auditor tenga solo lectura, el grupo contabilidad tenga lectura y escritura, y el grupo ti no tenga ningún acceso aunque sea propietario del directorio" |
| Troubleshooting | "El usuario carlos tiene permisos estándar de lectura sobre /datos pero no puede acceder. Las ACLs muestran una entrada para carlos con rwx. Encuentra por qué falla" |

---

## Links ★

| Nivel | Escenario de examen |
|-------|-------------------|
| Básico | "Crea un link simbólico llamado /opt/config que apunte a /etc/httpd/conf/httpd.conf" |
| Básico | "Crea un hard link de /etc/hostname llamado /tmp/hostname-backup" |
| Intermedio | "Explica por qué no puedes crear un hard link entre /etc/hostname y /tmp/hostname si están en distintas particiones" |
| Intermedio | "Encuentra todos los links simbólicos rotos en /etc" |
| Avanzado | "Crea una estructura donde múltiples servicios compartan el mismo archivo de configuración usando links, de forma que al editar uno se actualicen todos" |
| Troubleshooting | "Un servicio falla al arrancar con error 'file not found' pero el archivo existe. Investiga si hay links rotos involucrados y corrígelo" |

---

## Compresión ★

| Nivel | Escenario de examen |
|-------|-------------------|
| Básico | "Comprime el directorio /etc/httpd en un archivo llamado /tmp/httpd-backup.tar.gz" |
| Básico | "Extrae el contenido de /tmp/backup.tar.gz en el directorio /opt/restore" |
| Intermedio | "Comprime /var/log usando bzip2 y compara el tamaño resultante con gzip. ¿Cuál comprime más?" |
| Intermedio | "Lista el contenido de un archivo .tar.gz sin extraerlo" |
| Avanzado | "Crea un backup incremental diario de /etc que solo incluya los archivos modificados en las últimas 24 horas y excluya los archivos .tmp" |
| Troubleshooting | "Tienes un archivo .tar.gz que al extraer da error de checksum en algunos archivos. Extrae solo los archivos que no están corruptos" |

---

## Gestión de paquetes ★

| Nivel | Escenario de examen |
|-------|-------------------|
| Básico | "Instala el paquete httpd, verifica que está instalado y muestra su versión" |
| Básico | "Elimina el paquete vsftpd sin eliminar sus dependencias" |
| Intermedio | "Lista todos los paquetes instalados que contengan 'ssh' en el nombre" |
| Intermedio | "Muestra el historial de transacciones de dnf y deshaz la última instalación" |
| Avanzado | "Configura un repositorio local usando el ISO de Rocky Linux 9 montado en /mnt/iso" |
| Avanzado | "Verifica la integridad de todos los archivos instalados por el paquete httpd y reporta si alguno fue modificado" |
| Troubleshooting | "dnf update falla con error de dependencias rotas. Diagnostica y repara sin reinstalar el sistema" |

---

## Vim ★

| Nivel | Escenario de examen |
|-------|-------------------|
| Básico | "Abre /etc/hostname con vim, cambia el nombre y guarda sin salir" |
| Básico | "Abre un archivo con vim y ve directamente a la línea 50" |
| Intermedio | "En /etc/httpd/conf/httpd.conf busca todas las ocurrencias de 'Listen' y cámbialas a 'Listen 8080'" |
| Intermedio | "Abre dos archivos simultáneamente en vim y copia contenido de uno al otro" |
| Avanzado | "Crea un macro en vim que comente automáticamente líneas con # al principio" |
| Troubleshooting | "Estás editando /etc/fstab en un servidor remoto y la conexión SSH se cortó. El archivo quedó con un swap file. Recupéralo sin perder cambios" |

---

*Nota: En el examen real nunca te dicen qué comando usar. Te dan el escenario y tú decides cómo resolverlo. El resultado es verificado automáticamente.*
