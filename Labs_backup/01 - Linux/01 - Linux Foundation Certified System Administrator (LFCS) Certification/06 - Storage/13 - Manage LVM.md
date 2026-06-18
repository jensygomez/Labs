---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Tema: Lab - Manage LVM
Fecha de Inicio: 2026-05-09
Dificultad: Intermedio-Baja
Tareas del Lab: "12"
tags:
  - Laboratorios-del-LFCS
---
## 📊 Bitácora de Intentos
| Fecha        | Tiempo | Éxito | Notas Rápidas |
| :----------- | :----- | :---- | :------------ |
| `09/05/2026` | 30 min | 66 %  |               |
| `20/05/2026` | 45 min | 66 %  |               |
| `02/06/2026` | 35 min | 92 %  |               |

[[Laboratorios del LFCS]]

---

# Laboratorio LVM

LVM es la respuesta a un problema clásico en infraestructura: ¿qué haces cuando un disco se llena y no puedes parar el sistema? Aquí aprendes a separar el hardware físico de la lógica del almacenamiento. Tus discos crudos se convierten en bloques que puedes agrupar, expandir y contraer sin downtime. Es elasticidad de almacenamiento—lo mismo que ves en AWS o Azure, pero en tu VM. El flujo es simple: declaras discos como Physical Volumes, los agrupas en un Volume Group, y de ahí creas Logical Volumes que el sistema usa normalmente. Cuando se llena, agregas otro disco al grupo. Sin perder datos, sin parar nada.

Lo que ves en este lab es exactamente lo que harás como Sysadmin en Accenture: instalar LVM, preparar discos físicos, crear un contenedor de almacenamiento flexible, y después expandirlo cuando lo necesites. También aprenderás que remover capacidad requiere planificación—no puedes quitar un disco si tiene datos. Y destruir volúmenes es permanente. Estos detalles importan. Al redimensionar, usarás XFS como filesystem porque permite crecer en caliente. Es el ciclo completo: crear infraestructura, hacer crecer bajo presión, y finalmente desmantelar lo que ya no sirve.

La razón por la que esto importa para una entrevista es que muestra que entiendes cómo la industria resuelve problemas de almacenamiento a escala. No es solo "instalé LVM"—es que captaste por qué existe, cuándo usarlo, y cuáles son sus límites. Cuando un reclutador te pregunte "¿cómo creces almacenamiento sin parar el servicio?", tienes la respuesta. Y cuando te muestren un datacenter con servidores físicos, ya sabes que bajo el capó probablemente hay LVM (o sus equivalentes en almacenamiento enterprise). Para la certificación, recuerda que es una herramienta fundamental que aparecerá en cualquier examen de Sysadmin serio.

---

## Comandos Clave

```bash
# Q1: Instala el suite completo de herramientas de administración de LVM2 en el sistema confirmando de forma automática (--yes).
sudo apt install --yes lvm2

# Q2: Inicializa los discos físicos de bloque /dev/vdd y /dev/vde para que puedan ser reconocidos y utilizados por LVM como Volúmenes Físicos.
sudo pvcreate /dev/vdd /dev/vde

# Q3: Extrae de forma automática el tamaño exacto del PV /dev/vde eliminando la unidad de medida (g) y guardando solo el número entero en el archivo.
sudo pvs --noheadings --options pv_size --units g /dev/vde | awk '{print int($1)}' | sudo tee /root/pvsize

# Q4: Remueve la firma de LVM del dispositivo /dev/vde para regresarlo a su estado de disco estándar.
sudo pvremove /dev/vde

# Q5: Crea un nuevo Grupo de Volúmenes (VG) llamado "volume1" asignándole como base el almacenamiento del Volumen Físico /dev/vdd.
sudo vgcreate volume1 /dev/vdd

# Q6: Extiende la capacidad de almacenamiento del grupo "volume1" agregando un segundo Volumen Físico (/dev/vde) a la agrupación.
sudo pvcreate /dev/vde && sudo vgextend volume1 /dev/vde

# Q7: Reduce el espacio del grupo "volume1" retirando de forma segura el almacenamiento provisto por el disco /dev/vde.
sudo vgreduce volume1 /dev/vde

# Q8: Obtiene el tamaño total del VG "volume1" formateado con su unidad de medida explícita y guarda el resultado en la ruta de root.
sudo vgs --noheadings --options vg_size --units m volume1 | awk '{print $1"m"}' | sudo tee /root/volume1

# Q9: Crea un Volumen Lógico (LV) llamado "smalldata" con un tamaño estricto de 0.5 Gigabytes dentro del grupo "volume1".
sudo lvcreate --size 0.5G --name smalldata volume1

# Q10: Redimensiona de forma absoluta el tamaño del volumen lógico "smalldata" para que su espacio final sea exactamente de 752 Megabytes.
sudo lvresize --size 752M volume1/smalldata

# Q11: Crea un sistema de archivos XFS de alto rendimiento sobre la ruta de dispositivo absoluta del Volumen Lógico "smalldata".
sudo mkfs.xfs /dev/volume1/smalldata

# Q12: Elimina definitivamente el Volumen Lógico "smalldata" del sistema liberando el espacio del VG, forzando la confirmación (--force).
sudo lvremove --force volume1/smalldata
```