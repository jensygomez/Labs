¡Perfecto! Aquí está tu lista completa con el usuario indicado al final de cada ejercicio:

---

# 🚀 Guía de Inicio Rápido: Laboratorio Linux Foundation (LFCS/RHCSA)

¡Bienvenido a tu entorno de práctica! Este contenedor LXC ha sido provisionado automáticamente con Terraform y Ansible. Está diseñado para que practiques, rompas y repares sin miedo.

### 🖥️ Datos de Conexión
- **Nombre del Host:** `lf-practice`
- **Dirección IP:** `10.10.10.90`
- **Sistema Operativo:** AlmaLinux 9

### 🔑 Credenciales de Acceso
Desde tu nodo de control (el contenedor de Podman donde estás ahora), conéctate usando SSH. La contraseña por defecto para los usuarios con contraseña es: **`LabPassword123!`**

| Usuario | Contraseña | Propósito / Notas |
| :--- | :--- | :--- |
| **ansible** | `LabPassword123!` | Usuario administrador. Tiene `sudo` sin contraseña. Úsalo para instalar paquetes o configurar el sistema. |
| **alice** | `LabPassword123!` | Usuario normal. **Nota:** Está configurado para forzarte a cambiar la contraseña en el primer inicio de sesión. |
| **bob** | `LabPassword123!` | Usuario normal (UID 1500). Usado para ejercicios de envejecimiento de contraseñas y bloqueos. |
| **serviceaccount**| *(N/A)* | Cuenta de sistema. Tiene shell `/sbin/nologin`. No se puede usar para iniciar sesión. |
| **root** | *(Ver secrets)* | Acceso directo deshabilitado por SSH. Usa `sudo -i` o `sudo su -` desde el usuario `ansible`. |

### 📂 ¿Dónde están los materiales de práctica?
Ansible ya preparó el terreno para ti. La mayoría de los ejercicios se resuelven en estas ubicaciones:
- **Directorios de ejercicios:** `/opt/exercises/level-01-explorer/` hasta `level-08-selinux-master/`
- **Archivos de prueba:** `/opt/exercises/level-01-explorer/sample.txt`, etc.
- **Directorios con permisos especiales:** `/shared/team` (SGID) y `/tmp/test-sticky` (Sticky Bit).

### 💡 Reglas de Oro para este Laboratorio
1. **No hagas trampa:** Intenta resolverlo primero. Si te atascas, usa `man <comando>` o `tldr <comando>`.
2. **Usa `sudo`:** Si un comando dice "Permission denied", recuerda que la mayoría de las tareas de configuración requieren privilegios de root.
3. **¿Rompió todo?** No pasa nada. Sal del LXC, ve a la carpeta `terraform` y ejecuta `tofu destroy` y luego `tofu apply`. En 2 minutos tendrás un entorno 100% limpio y nuevo.

---

## 📋 TRAIL: Linux Foundation Mastery (75 ejercicios)

### 🟢 NIVEL 1: El Explorador (Navegación y Archivos) [10 ejercicios]
*Objetivo: Dominar la navegación, manipulación de archivos y redirecciones.*

1. Navega hasta `/var/log` y lista todos los archivos ordenados por fecha de modificación (más recientes primero). (Usuario: alice)
2. Crea la estructura de directorios `/opt/practice/{docs,scripts,backups}` con un solo comando. (Usuario: ansible)
3. Crea un archivo vacío llamado `test.txt` en tu home. Añádele 3 líneas de texto usando redirección `>>`. (Usuario: alice)
4. Copia recursivamente `/etc/skel` a `/tmp/skel-backup` preservando permisos. (Usuario: ansible)
5. Mueve todos los archivos `.tmp` de `/tmp` a `/tmp/old-files` (crea el directorio si no existe). (Usuario: ansible)
6. Elimina recursivamente un directorio con contenido usando un solo comando. (Usuario: alice)
7. Crea un enlace simbólico de `/etc/hostname` en tu home llamado `my-hostname-link`. (Usuario: alice)
8. Crea un enlace duro de `/etc/hostname` en tu home llamado `my-hostname-hard`. Verifica con `ls -i` que comparten el mismo inodo. (Usuario: alice)
9. Redirige la salida de `ls /nonexistent` a `/dev/null` para suprimir errores, y la salida estándar a `~/list.txt`. (Usuario: alice)
10. Encadena comandos: lista archivos de `/etc`, filtra los que contienen "host", y guarda el resultado en `~/hosts-files.txt`. (Usuario: alice)

### 🟡 NIVEL 2: El Buscador (Búsqueda y Procesamiento de Texto) [10 ejercicios]
*Objetivo: Dominar find, grep, awk, sed, sort, cut, wc.*

11. Encuentra todos los archivos `.conf` en `/etc` modificados en los últimos 7 días. (Usuario: ansible)
12. Busca archivos mayores a 10MB en todo el sistema y lista sus rutas. (Usuario: ansible)
13. Encuentra archivos que pertenezcan al usuario `root` y tengan permisos SUID. (Usuario: ansible)
14. Usa `grep` para buscar todas las líneas que contengan "error" (case-insensitive) en `/var/log/messages`. (Usuario: ansible)
15. Usa `grep -E` con expresiones regulares para extraer todas las direcciones IPv4 de `/var/log/secure`. (Usuario: ansible)
16. Usa `awk` para imprimir solo el nombre de usuario (columna 1) y el shell (columna 7) de `/etc/passwd`. (Usuario: alice)
17. Usa `sed` para reemplazar todas las ocurrencias de "root" por "admin" en una copia de `/etc/passwd`. (Usuario: alice)
18. Ordena `/etc/passwd` por UID (columna 3) numéricamente. (Usuario: alice)
19. Cuenta cuántos usuarios tienen `/bin/bash` como shell usando `grep` y `wc`. (Usuario: alice)
20. Combina `find`, `xargs` y `grep` para buscar la palabra "password" en todos los archivos `.conf` de `/etc`. (Usuario: ansible)

### 🟠 NIVEL 3: El Arquitecto (Usuarios y Grupos) [12 ejercicios]
*Objetivo: Dominar la gestión de usuarios, grupos, contraseñas y envejecimiento.*

21. Crea un grupo llamado `developers` con GID 2000. (Usuario: ansible)
22. Crea un usuario `alice` con home en `/home/alice`, shell `/bin/bash`, y miembro del grupo `developers`. (Usuario: ansible)
23. Crea un usuario `bob` con UID personalizado 1500 y sin directorio home. (Usuario: ansible)
24. Fuerza a `alice` a cambiar su contraseña en el próximo login. (Usuario: alice - ya configurado por Ansible, ¡pruébalo!)
25. Configura envejecimiento de contraseña para `bob`: cambio cada 90 días, aviso 7 días antes, inactividad 5 días. (Usuario: ansible - ya configurado por Ansible, verifícalo con `chage -l bob`)
26. Bloquea la cuenta de `bob` sin eliminarla. Verifica el estado en `/etc/shadow`. (Usuario: ansible)
27. Desbloquea la cuenta de `bob` y verifica. (Usuario: ansible)
28. Cambia el shell de `bob` a `/sbin/nologin` y verifica que no pueda iniciar sesión. (Usuario: ansible)
29. Añade a `alice` como miembro secundario de los grupos `wheel` y `developers` con un solo comando. (Usuario: ansible)
30. Elimina al usuario `bob` pero conserva su directorio home (si lo tiene). (Usuario: ansible)
31. Edita `/etc/sudoers` con `visudo` para permitir que el grupo `developers` ejecute `/bin/systemctl restart httpd` sin contraseña. (Usuario: ansible)
32. Crea un usuario `serviceaccount` con shell `/sbin/nologin`, sin home, y sin contraseña (cuenta de sistema). (Usuario: ansible - ya creado por Ansible)

### 🔴 NIVEL 4: El Guardián (Permisos y ACLs) [12 ejercicios]
*Objetivo: Dominar permisos UGO, especiales, ACLs y atributos extendidos.*

33. Crea un archivo con permisos `644` usando notación numérica y simbólica. (Usuario: alice)
34. Crea un directorio con permisos `755`. Cambia a `700` usando notación simbólica (`u=rwx,go=`). (Usuario: alice)
35. Aplica el bit SUID a un script bash. Ejecútalo como usuario normal y observa que corre con permisos del dueño. (Usuarios: ansible para crear, alice para probar)
36. Aplica el bit SGID a un directorio `/shared/team`. Crea archivos dentro y verifica que heredan el grupo del directorio. (Usuarios: ansible para configurar, alice para crear archivos)
37. Aplica el Sticky Bit a `/tmp/test-sticky`. Intenta borrar un archivo de otro usuario desde una cuenta diferente. (Usuarios: alice crea, bob intenta borrar)
38. Usa `setfacl` para dar al usuario `alice` permisos `rwx` sobre un archivo del que solo `root` es dueño. (Usuarios: ansible para configurar ACL, alice para probar)
39. Usa `getfacl` para ver las ACLs del archivo anterior. Elimina la ACL de `alice`. (Usuario: ansible)
40. Aplica ACLs recursivas a un directorio: grupo `developers` con `r-x`, usuario `alice` con `rwx`. (Usuario: ansible)
41. Usa `chattr +i` en un archivo crítico. Intenta modificarlo, borrarlo, renombrarlo. Luego quita el atributo. (Usuarios: ansible para aplicar atributo, alice para intentar modificar)
42. Usa `chattr +a` en un archivo de log. Intenta sobrescribirlo, luego añade contenido con `>>`. (Usuarios: ansible para aplicar atributo, alice para intentar sobrescribir)
43. Configura `umask 027` para un usuario específico de forma persistente en su `.bashrc`. (Usuario: alice)
44. Encuentra todos los archivos en `/opt` con permisos `777` y cámbialos a `755`. (Usuario: ansible)

### 🟣 NIVEL 5: El Ingeniero de Redes (Networking Básico) [10 ejercicios]
*Objetivo: Dominar configuración de red, DNS, firewalld y SSH.*

45. Usa `nmcli` para mostrar todas las conexiones activas y sus detalles. (Usuario: ansible)
46. Configura una IP estática `10.10.10.95/24` con gateway `10.10.10.1` y DNS `8.8.8.8` usando `nmcli`. (Usuario: ansible)
47. Crea una segunda conexión de red llamada "backup" con IP `10.10.10.96/24`. Actívala y desactívala. (Usuario: ansible)
48. Cambia el hostname del sistema a `lfcs-practice.local` de forma persistente usando `hostnamectl`. (Usuario: ansible)
49. Edita `/etc/hosts` para que `lfcs-practice.local` resuelva a `127.0.1.1`. (Usuario: ansible)
50. Usa `firewall-cmd` para agregar el servicio `http` a la zona `public` de forma permanente. Recarga y verifica. (Usuario: ansible)
51. Crea una Rich Rule en firewalld para bloquear todo el tráfico desde la IP `192.168.1.100`. (Usuario: ansible)
52. Configura port forwarding en firewalld: puerto `8080` → puerto `80`. (Usuario: ansible)
53. Genera un par de claves SSH ED25519 sin passphrase. Configura acceso sin contraseña al localhost. (Usuario: alice)
54. Edita `/etc/ssh/sshd_config` para deshabilitar login por contraseña de root. Reinicia `sshd` y verifica. (Usuario: ansible)

### 🔵 NIVEL 6: El Automatizador (Systemd y Servicios) [8 ejercicios]
*Objetivo: Dominar systemd, servicios, timers y programación de tareas.*

55. Lista todos los servicios activos, fallidos y en espera usando `systemctl`. (Usuario: ansible)
56. Crea un servicio systemd personalizado `/etc/systemd/system/myapp.service` que ejecute un script simple. (Usuario: ansible)
57. Habilita el servicio para que inicie al boot. Inícialo, deténlo, reinícialo y verifica su estado. (Usuario: ansible)
58. Crea un systemd timer `myapp.timer` que dispare el servicio cada 5 minutos. Verifica con `systemctl list-timers`. (Usuario: ansible)
59. Programa un cron job que se ejecute todos los días a las 3:00 AM: `echo "Backup done" >> /var/log/backup.log`. (Usuario: ansible)
60. Programa un cron job que se ejecute cada 15 minutos los días hábiles (lun-vie). (Usuario: ansible)
61. Usa `at` para programar una tarea única que se ejecute en 10 minutos. (Usuario: ansible)
62. Analiza los logs de tu servicio personalizado con `journalctl -u myapp.service --since "1 hour ago"`. (Usuario: ansible)

### 🟤 NIVEL 7: El Programador (Scripting Bash) [8 ejercicios]
*Objetivo: Dominar scripting bash, condiciones, loops y funciones.*

63. Crea un script que acepte un argumento (nombre de archivo) y muestre si existe, es un directorio, o no existe. (Usuario: alice)
64. Crea un script que use un bucle `for` para procesar todos los archivos `.txt` en un directorio y contar sus líneas. (Usuario: alice)
65. Crea un script que lea un archivo línea por línea y cuente cuántas líneas tienen más de 80 caracteres. (Usuario: alice)
66. Crea un script que use `if/else` para verificar si un servicio está corriendo. Si no, intenta iniciarlo. (Usuario: ansible)
67. Crea un script que acepte múltiples argumentos y los procese uno por uno usando `$@`. (Usuario: alice)
68. Crea un script que use `trap` para limpiar archivos temporales si se interrumpe con Ctrl+C. (Usuario: alice)
69. Crea una función en `.bashrc` llamada `mkcd` que cree un directorio y entre en él con un solo comando. (Usuario: alice)
70. Crea un script que use la salida de `date` como parte del nombre de un archivo de backup. (Usuario: alice)

### ⚫ NIVEL 8: El Maestro de SELinux (Seguridad Avanzada) [5 ejercicios]
*Objetivo: Dominar SELinux: modos, contextos, booleanos y políticas.*

71. Verifica el modo actual de SELinux. Cámbialo a `Enforcing` de forma persistente en `/etc/selinux/config`. (Usuario: ansible)
72. Crea un archivo en `/tmp` y observa su contexto con `ls -Z`. Muévelo a `/var/www/html` y observa que el contexto NO cambia. Ahora cópialo y observa que SÍ cambia. (Usuario: ansible)
73. Usa `restorecon -v` para corregir el contexto de un archivo movido incorrectamente. (Usuario: ansible)
74. Habilita el booleano `httpd_can_network_connect` de forma persistente con `setsebool -P`. (Usuario: ansible)
75. **Escenario final:** Cambia el puerto de SSH a `2222`. Usa `semanage port` para agregar el puerto `2222` al contexto `ssh_port_t`. Reinicia `sshd` y verifica que SELinux no lo bloquee. (Usuario: ansible)

---

### 📊 Resumen de Uso de Usuarios

| Nivel | Usuario Principal | Usuario Secundario |
|-------|-------------------|-------------------|
| 1-2 | alice | - |
| 3 | ansible | alice (para probar) |
| 4 | ansible | alice, bob (para probar) |
| 5-6 | ansible | - |
| 7 | alice | ansible (solo ejercicio 66) |
| 8 | ansible | - |

---

¿Perfecto? Ahora tienes una guía completamente autocontenida. Cada ejercicio te dice exactamente con qué usuario trabajar. ¿Empezamos con el **Ejercicio 1** para que veas el flujo completo en acción?
