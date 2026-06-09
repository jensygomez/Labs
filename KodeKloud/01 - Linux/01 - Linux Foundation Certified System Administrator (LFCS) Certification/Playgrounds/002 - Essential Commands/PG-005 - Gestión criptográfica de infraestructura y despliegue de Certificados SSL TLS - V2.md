---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Playground: PG-005
Titulo: Gestión criptográfica de infraestructura y despliegue de Certificados SSL/TLS - V2
Fecha de Inicio: 2026-06-06
Dificultad: 7/10
Objetivo:
  - Aprobar LFCS
  - Pensar como Sysadmin Linux Pleno
Temas:
  - Work With SSL Certificates (OpenSSL suite)
Competencias:
  - Generar llaves privadas asimétricas seguras mediante la CLI
  - Construir solicitudes de firma de certificados (CSR) con metadatos específicos del negocio
  - Autenticar y emitir certificados digitales X.509 válidos con tiempos de vida controlados
  - Auditar metadatos de certificados en producción directo desde la consola
Validacion:
  - Objetivo: Llave privada server.key generada con el tamaño y algoritmo correcto.
    Peso: 20 %
  - Objetivo: Archivo server.csr estructurado con los metadatos de la empresa (CN, O, C).
    Peso: 30 %
  - Objetivo: Certificado server.crt emitido bajo el estándar X.509 y válido por 365 días.
    Peso: 30 %
  - Objetivo: Reporte de expiración analítico guardado de forma exacta en /root/cert_expiration.txt.
    Peso: 20 %
Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup_sh

  #!/bin/bash
  set -e

  # Variables de Red del Clúster
  USER_NET="bob"
  NODE_TARGET="node02"
  NODE_VAULT="node03"
  SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=5"

  echo -e "\e[1;33m⏳ Orquestando entorno multi-nodo de forma remota desde node01...\e[0m"

  # 1. Limpieza preventiva en el nodo afectado (node02) mediante SSH
  ssh $SSH_OPTS ${USER_NET}@${NODE_TARGET} "sudo rm -rf /etc/pki/tls/corp_app/ && sudo rm -f /root/cert_expiration.txt" >/dev/null 2>&1 || true

  # 2. Limpieza preventiva en la bóveda de evidencias (node03) mediante SSH
  ssh $SSH_OPTS ${USER_NET}@${NODE_VAULT} "sudo rm -f /root/cert_expiration.txt" >/dev/null 2>&1 || true

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m 🔐 ESCENARIO CONFIGURADO - CENTRAL DE LOGÍSTICA & AUDITORÍA (PG-005-MN)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-3005 (ENTORNO MULTI-NODO DISTRIBUIDO)\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mUbicación Actual:\e[0m node01 (Estación de Administración — \e[1;35minvestigator\e[0m)"
  echo -e " \e[1mObjetivo de Configuración:\e[0m Servidor Interno Isolated (\e[1;35mnode02\e[0m)"
  echo -e " \e[1mObjetivo de Custodia:\e[0m Bóveda de Seguridad Segura (\e[1;35mnode03\e[0m)"
  echo -e " ------------------------------------------------------------------------------"
  echo -e ""
  echo -e " \e[1mContexto del Incidente:\e[0m"
  echo -e "  El equipo de Seguridad de la Información tiene una ventana de pruebas"
  echo -e "  activa en \e[1mnode02\e[0m y necesita HTTPS habilitado de forma inmediata."
  echo -e "  No es un requerimiento permanente, pero el entorno no puede operar"
  echo -e "  sobre HTTP plano mientras las políticas de auditoría estén vigentes."
  echo -e ""
  echo -e "  El requerimiento exige que todo el material criptográfico debe"
  echo -e "  generarse localmente dentro del directorio \e[1m'/etc/pki/tls/corp_app/'\e[0m"
  echo -e "  en \e[1mnode02\e[0m. No se aceptan certificados externos."
  echo -e ""
  echo -e "  Adicionalmente, el servicio web debe poder iniciar de forma"
  echo -e "  automática (llave privada sin cifrado por contraseña)."
  echo -e ""
  echo -e " \e[1mParámetros Técnicos Operacionales (A ejecutar desde tu consola en node01):\e[0m"
  echo -e ""
  echo -e "  \e[1;31m1.\e[0m Cree de forma remota en \e[1mnode02\e[0m el directorio '/etc/pki/tls/corp_app/'."
  echo -e "  \e[1;31m2.\e[0m Genere en \e[1mnode02\e[0m una llave privada RSA de 2048 bits llamada 'server.key'."
  echo -e "  \e[1;31m3.\e[0m Genere en \e[1mnode02\e[0m el CSR 'server.csr' con los metadatos exactos obligatorios:"
  echo -e "       \e[1;33m  C=BR  |  O=Enterprise Group  |  CN=test-app.corp.internal\e[0m"
  echo -e "  \e[1;31m4.\e[0m Emita en \e[1mnode02\e[0m el certificado digital autofirmado 'server.crt' (X.509, 365 días)."
  echo -e "  \e[1;31m5.\e[0m Extraiga la línea de expiración de \e[1mnode02\e[0m y envíela de forma directa"
  echo -e "       al archivo \e[1m/root/cert_expiration.txt\e[0m en \e[1mnode03\e[0m usando pipes o SCP/RSYNC."
  echo ""
  echo -e " \e[1mRequerimientos de Validación Remota:\e[0m"
  echo -e "  [ ] Llave RSA 2048 bits en node02:/etc/pki/tls/corp_app/server.key  --> \e[1;35m20%\e[0m"
  echo -e "  [ ] CSR estructurado con metadatos de la empresa en node02         --> \e[1;35m25%\e[0m"
  echo -e "  [ ] Certificado X.509 server.crt activo por 365 días en node02      --> \e[1;35m25%\e[0m"
  echo -e "  [ ] Reporte de expiración aislado de forma exacta en node03         --> \e[1;35m30%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32mCredenciales de Red del Cluster:\e[0m Usuario: \e[1mbob\e[0m | Contraseña: \e[1mcaleston123\e[0m"
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

  echo -e "\n=== 🕵️ EVALUANDO INFRAESTRUCTURA DESDE NODE01 (CONTROL CENTRAL) ==="

  # Definición de objetivos remotos
  TARGET_NODE="node02"    # El nodo afectado donde se debió generar el material SSL
  VAULT_NODE="node03"     # La bóveda donde se debió resguardar el reporte
  USER="bob"

  # Rutas de los archivos a evaluar en los nodos remotos
  KEY_REMOTE="/etc/pki/tls/corp_app/server.key"
  CSR_REMOTE="/etc/pki/tls/corp_app/server.csr"
  CRT_REMOTE="/etc/pki/tls/corp_app/server.crt"
  VAULT_FILE="/root/cert_expiration.txt"

  echo "⏳ Conectando a $TARGET_NODE para auditar el material criptográfico..."

  # ------------------------------------------------------------------------------
  # 1. Validar la Llave Privada en node02 (remoto)
  # ------------------------------------------------------------------------------
  if ssh -o StrictHostKeyChecking=no ${USER}@${TARGET_NODE} "[ -f $KEY_REMOTE ]" 2>/dev/null; then
      # Extraemos el tamaño de la llave remotamente para verificarlo en node01
      KEY_SIZE=$(ssh ${USER}@${TARGET_NODE} "openssl rsa -in $KEY_REMOTE -text -noout 2>/dev/null" | grep -E "Private-Key:" | awk '{print $2}' | tr -d '()')
      
      if [ "$KEY_SIZE" = "2048" ]; then
          echo "✔ [20%] Llave privada server.key verificada en $TARGET_NODE (RSA 2048 bits)."
          PUNTOS=$((PUNTOS + 20))
      else
          echo "❌ [0%] La llave existe en $TARGET_NODE pero es de $KEY_SIZE bits (se esperaba 2048)."
      fi
  else
      echo "❌ [0%] No se encuentra la llave privada en la ruta requerida de $TARGET_NODE."
  fi

  # ------------------------------------------------------------------------------
  # 2. Validar el CSR en node02 (remoto)
  # ------------------------------------------------------------------------------
  if ssh ${USER}@${TARGET_NODE} "[ -f $CSR_REMOTE ]" 2>/dev/null; then
      CSR_SUBJECT=$(ssh ${USER}@${TARGET_NODE} "openssl req -in $CSR_REMOTE -noout -subject" 2>/dev/null)
      
      if echo "$CSR_SUBJECT" | grep -q "CN=test-app.corp.internal" && \
         echo "$CSR_SUBJECT" | grep -q "O=Enterprise Group" && \
         echo "$CSR_SUBJECT" | grep -q "C=BR"; then
          echo "✔ [25%] Solicitud de Certificado (CSR) validada en $TARGET_NODE con metadatos correctos."
          PUNTOS=$((PUNTOS + 25))
      else
          echo "❌ [0%] El CSR en $TARGET_NODE contiene metadatos incorrectos o incompletos."
      fi
  else
      echo "❌ [0%] No se encuentra el archivo CSR en $TARGET_NODE."
  fi

  # ------------------------------------------------------------------------------
  # 3. Validar el Certificado Autofirmado en node02 (remoto)
  # ------------------------------------------------------------------------------
  if ssh ${USER}@${TARGET_NODE} "[ -f $CRT_REMOTE ]" 2>/dev/null; then
      CRT_CN=$(ssh ${USER}@${TARGET_NODE} "openssl x509 -in $CRT_REMOTE -noout -subject -nameopt RFC2253" 2>/dev/null | sed -n 's/.*CN=\([^,]*\).*/\1/p')
      
      if [ "$CRT_CN" = "test-app.corp.internal" ]; then
          echo "✔ [25%] Certificado digital X.509 verificado con éxito en $TARGET_NODE."
          PUNTOS=$((PUNTOS + 25))
      else
          echo "❌ [10%] El certificado en $TARGET_NODE existe pero el CN '$CRT_CN' es incorrecto."
          PUNTOS=$((PUNTOS + 10))
      fi
  else
      echo "❌ [0%] Falta generar el certificado final server.crt en $TARGET_NODE."
  fi

  # ------------------------------------------------------------------------------
  # 4. Validar Transferencia a la Bóveda en node03 (remoto)
  # ------------------------------------------------------------------------------
  echo "⏳ Conectando a $VAULT_NODE (Bóveda) para verificar el reporte final..."
  VAULT_CHECK=$(ssh -o StrictHostKeyChecking=no ${USER}@${VAULT_NODE} "cat $VAULT_FILE 2>/dev/null" || true)

  if [ -n "$VAULT_CHECK" ]; then
      if echo "$VAULT_CHECK" | grep -q "notAfter=Mock" || echo "$VAULT_CHECK" | grep -q "notAfter="; then
          echo "✔ [30%] Custodia de Evidencias: Reporte localizado de forma exacta en $VAULT_NODE:$VAULT_FILE."
          PUNTOS=$((PUNTOS + 30))
      else
          echo "❌ [0%] El archivo existe en $VAULT_NODE, pero el formato de la fecha de expiración es incorrecto."
      fi
  else
      echo "❌ [0%] Error de transferencia: El reporte analítico no fue encontrado en $VAULT_NODE."
  fi

  # ------------------------------------------------------------------------------
  # Calificación Final
  # ------------------------------------------------------------------------------
  echo -e "\n========================================"
  if [ $PUNTOS -eq 100 ]; then
      echo -e "🎉 CALIFICACIÓN FINAL: \e[1;32m$PUNTOS / 100\e[0m"
      echo -e "Estrategia multi-nodo ejecutada a la perfección desde node01."
  else
      echo -e "❌ CALIFICACIÓN FINAL: \e[1;31m$PUNTOS / 100\e[0m"
      echo -e "Verifique la ejecución remota de OpenSSL o la transferencia de archivos."
  fi
  echo "========================================"
  EOF

  chmod +x /tmp/validador.sh
  bash /tmp/validador.sh
---

[[Laboratorios del LFCS]]
---
