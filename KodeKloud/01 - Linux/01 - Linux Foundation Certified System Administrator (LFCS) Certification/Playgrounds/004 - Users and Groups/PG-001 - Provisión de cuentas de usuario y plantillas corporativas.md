---
Curso: Prep Course - LFCS Certification
Modulo: Users and Groups
Playground: PG-001
Titulo: Provisión de cuentas de usuario y plantillas corporativas
Fecha de Inicio: 2026-06-03
Dificultad: 3/10
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux
Temas:
  - Local User Accounts
  - Local Groups and Memberships
  - Template User Environment
Competencias:
  - Crear y modificar usuarios (useradd, usermod) con fechas de expiración específicas
  - Gestionar grupos locales (groupadd, gpasswd) e IDs estáticos (GID/UID)
  - Personalizar el entorno global de nuevos usuarios mediante /etc/skel
Ticket: |-
  INC-2001

  El departamento de Recursos Humanos solicita la creación urgente de la cuenta para el nuevo consultor externo de desarrollo. Adicionalmente, el equipo de seguridad exige que todas las nuevas cuentas locales incluyan un archivo de políticas de bienvenida en su directorio Home al momento de ser creadas.

  Requerimientos técnicos obligatorios:
  1. Crear un grupo llamado "devs" con el GID específico 2500.
  2. Modificar el esqueleto del sistema (/etc/skel) para que cualquier usuario nuevo creado a partir de ahora incluya automáticamente un archivo vacío llamado 'WELCOME_CORP.txt' en la raíz de su Home.
  3. Crear al usuario "consultor1" con el UID 2501, cuyo grupo primario sea "devs". La cuenta debe estar configurada para expirar el 31 de diciembre de 2026.
Validacion:
  - Objetivo: El grupo 'devs' existe con el GID correcto.
    Peso: 25 %
  - Objetivo: El entorno de plantilla (/etc/skel) contiene el archivo requerido.
    Peso: 25 %
  - Objetivo: El usuario 'consultor1' existe, tiene el UID/GID correcto y el archivo en su Home.
    Peso: 35 %
  - Objetivo: La cuenta del consultor tiene la fecha de expiración configurada para el 2026-12-31.
    Peso: 15 %
Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup_sh
  #!/bin/bash
  set -e

  # Limpieza previa por si se ejecuta varias veces
  userdel -r consultor1 2>/dev/null || true
  groupdel devs 2>/dev/null || true
  rm -f /etc/skel/WELCOME_CORP.txt

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m 🚀 ESCENARIO CONFIGURADO - MÓDULO USERS & GROUPS (PG-001)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-2001\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Provisión de cuentas de usuario y plantillas corporativas"
  echo -e " \e[1mSeveridad:\e[0m Normal / Operaciones de TI"
  echo -e ""
  echo -e " \e[1mDescripción:\e[0m"
  echo -e " Prepare el esqueleto del sistema según las normativas de seguridad, cree"
  echo -e " el grupo 'devs' (GID 2500) e incorpore al usuario 'consultor1' (UID 2501)"
  echo -e " asegurando que su cuenta expire el 2026-12-31."
  echo -e ""
  echo -e " \e[1mRequerimientos de Validación (Peso Total: 100%):\e[0m"
  echo -e "  [ ] Grupo 'devs' creado con GID 2500                             --> \e[1;35m25%\e[0m"
  echo -e "  [ ] Archivo WELCOME_CORP.txt creado dentro de /etc/skel/         --> \e[1;35m25%\e[0m"
  echo -e "  [ ] Usuario 'consultor1' (UID 2501) con grupo primario 'devs'    --> \e[1;35m35%\e[0m"
  echo -e "  [ ] Fecha de expiración de la cuenta fijada para el 2026-12-31   --> \e[1;35m15%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32mMisión:\e[0m Use 'groupadd', 'useradd', modifique /etc/skel y configure los tiempos con 'chage'.\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup_sh && rm -f /tmp/setup_sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0

  echo "=== EVALUANDO GESTIÓN DE USUARIOS Y GRUPOS ==="

  # 1. Validar existencia de grupo devs y su GID
  if getent group devs >/dev/null 2>&1; then
      GID_DEVS=$(getent group devs | cut -d: -f3)
      if [ "$GID_DEVS" -eq 2500 ]; then
          echo "✔ [25%] Grupo 'devs' verificado con el GID 2500."
          PUNTOS=$((PUNTOS + 25))
      else
          echo "❌ [0%] El grupo 'devs' existe pero su GID es $GID_DEVS (se esperaba 2500)."
      fi
  else
      echo "❌ [0%] El grupo 'devs' no existe en el sistema."
  fi

  # 2. Validar el archivo plantilla en /etc/skel
  if [ -f /etc/skel/WELCOME_CORP.txt ]; then
      echo "✔ [25%] Archivo de plantilla corporativa 'WELCOME_CORP.txt' detectado en /etc/skel/."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] No se encuentra el archivo 'WELCOME_CORP.txt' dentro de /etc/skel/."
  fi

  # 3. Validar existencia del usuario consultor1, su UID, su GID y si heredó la plantilla
  if id consultor1 >/dev/null 2>&1; then
      UID_CONSULTOR=$(id -u consultor1)
      GID_CONSULTOR=$(id -g consultor1)
      HOME_CONSULTOR=$(eval echo ~consultor1)
      
      if [ "$UID_CONSULTOR" -eq 2501 ] && [ "$GID_CONSULTOR" -eq 2500 ]; then
          if [ -f "$HOME_CONSULTOR/WELCOME_CORP.txt" ]; then
              echo "✔ [35%] Usuario 'consultor1' configurado correctamente (UID/GID válidos y herencia de Home exitosa)."
              PUNTOS=$((PUNTOS + 35))
          else
              echo "❌ [20%] Usuario e IDs correctos, pero el Home no heredó el archivo de la plantilla (¿creó el usuario antes de modificar /etc/skel?)."
              PUNTOS=$((PUNTOS + 20))
          fi
      else
          echo "❌ [0%] El usuario existe pero tiene UID:$UID_CONSULTOR o GID primario:$GID_CONSULTOR incorrectos."
      fi
  else
      echo "❌ [0%] El usuario 'consultor1' no ha sido creado en el sistema."
  fi

  # 4. Validar fecha de expiración (2026-12-31) usando chage/account expire
  if id consultor1 >/dev/null 2>&1; then
      # Obtener los días desde la época para la expiración de la cuenta (campo 8 de /etc/shadow)
      EXP_DAYS=$(getent shadow consultor1 | cut -d: -f8)
      # 2026-12-31 equivale a 20819 días desde 1970-01-01
      if [ "$EXP_DAYS" = "20819" ]; then
          echo "✔ [15%] Fecha de expiración de cuenta asignada correctamente (2026-12-31)."
          PUNTOS=$((PUNTOS + 15))
      else
          echo "❌ [0%] La cuenta no tiene la fecha de expiración requerida o no está configurada."
      fi
  else
      echo "❌ [0%] No se pudo validar la expiración porque el usuario no existe."
  fi

  echo "============================"
  echo "CALIFICACIÓN FINAL: $PUNTOS / 100"
  echo "============================"
---

[[Laboratorios del LFCS]]
---
