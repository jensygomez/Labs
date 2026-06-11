

---

### 🗺️ Ruta de Práctica: Storage Avanzado LFCS (Multi-Nodo)
*Arquitectura base: `node01` (Admin/Cliente NFS), `node02` (Servidor de Storage/LVM/NFS), `node03` (Servidor de Aplicaciones que consume storage remoto).*

#### **1. STG-001: El Disco Olvidado – Particionamiento, Filesystems y Montaje Persistente**
*   **Dificultad:** 6/10 | **Nivel:** L2
*   **Temas LFCS:** Partitions, File Systems, Mount at Boot, Swap.
*   **Escenario:** Se agregó un disco nuevo (`/dev/sdb`) a `node02` para logs, pero tras un reinicio no monta. El `/etc/fstab` tiene errores de sintaxis, el filesystem fue creado con el tipo incorrecto (`ext3` en lugar de `ext4`), y el swap no está activado. Debes particionar, formatear, montar con opciones correctas (`noatime`, `nofail`) y asegurar persistencia.

#### **2. STG-002: El Laberinto LVM – Volúmenes Lógicos que No Montan y VG Fragmentado**
*   **Dificultad:** 7/10 | **Nivel:** L2/L3
*   **Temas LFCS:** Manage and Configure LVM Storage.
*   **Escenario:** Un volumen lógico `lv-apps` en `node02` no monta tras una expansión fallida. El VG tiene espacio libre pero el LV está en estado inconsistente, y el `fstab` apunta a un UUID antiguo. Debes diagnosticar con `pvs`, `vgs`, `lvs`, extender el LV correctamente, redimensionar el filesystem (`resize2fs` o `xfs_growfs`) y corregir el montaje.

#### **3. STG-003: La Montaña Rusa de I/O – Monitoreo de Performance y Cuellos de Botella**
*   **Dificultad:** 7/10 | **Nivel:** L3
*   **Temas LFCS:** Monitor Storage Performance, Filesystem Mount Options.
*   **Escenario:** Una aplicación en `node03` reporta latencia extrema al escribir en un mount NFS. Usando `iostat`, `iotop`, `sar -d` y `nfsiostat`, debes identificar si el cuello de botella está en el cliente (opciones de mount incorrectas como `sync`), en la red, o en el servidor NFS (`node02`). Debes aplicar opciones de rendimiento (`async`, `noatime`, `rsize/wsize`).

#### **4. STG-004: El Puente Roto – NFS Server/Client y Exportaciones con Restricciones**
*   **Dificultad:** 7/10 | **Nivel:** L2/L3
*   **Temas LFCS:** Use Remote Filesystems: NFS.
*   **Escenario:** `node02` exporta `/srv/shared` hacia `node03`, pero el cliente recibe "Permission denied" al escribir. El `exports` tiene `root_squash` activo, el firewall bloquea los puertos dinámicos de NFS, y el cliente monta con opciones inseguras. Debes configurar `exports` con `no_root_squash` para subred específica, abrir puertos en `firewalld`/`iptables`, y montar con opciones seguras.

#### **5. STG-005: Los Permisos Rebeldes – ACLs, SGID y Sticky Bit en Directorios Compartidos**
*   **Dificultad:** 8/10 | **Nivel:** L3
*   **Temas LFCS:** Advanced Filesystem Permissions.
*   **Escenario:** Un directorio compartido `/srv/proyectos` en `node02` debe permitir que los grupos `devs` y `ops` colaboren, pero los usuarios solo pueden borrar sus propios archivos. Además, un subdirectorio requiere que el usuario `auditor` tenga acceso de lectura sin ser propietario. Debes implementar SGID, sticky bit y ACLs (`setfacl`) con máscaras correctas, y validar que la herencia funcione para nuevos archivos.

#### **6. STG-006: El Volumen Fantasma – Recuperación de Filesystem Corrupto y LVM con PV Faltante**
*   **Dificultad:** 8/10 | **Nivel:** L3
*   **Temas LFCS:** LVM, Filesystem Recovery, Mount Options.
*   **Escenario:** Tras una caída abrupta de `node02`, un LV con `xfs` no monta y `xfs_repair` reporta errores. Además, uno de los PVs del VG aparece como "missing" en `pvs`. Debes usar `pvscan --cache`, restaurar la metadata del VG con `vgcfgrestore`, ejecutar `xfs_repair` (o `e2fsck`), y montar con opciones de recuperación.

#### **7. STG-007: El Almacén Elástico – Thin Provisioning con LVM y Snapshots para Backups**
*   **Dificultad:** 8/10 | **Nivel:** L3 (Enfoque DevOps)
*   **Temas LFCS:** LVM, Snapshots, Mount Options.
*   **Escenario:** Se requiere un entorno de pruebas que pueda clonarse rápidamente. Debes configurar un *thin pool* en `node02`, crear volúmenes thin-provisioned, y automatizar snapshots consistentes para backups. El script de validación debe verificar que el snapshot sea montable y que el thin pool no esté sobre-comprometido (>80%).

#### **8. STG-008: El Colapso del Storage – Incidente Compuesto (LVM + NFS + ACLs + Performance)**
*   **Dificultad:** 9/10 | **Nivel:** L3 (Examen Final)
*   **Temas LFCS:** Todos los anteriores integrados.
*   **Escenario:** Un "Capture The Flag" operativo. Una aplicación crítica en `node03` depende de un mount NFS desde `node02`, que a su vez usa un LV con LVM. Los síntomas son: alta latencia de I/O, errores de permisos al escribir, y el filesystem está al 95% de capacidad. Debes diagnosticar con `df`, `du`, `iostat`, `nfsiostat`, expandir el LV, corregir ACLs, optimizar opciones de mount NFS y documentar la solución en la bóveda.

---

bob@node01 ~ ➜ lsblk && sudo cat /etc/fstab lsblk: /proc/swaps: parse error at line 1 -- ignored NAME MAJ:MIN RM SIZE RO TYPE MOUNTPOINT nvme0n1 259:0 0 477G 0 disk ├─nvme0n1p1 259:6 0 256M 0 part ├─nvme0n1p2 259:7 0 31G 0 part ├─nvme0n1p3 259:8 0 1G 0 part └─nvme0n1p4 259:9 0 444.7G 0 part nvme1n1 259:1 0 477G 0 disk ├─nvme1n1p1 259:2 0 256M 0 part ├─nvme1n1p2 259:3 0 31G 0 part ├─nvme1n1p3 259:4 0 1G 0 part └─nvme1n1p4 259:5 0 444.7G 0 part # UNCONFIGURED FSTAB FOR BASE SYSTEM bob@node01 ~ ➜ ssh bob@node02 'sudo lsblk && sudo cat /etc/fstab' lsblk: /proc/swaps: parse error at line 1 -- ignored NAME MAJ:MIN RM SIZE RO TYPE MOUNTPOINT nvme0n1 259:0 0 477G 0 disk |-nvme0n1p1 259:6 0 256M 0 part |-nvme0n1p2 259:7 0 31G 0 part |-nvme0n1p3 259:8 0 1G 0 part `-nvme0n1p4 259:9 0 444.7G 0 part nvme1n1 259:1 0 477G 0 disk |-nvme1n1p1 259:2 0 256M 0 part |-nvme1n1p2 259:3 0 31G 0 part |-nvme1n1p3 259:4 0 1G 0 part `-nvme1n1p4 259:5 0 444.7G 0 part # UNCONFIGURED FSTAB FOR BASE SYSTEM bob@node01 ~ ➜ ssh bob@node03 'sudo lsblk && sudo cat /etc/fstab' lsblk: /proc/swaps: parse error at line 1 -- ignored NAME MAJ:MIN RM SIZE RO TYPE MOUNTPOINT nvme0n1 259:0 0 477G 0 disk |-nvme0n1p1 259:6 0 256M 0 part |-nvme0n1p2 259:7 0 31G 0 part |-nvme0n1p3 259:8 0 1G 0 part `-nvme0n1p4 259:9 0 444.7G 0 part nvme1n1 259:1 0 477G 0 disk |-nvme1n1p1 259:2 0 256M 0 part |-nvme1n1p2 259:3 0 31G 0 part |-nvme1n1p3 259:4 0 1G 0 part `-nvme1n1p4 259:5 0 444.7G 0 part # UNCONFIGURED FSTAB FOR BASE SYSTEM bob@node01 ~ ➜