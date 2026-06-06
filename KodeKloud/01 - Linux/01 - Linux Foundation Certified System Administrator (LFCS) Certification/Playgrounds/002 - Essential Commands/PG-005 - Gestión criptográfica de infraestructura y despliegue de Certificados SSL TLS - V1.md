---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Playground: PG-005
Titulo: Gestión criptográfica de infraestructura y despliegue de Certificados SSL/TLS - V1
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
Ticket: |-
  INC-3005

  El equipo de seguridad de la información solicita habilitar HTTPS de forma temporal para un servidor de pruebas interno. Debido a políticas de auditoría, se exige generar el material criptográfico localmente en el directorio '/etc/pki/tls/corp_app/'.

  Deberá cumplir estrictamente con los siguientes parámetros técnicos:
  1. Crear el directorio '/etc/pki/tls/corp_app/' para almacenar el material.
  2. Generar una llave privada RSA de 2048 bits llamada 'server.key'. No debe utilizar cifrado por contraseña para permitir el inicio automático del servicio web.
  3. Crear una solicitud de firma de certificado (CSR) llamada 'server.csr' basada en esa llave, utilizando exactamente los siguientes metadatos:
     - Country Name (C): BR
     - Organization (O): Enterprise Group
     - Common Name (CN): test-app.corp.internal
  4. Emitir un certificado digital autofirmado (X.509) llamado 'server.crt' válido por 365 días a partir de la llave y el CSR generados.
  5. Use comandos de verificación de OpenSSL para extraer la fecha de expiración del certificado generado y guarde de forma exclusiva esa línea de información en el archivo '/root/cert_expiration.txt'.
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

  # Limpieza absoluta de laboratorios criptográficos previos
  rm -rf /etc/pki/tls/corp_app
  rm -f /root/cert_expiration.txt

  clear
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;32m 🚀 ESCENARIO CONFIGURADO - ESSENTIAL COMMANDS (PG-005)\e[0m"
  echo -e "\e[1;36m================================================================================\e[0m"
  echo -e "\e[1;33m TICKET DE INCIDENTE: INC-3005\e[0m"
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1mAsunto:\e[0m Gestión criptográfica y despliegue de Certificados SSL/TLS"
  echo -e " \e[1mSeveridad:\e[0m Alta / Infraestructura de Seguridad"
  echo -e ""
  echo -e " \e[1mDescripción:\e[0m"
  echo -e " Genere la estructura de claves y certificados TLS requerida para el entorno"
  echo -e " interno de pruebas. Asegure la coincidencia exacta de los metadatos corporativos"
  echo -e " y extraiga el reporte de validez temporal exigido por auditoría."
  echo -e ""
  echo -e " \e[1mRequerimientos de Validación (Peso Total: 100%):\e[0m"
  echo -e "  [ ] Llave RSA 2048 bits en /etc/pki/tls/corp_app/server.key    --> \e[1;35m20%\e[0m"
  echo -e "  [ ] CSR generado con CN=test-app.corp.internal, O=Enterprise Group, C=BR --> \e[1;35m30%\e[0m"
  echo -e "  [ ] Certificado X.509 server.crt válido por 365 días            --> \e[1;35m30%\e[0m"
  echo -e "  [ ] Reporte de fin de validez en /root/cert_expiration.txt       --> \e[1;35m20%\e[0m"
  echo -e " ------------------------------------------------------------------------------"
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

  echo "=== EVALUANDO INFRAESTRUCTURA DE LLAVES PÚBLICAS Y CERTIFICADOS ==="

  KEY="/etc/pki/tls/corp_app/server.key"
  CSR="/etc/pki/tls/corp_app/server.csr"
  CRT="/etc/pki/tls/corp_app/server.crt"
  EXP_TXT="/root/cert_expiration.txt"

  # 1. Validar la Llave Privada
  if [ -f "$KEY" ]; then
      if openssl rsa -in "$KEY" -check -noout >/dev/null 2>&1; then
          KEY_SIZE=$(openssl rsa -in "$KEY" -text -noout 2>/dev/null | grep -E "Private-Key:" | awk '{print $2}' | tr -d '()')
          if [ "$KEY_SIZE" = "2048" ]; then
              echo "✔ [20%] Llave privada server.key verificada (Algoritmo RSA, tamaño 2048 bits)."
              PUNTOS=$((PUNTOS + 20))
          else
              echo "❌ [0%] La llave existe pero su tamaño es de $KEY_SIZE bits (se esperaba 2048)."
          fi
      else
          echo "❌ [0%] El archivo en $KEY no es una llave privada RSA válida."
      fi
  else
      echo "❌ [0%] No se encuentra la llave privada en la ruta requerida."
  fi

  # 2. Validar el CSR y sus metadatos obligatorios
  if [ -f "$CSR" ]; then
      CSR_CN=$(openssl req -in "$CSR" -noout -subject | grep -o "CN=.*" | cut -d= -f2 | tr -d ' ')
      CSR_O=$(openssl req -in "$CSR" -noout -subject | grep -o "O=.*" | cut -d= -f2 | cut -d',' -f1 | xargs)
      CSR_C=$(openssl req -in "$CSR" -noout -subject | grep -o "C=.*" | cut -d= -f2 | cut -d',' -f1 | xargs)

      if [ "$CSR_CN" = "test-app.corp.internal" ] && \
         [ "$CSR_O" = "Enterprise Group" ] && \
         [ "$CSR_C" = "BR" ]; then
          echo "✔ [30%] Solicitud de Certificado (CSR) validada con los metadatos corporativos requeridos."
          PUNTOS=$((PUNTOS + 30))
      else
          echo "❌ [0%] El CSR existe pero contiene metadatos incorrectos o incompletos."
          echo "    CN=$CSR_CN | O=$CSR_O | C=$CSR_C"
      fi
  else
      echo "❌ [0%] No se encuentra el archivo de solicitud $CSR."
  fi

  # 3. Validar el Certificado Autofirmado
  if [ -f "$CRT" ]; then
      if openssl x509 -in "$CRT" -text -noout >/dev/null 2>&1; then
          CRT_CN=$(openssl x509 -in "$CRT" -noout -subject -nameopt RFC2253 \
                   | sed -n 's/.*CN=\([^,]*\).*/\1/p')

          if [ "$CRT_CN" = "test-app.corp.internal" ]; then
              echo "✔ [30%] Certificado digital X.509 corporativo verificado con éxito."
              PUNTOS=$((PUNTOS + 30))
          else
              echo "❌ [15%] El certificado es válido pero fue emitido para el CN '$CRT_CN' incorrecto."
              PUNTOS=$((PUNTOS + 15))
          fi
      else
          echo "❌ [0%] El archivo en $CRT no es un certificado estructurado X.509 válido."
      fi
  else
      echo "❌ [0%] Falta generar el certificado final server.crt."
  fi

  # 4. Validar el reporte de expiración analítico extraído
  if [ -f "$EXP_TXT" ]; then
      if grep -q "notAfter=" "$EXP_TXT"; then
          echo "✔ [20%] Reporte forense de expiración verificado en $EXP_TXT."
          PUNTOS=$((PUNTOS + 20))
      else
          echo "❌ [0%] El archivo de expiración existe pero no contiene el formato de fecha 'notAfter=' filtrado."
      fi
  else
      echo "❌ [0%] No se encuentra el reporte analítico en la ruta especificada."
  fi

  echo "============================"
  echo "CALIFICACIÓN FINAL: $PUNTOS / 100"
  echo "============================"
  EOF

  chmod +x /tmp/validador.sh
  bash /tmp/validador.sh
---

[[Laboratorios del LFCS]]
---
