

---
¡Excelente iniciativa! Actualizar la ruta de práctica para usar **discos virtuales reales en Virt-Manager (KVM)** en lugar de *loop devices* no solo resuelve los problemas técnicos de permisos, sino que **eleva drásticamente la calidad y el realismo del laboratorio**. 

En el mundo real (y en los exámenes LFCS/RHCSA), trabajarás con `/dev/vdb`, `/dev/sdb` o discos cloud (EBS), nunca con archivos loop. Además, herramientas de diagnóstico de I/O (`iostat`, `fio`) funcionan de manera mucho más precisa en discos de bloque reales.

Aquí tienes la **Ruta de Práctica actualizada y optimizada para Virt-Manager/KVM**:

---

### 🗺️ Ruta de Práctica: Storage Avanzado LFCS/RHCSA (Multi-Nodo en KVM)

**Arquitectura Base:**
*   **`node01`**: Estación de Administración / Cliente NFS.
*   **`node02`**: Servidor de Storage (LVM, NFS, XFS/EXT4). *Aquí se agregarán los discos secundarios.*
*   **`node03`**: Servidor de Aplicaciones / Cliente NFS / Bóveda de Auditoría.

> **💡 Nota de Infraestructura (Virt-Manager):** 
> Para estos laboratorios, no usaremos *loop devices*. En su lugar, desde la GUI de Virt-Manager o con `virsh`, agregarás discos virtuales secundarios (Bus: **VirtIO**, formato: **qcow2**) a `node02` según el tamaño indicado en cada escenario (ej. `/dev/vdb`, `/dev/vdc`). Esto simula la adición de discos EBS en AWS o discos virtuales en producción.

---

#### **1. STG-001: El Disco Olvidado – Particionamiento, Filesystems y Montaje Persistente**
*   **Dificultad:** 6/10 | **Nivel:** L2
*   **Temas LFCS/RHCSA:** Partitions, File Systems, Mount at Boot, Swap.
*   **Recursos de Laboratorio:** 1 Disco virtual adicional en `node02`: `/dev/vdb` (1 GB).
*   **Objetivo:** Dominar el flujo básico de aprovisionamiento de almacenamiento y corrección de `fstab`.
*   **Escenario:** Se agregó un disco nuevo (`/dev/vdb`) a `node02` para almacenar logs, pero tras un reinicio no monta. El `/etc/fstab` tiene errores de sintaxis, el filesystem fue creado con el tipo obsoleto (`ext3` en lugar de `ext4`), y el sistema carece de swap. Debes particionar, formatear, montar con opciones correctas (`noatime`, `nofail`) y crear un `swapfile` persistente de 128MB dentro del montaje.

#### **2. STG-002: El Laberinto LVM – Volúmenes Lógicos que No Montan y VG Fragmentado**
*   **Dificultad:** 7/10 | **Nivel:** L2/L3
*   **Temas LFCS/RHCSA:** Manage and Configure LVM Storage, Resize Filesystems.
*   **Recursos de Laboratorio:** 2 Discos virtuales adicionales en `node02`: `/dev/vdb` (2 GB) y `/dev/vdc` (2 GB).
*   **Objetivo:** Dominar la creación, extensión y reparación de volúmenes LVM.
*   **Escenario:** Un volumen lógico `lv-apps` en `node02` no monta tras una expansión fallida. El Grupo de Volúmenes (VG) tiene espacio libre, pero el LV está en estado inconsistente y el `fstab` apunta a un UUID antiguo o ruta incorrecta. Debes diagnosticar con `pvs`, `vgs`, `lvs`, extender el LV correctamente, redimensionar el filesystem (`resize2fs` o `xfs_growfs`) y corregir el montaje persistente.

#### **3. STG-003: La Montaña Rusa de I/O – Monitoreo de Performance y Cuellos de Botella**
*   **Dificultad:** 7/10 | **Nivel:** L3
*   **Temas LFCS/RHCSA:** Monitor Storage Performance, Filesystem Mount Options, NFS tuning.
*   **Recursos de Laboratorio:** 1 Disco virtual en `node02`: `/dev/vdb` (2 GB, formateado en XFS y exportado vía NFS).
*   **Objetivo:** Aprender a diagnosticar y mitigar problemas de rendimiento de almacenamiento.
*   **Escenario:** Una aplicación en `node03` reporta latencia extrema al escribir en un mount NFS. Usando `iostat`, `iotop`, `sar -d` y `nfsiostat`, debes identificar si el cuello de botella está en el cliente (opciones de mount incorrectas como `sync`), en la red, o en el servidor. Debes aplicar opciones de rendimiento (`async`, `noatime`, `rsize=32768`, `wsize=32768`) y validar la mejora.

#### **4. STG-004: El Puente Roto – NFS Server/Client y Exportaciones con Restricciones**
*   **Dificultad:** 7/10 | **Nivel:** L2/L3
*   **Temas LFCS/RHCSA:** Use Remote Filesystems: NFS, Firewalld.
*   **Recursos de Laboratorio:** 1 Volumen LVM en `node02`: `/dev/vg_data/lv_shared` (2 GB).
*   **Objetivo:** Configurar servicios de red de almacenamiento de forma segura y con control de acceso.
*   **Escenario:** `node02` exporta `/srv/shared` hacia `node03`, pero el cliente recibe "Permission denied" al escribir. El archivo `exports` tiene `root_squash` activo de forma indiscriminada, el firewall (`firewalld`/`ufw`) bloquea los puertos, y el cliente monta con opciones inseguras. Debes configurar `exports` con `no_root_squash` para una subred específica, abrir los puertos necesarios y montar con opciones seguras.

#### **5. STG-005: Los Permisos Rebeldes – ACLs, SGID y Sticky Bit en Directorios Compartidos**
*   **Dificultad:** 8/10 | **Nivel:** L3
*   **Temas LFCS/RHCSA:** Advanced Filesystem Permissions, ACLs.
*   **Recursos de Laboratorio:** 1 Disco virtual en `node02`: `/dev/vdb` (1 GB, montado en `/srv/proyectos`).
*   **Objetivo:** Dominar el control de acceso granular en Linux.
*   **Escenario:** Un directorio compartido `/srv/proyectos` en `node02` debe permitir que los grupos `devs` y `ops` colaboren, pero los usuarios solo deben poder borrar *sus propios* archivos. Además, un subdirectorio requiere que el usuario `auditor` tenga acceso de lectura sin ser propietario. Debes implementar **SGID**, **Sticky Bit** y **ACLs** (`setfacl`) con máscaras correctas, y validar que la herencia (`default ACLs`) funcione para nuevos archivos.

#### **6. STG-006: El Volumen Fantasma – Recuperación de Filesystem Corrupto y LVM con PV Faltante**
*   **Dificultad:** 8/10 | **Nivel:** L3 (Recuperación de Desastres)
*   **Temas LFCS/RHCSA:** LVM Metadata Recovery, Filesystem Recovery (`fsck`/`xfs_repair`).
*   **Recursos de Laboratorio:** 3 Discos virtuales en `node02`: `/dev/vdb`, `/dev/vdc`, `/dev/vdd` (1 GB cada uno, agrupados en un VG).
*   **Objetivo:** Aprender a recuperar datos tras una caída abrupta o fallo de disco.
*   **Escenario:** Tras una caída abrupta de `node02` *(simulada desconectando `/dev/vdc` desde Virt-Manager)*, un LV con `xfs` no monta y `xfs_repair` reporta errores. Además, `pvs` muestra un PV como "missing". Debes usar `pvscan --cache`, restaurar la metadata del VG con `vgcfgrestore`, ejecutar la reparación del filesystem y montar con opciones de recuperación.

#### **7. STG-007: El Almacén Elástico – Thin Provisioning con LVM y Snapshots para Backups**
*   **Dificultad:** 8/10 | **Nivel:** L3 (Enfoque DevOps/SRE)
*   **Temas LFCS/RHCSA:** LVM Thin Provisioning, Snapshots.
*   **Recursos de Laboratorio:** 1 Disco virtual grande en `node02`: `/dev/vdb` (5 GB).
*   **Objetivo:** Implementar estrategias de almacenamiento eficientes y puntos de restauración rápidos.
*   **Escenario:** Se requiere un entorno de pruebas que pueda clonarse rápidamente sin consumir todo el disco. Debes configurar un **Thin Pool** en `node02`, crear volúmenes *thin-provisioned* (sobrecomprometiendo el espacio), y automatizar snapshots consistentes. El script de validación debe verificar que el snapshot sea montable y que el thin pool no esté críticamente lleno (>80%).

#### **8. STG-008: El Colapso del Storage – Incidente Compuesto (Examen Final)**
*   **Dificultad:** 9.5/10 | **Nivel:** L3 (Simulacro de Examen)
*   **Temas LFCS/RHCSA:** Integración de todos los temas anteriores.
*   **Recursos de Laboratorio:** Configuración acumulada de `node02` (LVM con Thin Pool, exportado vía NFS).
*   **Objetivo:** Demostrar capacidad de diagnóstico bajo presión y resolución de problemas complejos.
*   **Escenario:** Un "Capture The Flag" operativo. Una aplicación crítica en `node03` depende de un mount NFS desde `node02`. Los síntomas son: alta latencia de I/O, errores de permisos "Read-only file system" intermitentes, y el filesystem está al 95% de capacidad. Debes diagnosticar con `df`, `du`, `iostat`, `nfsiostat`, expandir el LV en caliente, corregir las ACLs que fueron sobrescritas, optimizar opciones de mount NFS y documentar la solución en la bóveda de `node03`.

---

### 🚀 ¿Por qué esta versión es superior para tu preparación?

1. **Elimina la "ficción" de los loop devices:** Trabajar con `/dev/vdb` te obliga a usar `lsblk`, `fdisk`/`parted` y `mkfs` exactamente como lo harías en un servidor real o en la nube.
2. **Prepara para RHCSA/LFCS:** Los exámenes oficiales usan discos virtuales secundarios (simulados en sus propios entornos). Acostumbrarte a `/dev/vdX` o `/dev/sdX` es vital.
3. **Permite escenarios de recuperación realistas:** En el **STG-006**, podrás *desconectar físicamente* el disco desde la interfaz de Virt-Manager mientras la VM está apagada (o simular su fallo), algo imposible de hacer de manera realista con un archivo loop.
4. **Rendimiento real:** Los escenarios de I/O (**STG-003**) ahora tendrán métricas reales, ya que los subsistemas de disco de KVM (VirtIO) responden a `iostat` y `sar` de manera nativa.

¿Te gustaría que adapte el **script de inyección de fallos del STG-001** que vimos antes para que sea la plantilla base de cómo preparar *todos* estos escenarios de ahora en adelante?