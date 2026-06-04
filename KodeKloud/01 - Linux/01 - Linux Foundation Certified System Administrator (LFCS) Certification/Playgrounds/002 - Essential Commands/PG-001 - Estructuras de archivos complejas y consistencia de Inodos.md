---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Playground: PG-001
Titulo: Estructuras de archivos complejas y consistencia de Inodos
Fecha de Inicio: 2026-06-04
Dificultad: 4/10
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux Pleno
Temas:
  - Create, Delete, Copy, and Move Files and Directories
  - Create and Manage Hard Links
  - Create and Manage Soft Links
  - Read and Use System Documentation
Competencias:
  - Diseñar e interconectar estructuras de directorios corporativos desde cero
  - Diferenciar y aplicar Enlaces duros (Hard Links) y Enlaces simbólicos (Soft Links) bajo restricciones del sistema de archivos
  - Rastrear el uso e identificadores de Inodos en el almacenamiento local
Ticket: |-
  INC-3001

  El equipo de base de datos reporta que un sistema heredado (legacy) requiere que su archivo de configuración principal esté accesible desde múltiples ubicaciones dentro del servidor. Sin embargo, por regulaciones de integridad de la empresa, no se permite duplicar el archivo (hacer copias físicas) para evitar desincronizaciones de datos.

  Requerimientos obligatorios:
  1. Crear el directorio contenedor en '/srv/production/app_v1'.
  2. Crear el archivo maestro original de configuración en '/srv/production/app_v1/master.conf' con el texto "STAGE=PROD".
  3. Crear un enlace de tal manera que si el archivo original '/srv/production/app_v1/master.conf' se mueve de directorio o se renombra en el futuro, el enlace secundario ubicado en '/var/log/app_mirror.conf' NO pierda el acceso al contenido de los datos (Pista: Memoria del Inodo).
  4. Crear un enlace simbólico clásico (Soft link) que apunte desde '/etc/app_link.conf' hacia el archivo maestro original.
Validacion:
  - Objetivo: El directorio y el archivo maestro existen con los datos correctos.
    Peso: 20 %
  - Objetivo: El archivo de espejo en /var/log/app_mirror.conf es un Hard Link válido apuntando al mismo Inodo que el maestro.
    Peso: 40 %
  - Objetivo: El archivo /etc/app_link.conf es un enlace simbólico (Soft Link) apuntando al archivo maestro.
    Peso: 40 %
Calificacion Final: 80 %
Script: |-
  cat << 'EOF' > /tmp/setup_sh
  #!/bin/bash
  set -e

  # Limpieza absoluta de escenarios previos
  rm -rf /srv/production/app_v1
  rm -f /var/log/app_mirror.conf
  rm -f /etc/app_link.conf

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m 🚀 ESCENARIO CONFIGURADO - ESSENTIAL COMMANDS (PG-001)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-3001\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Estructuras de archivos complejas y consistencia de Inodos"
  echo -e " \e[1mSeveridad:\e[0m Normal / Configuración de Entorno"
  echo -e ""
  echo -e " \e[1mDescripción:\e[0m"
  echo -e " Configure la arquitectura de enlaces requerida por el equipo de base de datos."
  echo -e " Asegúrese de elegir correctamente el tipo de enlace (Hard vs Soft) basado en"
  echo -e " el requerimiento de persistencia ante cambios de nombre del archivo original."
  echo -e ""
  echo -e " \e[1mRequerimientos de Validación (Peso Total: 100%):\e[0m"
  echo -e "  [ ] Estructura /srv/production/app_v1/master.conf lista       --> \e[1;35m20%\e[0m"
  echo -e "  [ ] Enlace persistente (mismo Inodo) en /var/log/app_mirror.conf-> \e[1;35m40%\e[0m"
  echo -e "  [ ] Enlace simbólico en /etc/app_link.conf                      --> \e[1;35m40%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32mMisión:\e[0m Use los comandos 'mkdir -p', 'ln' con y sin sus modificadores de tipo de enlace.\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup_sh && rm -f /tmp/setup_sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0

  echo "=== EVALUANDO OPERACIONES DE ARCHIVOS Y ENLACES ==="

  MAESTRO="/srv/production/app_v1/master.conf"
  HARD_L="/var/log/app_mirror.conf"
  SOFT_L="/etc/app_link.conf"

  # 1. Validar el archivo maestro original
  if [ -f "$MAESTRO" ] && grep -q "STAGE=PROD" "$MAESTRO"; then
      echo "✔ [20%] Directorio corporativo y archivo maestro creados con éxito."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] El archivo maestro en $MAESTRO no existe o no tiene el contenido requerido."
  fi

  # 2. Validar que el espejo sea un Hard Link (deben compartir exactamente el mismo número de Inodo)
  if [ -f "$MAESTRO" ] && [ -f "$HARD_L" ]; then
      INODO_MAESTRO=$(stat -c '%i' "$MAESTRO")
      INODO_HARD=$(stat -c '%i' "$HARD_L")
      
      if [ "$INODO_MAESTRO" -eq "$INODO_HARD" ]; then
          # Validar que no sea el mismo archivo apuntándose a sí mismo por error de ruta
          if [ "$MAESTRO" != "$HARD_L" ]; then
              echo "✔ [40%] Enlace persistente validado: El archivo en $HARD_L comparte el Inodo $INODO_MAESTRO."
              PUNTOS=$((PUNTOS + 40))
          else
              echo "❌ [0%] Error en la ruta del enlace configurado."
          fi
      else
          echo "❌ [0%] El archivo $HARD_L existe pero es una copia independiente o un Soft Link (diferente Inodo)."
      fi
  else
      echo "❌ [0%] Falta crear el enlace permanente en $HARD_L."
  fi

  # 3. Validar que el acceso de configuración sea un Soft Link (Enlace Simbólico)
  if [ -L "$SOFT_L" ]; then
      TARGET_SOFT=$(readlink "$SOFT_L")
      if [ "$TARGET_SOFT" = "$MAESTRO" ]; then
          echo "✔ [40%] Enlace simbólico (Soft Link) en $SOFT_L apunta correctamente al maestro."
          PUNTOS=$((PUNTOS + 40))
      else
          echo "❌ [0%] El enlace simbólico en $SOFT_L existe pero apunta a '$TARGET_SOFT' en lugar de al maestro."
      fi
  else
      echo "❌ [0%] El archivo en $SOFT_L no es un enlace simbólico legítimo."
  fi

  echo "============================"
  echo "CALIFICACIÓN FINAL: $PUNTOS / 100"
  echo "============================"
---

[[Laboratorios del LFCS]]
---
Here's a summary of what I did in this lab, written in first person, as if I were explaining it to my manager, a friend, or an interviewer — in clear, non-technical English (B2 level):

---

Today I worked on a lab about file structures and links in Linux. The task was to set up a specific file architecture that the database team requires, using both hard links and symbolic links correctly.

First, I created the directory structure and the master configuration file. I used `mkdir -p` to create `/srv/production/app_v1/`, and then I created the file `master.conf` inside it with some configuration text.

Next, I created a **hard link** (permanent link) at `/var/log/app_mirror.conf` that points to the master file. A hard link means both files share the exact same inode on the disk, so they're essentially the same file from the system's perspective. This is important because even if the original file gets renamed or moved, the hard link still works.

Then, I created a **symbolic link** (soft link) at `/etc/app_link.conf` using `ln -s`. A symbolic link is like a shortcut that points to the original file's path. It's different from a hard link because if the original file is deleted, the symbolic link breaks.

In the end, 80 out of 100 points were validated: both links were created correctly (hard link with the same inode, and symbolic link pointing to the master file), but the master file itself didn't pass validation because of how I created it (I accidentally wrote to the directory instead of the file at first, then fixed it with `touch`).

The key takeaway for me was understanding the difference between hard links and symbolic links, and how to use `ln` correctly with and without the `-s` flag. This is useful in real production environments where you need persistent file references that survive renames or moves.