---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Playground: PG-006
Titulo: Control de versiones de infraestructura y gestión de ramas locales con Git - V2
Fecha de Inicio: 2026-06-14
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
Script: |-
  cat << 'EOF' > /tmp/setup.sh

  #!/bin/bash
  set -e

  # ── Parámetros del Clúster ──────────────────────────────────────────────────
  USER_NET="bob"
  PASS="caleston123"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"
  SSH="sshpass -p $PASS ssh $SSH_OPTS"

  echo -e "\e[1;33m⏳ [node01 → node02] Inicializando repositorio Git con estado divergente...\e[0m"

  # ── 1. Construir el escenario Git roto en node02 ────────────────────────────
  $SSH -t ${USER_NET}@${NODE_TARGET} "sudo bash -c '

      # Limpieza de ejecuciones previas
      rm -rf /opt/scripts_core

      # Crear directorio y repositorio
      mkdir -p /opt/scripts_core
      cd /opt/scripts_core

      git init -b master
      git config user.name \"Sysadmin Pleno\"
      git config user.email \"admin@corp.internal\"

      # Archivos iniciales (V1 ya completada)
      echo -e \"#!/bin/bash\necho Checking system health\" > monitor.sh
      echo -e \"#!/bin/bash\necho Cleaning temp files\" > cleanup.sh
      chmod +x *.sh

      git add monitor.sh cleanup.sh
      git commit -m \"Initial commit con script de monitoreo\"

      # Rama de características lista para el estudiante
      git branch feature-patch

      # Permisos para que bob pueda trabajar
      chown -R bob:bob /opt/scripts_core
  '"

  echo -e "\e[1;33m⏳ [node01 → node03] Preparando bóveda de custodia de releases...\e[0m"

  # ── 2. Preparar bóveda en node03 ─────────────────────────────────────────────
  $SSH -t ${USER_NET}@${NODE_VAULT} "sudo bash -c '
      rm -rf /opt/git-compliance/*
      mkdir -p /opt/git-compliance/
      chown -R bob:bob /opt/git-compliance/
  '"

  clear

  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  TICKET INC-9006  │  Severidad: CRÍTICA  │  Urgente  │  Nivel: L2/L3\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m  🌿 PG-006-MN — Control de Versiones de Infraestructura con Git\e[0m"
  echo -e "\e[1;36m  Módulo: Essential Commands  │  Dificultad: 7/10  │  Nivel: L2/L3\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mUbicación de Control:\e[0m  node01 (Estación del Administrador — \e[1;32mbob\e[0m)"
  echo -e " \e[1mNodo a Intervenir:\e[0m     node02 (Servidor con Repositorio Git — \e[1;35m/opt/scripts_core\e[0m)"
  echo -e " \e[1mNodo Bóveda Destino:\e[0m   node03 (Repositorio de Releases — \e[1;35m/opt/git-compliance/\e[0m)"
  echo -e " \e[1mContraseña del Clúster:\e[0m \e[1;32mcaleston123\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e ""
  echo -e " \e[1mContexto del Incidente:\e[0m"
  echo -e "  El equipo de \e[1mDevOps\e[0m reportó una ruptura en la consistencia del repositorio"
  echo -e "  local ubicado en \e[1mnode02:/opt/scripts_core\e[0m. El equipo de \e[1mSRE\e[0m intervino"
  echo -e "  de urgencia \e[1mmonitor.sh\e[0m sobre la rama principal, mientras el ingeniero"
  echo -e "  avanzaba un parche sobre la rama \e[1mfeature-patch\e[0m. Al intentar unificar"
  echo -e "  ambas líneas, el merge falló por líneas desalineadas en el mismo archivo."
  echo -e "  Usted debe resolver el conflicto de forma remota desde \e[1mnode01\e[0m."
  echo -e ""
  echo -e " \e[1mParámetros Técnicos Obligatorios (SSH desde node01 hacia node02):\e[0m"
  echo -e ""
  echo -e "  \e[1;31m1. Verificar Identidad del Repositorio (Remoto en node02)\e[0m"
  echo -e "     Confirme que el repositorio tiene configurados:"
  echo -e "     - user.name = 'Sysadmin Pleno'"
  echo -e "     - user.email = 'admin@corp.internal'"
  echo -e ""
  echo -e "  \e[1;31m2. Aislar Trabajo Incompleto con Git Stash (Remoto en node02)\e[0m"
  echo -e "     Desde la rama \e[1mfeature-patch\e[0m, agregue la línea \e[1mDEBUG=true\e[0m al final"
  echo -e "     de \e[1mcleanup.sh\e[0m. Antes de hacer commit, preserve ese trabajo con"
  echo -e "     \e[1mgit stash\e[0m. Verifique con 'git stash list'."
  echo -e ""
  echo -e "  \e[1;31m3. Crear Commits Divergentes (Remoto en node02)\e[0m"
  echo -e "     En rama \e[1mmaster\e[0m: edite la línea 2 de monitor.sh con el texto:"
  echo -e "     \e[1mecho 'Hotfix SRE: health check v2'\e[0m — haga commit."
  echo -e "     En rama \e[1mfeature-patch\e[0m: recupere el stash, edite esa misma línea con:"
  echo -e "     \e[1mecho 'Feature: extended health metrics'\e[0m — haga commit."
  echo -e ""
  echo -e "  \e[1;31m4. Resolver el Conflicto de Merge (Remoto en node02)\e[0m"
  echo -e "     Desde \e[1mmaster\e[0m ejecute el merge contra \e[1mfeature-patch\e[0m. Git se detendrá"
  echo -e "     por conflicto. Resuelva manualmente conservando \e[1múnicamente\e[0m la línea"
  echo -e "     de feature-patch. Finalice el merge con el mensaje exacto:"
  echo -e "     \e[1m'Resolución de conflicto en monitor.sh'\e[0m"
  echo -e ""
  echo -e "  \e[1;31m5. Crear Tag Anotado de Release (Remoto en node02)\e[0m"
  echo -e "     Genere el tag \e[1mv2.0.0\e[0m sobre el último commit de master con el mensaje:"
  echo -e "     \e[1m'Release v2.0.0 — infraestructura estabilizada'\e[0m"
  echo -e ""
  echo -e "  \e[1;31m6. Centralización de Evidencias (node02 → node03)\e[0m"
  echo -e "     Exporte el log del repositorio y los archivos finales desde node02"
  echo -e "     hacia la bóveda en node03. Nómbrelos como:"
  echo -e "     - 'git_log.evidence'     (salida de: git log --oneline)"
  echo -e "     - 'monitor.evidence'     (contenido final de monitor.sh)"
  echo -e "     - 'tag_release.evidence' (salida de: git tag -v v2.0.0)"
  echo -e ""
  echo -e " \e[1mRequerimientos de Validación Remota:\e[0m"
  echo -e "  [ ] Identidad Git configurada correctamente en node02          --> \e[1;35m15%\e[0m"
  echo -e "  [ ] Stash contiene cambio de cleanup.sh (DEBUG=true)           --> \e[1;35m15%\e[0m"
  echo -e "  [ ] Commits divergentes presentes en ambas ramas               --> \e[1;35m20%\e[0m"
  echo -e "  [ ] Merge completado conservando línea de feature-patch        --> \e[1;35m25%\e[0m"
  echo -e "  [ ] Tag anotado v2.0.0 creado con mensaje correcto             --> \e[1;35m25%\e[0m  (bonus)"
  echo -e "  [ ] Las 3 evidencias centralizadas en node03:/opt/git-compliance/ -> \e[1;35m20%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32m🚨 REGLA DE ORO:\e[0m Trabaje siempre dentro de /opt/scripts_core en node02."
  echo -e "               Diagnóstico: ssh bob@node02 'cd /opt/scripts_core && git log --oneline --all --graph'"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup.sh && rm -f /tmp/setup.sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  cat > /tmp/validador.sh << 'EOF'
  #!/bin/bash
  PUNTOS=0

  NODE_TARGET="node02"
  NODE_VAULT="node03"
  USER_NET="bob"
  PASS="caleston123"
  REPO="/opt/scripts_core"
  VAULT_DIR="/opt/git-compliance"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=4"
  SSH="sshpass -p $PASS ssh $SSH_OPTS"

  echo -e "\n\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m  🕵️  AUDITORÍA GIT — INC-9006 (Control de Versiones / PG-006-MN)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"

  # ── 1. Identidad Git configurada ──────────────────────────────────────────────
  echo -e "\n\e[1;37m⏳ [1/6] Verificando identidad del operador en node02...\e[0m"

  GIT_NAME=$($SSH ${USER_NET}@${NODE_TARGET} \
      "git -C $REPO config user.name 2>/dev/null" || true)
  GIT_EMAIL=$($SSH ${USER_NET}@${NODE_TARGET} \
      "git -C $REPO config user.email 2>/dev/null" || true)

  if [ "$GIT_NAME" = "Sysadmin Pleno" ] && [ "$GIT_EMAIL" = "admin@corp.internal" ]; then
      echo -e "\e[1;32m  ✔ [15%] Identidad configurada: $GIT_NAME <$GIT_EMAIL>\e[0m"
      PUNTOS=$((PUNTOS + 15))
  else
      echo -e "\e[1;31m  ❌ [0%] Identidad incorrecta o no configurada en el repositorio.\e[0m"
      echo -e "       → user.name:  \e[1;31m'$GIT_NAME'\e[0m  (se espera: 'Sysadmin Pleno')"
      echo -e "       → user.email: \e[1;31m'$GIT_EMAIL'\e[0m  (se espera: 'admin@corp.internal')"
  fi

  # ── 2. Stash contiene DEBUG=true de cleanup.sh ───────────────────────────────
  echo -e "\n\e[1;37m⏳ [2/6] Verificando stash con cambio de cleanup.sh en node02...\e[0m"

  STASH_CHECK=$($SSH ${USER_NET}@${NODE_TARGET} \
      "git -C $REPO stash list 2>/dev/null | head -1" || true)
  STASH_CONTENT=$($SSH ${USER_NET}@${NODE_TARGET} \
      "git -C $REPO stash show -p 2>/dev/null | grep 'DEBUG=true'" || true)

  if [ -n "$STASH_CHECK" ] && [ -n "$STASH_CONTENT" ]; then
      echo -e "\e[1;32m  ✔ [15%] Stash presente con línea DEBUG=true aislada de cleanup.sh.\e[0m"
      PUNTOS=$((PUNTOS + 15))
  else
      echo -e "\e[1;31m  ❌ [0%] No se encontró stash con el cambio esperado en cleanup.sh.\e[0m"
      [ -z "$STASH_CHECK" ]   && echo -e "       → git stash list está vacío"
      [ -z "$STASH_CONTENT" ] && echo -e "       → El stash no contiene 'DEBUG=true'"
  fi

  # ── 3. Commits divergentes en ambas ramas ────────────────────────────────────
  echo -e "\n\e[1;37m⏳ [3/6] Verificando commits divergentes en master y feature-patch...\e[0m"

  MASTER_COMMIT=$($SSH ${USER_NET}@${NODE_TARGET} \
      "git -C $REPO log master --oneline 2>/dev/null | grep -i 'hotfix\|health check v2\|sre'" || true)
  FEATURE_COMMIT=$($SSH ${USER_NET}@${NODE_TARGET} \
      "git -C $REPO log feature-patch --oneline 2>/dev/null | grep -i 'feature\|extended\|metrics'" || true)

  if [ -n "$MASTER_COMMIT" ] && [ -n "$FEATURE_COMMIT" ]; then
      echo -e "\e[1;32m  ✔ [20%] Commits divergentes confirmados en ambas ramas.\e[0m"
      echo -e "         → master:        \e[1;37m$MASTER_COMMIT\e[0m"
      echo -e "         → feature-patch: \e[1;37m$FEATURE_COMMIT\e[0m"
      PUNTOS=$((PUNTOS + 20))
  else
      echo -e "\e[1;31m  ❌ [0%] No se detectaron commits divergentes en una o ambas ramas.\e[0m"
      [ -z "$MASTER_COMMIT"  ] && echo -e "       → master no tiene commit del hotfix SRE"
      [ -z "$FEATURE_COMMIT" ] && echo -e "       → feature-patch no tiene commit de extended metrics"
  fi

  # ── 4. Merge completado conservando línea de feature-patch ───────────────────
  echo -e "\n\e[1;37m⏳ [4/6] Verificando resolución del merge en master...\e[0m"

  MERGE_MSG=$($SSH ${USER_NET}@${NODE_TARGET} \
      "git -C $REPO log master --oneline 2>/dev/null | grep -i 'resolución\|resolucion\|conflicto'" || true)
  MONITOR_CONTENT=$($SSH ${USER_NET}@${NODE_TARGET} \
      "cat $REPO/monitor.sh 2>/dev/null | grep -i 'extended\|metrics'" || true)
  CONFLICT_MARKERS=$($SSH ${USER_NET}@${NODE_TARGET} \
      "grep -c '<<<<<<\|>>>>>>\|=======' $REPO/monitor.sh 2>/dev/null || echo 0" || true)

  if [ -n "$MERGE_MSG" ] && [ -n "$MONITOR_CONTENT" ] && [ "${CONFLICT_MARKERS:-0}" = "0" ]; then
      echo -e "\e[1;32m  ✔ [25%] Merge resuelto correctamente con línea de feature-patch conservada.\e[0m"
      echo -e "         → Commit de merge: \e[1;37m$MERGE_MSG\e[0m"
      PUNTOS=$((PUNTOS + 25))
  else
      echo -e "\e[1;31m  ❌ [0%] El merge no fue resuelto correctamente.\e[0m"
      [ -z "$MERGE_MSG" ]      && echo -e "       → No se encontró commit con mensaje 'Resolución de conflicto en monitor.sh'"
      [ -z "$MONITOR_CONTENT" ] && echo -e "       → monitor.sh no contiene la línea de feature-patch"
      [ "${CONFLICT_MARKERS:-0}" != "0" ] && echo -e "       → monitor.sh aún tiene marcadores de conflicto (<<<<< / >>>>>)"
  fi

  # ── 5. Tag anotado v2.0.0 creado correctamente ───────────────────────────────
  echo -e "\n\e[1;37m⏳ [5/6] Verificando tag anotado v2.0.0 en node02...\e[0m"

  TAG_EXISTS=$($SSH ${USER_NET}@${NODE_TARGET} \
      "git -C $REPO tag -l v2.0.0 2>/dev/null" || true)
  TAG_TYPE=$($SSH ${USER_NET}@${NODE_TARGET} \
      "git -C $REPO cat-file -t v2.0.0 2>/dev/null" || true)
  TAG_MSG=$($SSH ${USER_NET}@${NODE_TARGET} \
      "git -C $REPO tag -v v2.0.0 2>/dev/null | grep -i 'release\|infraestructura\|estabilizada'" || true)

  if [ "$TAG_EXISTS" = "v2.0.0" ] && [ "$TAG_TYPE" = "tag" ] && [ -n "$TAG_MSG" ]; then
      echo -e "\e[1;32m  ✔ [25%] Tag anotado v2.0.0 creado con mensaje de release correcto.\e[0m"
      PUNTOS=$((PUNTOS + 25))
      [ $PUNTOS -gt 100 ] && PUNTOS=100
  else
      echo -e "\e[1;31m  ❌ [0%] Tag v2.0.0 ausente, no es anotado o tiene mensaje incorrecto.\e[0m"
      [ -z "$TAG_EXISTS" ]      && echo -e "       → Tag v2.0.0 no existe — cree con: git tag -a v2.0.0 -m '...'"
      [ "$TAG_TYPE" != "tag" ]  && echo -e "       → El tag existe pero no es anotado (tipo: $TAG_TYPE)"
      [ -z "$TAG_MSG" ]         && echo -e "       → Mensaje del tag no contiene 'Release v2.0.0 — infraestructura estabilizada'"
  fi

  # ── 6. Evidencias centralizadas en node03 ─────────────────────────────────────
  echo -e "\n\e[1;37m⏳ [6/6] Auditando custodia de evidencias en node03:$VAULT_DIR...\e[0m"

  EVIDENCE_CHECK=$($SSH ${USER_NET}@${NODE_VAULT} \
      "[ -f $VAULT_DIR/git_log.evidence ] && \
       [ -f $VAULT_DIR/monitor.evidence ] && \
       [ -f $VAULT_DIR/tag_release.evidence ] && echo ok" 2>/dev/null || true)

  if [ "$EVIDENCE_CHECK" = "ok" ]; then
      echo -e "\e[1;32m  ✔ [20%] Las 3 evidencias centralizadas correctamente en node03.\e[0m"
      PUNTOS=$((PUNTOS + 20))
      [ $PUNTOS -gt 100 ] && PUNTOS=100
  else
      echo -e "\e[1;31m  ❌ [0%] Faltan archivos de evidencia en node03:$VAULT_DIR/\e[0m"
      echo -e "       → Se esperan: git_log.evidence | monitor.evidence | tag_release.evidence"
  fi

  # ── Resultado Final ────────────────────────────────────────────────────────────
  echo -e "\n\e[1;36m================================================================================\e[0m"
  if [ $PUNTOS -ge 100 ]; then
      echo -e "  🎉 CALIFICACIÓN FINAL: \e[1;32m$PUNTOS / 100\e[0m — Repositorio estabilizado y release certificado."
  elif [ $PUNTOS -ge 55 ]; then
      echo -e "  ⚠️  CALIFICACIÓN FINAL: \e[1;33m$PUNTOS / 100\e[0m — Parcialmente resuelto. Revise los ❌."
  else
      echo -e "  ❌ CALIFICACIÓN FINAL: \e[1;31m$PUNTOS / 100\e[0m — Revise el flujo completo en node02."
  fi
  echo -e "\e[1;36m================================================================================\e[0m"
  echo ""
  EOF

  chmod +x /tmp/validador.sh
  bash /tmp/validador.sh
---
[[Laboratorios del LFCS]]
