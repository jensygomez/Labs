---
Curso: Prep Course - LFCS Certification
Modulo: Users and Groups
Playground: PG-003
Titulo: Gestión de privilegios y control de acceso (Sudoers, PAM y NSSwitch) - V1
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
Script: |-
  cat << 'EOF' > /tmp/setup_sh
  #!/bin/bash
  set -e

  # Parámetros de Red del Clúster (Usuario bob / Contraseña caleston123 nativa)
  USER_NET="bob"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"

  echo -e "\e[1;33m⏳ Desplegando escenario de Hardening de Identidades en node02 desde node01...\e[0m"

  # 1. Configuración remota del estado vulnerable en node02
  ssh $SSH_OPTS -t ${USER_NET}@${NODE_TARGET} "sudo bash -c '
      # Asegurar existencia del grupo devs en node02
      getent group devs >/dev/null 2>&1 || groupadd -g 2500 devs

      # Limpieza de configuraciones previas para consistencia del lab en node02
      rm -f /etc/sudoers.d/devs-privileges
      sed -i \"s/^auth\s\+required\s\+pam_wheel.so/# auth required pam_wheel.so/\" /etc/pam.d/su

      # Modificar nsswitch de manera intencional (simula falta de preparación para LDAP)
      sed -i \"s/^passwd:.*/passwd:      files/\" /etc/nsswitch.conf
      sed -i \"s/^group:.*/group:       files/\" /etc/nsswitch.conf
  '"

  # 2. Preparación y limpieza de la Bóveda de Cumplimiento en node03
  ssh $SSH_OPTS -t ${USER_NET}@${NODE_VAULT} "sudo rm -rf /opt/security-compliance/* && sudo mkdir -p /opt/security-compliance/ && sudo chown -R bob:bob /opt/security-compliance/"

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m 🔐 ESCENARIO CONFIGURADO - HARDENING DISTRIBUIDO DE ACCESOS (PG-003-MN)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-2003 (MÓDULO: USERS, GROUPS & PAM)\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mUbicación de Control:\e[0m node01 (Estación Local — Administrador \e[1;32mbob\e[0m)"
  echo -e " \e[1mNodo a Intervenir:\e[0m    node02 (Servidor Remoto con Hallazgos de Seguridad)"
  echo -e " \e[1mNodo Bóveda Destino:\e[0m   node03 (Repositorio de Auditoría — \e[1;35m/opt/security-compliance/\e[0m)"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mContexto del Incidente (Hallazgos de Auditoría Interna):\e[0m"
  echo -e "  Una auditoría arrojó vulnerabilidades críticas en el servidor \e[1mnode02\e[0m."
  echo -e "  Usted debe mitigar de forma remota los tres vectores de ataque y, como"
  echo -e "  paso crítico de cumplimiento, centralizar las evidencias de la solución"
  echo -e "  dentro de la bóveda de seguridad ubicada en \e[1mnode03\e[0m."
  echo -e ""
  echo -e " \e[1mParámetros Técnicos Obligatorios (A ejecutar mediante comandos de red):\e[0m"
  echo -e ""
  echo -e "  \e[1;31m1. Acotamiento de Privilegios Sudoers Modulares (Remoto en node02)\e[0m"
  echo -e "     Cree el archivo '/etc/sudoers.d/devs-privileges' en node02. El grupo '@devs'"
  echo -e "     debe poder ejecutar exclusivamente el comando '/usr/bin/systemctl restart'"
  echo -e "     sobre cualquier servicio, con la directiva 'NOPASSWD:' activa."
  echo -e ""
  echo -e "  \e[1;31m2. Restricción del Mecanismo de Autenticación PAM (Remoto en node02)\e[0m"
  echo -e "     Modifique '/etc/pam.d/su' en node02 para activar el uso del módulo"
  echo -e "     'pam_wheel.so'. Esto restringirá el comando 'su' únicamente a usuarios"
  echo -e "     que pertenezcan al grupo administrativo 'wheel'."
  echo -e ""
  echo -e "  \e[1;31m3. Orden de Resolución de Nombres NSSwitch (Remoto en node02)\e[0m"
  echo -e "     Modifique '/etc/nsswitch.conf' en node02 para que las bases de datos de"
  echo -e "     'passwd' y 'group' resuelvan de forma prioritaria en 'files' y,"
  echo -e "     en segunda instancia, consulten el demonio 'sssd' (Filtro: 'files sssd')."
  echo -e ""
  echo -e "  \e[1;31m4. Centralización Criptográfica de Evidencias (Hacia node03)\e[0m"
  echo -e "     Una vez aplicados los cambios, extraiga los archivos modificados de node02"
  echo -e "     y envíelos a la ruta '/opt/security-compliance/' en node03, renombrándolos como:"
  echo -e "     - 'sudoers_devs.evidence' | 'pam_su.evidence' | 'nsswitch.evidence'"
  echo ""
  echo -e " \e[1mRequerimientos de Validación Remota:\e[0m"
  echo -e "  [ ] Sudoers modular en node02 acotado a 'systemctl restart'        --> \e[1;35m30%\e[0m"
  echo -e "  [ ] Módulo pam_wheel.so activo sin comentarios en node02:/etc/pam.d/su -> \e[1;35m25%\e[0m"
  echo -e "  [ ] NSSwitch con soporte secuencial 'files sssd' en node02           --> \e[1;35m25%\e[0m"
  echo -e "  [ ] Resguardo y trazabilidad de las 3 evidencias localizadas en node03 -> \e[1;35m20%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32m🚨 REGLA DE ORO DE ACCESO:\e[0m Ejecute visudo de forma remota o use validadores"
  echo -e "                        antes de perder acceso. Contraseña del clúster: \e[1mcaleston123\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup_sh && rm -f /tmp/setup_sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash

  cat > /tmp/validador.sh << 'EOF'
  #!/bin/bash
  PUNTOS=0

  NODE_TARGET="node02"
  NODE_VAULT="node03"
  USER_NET="bob"
  VAULT_DIR="/opt/security-compliance"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=4"

  echo -e "\n=== 🕵️ AUDITANDO HARDENING DE ACCESOS Y ENTRADA A BÓVEDA (INC-2003) ==="

  # 1. Validar Sudoers Modular en node02
  echo "⏳ Analizando sintaxis y restricciones de sudoers en node02..."
  if ssh $SSH_OPTS ${USER_NET}@${NODE_TARGET} "[ -f /etc/sudoers.d/devs-privileges ]" 2>/dev/null; then
      SUDO_CHECK=$(ssh $SSH_OPTS ${USER_NET}@${NODE_TARGET} "sudo cat /etc/sudoers.d/devs-privileges" 2>/dev/null || true)
      
      # Validar sintaxis remota con visudo
      SYNTAX_SUDO=$(ssh $SSH_OPTS ${USER_NET}@${NODE_TARGET} "sudo visudo -cf /etc/sudoers.d/devs-privileges" 2>/dev/null || true)
      
      if echo "$SYNTAX_SUDO" | grep -q "OK" && echo "$SUDO_CHECK" | grep -q "@devs" && echo "$SUDO_CHECK" | grep -q "NOPASSWD:" && echo "$SUDO_CHECK" | grep -q "/usr/bin/systemctl restart"; then
          echo "✔ [30%] Sudoers modular configurado correctamente en node02 con privilegios mínimos obligatorios."
          PUNTOS=$((PUNTOS + 30))
      else
          echo "❌ [0%] El archivo de sudoers modular en node02 tiene errores de sintaxis o excede los permisos requeridos."
      fi
  else
      echo "❌ [0%] No se encontró el archivo /etc/sudoers.d/devs-privileges en node02."
  fi

  # 2. Validar Restricción PAM en node02
  echo "⏳ Verificando políticas del módulo de autenticación PAM en node02..."
  PAM_CHECK=$(ssh $SSH_OPTS ${USER_NET}@${NODE_TARGET} "cat /etc/pam.d/su" 2>/dev/null | grep -E "pam_wheel.so" || true)

  if [ -n "$PAM_CHECK" ] && ! echo "$PAM_CHECK" | grep -q "^#"; then
      echo "✔ [25%] Restricción PAM (pam_wheel.so) activada de forma estricta para el comando su en node02."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] El módulo pam_wheel.so sigue comentado o ausente en /etc/pam.d/su dentro de node02."
  fi

  # 3. Validar NSSwitch en node02
  echo "⏳ Evaluando prioridades de fuentes de información en node02:/etc/nsswitch.conf..."
  NSS_PASSWD=$(ssh $SSH_OPTS ${USER_NET}@${NODE_TARGET} "grep '^passwd:' /etc/nsswitch.conf" 2>/dev/null || true)
  NSS_GROUP=$(ssh $SSH_OPTS ${USER_NET}@${NODE_TARGET} "grep '^group:' /etc/nsswitch.conf" 2>/dev/null || true)

  if echo "$NSS_PASSWD" | grep -q "files sssd" && echo "$NSS_GROUP" | grep -q "files sssd"; then
      echo "✔ [25%] Orden secuencial en NSSwitch listo para migración LDAP (files sssd) en node02."
      PUNTOS=$((PUNTOS + 25))
  else
      echo "❌ [0%] Configuración de NSSwitch incorrecta. El orden secuencial debe ser exclusivamente 'files sssd'."
  fi

  # 4. Validar existencia de evidencias replicadas en la Bóveda (node03)
  echo "⏳ Auditando repositorio de custodia de evidencias en node03..."
  if ssh $SSH_OPTS ${USER_NET}@${NODE_VAULT} "[ -f $VAULT_DIR/sudoers_devs.evidence ] && [ -f $VAULT_DIR/pam_su.evidence ] && [ -f $VAULT_DIR/nsswitch.evidence ]" 2>/dev/null; then
      echo "✔ [20%] Custodia de Evidencias: Las tres pruebas de mitigación fueron centralizadas con éxito en node03."
      PUNTOS=$((PUNTOS + 20))
  else
      echo "❌ [0%] Incumplimiento de políticas forenses: Faltan archivos de evidencia mitigatoria en node03:$VAULT_DIR/."
  fi

  # Resultado global de la Calificación
  echo -e "\n========================================"
  if [ $PUNTOS -eq 100 ]; then
      echo -e "🎉 CALIFICACIÓN FINAL: \e[1;32m$PUNTOS / 100\e[0m"
      echo -e "Control de Accesos y Privilegios mitigados con éxito en la topología distribuida."
  else
      echo -e "❌ CALIFICACIÓN FINAL: \e[1;31m$PUNTOS / 100\e[0m"
      echo -e "Revise las configuraciones locales de node02 o los envíos de flujos hacia node03."
  fi
  echo "========================================"
  EOF

  chmod +x /tmp/validador.sh
  bash /tmp/validador.sh
---

[[Laboratorios del LFCS]]
---
