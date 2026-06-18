---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Playground: PG-002
Titulo: Permisos avanzados y bastionado de directorios compartidos (SUID, SGID, Sticky Bit) - V2
Fecha de Inicio: 2026-06-09
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
Validacion:
  - Objetivo: El directorio /opt/ci_shared/builds pertenece a root:release-ops con permisos de grupo rwxs.
    Peso: 25 %
  - Objetivo: El Sticky Bit está activo en el directorio protegiendo los artefactos de modificaciones/borrados no autorizados (Permiso Octal 3775 o similar).
    Peso: 35 %
  - Objetivo: El binario compilado /usr/bin/sysperf está configurado correctamente con el bit SUID activo.
    Peso: 40 %
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
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-5022 (CRÍTICO)\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Brecha de Seguridad y Desconfiguración de Entorno Compartido en CI/CD"
  echo -e " \e[1mSeveridad:\e[0m Crítica / Bloqueo de Pipeline de Despliegue"
  echo -e ""
  echo -e " \e[1mContexto del Incidente:\e[0m"
  echo -e "  Durante una auditoría en caliente, el equipo de Ciberseguridad encontró"
  echo -e "  dos hallazgos que no podían ignorarse. La situación escaló de inmediato"
  echo -e "  y el nodo de compilación 'build-node-01' fue bloqueado preventivamente."
  echo -e "  El pipeline de despliegue está detenido hasta que esto se resuelva."
  echo -e ""
  echo -e "  El primer hallazgo tiene que ver con el directorio '/opt/ci_shared/builds'."
  echo -e "  Fue configurado con permisos incorrectos desde el inicio. Cada vez que"
  echo -e "  el agente 'jenkins-agent' genera un artefacto, ese archivo nace con el"
  echo -e "  grupo equivocado. El equipo 'release-ops' no puede modificarlo ni"
  echo -e "  empaquetarlo. El directorio no hereda el grupo corporativo. Resultado:"
  echo -e "  el proceso de release está completamente bloqueado."
  echo -e ""
  echo -e "  El segundo hallazgo es más delicado. Ingenieros de otros equipos han"
  echo -e "  estado borrando por error reportes de cobertura que no les pertenecían,"
  echo -e "  dentro de ese mismo directorio compartido. No hubo intención maliciosa,"
  echo -e "  pero el daño es real. Sin un control a nivel de permisos del sistema,"
  echo -e "  esto volverá a ocurrir."
  echo -e ""
  echo -e "  Adicionalmente, Infraestructura tiene un requerimiento pendiente."
  echo -e "  La herramienta de telemetría '/usr/bin/sysperf' interactúa directamente"
  echo -e "  con descriptores protegidos del Kernel. Cualquier operador del sistema"
  echo -e "  debe poder ejecutarla, pero siempre con los privilegios del propietario."
  echo -e "  Sin eso, los operadores reciben 'Permission Denied' y la telemetría falla."
  echo -e ""
  echo -e " \e[1mMisión de Hardening — tres frentes, sin margen de error:\e[0m"
  echo -e ""
  echo -e "  \e[1;31m1.\e[0m Corrija la propiedad del directorio operativo a 'root:release-ops'."
  echo -e "     Mientras eso no esté bien, todo lo demás es construir sobre arena."
  echo -e ""
  echo -e "  \e[1;31m2.\e[0m Configure los permisos especiales que fuercen la herencia de grupo"
  echo -e "     en cada archivo creado dentro del directorio, y que impidan que un"
  echo -e "     usuario elimine archivos que no le pertenecen."
  echo -e "     Dos bits especiales. Los dos son necesarios. Ninguno es opcional."
  echo -e ""
  echo -e "  \e[1;31m3.\e[0m Asegure que el binario de telemetría adquiera los privilegios del"
  echo -e "     propietario en el momento de ejecución, de forma nativa en el Kernel."
  echo -e "     Sin wrappers. Sin sudo. El bit correcto en el lugar correcto."
  echo -e ""
  echo -e " \e[1mRequerimientos de Validación:\e[0m"
  echo -e "  [ ] Propietario root:release-ops en /opt/ci_shared/builds     --> \e[1;35m25%\e[0m"
  echo -e "  [ ] SGID + Sticky Bit combinados en el directorio operativo    --> \e[1;35m35%\e[0m"
  echo -e "  [ ] SUID activo en el binario compilado /usr/bin/sysperf       --> \e[1;34m40%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32mNota de Campo:\e[0m Observe cómo cambia el color del binario en la terminal"
  echo -e "              al momento de activar SUID. El sistema operativo lo marca."
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


---

Recently, I resolved a critical security incident — INC-5022 — on a CI/CD build node that had been preventively taken offline by the cybersecurity team. The deployment pipeline was completely blocked, so I had to work efficiently and without margin for error.

The first thing I did was correct the ownership of the shared operational directory `/opt/ci_shared/builds`, assigning it to `root:release-ops`. That was the foundation — without it, nothing else would have made sense.

Then I configured two special permission bits on that directory. I applied SGID so that every file created inside automatically inherits the group, which solves the broken artifact ownership issue the release team was facing. I also applied the Sticky Bit to prevent engineers from accidentally deleting files that didn't belong to them — something that had already caused real damage according to the audit findings. The key detail here was getting the base permissions right: my first attempt used `777`, which the CIS Benchmark flagged immediately because it rendered the group control meaningless. I corrected it to `3775`, which enforces least privilege while keeping the special bits fully functional.

Finally, I secured the telemetry binary `/usr/bin/sysperf` by setting the SUID bit. This allows any system operator to execute it while the process runs with the owner's privileges at the kernel level — no wrappers, no sudo, no workarounds.

The audit closed at 100/100. The pipeline was unblocked and the security findings were fully remediated.

This is the kind of work I'm actively building my skills around — understanding not just what a command does, but why the system behaves the way it does at a permissions level.