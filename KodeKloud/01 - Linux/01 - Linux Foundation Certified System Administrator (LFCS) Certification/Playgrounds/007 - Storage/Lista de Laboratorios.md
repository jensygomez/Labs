
# 📘 Ruta de Práctica: Storage Avanzado LFCS/RHCSA (Multi-Nodo en KVM/Vagrant)

## 🏗️ Guía Maestra: Estructura Estándar y Flujo de Trabajo


| Componente | Configuración Estándar |
|------------|------------------------|
| **Proveedor** | `libvirt` (KVM/QEMU) + `vagrant` |
| **Imagen Base** | `generic/ubuntu2204` (Ubuntu 22.04 LTS Server) |
| **Recursos por Nodo** | `1 CPU` \| `1024 MB RAM` \| Bus de disco: `VirtIO` |
| **Red** | `default` de Libvirt (`192.168.122.0/24`). IPs fijas: `node01(.11)`, `node02(.12)`, `node03(.13)` |
| **Usuario** | `bob` / `caleston123` \| `sudo NOPASSWD` \| Acceso vía `sshpass` desde `node01` |
| **Almacenamiento** | ✅ **Cero loop devices.** Discos virtuales reales (`/dev/vdb`, `/dev/vdc`...) agregados como archivos `qcow2` thin-provisioned. |
| **Resolución DNS** | Inyección automática en `/etc/hosts` + red Libvirt `dnsmasq` |
| **Ciclo de Práctica** | `vagrant up --provider=libvirt` → Resuelve ticket → `vagrant destroy -f` → Siguiente escenario |

### 📜 Plantilla de Automatización (Vagrantfile Base)
```ruby
# -*- mode: ruby -*-
Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  nodes = [
    { name: "node01", ip: "192.168.122.11", extra_disk: false },
    { name: "node02", ip: "192.168.122.12", extra_disk: true },  # ← Ajustar según escenario
    { name: "node03", ip: "192.168.122.13", extra_disk: false }
  ]
  nodes.each do |node|
    config.vm.define node[:name] do |nc|
      nc.vm.hostname = node[:name]
      nc.vm.network "private_network", ip: node[:ip], libvirt__network_name: "default"
      nc.vm.provider "libvirt" do |lv|
        lv.memory, lv.cpus, lv.driver = 1024, 1, "kvm"
        lv.storage :file, :size => '1G', :type => 'qcow2' if node[:extra_disk] # ← Cambiar tamaño
      end
      nc.vm.provision "shell", inline: <<-SHELL
        cat << 'HOSTS' >> /etc/hosts
192.168.122.11 node01
192.168.122.12 node02
192.168.122.13 node03
HOSTS
        useradd -m -s /bin/bash bob
        echo 'bob:caleston123' | chpasswd
        echo 'bob ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/bob
        chmod 0440 /etc/sudoers.d/bob
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq && apt-get install -y -qq sshpass parted nfs-common
      SHELL
      # → AQUÍ INYECTAR FALLOS ESPECÍFICOS DEL ESCENARIO EN node02
      # → AQUÍ GENERAR TICKET EN node01
    end
  end
end
```

---

## 🗺️ Ruta de Práctica: Escenarios Storage

#### **1. STG-001: El Disco Olvidado – Particionamiento, Filesystems y Montaje Persistente**
- **Dificultad:** 6/10 | **Nivel:** L2
- **Temas LFCS/RHCSA:** Partitions, File Systems, Mount at Boot, Swap.
- **Recursos:** 1 Disco virtual en `node02`: `/dev/vdb` (1 GB).
- **Objetivo:** Dominar el flujo básico de aprovisionamiento y corrección de `fstab`.
- **Escenario:** Tras un reinicio, `/dev/vdb1` no monta en `/mnt/app-data`. El `fstab` apunta a `ext3`, el estándar corporativo es `ext4`, y no hay swap. Debes particionar, formatear, montar con `noatime,nofail` y crear un `swapfile` de 128MB persistente.
- **Validación:** `lsblk -f`, `mount | grep app-data`, `swapon --show`, `sudo mount -a` (sin errores).

#### **2. STG-002: El Laberinto LVM – Volúmenes Lógicos que No Montan y VG Fragmentado**
- **Dificultad:** 7/10 | **Nivel:** L2/L3
- **Temas LFCS/RHCSA:** Manage and Configure LVM Storage, Resize Filesystems.
- **Recursos:** 2 Discos virtuales en `node02`: `/dev/vdb` (2 GB) y `/dev/vdc` (2 GB).
- **Objetivo:** Creación, extensión y reparación de volúmenes LVM.
- **Escenario:** `lv-apps` no monta tras una expansión fallida. El VG tiene PE libres, el LV está inconsistente y `fstab` usa un UUID obsoleto. Diagnóstico con `pvs/vgs/lvs`, extensión de LV, `resize2fs`/`xfs_growfs` y corrección de montaje.

#### **3. STG-003: La Montaña Rusa de I/O – Monitoreo de Performance y Cuellos de Botella**
- **Dificultad:** 7/10 | **Nivel:** L3
- **Temas LFCS/RHCSA:** Monitor Storage Performance, Filesystem Mount Options, NFS tuning.
- **Recursos:** 1 Disco en `node02`: `/dev/vdb` (2 GB, XFS, exportado vía NFS).
- **Objetivo:** Diagnosticar y mitigar problemas de rendimiento de almacenamiento.
- **Escenario:** Latencia extrema en `node03` al escribir en mount NFS. Uso de `iostat`, `iotop`, `sar -d`, `nfsiostat`. Ajuste de opciones `async,noatime,rsize=32768,wsize=32768` y validación de mejora.

#### **4. STG-004: El Puente Roto – NFS Server/Client y Exportaciones con Restricciones**
- **Dificultad:** 7/10 | **Nivel:** L2/L3
- **Temas LFCS/RHCSA:** Use Remote Filesystems: NFS, Firewalld.
- **Recursos:** 1 Volumen LVM en `node02`: `/dev/vg_data/lv_shared` (2 GB).
- **Objetivo:** Configurar servicios de red de almacenamiento con control de acceso.
- **Escenario:** `node02` exporta `/srv/shared` a `node03`, pero el cliente recibe `Permission denied`. `root_squash` activo, firewall bloqueando puertos RPC, opciones de mount inseguras. Configuración de `exports` por subred, apertura de puertos y montaje seguro.

#### **5. STG-005: Los Permisos Rebeldes – ACLs, SGID y Sticky Bit en Directorios Compartidos**
- **Dificultad:** 8/10 | **Nivel:** L3
- **Temas LFCS/RHCSA:** Advanced Filesystem Permissions, ACLs.
- **Recursos:** 1 Disco en `node02`: `/dev/vdb` (1 GB, montado en `/srv/proyectos`).
- **Objetivo:** Dominar control de acceso granular en Linux.
- **Escenario:** Directorio `/srv/proyectos` debe permitir colaboración entre `devs` y `ops`, pero solo el dueño puede borrar archivos. Subdirectorio requiere acceso de solo lectura para `auditor`. Implementación de `SGID`, `Sticky Bit`, `setfacl` con `default ACLs` y validación de herencia.

#### **6. STG-006: El Volumen Fantasma – Recuperación de Filesystem Corrupto y LVM con PV Faltante**
- **Dificultad:** 8/10 | **Nivel:** L3 (Recuperación de Desastres)
- **Temas LFCS/RHCSA:** LVM Metadata Recovery, Filesystem Recovery (`fsck`/`xfs_repair`).
- **Recursos:** 3 Discos en `node02`: `/dev/vdb`, `/dev/vdc`, `/dev/vdd` (1 GB cada uno, en un VG).
- **Objetivo:** Recuperar datos tras caída abrupta o fallo de disco.
- **Escenario:** Caída simulada (desconexión de `/dev/vdc` desde Virt-Manager). LV `xfs` no monta, `pvs` muestra PV `missing`. Uso de `pvscan --cache`, `vgcfgrestore`, `xfs_repair`/`e2fsck` y montaje en modo recuperación.

#### **7. STG-007: El Almacén Elástico – Thin Provisioning con LVM y Snapshots para Backups**
- **Dificultad:** 8/10 | **Nivel:** L3 (Enfoque DevOps/SRE)
- **Temas LFCS/RHCSA:** LVM Thin Provisioning, Snapshots.
- **Recursos:** 1 Disco grande en `node02`: `/dev/vdb` (5 GB).
- **Objetivo:** Implementar almacenamiento eficiente y puntos de restauración rápidos.
- **Escenario:** Entorno de pruebas que debe clonarse rápidamente. Configuración de `Thin Pool`, volúmenes thin-provisioned, snapshots consistentes. Validación de montabilidad del snapshot y monitoreo de sobrecompromiso (<80%).

#### **8. STG-008: El Colapso del Storage – Incidente Compuesto (Examen Final)**
- **Dificultad:** 9.5/10 | **Nivel:** L3 (Simulacro de Examen)
- **Temas LFCS/RHCSA:** Integración de todos los temas anteriores.
- **Recursos:** Configuración acumulada de `node02` (LVM + Thin Pool + NFS + ACLs).
- **Objetivo:** Diagnóstico bajo presión y resolución integral.
- **Escenario:** CTF operativo. App en `node03` falla: alta latencia I/O, errores `Read-only file system` intermitentes, filesystem al 95%. Diagnóstico con `df/du/iostat/nfsiostat`, expansión en caliente de LV, corrección de ACLs, optimización de mount NFS y documentación en bóveda.

---
