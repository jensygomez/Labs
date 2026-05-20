---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Tema: Lab - Manage LVM
Fecha de Inicio: 2026-05-09
Dificultad: Intermedio-Baja
Tareas del Lab: "12"
---
## 📊 Bitácora de Intentos
| Fecha          | Tiempo | Éxito | Notas Rápidas |
| :------------- | :----- | :---- | :------------ |
| 09 - 05 - 2026 | 30 min | 66 %  |               |
| 20 - 05 - 2026 | min    | %     |               |

[[Laboratorios del LFCS]]

---

## LVM Hands-On: Del Disco Físico al Volumen Lógico

Este laboratorio cubrió el ciclo completo de administración de LVM desde cero. Se comenzó instalando lvm2 y creando Physical Volumes a partir de discos nuevos (/dev/vdd y /dev/vde), luego se agruparon en un Volume Group llamado volume1. El concepto clave fue entender cómo los discos físicos se abstraen en PVs, estos se agrupan en VGs, y dentro de los VGs se crean LVs con tamaños específicos. Se practicó la expansión dinámica del VG añadiendo nuevos discos cuando el espacio se agotaba, y la reducción de discos cuando ya no eran necesarios.

La parte práctica incluyó operaciones críticas para sysadmins: crear Logical Volumes con tamaños específicos (0.5GB), redimensionar LVs dinámicamente (a 752MB), y crear filesystems en ellos (XFS en este caso). El aspecto operacional importante fue entender que redimensionar un LV no requiere downtime si usas `lvresize --resizefs`. Finalmente, se practicó destruir componentes completamente (remover LVs y PVs). Este lab refuerza que LVM es la base para almacenamiento flexible en entornos de producción Linux.

## Comandos Prácticos Completos

```bash
# 1. Instalar LVM
sudo apt install lvm2

# 2. Crear Physical Volumes
sudo pvcreate /dev/vdd /dev/vde

# 3. Ver información de PVs
sudo pvs
# Guardar PSize: sudo pvs /dev/vde > /root/pvsize

# 4. Crear Volume Group
sudo vgcreate volume1 /dev/vdd

# 5. Ver información de VGs
sudo vgs
# Guardar VSize: sudo vgs volume1 > /root/volume1

# 6. Expandir Volume Group
sudo vgextend volume1 /dev/vde

# 7. Crear Logical Volume (0.5GB)
sudo lvcreate --size 0.5G --name smalldata volume1

# 8. Redimensionar LV (a 752MB)
sudo lvresize --resizefs --size 752M volume1/smalldata

# 9. Crear filesystem XFS
sudo mkfs.xfs /dev/volume1/smalldata

# 10. Remover disco de VG
sudo vgreduce volume1 /dev/vde

# 11. Remover Physical Volume
sudo pvremove /dev/vde

# 12. Remover Logical Volume
sudo lvremove volume1/smalldata
```