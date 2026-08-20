---

```bash
# 📦 Rol Ansible: Centralized Storage (LVM + NFS)

## 📐 Topología y Arquitectura del Módulo

Este módulo implementa la capa de almacenamiento compartido centralizado para la granja de servidores web, garantizando persistencia de datos y consistencia entre nodos.

```text
  [ App Node 01 ] (AlmaLinux 9) ──┐
  [ App Node 02 ] (AlmaLinux 9) ──┼──► [ NFSv4 Client /var/www/html ]
  [ App Node 03 ] (AlmaLinux 9) ──┘                  │
                                                     ▼ (Red 10.10.10.0/24)
                                             [ storage01 ] (AlmaLinux 9)
                                                     │
                                                     ├── Firewalld (Puertos 2049/TCP, RPC)
                                                     ├── SELinux (httpd_use_nfs=1)
                                                     ├── /etc/exports (/mnt/shared_webdata)
                                                     └── Mount Point: /mnt/shared_webdata
                                                             │
                                                             ▼
                                                    [ XFS Filesystem ]
                                                             │
                                                     [ LV: lv_shared ]
                                                             │
                                                     [ VG: vg_data ]
                                                             │
                                                     [ PV: /dev/sdb ]

```

### Componentes Clave:

1. **Capa Física / LVM (`storage01`):** Disco secundario `/dev/sdb` inicializado como Physical Volume (PV), agrupado en el Volume Group `vg_data` y particionado en el Logical Volume `lv_shared` con sistema de archivos **XFS**.
2. **Servicio NFS (`storage01`):** Recurso exportado en `/mnt/shared_webdata` restringido a la subred interna `10.10.10.0/24` con opciones `rw,sync,no_root_squash`.
3. **Clientes NFS (`app01`, `app02`, `app03`):** Montaje en `/var/www/html` configurado para persistencia en `/etc/fstab`.
4. **Seguridad Integrada:** Reglas en `firewalld` para servicios `nfs`, `rpc-bind`, `mountd` y ajuste del booleano de SELinux `httpd_use_nfs` para permitir a Apache servir contenido montado por red.

---

## 🎯 Playbook de Ejecución Aislada (`site_storage.yml`)

Para desplegar o validar únicamente la capa de almacenamiento sin afectar el resto de la infraestructura:

```yaml
---
- name: "Aprovisionamiento de Almacenamiento Centralizado (LVM + NFS)"
  hosts: all
  become: true
  roles:
    - role_nfs_lvm_storage

```

**Comando de ejecución:**

```bash
ansible-playbook -i inventories/production/hosts.yml site_storage.yml --ask-vault-pass

```

---

## 📋 Catálogo de Laboratorios de Incidentes & Troubleshooting (Storage & Kernel)

### 1. Incidente ST-01: Caída de Conectividad RPC y Bloqueo de Montaje NFS

* **Acción a realizar:** Manipulación del servicio `nfs-server` o filtrado de puertos en `firewalld` en el nodo `storage01`.
* **Causa probable esperada:** Bloqueo de solicitudes de red NFS o desconexión del demonio kernel NFS.
* **Supuestos falsos / Despistadores:**
* El sistema puede reportar errores de permisos `403 Forbidden` en Apache, sugiriendo un fallo de SELinux.
* El comando `df -h` en los nodos cliente se congelará (I/O Wait), lo que podría confundirse con agotamiento de memoria RAM o falla de disco en `app01..03`.



---

### 2. Incidente ST-02: Agotamiento de Capacidad en LVM y Colapso de Escritura XFS

* **Acción a realizar:** Generación masiva de datos en `/mnt/shared_webdata` hasta consumir el 100% del espacio del `lv_shared`.
* **Causa probable esperada:** Falta de espacio en el sistema de archivos XFS montado sobre LVM.
* **Supuestos falsos / Despistadores:**
* Apache responderá con errores `500 Internal Server Error`, insinuando un error de sintaxis en el código PHP/HTML o en la configuración de Apache.
* Los comandos de consulta de disco locales (`df -h /`) en los nodos web mostrarán espacio libre de sobra en la raíz, despistando sobre dónde está el llenado real.



---

### 3. Incidente ST-03: Agotamiento Oculto de Inodos en Sistema XFS

* **Acción a realizar:** Creación masiva de cientos de miles de archivos de 0 bytes en el punto de montaje NFS.
* **Causa probable esperada:** Agotamiento de la tabla de inodos en la estructura del sistema de archivos XFS.
* **Supuestos falsos / Despistadores:**
* El comando `df -h` mostrará que el disco tiene gigabytes de espacio disponible libre.
* Las herramientas de monitoreo tradicionales indicarán que el volumen LVM está saludable y con baja utilización de almacenamiento.



---

### 4. Incidente ST-04: Bloqueo de Políticas de Seguridad SELinux en Clientes Web

* **Acción a realizar:** Desactivación del booleano `httpd_use_nfs` o alteración de contextos SELinux en los clientes `app01..03`.
* **Causa probable esperada:** Denegación de AVC (Access Vector Cache) de SELinux impidiendo que el proceso `httpd` acceda a sockets o archivos del montaje NFS.
* **Supuestos falsos / Despistadores:**
* Apache devolverá un error `403 Forbidden`, sugiriendo un problema de directivas `Require all granted` en `/etc/httpd/conf/httpd.conf` o permisos Unix tradicionales (`chmod`).
* Las pruebas de lectura mediante comandos como `cat` o `nano` ejecutados como usuario `root` en la terminal funcionarán perfectamente.



---

### 5. Incidente ST-05: Incompatibilidad de Exportaciones NFS y Máscara de Red

* **Acción a realizar:** Modificación de las opciones de red en `/etc/exports` en `storage01` ajustando la IP/subred autorizada a un segmento incorrecto.
* **Causa probable esperada:** Rechazo de montajes o pérdida de permisos de lectura/escritura por desacuerdo en las ACLs de `/etc/exports`.
* **Supuestos falsos / Despistadores:**
* Mensajes de error tipo `Permission Denied` al intentar montar, haciendo parecer que la contraseña de SSH o las llaves de autenticación fallaron.
* Estado "active (running)" en el servicio `nfs-server`, dando la falsa impresión de que la capa de almacenamiento está completamente sana.



---

### 6. Incidente ST-06: Corrupción Métricas LVM (Metadata Corruption)

* **Acción a realizar:** Modificación accidental o sobreescritura de los cabezales del Physical Volume (PV) en `/dev/sdb`.
* **Causa probable esperada:** Pérdida de la tabla de descriptores de LVM en el sector de arranque del disco.
* **Supuestos falsos / Despistadores:**
* El sistema operativo reportará que el disco `/dev/sdb` está físicamente presente y "sano" en `lsblk`.
* Parecerá un fallo de hardware del controlador SCSI/SATA o una eliminación accidental del volumen por parte de otro administrador.



---

### 7. Incidente ST-07: Cuello de Botella por I/O Wait y Congestión de Sockets RPC

* **Acción a realizar:** Saturación de la cola de I/O en `storage01` mediante pruebas de estrés sintético de escritura (`fio`/`dd`) reduciendo los hilos del servidor NFS (`RPCNFSDCOUNT`).
* **Causa probable esperada:** Insuficiencia de hilos de trabajo en el kernel para procesar peticiones NFS concurrentes.
* **Supuestos falsos / Despistadores:**
* Alto consumo de CPU en los nodos `app01..03` debido a procesos `httpd` colgados en estado `D` (Uninterruptible Sleep).
* Dará la impresión de que los nodos Apache necesitan más RAM o procesador, cuando el cuello de botella es 100% de la cola RPC en el servidor de storage.



---

### 8. Incidente ST-08: Bloqueo de Archivos por NLM (Network Lock Manager) Desincronizado

* **Acción a realizar:** Forzado de un "Hard Kill" (`kill -9`) sobre procesos con archivos abiertos en el cliente NFS bajo un montaje con opciones de bloqueo (`lock`).
* **Causa probable esperada:** El servidor NFS mantiene locks huérfanos en la tabla NLM, impidiendo que otros nodos web escriban sobre el mismo archivo.
* **Supuestos falsos / Despistadores:**
* Permisos chmod/chown correctos en el sistema de archivos (`775` / `apache:apache`).
* Múltiples errores `Resource temporarily unavailable` o `Input/output error` que sugieren que el disco está fallando físicamente.



---

### 9. Incidente ST-09: Desincronización del Reloj de Red (NTP/Chronyd) y Vaciado de Caché NFS

* **Acción a realizar:** Desviar la hora del sistema en `storage01` por varias horas o días respecto a los nodos `app`.
* **Causa probable esperada:** Falla en la validación de atributos de archivos por marcas de tiempo (*timestamps* de modificación/acceso) en el protocolo NFSv4.
* **Supuestos falsos / Despistadores:**
* Archivos subidos que "desaparecen" o no actualizan su contenido en el navegador web (comportamiento extraño de caché de Apache).
* Sesiones de usuario en la aplicación web que se cierran arbitrariamente.



---

### 10. Incidente ST-10: Fallo en la Capa de Red L2/L3 (MTU Mismatch & Fragmentation)

* **Acción a realizar:** Alterar la MTU (Maximum Transmission Unit) en la interfaz de red de `storage01` (ej. bajarla a 1200) dejando los clientes en 1500.
* **Causa probable esperada:** Fragmentación excesiva o caída silenciosa de paquetes jumbo/grandes de NFS sobre UDP/TCP.
* **Supuestos falsos / Despistadores:**
* El comando `ping` estándar hacia la IP de `storage01` responderá con 0% de pérdida de paquetes.
* El comando `showmount -e` funcionará perfectamente, pero la transferencia de archivos de más de 2 KB se congelará al 99%.
EOF



```

---

Documento generado y listo. ¿Damos paso al siguiente rol para armar su catálogo (`role_lb_ha` o `role_web_app`), o quieres probar de una vez el primer fallo en el laboratorio?

```
