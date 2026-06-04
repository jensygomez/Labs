---
Curso: Prep Course - LFCS Certification
Modulo: Users and Groups
Playground: PG-003
Titulo: Gestión de privilegios y control de acceso (Sudoers, PAM y NSSwitch)
Fecha de Inicio: 2026-06-03
Dificultad: 5/10
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux
Temas:
  - Manage User Privileges
  - Manage Access to Root Account
  - LDAP User and Group Accounts (NSSwitch/SSSD Coordination)
Competencias:
  - Delegar privilegios específicos en /etc/sudoers.d/ sin otorgar acceso total
  - Restringir el uso del comando 'su' mediante el módulo PAM wheel
  - Configurar el orden de resolución de nombres y servicios en /etc/nsswitch.conf
Ticket: |-
  INC-2003

  Una auditoría interna de seguridad ha detectado dos vulnerabilidades críticas en el servidor:
  1. Los desarrolladores están usando cuentas con privilegios totales innecesarios. Se solicita que los miembros del grupo "devs" solo puedan reiniciar servicios de Systemd (comando /usr/bin/systemctl restart) sin solicitar contraseña, denegando cualquier otro comando administrativo.
  2. Cualquier usuario local puede intentar adivinar la contraseña de Root usando 'su'. Restrinja el uso de 'su' únicamente a los miembros del grupo administrativo "wheel".
  3. El equipo de arquitectura migrará las cuentas a un servidor LDAP centralizado. Prepare el archivo de configuración de resolución del sistema para que busque usuarios y grupos primero en los archivos locales y, si no los encuentra, consulte el servicio SSSD/LDAP.

  Aplique estas políticas de manera estricta y modular.
Validacion:
  - Objetivo: Regla modular de sudo para @devs creada correctamente en /etc/sudoers.d/.
    Peso: 30 %
  - Objetivo: La regla de sudo permite 'systemctl restart' con la directiva NOPASSWD.
    Peso: 25 %
  - Objetivo: Módulo PAM wheel activo para mitigar accesos no autorizados a la cuenta de Root.
    Peso: 25 %
  - Objetivo: Archivo /etc/nsswitch.conf configurado con el orden 'files sssd' o 'files ldap'.
    Peso: 20 %
Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup_sh
  #!/bin/bash
  set -e

  # Asegurar existencia del grupo devs
  getent group devs >/dev/null 2>&1 || groupadd -g 2500 devs

  # Limpieza de configuraciones previas para consistencia del lab
  rm -f /etc/sudoers.d/devs-privileges
  sed -i 's/^auth\s\+required\s\+pam_wheel.so/# auth required pam_wheel.so/' /etc/pam.d/su

  # Modificar nsswitch de manera intencional para dejarlo por defecto o roto
  sed -i 's/^passwd:.*/passwd:      files/' /etc/nsswitch.conf
  sed -i 's/^group:.*/group:       files/' /etc/nsswitch.conf

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;31m 🚀 ESCENARIO CONFIGURADO - MÓDULO USERS & GROUPS (PG-003)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-2003\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Gestión de privilegios y control de acceso"
  echo -e " \e[1mSeveridad:\e[0m Alta / Cumplimiento de Seguridad (Hardening)"
  echo -e ""
  echo -e " \e[1mDescripción:\e[0m"
  echo -e " Configure Sudoers modularmente para el grupo '@devs', bloquee el acceso"
  echo -e " a 'su' mediante PAM para cuentas fuera de 'wheel', y prepare la resolución"
  echo -e " de nombres de NSSwitch para incorporar fuentes SSSD/LDAP."
  echo -e ""
  echo -e " \e[1mRequerimientos de Validación (Peso Total: 100%):\e[0m"
  echo -e "  [ ] Archivo /etc/sudoers.d/devs-privileges bien estructurado     --> \e[1;35m30%\e[0m"
  echo -e "  [ ] Permiso exclusivo 'systemctl restart' con NOPASSWD           --> \e[1;35m25%\e[0m"
  echo -e "  [ ] Restricción PAM wheel habilitada en /etc/pam.d/su            --> \e[1;35m25%\e[0m"
  echo -e "  [ ] NSSwitch configurado con 'files sssd' (o ldap) en passwd/group-> \e[1;35m20%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32mMisión:\e[0m Utilice visudo, edite las configuraciones de PAM y actualice nsswitch.conf\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup_sh && rm -f /tmp/setup_sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0

  echo "=== EVALUANDO CONFIGURACIÓN DE PRIVILEGIOS Y IDENTIDAD ==="

  # 1 y 2. Validar reglas en /etc/sudoers.d/devs-privileges
  FILE_SUDO="/etc/sudoers.d/devs-privileges"
  if [ -f "$FILE_SUDO" ]; then
      echo "✔ [30%] Archivo de privilegios modulares '$FILE_SUDO' detectado."
      PUNTOS=$((PUNTOS + 30))
      
      # Verificar contenido y restricción de comando exacta con NOPASSWD
      if grep -E "^\s*@devs\s+.*NOPASSWD:\s*\/usr\/bin\/systemctl\s+restart" "$FILE_SUDO" >/dev/null 2>&1; then
          echo "✔ [25%] Sintaxis de delegación de comandos y NOPASSWD para @devs validada."
          PUNTOS=$((PUNTOS + 25))
      else
          echo "❌ [0%] La regla de sudo existe pero no restringe el comando exacto o le falta NOPASSWD."
      fi
  else
      echo "❌ [0%] No se encuentra el archivo modular de sudoers en /etc/sudoers.d/devs-privileges."
  fi

  # 3. Validar restricción PAM para la cuenta de Root (comando su)
  if grep -E "^\s*auth\s+required\s+pam_wheel\.so\s*$" /etc/pam.d/su >/dev/null 2>&1 || grep -E "^\s*auth\s+required\s+pam_wheel\.so\s+use_uid" /etc/pam.d/su >/dev/null 2>&1; then
      echo "✔ [25%] Restricción PAM activada: Solo miembros de 'wheel' pueden usar 'su'."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] El archivo /etc/pam.d/su permite que cualquier usuario ejecute el comando 'su'."
  fi

  # 4. Validar orden de NSSwitch para soporte LDAP/SSSD
  PASSWD_NSS=$(grep "^passwd:" /etc/nsswitch.conf)
  GROUP_NSS=$(grep "^group:" /etc/nsswitch.conf)

  if echo "$PASSWD_NSS" | grep -E "files\s+(sssd|ldap)" >/dev/null 2>&1 && echo "$GROUP_NSS" | grep -E "files\s+(sssd|ldap)" >/dev/null 2>&1; then
      echo "✔ [20%] NSSwitch configurado correctamente para resolver localmente antes de consultar la red."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] NSSwitch no incluye la directiva sssd/ldap en el orden jerárquico correcto."
  fi

  echo "============================"
  echo "CALIFICACIÓN FINAL: $PUNTOS / 100"
  echo "============================"
---

[[Laboratorios del LFCS]]
---
