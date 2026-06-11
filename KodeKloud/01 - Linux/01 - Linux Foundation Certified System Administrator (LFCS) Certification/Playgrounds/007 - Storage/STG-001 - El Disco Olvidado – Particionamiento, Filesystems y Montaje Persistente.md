---
Curso: Prep Course - LFCS Certification
Modulo: Storage
Playground: STG-001-MN
Titulo: El Disco Olvidado – Particionamiento, Filesystems y Montaje Persistente
Fecha de Inicio: 2026-06-11
Dificultad: 6/10
Level Escalation: L2
Objetivo: |-
  - Aprobar LFCS
  - Pensar como Sysadmin Linux Pleno / DevOps Engineer
Temas: |-
  - Block Device Management (lsblk, fdisk/parted)
  - File System Creation (mkfs.ext4)
  - Persistent Mounting (/etc/fstab, mount options)
  - Swap Space Configuration
Competencias: |-
  - Identificar y preparar discos raw sin afectar el sistema operativo.
  - Configurar montajes persistentes con opciones de resiliencia (nofail, noatime).
  - Gestionar espacio de intercambio (Swap) de forma segura.
Script: |-
  # [ESPACIO RESERVADO PARA EL SCRIPT DE SETUP]
  # Aquí se inyectará el fallo en node02:
  # 1. Limpiar cualquier rastro previo en /dev/nvme1n1.
  # 2. Crear una partición primaria (/dev/nvme1n1p1) pero formatearla con un FS subóptimo o sin opciones.
  # 3. Crear un punto de montaje /mnt/app-data pero dejarlo sin montar.
  # 4. Agregar una línea MAL FORMADA o incompleta en /etc/fstab (ej. falta 'nofail', o UUID incorrecto).
  # 5. Dejar el sistema sin Swap activa (swapoff -a).
  # 6. Mostrar el siguiente ticket en pantalla.

  # --- INICIO DEL TICKET VISUAL ---
  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  TICKET INC-5001  │  Severidad: MEDIA  │  Ambiente: CLÚSTER DISTRIBUIDO\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m  💾 STG-001-MN — El Disco Olvidado (Particiones, Fstab y Swap)\e[0m"
  echo -e "\e[1;36m  Módulo: Storage  │  Dificultad: 6/10  │  Nivel: L2\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mUbicación de Control:\e[0m  node01 (Estación del Administrador — \e[1;32mbob\e[0m)"
  echo -e " \e[1mNodo a Intervenir:\e[0m     node02 (Servidor con disco secundario mal configurado)"
  echo -e " \e[1mNodo Bóveda Destino:\e[0m   node03 (Bóveda de Gobernanza — \e[1;35m/opt/backup-vault/\e[0m)"
  echo -e " \e[1mContraseña del Clúster:\e[0m \e[1;32mcaleston123\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " "
  echo -e " \e[1mContexto del Incidente:\e[0m"
  echo -e "  Se aprovisionó un disco secundario (\e[1m/dev/nvme1n1\e[0m) en \e[1mnode02\e[0m para"
  echo -e "  almacenar datos de aplicación en \e[1m/mnt/app-data\e[0m. Sin embargo, tras"
  echo -e "  un reinicio de mantenimiento, la aplicación falla porque el directorio"
  echo -e "  está vacío. Además, el equipo de monitoreo reporta que el nodo no tiene"
  echo -e "  espacio de intercambio (Swap) activo, lo que representa un riesgo de OOM."
  echo -e " "
  echo -e " \e[1mParámetros Técnicos Obligatorios (SSH desde node01 hacia node02):\e[0m"
  echo -e " "
  echo -e "  \e[1;31m1. Particionamiento y Filesystem (Remoto en node02)\e[0m"
  echo -e "     Utilice \e[1mfdisk\e[0m o \e[1mparted\e[0m para crear una partición primaria"
  echo -e "     en \e[1m/dev/nvme1n1\e[0m. Formatee esta partición con \e[1mext4\e[0m."
  echo -e " "
  echo -e "  \e[1;31m2. Configuración de Swap (Remoto en node02)\e[0m"
  echo -e "     Cree un archivo de swap de \e[1m1G\e[0m en \e[1m/mnt/app-data/swapfile\e[0m"
  echo -e "     (o una partición dedicada), configúrelo con \e[1mmkswap\e[0m y actívelo."
  echo -e "     Asegure permisos \e[1m600\e[0m para el archivo de swap."
  echo -e " "
  echo -e "  \e[1;31m3. Montaje Persistente y Resiliente (Remoto en node02)\e[0m"
  echo -e "     Corrija o agregue la entrada en \e[1m/etc/fstab\e[0m para \e[1m/mnt/app-data\e[0m."
  echo -e "     \e[1mOBLIGATORIO:\e[0m Incluya las opciones de montaje \e[1mdefaults,noatime,nofail\e[0m."
  echo -e "     Valide la sintaxis con \e[1msudo mount -a\e[0m antes de continuar."
  echo -e " "
  echo -e "  \e[1;31m4. Resguardo en Bóveda (node02 → node03)\e[0m"
  echo -e "     Copie el \e[1m/etc/fstab\e[0m corregido y la salida de \e[1mlsblk -f\e[0m a:"
  echo -e "     \e[1mnode03:/opt/backup-vault/stg001_fstab.bak\e[0m"
  echo -e " "
  echo -e " \e[1mCriterios de Aceptación:\e[0m"
  echo -e "  [ ] Existe partición válida en /dev/nvme1n1 con filesystem ext4   --> \e[1;35m25%\e[0m"
  echo -e "  [ ] /mnt/app-data está montado y accesible                         --> \e[1;35m25%\e[0m"
  echo -e "  [ ] /etc/fstab contiene la entrada con 'noatime' y 'nofail'        --> \e[1;35m20%\e[0m"
  echo -e "  [ ] Swap está activo (swapon --show) con tamaño >= 1G              --> \e[1;35m20%\e[0m"
  echo -e "  [ ] Backup de fstab y lsblk custodiado en node03                   --> \e[1;35m10%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32m🚨 REGLA DE ORO:\e[0m NUNCA reinicie sin validar \e[1msudo mount -a\e[0m."
  echo -e "               Un error en fstab puede dejar el nodo inoperable (Emergency Mode)."
  echo -e "               Diagnóstico: \e[1mlsblk -f\e[0m y \e[1mcat /etc/fstab\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e " "
Script Validacion: |-
  # [ESPACIO RESERVADO PARA EL SCRIPT DE VALIDACIÓN]
  # Aquí se verificará:
  # 1. 'lsblk -f /dev/nvme1n1' muestra una partición con FSTYPE=ext4.
  # 2. 'findmnt /mnt/app-data' devuelve éxito y muestra las opciones noatime,nofail.
  # 3. 'swapon --show' muestra al menos 1G de swap activo.
  # 4. El archivo /etc/fstab contiene la línea correcta y no tiene errores de sintaxis.
  # 5. El backup existe en node03 y contiene la configuración válida.
tags:
  - Laboratorios-del-LFCS
---
[[Laboratorios del LFCS]]

---

