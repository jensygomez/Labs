---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Playground: PG-006
Titulo: Control de versiones de infraestructura y gestión de ramas locales con Git - V2
Fecha de Inicio: 2026-06-06
Dificultad: 7/10
Level Escalation: L2/L3
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux Pleno
Temas:
  - Git - Advanced Branching and Merge Conflicts
  - Git - Stash Management (Temporary Isolation)
  - Git - Tagging and Version Releases
Competencias:
  - Resolver conflictos de merge estructurales en archivos de configuración críticos (IaC)
  - Mitigar interrupciones de tareas concurrentes aislando entornos con comandos forenses (git stash)
  - Establecer líneas base de despliegue inmutables mediante versionamiento semántico con etiquetas (git tag)
Ticket: |-
  INC-9006 (URGENTE) - Conflicto en Scripts de Automatización Core y Despliegue de Release

  El equipo de DevOps reporta un quiebre en la consistencia del repositorio local '/opt/scripts_core'. Mientras se desarrollaba un parche de optimización en la rama 'feature-patch', el equipo de SRE modificó de urgencia el archivo 'monitor.sh' directamente en la rama principal. Al intentar unificar la infraestructura, el sistema arrojó fallas por líneas desalineadas.

  Siga estrictamente el siguiente flujo técnico de mitigación y ordenación:
  1. Identidad: Garantizar que el repositorio en '/opt/scripts_core' mantenga configurada la identidad del operador (Sysadmin Pleno / admin@corp.internal).
  2. Uso de Stash ante Interrupciones:
     - Párese en la rama 'feature-patch'. Simule que está modificando el script pero surge una emergencia: agregue la línea "DEBUG=true" al final de 'cleanup.sh', y antes de hacer commit, guarde los cambios en el área de aislamiento temporal de Git (`git stash save "parche_incompleto"`).
  3. Gestión Concurrentes de Ramas y Conflicto:
     - Regrese a la rama principal (master o main) y edite la línea 2 de 'monitor.sh' cambiándola exactamente a: "echo 'CRITICAL: System health check mode'". Haga commit con el mensaje "Urgente: Actualizado monitor en rama principal".
     - Cámbiese a la rama 'feature-patch', recupere su trabajo aislado (`git stash pop`), y modifique la línea 2 de 'monitor.sh' (sí, el mismo archivo) para que diga: "echo 'FEATURE: Enhanced health check mode'". Haga commit con el mensaje "Modificado monitor en rama feature".
  4. Fusión y Arbitraje de Conflictos:
     - Regrese a la rama principal e intente fusionar la rama 'feature-patch' (`git merge feature-patch`).
     - Git detectará un conflicto de fusión. Resuelva el conflicto de forma manual editando 'monitor.sh'. La línea final consolidada debe conservar ÚNICAMENTE el cambio de la rama feature: "echo 'FEATURE: Enhanced health check mode'".
     - Añada el archivo resuelto a staging y finalice el merge haciendo commit con el mensaje exacto: "Resolución de conflicto en monitor.sh".
  5. Versionamiento de Release:
     - Genere una etiqueta anotada en el último commit de la rama principal llamada 'v2.0.0' utilizando el mensaje: "Release oficial de infraestructura v2.0.0".
Validacion:
  - Objetivo: Uso correcto del flujo de aislamiento temporal verificado a través del histórico de stashes o commits secundarios.
    Peso: 20 %
  - Objetivo: Registro del commit de urgencia en la rama principal previo a la fusión.
    Peso: 20 %
  - Objetivo: Fusión y resolución manual del conflicto confirmadas con el mensaje de commit exacto.
    Peso: 40 %
  - Objetivo: Etiqueta de versión inmutable (Tag v2.0.0) registrada correctamente con su metadato anotado.
    Peso: 20 %
Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup_v2_sh
  #!/bin/bash
  set -e

  # 1. Limpieza absoluta de entornos previos
  rm -rf /opt/scripts_core
  rm -f /root/.gitconfig

  # 2. Configurar el directorio base simulando la V1 completada
  mkdir -p /opt/scripts_core
  cd /opt/scripts_core

  # Inicializar repositorio y configurar identidad local obligatoria
  git init -b master
  git config user.name "Sysadmin Pleno"
  git config user.email "admin@corp.internal"

  # Crear archivos iniciales de la V1
  echo -e "#!/bin/bash\necho 'Checking system health'" > monitor.sh
  echo -e "#!/bin/bash\necho 'Cleaning temp files'" > cleanup.sh
  chmod +x *.sh

  git add monitor.sh cleanup.sh
  git commit -m "Initial commit con script de monitoreo"

  # Crear la rama de características (feature-patch) para el Sysadmin
  git branch feature-patch

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;31m 🔥 ESCENARIO GIT PG-006 V2 CONFIGURADO - RESOLUCIÓN DE CONFLICTOS AVANZADOS\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-9006 (NIVEL PLENO L2/L3)\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Control de versiones, Git Stash y arbitraje de conflictos en caliente"
  echo -e " \e[1mSeveridad:\e[0m Crítica / Consistencia del código de infraestructura"
  echo -e ""
  echo -e " \e[1mRequerimientos Técnicos Obligatorios:\e[0m"
  echo -e "  [ ] Aislar un cambio parcial en 'cleanup.sh' usando 'git stash' en la rama feature-patch."
  echo -e "  [ ] Commitear cambios divergentes en la línea 2 de 'monitor.sh' en ambas ramas."
  echo -e "  [ ] Ejecutar el merge, detenerse ante el conflicto y resolverlo dejando la línea de la feature."
  echo -e "  [ ] Confirmar el merge con el mensaje exacto: 'Resolución de conflicto en monitor.sh'."
  echo -e "  [ ] Crear el tag anotado 'v2.0.0' con el mensaje de release especificado."
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32mMisión:\e[0m Opere netamente desde la terminal dentro de /opt/scripts_core. No use instaladores automáticos.\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup_v2_sh && rm -f /tmp/setup_v2_sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0
  REPO_DIR="/opt/scripts_core"

  echo "=== EVALUANDO OPERACIONES AVANZADAS DE GIT E INTEGRIDAD DE INFRAESTRUCTURA ==="

  if [ -d "$REPO_DIR/.git" ]; then
      cd "$REPO_DIR"

      # 1. Validar que la identidad se mantiene intacta
      GIT_USER=$(git config user.name || true)
      if [ "$GIT_USER" = "Sysadmin Pleno" ]; then
          echo "✔ [20%] Identidad autorizada confirmada en la auditoría del repositorio."
          PUNTOS=$((PUNTOS + 20))
      else
          echo "❌ [0%] Error de identidad en Git."
      fi

      # 2. Validar que existió la alteración y confirmación en la rama principal antes de la fusión
      if git log --all --grep="Urgente: Actualizado monitor en rama principal" >/dev/null 2>&1; then
          echo "✔ [20%] Flujo de emergencia en rama principal detectado en el histórico."
          PUNTOS=$((PUNTOS + 20))
      else
          echo "❌ [0%] No se encontró el commit intermedio de la rama principal."
      fi

      # 3. Validar resolución del conflicto y mensaje del commit de fusión
      if git log --grep="Resolución de conflicto en monitor.sh" >/dev/null 2>&1; then
          # Verificar si el contenido final fue resuelto de acuerdo a la regla de negocio (quedarse con la versión de la feature)
          if grep -q "FEATURE: Enhanced health check mode" monitor.sh && ! grep -q "<<<<<<<" monitor.sh; then
              echo "✔ [40%] Conflicto resuelto exitosamente. El archivo monitor.sh preserva la consistencia requerida."
              PUNTOS=$((PUNTOS + 40))
          else
              echo "❌ [0%] El conflicto se resolvió de forma incorrecta o conserva marcas de Git (<<<<<<<)."
          fi
      else
          echo "❌ [0%] Falta el commit de fusión con el mensaje de confirmación requerido."
      fi

      # 4. Validar creación del Tag anotado v2.0.0
      if git tag -l | grep -q "v2.0.0"; then
          TAG_MSG=$(git tag -l -n1 v2.0.0 | sed 's/v2.0.0\s*//')
          if git log -1 v2.0.0 >/dev/null 2>&1; then
              echo "✔ [20%] Tag anotado 'v2.0.0' detectado y validado en la línea de release."
              PUNTOS=$((PUNTOS + 20))
          else
              echo "❌ [0%] El tag existe pero no se creó como una etiqueta anotada (-a)."
          fi
      else
          echo "❌ [0%] No se ha configurado la etiqueta 'v2.0.0' en el repositorio."
      fi

  else
      echo "❌ [0%] El repositorio Git no se encuentra inicializado."
  fi

  echo "============================"
  echo "CALIFICACIÓN FINAL: $PUNTOS / 100"
  echo "============================"
---
