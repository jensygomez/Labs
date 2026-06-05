---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Playground: PG-002
Titulo: Permisos avanzados y bastionado de directorios compartidos (SUID, SGID, Sticky Bit) - V2
Fecha de Inicio: 2026-06-05
Dificultad: 7/10
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux Pleno Level 2/3
Temas:
  - List, Set, and Change Standard File Permissions
  - SUID, SGID, and Sticky Bit Security Constraints
Competencias:
  - Asegurar la colaboración en entornos multitenant mediante herencia forzada de GIDs
  - Implementar contenciones contra la destrucción de datos (Data Deletion/Tampering) en almacenamiento compartido
  - Comprender los riesgos y limitaciones de seguridad del bit SUID en binarios compilados vs scripts interpretados
Ticket: |-
  INC-5022 (CRÍTICO) - Brecha de Seguridad y Desconfiguración de Entorno Compartido en CI/CD

  El equipo de Ciberseguridad bloqueó el nodo de compilación 'build-node-01' debido a dos hallazgos graves durante una auditoría en caliente:
  1. El directorio de integración '/opt/ci_shared/builds' fue configurado erróneamente con permisos laxos. Cuando el pipeline del usuario 'jenkins-agent' genera artefactos, el grupo de ingenieros 'release-ops' no puede modificarlos ni empaquetarlos porque nacen sin la herencia del grupo corporativo.
  2. Se detectó que ingenieros de otros equipos borraron por error reportes de cobertura que no les pertenecían dentro de ese mismo directorio.
  3. Requerimiento de Infraestructura: Se necesita que la herramienta nativa de telemetría de rendimiento '/usr/bin/sysperf', que interactúa directamente con descriptores del Kernel protegidos, pueda ser ejecutada por cualquier operador del sistema, pero asegurando que SIEMPRE se ejecute con los privilegios del usuario propietario ('root') para evitar errores de 'Permission Denied'.

  Misión de Hardening:
  - Corrija la propiedad del directorio a 'root:release-ops'.
  - Configure los permisos especiales necesarios para forzar la herencia de grupo y blindar el directorio contra borrados cruzados de archivos de terceros.
  - Asegure que el binario de telemetría adquiera los privilegios de ejecución del propietario de forma nativa en el Kernel.
Validacion:
  - Objetivo: El directorio /opt/ci_shared/builds pertenece a root:release-ops con permisos de grupo rwxs.
    Peso: 25 %
  - Objetivo: El Sticky Bit está activo en el directorio protegiendo los artefactos de modificaciones/borrados no autorizados (Permiso Octal 3775 o similar).
    Peso: 35 %
  - Objetivo: El binario compilado /usr/bin/sysperf está configurado correctamente con el bit SUID activo.
    Peso: 40 %
Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup_sh
  #!/bin/bash
  set -e

  # Garantizar entorno limpio y creación de identidades del laboratorio
  groupadd -g 3500 release-ops 2>/dev/null || true
  useradd -u 3501 -g release-ops jenkins-agent 2>/dev/null || true
  useradd -u 3502 -g release-ops operator-l1 2>/dev/null || true

  # Crear escenario roto (Permisos incorrectos y dueño desalineado)
  mkdir -p /opt/ci_shared/builds
  chown root:root /opt/ci_shared/builds
  chmod 777 /opt/ci_shared/builds

  # SIMULACIÓN AVANZADA: SUID solo funciona en binarios compilados en el Kernel de Linux.
  # Compilaremos un binario real en C en caliente para simular la herramienta 'sysperf'.
  mkdir -p /usr/bin
  cat << 'SOURCE_C' > /tmp/sysperf.c
  #include <stdio.h>
  #include <unistd.h>
  int main() {
      printf("Telemetry analyzer executing under Effective UID: %d\n", geteuid());
      return 0;
  }
  SOURCE_C

  # Compilar si gcc está disponible, de lo contrario simular estructura con un binario mock
  if command -v gcc &>/dev/null; then
      gcc /tmp/sysperf.c -o /usr/bin/sysperf
  else
      # Fallback si no hay GCC: Copiamos un binario del sistema para la prueba
      cp /bin/true /usr/bin/sysperf
  fi
  chmod 755 /usr/bin/sysperf
  chown root:root /usr/bin/sysperf
  rm -f /tmp/sysperf.c /tmp/sysperf

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;31m 🔥 ESCENARIO AVANZADO CONFIGURADO - ESSENTIAL COMMANDS (PG-002 v2)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-5022\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Hardening Multitenant y Mitigación de Escalada de Privilegios"
  echo -e " \e[1mSeveridad:\e[0m Crítica / Bloqueo de Pipeline de Despliegue"
  echo -e ""
  echo -e " \e[1mDescripción:\e[0m"
  echo -e " Ajuste el directorio /opt/ci_shared/builds (propietario root:release-ops)."
  echo -e " Aplique SGID para resolver la herencia y Sticky Bit para mitigar el sabotaje"
  echo -e " de archivos. Configure el binario de telemetría '/usr/bin/sysperf' con SUID."
  echo -e ""
  echo -e " \e[1mRequerimientos de Validación:\e[0m"
  echo -e "  [ ] Propietario root:release-ops en /opt/ci_shared/builds     --> \e[1;35m25%\e[0m"
  echo -e "  [ ] SGID + Sticky Bit combinados en el directorio operativo     --> \e[1;35m35%\e[0m"
  echo -e "  [ ] SUID activo en el binario compilado /usr/bin/sysperf       --> \e[1;34m40%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32mNota de Campo:\e[0m Note cómo cambia el color del binario en la terminal al activar SUID.\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup_sh && rm -f /tmp/setup_sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0

  echo "=== AUDITORÍA FORENSE DE PERMISOS CIS BENCHMARK ==="

  DIR="/opt/ci_shared/builds"
  BIN="/usr/bin/sysperf"

  # 1. Validar Dueño y Grupo
  if [ -d "$DIR" ]; then
      OWNER=$(stat -c '%U' "$DIR")
      GROUP=$(stat -c '%G' "$DIR")
      if [ "$OWNER" = "root" ] && [ "$GROUP" = "release-ops" ]; then
          echo "✔ [25%] Propietario (root) y Grupo (release-ops) asignados correctamente."
          PUNTOS=$((PUNTOS + 25))
      else
          echo "❌ [0%] Falló la propiedad: Encontrado $OWNER:$GROUP."
      fi
  else
      echo "❌ [0%] El directorio de compilación no existe."
  fi

  # 2. Validar SGID y Sticky Bit en simultáneo
  if [ -d "$DIR" ]; then
      OCTAL_FULL=$(stat -c '%a' "$DIR")
      if [ ${#OCTAL_FULL} -eq 4 ]; then
          SPECIAL_BIT=$(echo "$OCTAL_FULL" | cut -c1)
          # SGID (2) + Sticky (1) = 3. Si además tuviera SUID (cosa que no debe) sería 7.
          if [ "$SPECIAL_BIT" = "3" ]; then
              # Validar que los permisos base sean permisivos para el grupo (rwxrwxr-x o similar, es decir, x75 o x70)
              BASE_PERM=$(echo "$OCTAL_FULL" | cut -c2-4)
              if [[ "$BASE_PERM" == "775" || "$BASE_PERM" == "770" ]]; then
                  echo "✔ [35%] Combinación perfecta de SGID (Herencia) y Sticky Bit (Protección de borrado) detectada: Permiso $OCTAL_FULL."
                  PUNTOS=$((PUNTOS + 35))
              else
                  echo "❌ [15%] Bits especiales configurados bien, pero los permisos base ($BASE_PERM) bloquean al grupo."
                  PUNTOS=$((PUNTOS + 15))
              fi
          else
              echo "❌ [0%] Los bits especiales no corresponden a SGID + Sticky Bit combinados (Dígito inicial: $SPECIAL_BIT)."
          fi
      else
          echo "❌ [0%] No se detectaron permisos especiales activos (Formato octal estándar sin prefijo)."
      fi
  fi

  # 3. Validar SUID en el Binario Real
  if [ -f "$BIN" ]; then
      PERM_TEXT=$(stat -c '%A' "$BIN")
      if echo "$PERM_TEXT" | grep -q "..s"; then
          echo "✔ [40%] Bit SUID validado en el binario compilado. Ejecución forzada como root."
          PUNTOS=$((PUNTOS + 40))
      else
          echo "❌ [0%] El binario no cuenta con el bit SUID activo en los permisos del propietario."
      fi
  else
      echo "❌ [0%] El binario crítico de telemetría no se encuentra en la ruta."
  fi

  echo "====================================================="
  echo "🎯 RESULTADO DE LA MITIGACIÓN: $PUNTOS / 100"
  echo "====================================================="
---
[[Laboratorios del LFCS]]
---
