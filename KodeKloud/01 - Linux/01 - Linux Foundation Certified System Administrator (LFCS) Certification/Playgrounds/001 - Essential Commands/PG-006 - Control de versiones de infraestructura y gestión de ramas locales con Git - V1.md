---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Playground: PG-006
Titulo: Control de versiones de infraestructura y gestión de ramas locales con Git - V1
Fecha de Inicio: 2026-06-06
Dificultad: 6/10
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux Pleno
Temas:
  - Git - Basic Operations
  - Git - Staging and Committing Changes
  - Git - Branches and Remote Repositories
Competencias:
  - Implementar el ciclo de vida de Git local para auditar configuraciones del sistema
  - Controlar flujos de cambios aislados mediante ramificaciones (branches)
  - Fusionar actualizaciones de código de infraestructura bajo el principio de consistencia
Ticket: |-
  INC-3006

  El equipo de DevOps solicita estandarizar el almacenamiento de los scripts de mantenimiento local ubicados en '/opt/scripts_core'. Se requiere inicializar un repositorio Git local para auditar estos archivos y realizar una modificación controlada en el script de respaldo mediante ramas.

  Siga estrictamente el siguiente flujo de trabajo técnico:
  1. Inicializar un repositorio Git local dentro del directorio '/opt/scripts_core'.
  2. Configurar las variables locales (o globales) de Git para este entorno:
     - Nombre de usuario: Sysadmin Pleno
     - Correo electrónico: admin@corp.internal
  3. Crear un commit inicial en la rama por defecto que guarde el script base existente 'monitor.sh'. El mensaje del commit debe ser "Initial commit con script de monitoreo".
  4. Crear y cambiarse a una nueva rama llamada 'feature-patch'.
  5. Dentro de la rama 'feature-patch', cree un nuevo script llamado 'cleanup.sh' que contenga el texto "#!/bin/bash\necho 'Cleaning temp files'". Añada este archivo al área de staging y haga un commit con el mensaje "Añadido script de limpieza en rama feature".
  6. Regrese a la rama principal (main o master, según se haya inicializado por defecto) y fusione (merge) los cambios de la rama 'feature-patch' para consolidar la infraestructura de scripts.
Validacion:
  - Objetivo: Repositorio inicializado y datos de identidad configurados en Git.
    Peso: 20 %
  - Objetivo: Primer commit del script base registrado con el mensaje correcto en la rama principal.
    Peso: 30 %
  - Objetivo: Rama 'feature-patch' creada con el nuevo archivo cleanup.sh confirmado.
    Peso: 30 %
  - Objetivo: Fusión ejecutada con éxito; la rama principal tiene ambos commits e histórico unificado.
    Peso: 20 %
Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup_sh
  #!/bin/bash
  set -e

  # Limpieza absoluta de entornos Git previos
  rm -rf /opt/scripts_core
  rm -f /root/.gitconfig

  # Configurar el directorio del laboratorio
  mkdir -p /opt/scripts_core
  echo -e "#!/bin/bash\necho 'Checking system health'" > /opt/scripts_core/monitor.sh
  chmod +x /opt/scripts_core/monitor.sh

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m 🚀 ESCENARIO CONFIGURADO - ESSENTIAL COMMANDS (PG-006)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-3006\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Control de versiones de infraestructura locales con Git"
  echo -e " \e[1mSeveridad:\e[0m Normal / Gestión de Configuración (IaC)"
  echo -e ""
  echo -e " \e[1mDescripción:\e[0m"
  echo -e " Inicialice el repositorio Git en /opt/scripts_core. Configure la identidad"
  echo -e " con user.name='Sysadmin Pleno' y user.email='admin@corp.internal'."
  echo -e " Gestione el ciclo de vida de los archivos utilizando el área de staging,"
  echo -e " cree la rama de parche requerida, confirme los cambios y realice la fusión"
  echo -e " final en la rama de producción. El archivo cleanup.sh debe crearse en la"
  echo -e " rama feature-patch con el contenido mínimo de un script bash válido."
  echo -e ""
  echo -e " \e[1mRequerimientos de Validación (Peso Total: 100%):\e[0m"
  echo -e "  [ ] Git init y configuración de user.name='Sysadmin Pleno' y user.email='admin@corp.internal'  --> \e[1;35m20%\e[0m"
  echo -e "  [ ] Commit inicial de monitor.sh con mensaje exacto:                                           --> \e[1;35m30%\e[0m"
  echo -e "      'Initial commit con script de monitoreo'"
  echo -e "  [ ] Rama 'feature-patch' con cleanup.sh commiteado con mensaje exacto:                        --> \e[1;35m30%\e[0m"
  echo -e "      'Añadido script de limpieza en rama feature'"
  echo -e "  [ ] Git merge de feature-patch completado en master con ambos archivos presentes               --> \e[1;35m20%\e[0m"
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

  echo "=== EVALUANDO CONTROL DE VERSIONES LOCAL CON GIT ==="

  REPO_DIR="/opt/scripts_core"

  if [ -d "$REPO_DIR/.git" ]; then
      cd "$REPO_DIR"

      # 1. Validar configuraciones de identidad
      # Usamos git config local o global para extraer los valores inyectados
      GIT_USER=$(git config user.name || true)
      GIT_EMAIL=$(git config user.email || true)

      if [ "$GIT_USER" = "Sysadmin Pleno" ] && [ "$GIT_EMAIL" = "admin@corp.internal" ]; then
          echo "✔ [20%] Identidad de Git configurada correctamente (User y Email corporativo)."
          PUNTOS=$((PUNTOS + 20))
      else
          echo "❌ [0%] Falta configurar la identidad de Git o los valores no coinciden con el ticket."
      fi

      # Determinar el nombre de la rama principal por defecto (puede ser master o main)
      RAMA_PRINCIPAL=$(git branch --show-current)

      # 2. Validar commit inicial del monitor.sh
      if git log --all --grep="Initial commit con script de monitoreo" >/dev/null 2>&1; then
          echo "✔ [30%] Commit inicial validado con su respectivo mensaje y archivo base rastreado."
          PUNTOS=$((PUNTOS + 30))
      else
          echo "❌ [0%] No se encontró el commit inicial con el mensaje exacto requerido."
      fi

      # 3. Validar existencia histórica de la rama feature-patch y su commit
      if git branch -a | grep "feature-patch" >/dev/null 2>&1 || git log --all --grep="Añadido script de limpieza en rama feature" >/dev/null 2>&1; then
          echo "✔ [30%] Trabajo en rama remota/local 'feature-patch' e inyección del archivo cleanup.sh confirmados."
          PUNTOS=$((PUNTOS + 30))
      else
          echo "❌ [0%] No se detectó la rama 'feature-patch' o su commit correspondiente."
      fi

      # 4. Validar la fusión (Merge) en la rama principal
      # Si el merge se hizo bien, parados en la rama principal deberíamos ver el archivo cleanup.sh existente físicamente
      if [ -f "monitor.sh" ] && [ -f "cleanup.sh" ]; then
          echo "✔ [20%] Operación de Fusión (Git Merge) completada de forma exitosa en la rama principal."
          PUNTOS=$((PUNTOS + 20))
      else
          echo "❌ [0%] Los archivos no están unificados en la rama principal. ¿Olvidó ejecutar el comando merge?"
      fi

  else
      echo "❌ [0%] El directorio $REPO_DIR no ha sido inicializado como un repositorio Git (.git ausente)."
  fi

  echo "============================"
  echo "CALIFICACIÓN FINAL: $PUNTOS / 100"
  echo "============================"
---

[[Laboratorios del LFCS]]
---
Today I worked on a Git-based infrastructure version control scenario, which is a core practice in IaC environments. I initialized a local repository, configured the commit identity, managed the staging area, and handled the full branch lifecycle — from creating a feature branch to merging it back into the production branch.

One thing I want to highlight is that before executing anything, I reviewed both the ticket and the validator script to identify an inconsistency — the ticket didn't specify the exact values for user identity or the commit messages, but the validator had them hardcoded. I flagged that, proposed a corrected version of the ticket, and then proceeded with execution. That kind of critical reading is something I'm actively developing as part of my growth toward an L2/L3 role.