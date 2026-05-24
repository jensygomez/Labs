---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Tema: Lab - Remote File Systems --> NFS
Fecha de Inicio: 2026-05-09
Dificultad: Intermedio-Baja
Tareas del Lab: "8"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha          | Tiempo | Éxito | Notas Rápidas |
| :------------- | :----- | :---- | :------------ |
| 09 - 05 - 2026 | 15 min | 0 %   |               |
| 20 - 05 - 2026 | 20 min | 25 %  |               |

[[Laboratorios del LFCS]]
---

# NFS (Network File System) - Resumen de Laboratorio

 ## Exportación en el Servidor (Control de Acceso): 
NFS es compartir directorios entre servidores de forma transparente. El archivo `/etc/exports` es tu "puerta de seguridad" donde defines quién accede a qué con qué permisos usando la sintaxis: `directorio cliente(opciones)`. Debes dominar: especificación de clientes (IPs exactas como `127.0.0.1` o rangos CIDR como `10.0.0.0/24`), permisos (`ro` para read-only, `rw` para read-write), y opciones críticas de seguridad (`root_squash` anula privilegios remotos de root, `no_root_squash` los permite—riesgo). Después de editar `/etc/exports`, usa `sudo exportfs -r` para recargar sin reiniciar NFS (filosofía Linux: cambios dinámicos sin downtime). _Ejemplo: `/home 10.0.0.0/24(ro) 127.0.0.10(rw,no_root_squash)` da acceso read-only a una red y read-write con privilegios root a una IP específica._

## Montaje Manual y Persistencia: 
El montaje manual `sudo mount -t nfs servidor:/directorio /punto_local` te enseña que NFS es "solo otro filesystem" en Linux. Verifica con `mount` o `df -h`. Pero en producción necesitas persistencia: el archivo `/etc/fstab` es tu "blueprint" del sistema—una línea como `127.0.0.1:/home /mnt nfs defaults 0 0` le dice al kernel "monta esto en boot". Los campos son: `servidor:ruta punto_montaje tipo opciones dump fsck_order`. Filosofía Linux: la automatización es confiabilidad—tu servidor se reinicia solo y sigue funcionando sin intervención. _Ejemplo: agregar esa línea a fstab garantiza que `/mnt` está montado en cada arranque._

## Troubleshooting y Aplicación Real: 
Para certificación y entrevistas, debes conectar estos conceptos: el servidor exporta en `/etc/exports`, el cliente monta con `mount -t nfs`, y la persistencia viene de `/etc/fstab`. Troubleshooting rápido: `sudo exportfs -v` verifica qué está exportado, `showmount -e IP` ve las exportaciones desde el cliente, `mount | grep nfs` lista montajes activos. En una entrevista, prepárate para: "En producción usaría NFS para backups centralizados. Exportaría `/var/log` en `ro` para integridad, usaría CIDR restringido para seguridad, y configuraría `fstab` para que sobreviva reinicios." Domina la diferencia `root_squash` vs `no_root_squash` (la más importante: root remoto no es root local por defecto).