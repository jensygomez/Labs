---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Playground: PG-002
Titulo: Permisos avanzados y bastionado de directorios compartidos (SUID, SGID, Sticky Bit) - V1
Fecha de Inicio: 2026-06-04
Dificultad: 6/10
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux Pleno
Temas:
  - List, Set, and Change Standard File Permissions
  - SUID, SGID, and Sticky Bit
Competencias:
  - Implementar esquemas de colaboración segura mediante el bit SGID (g+s)
  - Proteger la integridad de borrado en directorios compartidos con el Sticky Bit (+t)
  - Auditar y asignar el bit SUID (u+s) a binarios específicos bajo el principio de menor privilegio
Ticket: |-
  INC-3002

  El líder del equipo de desarrollo reporta dos incidentes graves de seguridad en el servidor de pruebas:
  1. En el directorio compartido de desarrollo '/srv/shared_dev', cuando el usuario 'consultor1' crea un archivo, los otros miembros del grupo 'devs' no pueden modificarlo porque el archivo nace con el grupo primario del usuario y no con el del proyecto.
  2. Un usuario eliminó accidentalmente un código fuente que pertenecía a otro compañero dentro de ese mismo directorio compartido.
  3. Adicionalmente, se requiere que un script/binario ejecutable de auditoría ubicado en '/usr/local/bin/syswatch' se ejecute siempre con los privilegios del usuario propietario (root), incluso cuando sea lanzado por desarrolladores estándar.

  Misión: Corrija los permisos de la estructura existente, asegure la herencia de grupo, restrinja el borrado cruzado y configure el binario de auditoría.
Validacion:
  - Objetivo: El directorio /srv/shared_dev pertenece al grupo devs con permisos estándar de lectura/escritura/ejecución.
    Peso: 20 %
  - Objetivo: Habilitar SGID en el directorio para forzar la herencia del grupo devs.
    Peso: 30 %
  - Objetivo: Habilitar Sticky Bit en el directorio para prohibir el borrado de archivos entre usuarios.
    Peso: 30 %
  - Objetivo: Asignar permisos SUID al ejecutable /usr/local/bin/syswatch.
    Peso: 20 %
Calificacion Final: 100 %
Script: |-
  cat << 'EOF' > /tmp/setup_sh
  #!/bin/bash
  set -e

  # Asegurar entorno limpio del módulo anterior
  groupadd -g 2500 devs 2>/dev/null || true
  useradd -u 2501 -g devs consultor1 2>/dev/null || true
  useradd -u 2502 -g devs desarrollador2 2>/dev/null || true

  # Crear escenario roto (sin permisos especiales, dueño incorrecto)
  mkdir -p /srv/shared_dev
  chown root:root /srv/shared_dev
  chmod 777 /srv/shared_dev

  # Crear el binario de simulación syswatch
  mkdir -p /usr/local/bin
  echo -e '#!/bin/bash\necho "Auditing system resources as user: $(whoami)"' > /usr/local/bin/syswatch
  chmod 755 /usr/local/bin/syswatch
  chown root:root /usr/local/bin/syswatch

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m 🚀 ESCENARIO CONFIGURADO - ESSENTIAL COMMANDS (PG-002)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-3002\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Permisos avanzados y bastionado de directorios compartidos"
  echo -e " \e[1mSeveridad:\e[0m Alta / Control de Accesos"
  echo -e ""
  echo -e " \e[1mDescripción:\e[0m"
  echo -e " Ajuste el directorio /srv/shared_dev (propietario root, grupo devs)."
  echo -e " Aplique SGID para herencia de grupo y Sticky Bit para mitigar borrados."
  echo -e " Finalmente, configure /usr/local/bin/syswatch con el bit SUID."
  echo -e ""
  echo -e " \e[1mRequerimientos de Validación (Peso Total: 100%):\e[0m"
  echo -e "  [ ] Propietario root:devs y permisos rwx en /srv/shared_dev    --> \e[1;35m20%\e[0m"
  echo -e "  [ ] SGID activo (herencia de grupo automática)                  --> \e[1;35m30%\e[0m"
  echo -e "  [ ] Sticky Bit activo (protección contra eliminación)          --> \e[1;35m30%\e[0m"
  echo -e "  [ ] SUID activo en /usr/local/bin/syswatch                     --> \e[1;35m20%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup_sh && rm -f /tmp/setup_sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0

  echo "=== EVALUANDO PERMISOS ESPECIALES Y SEGURIDAD EN CAPAS ==="

  DIR="/srv/shared_dev"
  BIN="/usr/local/bin/syswatch"

  # 1. Validar Propietario y Grupo del directorio
  if [ -d "$DIR" ]; then
      OWNER=$(stat -c '%U' "$DIR")
      GROUP=$(stat -c '%G' "$DIR")
      PERM_STD=$(stat -c '%a' "$DIR" | sed 's/.//') # Ignorar el primer dígito especial temporalmente
      
      if [ "$OWNER" = "root" ] && [ "$GROUP" = "devs" ]; then
          echo "✔ [20%] Propietario (root) y Grupo (devs) asignados correctamente al directorio."
          PUNTOS=$((PUNTOS + 20))
      else
          echo "❌ [0%] Error: El directorio pertenece a $OWNER:$GROUP (se esperaba root:devs)."
      fi
  else
      echo "❌ [0%] El directorio $DIR no existe."
  fi

  # 2. Validar SGID (Debe mostrar la 's' en los permisos del grupo, representación octal incluye el bit 2)
  if [ -d "$DIR" ]; then
      # Capturar el formato octal completo (4 dígitos)
      OCTAL_FULL=$(stat -c '%a' "$DIR")
      # Si tiene 4 dígitos, el primero representa los permisos especiales
      if [ ${#OCTAL_FULL} -eq 4 ]; then
          SPECIAL_BIT=$(echo "$OCTAL_FULL" | cut -c1)
          # El bit SGID es 2. Si están SGID y Sticky Bit juntos, es 2+1=3 o similar.
          if [[ "$SPECIAL_BIT" == "2" || "$SPECIAL_BIT" == "3" || "$SPECIAL_BIT" == "6" || "$SPECIAL_BIT" == "7" ]]; then
              echo "✔ [30%] Permiso especial SGID detectado de forma correcta (Herencia activa)."
              PUNTOS=$((PUNTOS + 30))
          else
              echo "❌ [0%] El bit SGID no está configurado en el directorio."
          fi
      else
          echo "❌ [0%] No se detectaron permisos especiales activos en el directorio."
      fi
  fi

  # 3. Validar Sticky Bit (Debe mostrar la 't' al final, representación octal incluye el bit 1)
  if [ -d "$DIR" ]; then
      OCTAL_FULL=$(stat -c '%a' "$DIR")
      if [ ${#OCTAL_FULL} -eq 4 ]; then
          SPECIAL_BIT=$(echo "$OCTAL_FULL" | cut -c1)
          if [[ "$SPECIAL_BIT" == "1" || "$SPECIAL_BIT" == "3" || "$SPECIAL_BIT" == "5" || "$SPECIAL_BIT" == "7" ]]; then
              echo "✔ [30%] Permiso especial Sticky Bit detectado (Protección de borrado activa)."
              PUNTOS=$((PUNTOS + 30))
          else
              echo "❌ [0%] El Sticky Bit no está configurado en el directorio."
          fi
      else
          echo "❌ [0%] El Sticky Bit no está activo."
      fi
  fi

  # 4. Validar SUID en el binario (Octal debe empezar con 4 o el formato de texto incluir 's' en el dueño)
  if [ -f "$BIN" ]; then
      if stat -c '%A' "$BIN" | grep -q "..s"; then
          echo "✔ [20%] Bit SUID configurado exitosamente en el binario $BIN."
          PUNTOS=$((PUNTOS + 20))
      else
          echo "❌ [0%] El binario $BIN no tiene el bit SUID activo o no se ejecuta como root."
      fi
  else
      echo "❌ [0%] El archivo ejecutable de auditoría no existe."
  fi

  echo "============================"
  echo "CALIFICACIÓN FINAL: $PUNTOS / 100"
  echo "============================"
---

[[Laboratorios del LFCS]]
---
Hey, I just closed ticket INC-3002. It was about hardening permissions on a shared development directory.

I configured the /srv/shared_dev folder with the correct ownership (root:devs), enabled SGID to ensure proper group inheritance for new files, and activated the Sticky Bit to prevent users from deleting each other’s work. Finally, I applied the SUID bit on the syswatch binary as requested.

It was a straightforward but important task to improve both collaboration and security on the shared environment. Everything validated successfully at 100/100.