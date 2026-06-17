---
Curso: Prep Course - LFCS Certification
Modulo: Essential Commands
Playground: PG-007
Titulo: Triage de Incidente Mayor y Restauración de Servicios Críticos (Examen Integrador)
Fecha de Inicio: 2026-06-04
Dificultad: 9/10
Objetivo:
  - Aprobar LFCS
  - Demostrar nivel Sysadmin Linux Pleno (Level 2/3) ante la gerencia
Temas:
  - All Essential Commands Subjects (Lessons 1-28)
Competencias:
  - Mitigación de incidentes complejos multi-componente bajo presión
  - Filtrado forense de texto avanzado y remediación criptográfica con OpenSSL
  - Control de consistencia en el sistema de archivos (Inodos) y versionamiento con Git
Ticket: |-
  INC-3007 (CRÍTICO) - COLAPSO DE INFRAESTRUCTURA EN NODO DE DESARROLLO

  Un script de despliegue malicioso o corrupto se ejecutó con privilegios elevados en el servidor y provocó los siguientes impactos masivos:
  1. El archivo de configuración '/etc/nginx/app_core.conf' quedó inundado de líneas basura y comentarios que corrompen el parseo del servicio. Además, el log '/var/log/bad_deploy.log' contiene líneas de compromiso que deben ser auditadas.
  2. El directorio colaborativo '/srv/shared_dev' perdió sus permisos especiales (SGID y Sticky Bit), bloqueando el trabajo del equipo. El binario de monitoreo '/usr/local/bin/syswatch' perdió su bit SUID.
  3. Los enlaces hacia el archivo maestro de la base de datos fueron eliminados de las rutas '/var/log/app_mirror.conf' y '/etc/app_link.conf'.
  4. Los certificados SSL del servidor web fueron borrados o corrompidos, impidiendo levantar el puerto 443 de forma segura.
  5. El repositorio de scripts locales en '/opt/scripts_core' fue desconfigurado por completo (.git eliminado).

  Misión: Ejecute un plan de contingencia estructurado. Limpie las configuraciones, devuelva los permisos especiales, regenere los enlaces basándose en los inodos correctos, re-emita el certificado TLS corporativo con OpenSSL y vuelva a poner los scripts bajo control de versiones con Git.
Validacion:
  - Objetivo: Configuración limpia generada en /etc/nginx/app_core.conf.clean y errores extraídos.
    Peso: 20 %
  - Objetivo: Permisos SUID, SGID y Sticky Bit restaurados con precisión quirúrgica.
    Peso: 25 %
  - Objetivo: Inodos y enlaces (Hard Link en /var/log y Soft Link en /etc) reconstruidos.
    Peso: 20 %
  - Objetivo: Par criptográfico (llave, CSR con CN=test-app.corp.internal y certificado X.509 de 365 días) funcional en /etc/pki/tls/corp_app/.
    Peso: 20 %
  - Objetivo: Repositorio Git recuperado con identidad corporativa y cambios fusionados desde 'feature-patch'.
    Peso: 15 %
Calificacion Final:
Script: |-
  cat << 'EOF' > /tmp/setup_sh
  #!/bin/bash
  set -e

  # Limpieza radical para garantizar consistencia absoluta en máquina limpia
  rm -rf /etc/nginx /var/log/bad_deploy.log /srv/shared_dev /usr/local/bin/syswatch /srv/production /var/log/app_mirror.conf /etc/app_link.conf /etc/pki/tls/corp_app /root/cert_expiration.txt /opt/scripts_core

  # 1. Simular caos de texto
  mkdir -p /etc/nginx
  cat << 'BADCONF' > /etc/nginx/app_core.conf
  # Nginx Core Config
  worker_processes auto;

  # ERROR_ZONE: Configuración alterada
  # listen 80;
  server_name localhost;

  # FIXME: Verificar rutas proxy
  location / {
      root /usr/share/nginx/html;
  }
  BADCONF

  cat << 'BADLOG' > /var/log/bad_deploy.log
  INFO: Started at 03:00
  CRITICAL: Malicious binary injection attempted from 10.10.50.4
  WARNING: High CPU load
  FATAL: Corrupting file system structures now
  INFO: Finished with errors
  BADLOG

  # 2. Simular caída de permisos especiales
  mkdir -p /srv/shared_dev
  groupadd -g 2500 devs 2>/dev/null || true
  chown root:devs /srv/shared_dev
  chmod 700 /srv/shared_dev # Totalmente cerrado y sin bits especiales

  mkdir -p /usr/local/bin
  echo '#!/bin/bash' > /usr/local/bin/syswatch
  chmod 600 /usr/local/bin/syswatch # Sin SUID

  # 3. Simular destrucción de enlaces
  mkdir -p /srv/production/app_v1
  echo "STAGE=PROD" > /srv/production/app_v1/master.conf

  # 4. Eliminar infraestructura SSL previa
  mkdir -p /etc/pki/tls/corp_app

  # 5. Destruir repositorio Git (Dejar solo el script guacho)
  mkdir -p /opt/scripts_core
  echo "echo 'Contingency version'" > /opt/scripts_core/monitor.sh

  clear
  echo -e "\e[1;31m================================================================================\e[0m"
  echo -e "\e[1;37;41m 🔥 ALERTA MÁXIMA: INICIANDO PG-007 - EXAMEN INTEGRADOR DEL MÓDULO 🔥 \e[0m"
  echo -e "\e[1;31m================================================================================\e[0m"
  echo -e " El servidor central se encuentra en un estado de degradación crítica de servicios."
  echo -e " Múltiples vectores (Seguridad, Almacenamiento, Red y Código) están caídos."
  echo -e ""
  echo -e " \e[1mProcedimiento de Respuesta Técnica Exigido:\e[0m"
  echo -e "  1. Genere /etc/nginx/app_core.conf.clean sin comentarios ni espacios, e aísle"
  echo -e "     los errores CRITICAL|FATAL de /var/log/bad_deploy.log en /root/incident_errors.log."
  echo -e "  2. Devuelva la herencia (SGID) y protección (Sticky) a /srv/shared_dev (permisos 3775),"
  echo -e "     y reactive el SUID en /usr/local/bin/syswatch."
  echo -e "  3. Reconstruya el Hard Link en /var/log/app_mirror.conf y el Soft Link en /etc/app_link.conf."
  echo -e "  4. Genere una nueva llave RSA de 2048, CSR y certificado X.509 de 365 días para test-app.corp.internal."
  echo -e "  5. Inicialice Git en /opt/scripts_core, configure la identidad corporativa,"
  echo -e "     haga el commit inicial, cree la rama 'feature-patch', añada 'cleanup.sh' y fusione."
  echo -e " ------------------------------------------------------------------------------"
  echo -e " \e[1;32mPiense como un Líder de Infraestructura Pleno. Devuelva el control al nodo.\e[0m"
  echo -e "\e[1;31m================================================================================\e[0m"
  echo ""
  EOF
  bash /tmp/setup_sh && rm -f /tmp/setup_sh
tags:
  - Laboratorios-del-LFCS
Script Validacion: |-
  #!/bin/bash
  PUNTOS=0

  echo "=== EVALUANDO TRAGE GLOBAL DEL SISTEMA (PG-007) ==="

  # 1. Validar Texto y Regex
  if [ -f /etc/nginx/app_core.conf.clean ] && [ -f /root/incident_errors.log ]; then
      if ! grep -q "^#" /etc/nginx/app_core.conf.clean && grep -q "CRITICAL" /root/incident_errors.log && grep -q "FATAL" /root/incident_errors.log; then
          echo "✔ [20%] Hito 1: Auditoría forense de texto y limpieza de Nginx validadas."
          PUNTOS=$((PUNTOS + 20))
      else
          echo "❌ [0%] Hito 1: Los archivos existen pero la limpieza de comentarios o filtrado de logs falló."
      fi
  else
      echo "❌ [0%] Hito 1: Falta generar /etc/nginx/app_core.conf.clean o /root/incident_errors.log."
  fi

  # 2. Validar Permisos Especiales
  OCTAL_DIR=$(stat -c '%a' /srv/shared_dev 2>/dev/null || echo "0")
  PERM_BIN=$(stat -c '%A' /usr/local/bin/syswatch 2>/dev/null || echo "0")
  if [[ "$OCTAL_DIR" == "3775" || "$OCTAL_DIR" == "2775" || "$OCTAL_DIR" == "1775" ]]; then
      # Verificar si están ambos (el bit 3 en el primer dígito octal de 4 cifras representa SGID+Sticky = 2+1=3)
      OCTAL_4=$(stat -c '%a' /srv/shared_dev)
      if [ ${#OCTAL_4} -eq 4 ] && [ "$(echo $OCTAL_4 | cut -c1)" = "3" ]; then
          if echo "$PERM_BIN" | grep -q "..s"; then
              echo "✔ [25%] Hito 2: Bastionado de seguridad (SUID, SGID, Sticky Bit) reestablecido con éxito."
              PUNTOS=$((PUNTOS + 25))
          else
              echo "❌ [10%] Hito 2: Directorio corregido, pero el binario syswatch no tiene el bit SUID activo."
              PUNTOS=$((PUNTOS + 10))
          fi
      else
          echo "❌ [0%] Hito 2: Al directorio compartido le faltan los bits combinados de herencia y protección."
      fi
  else
      echo "❌ [0%] Hito 2: Los permisos base del directorio /srv/shared_dev siguen incorrectos."
  fi

  # 3. Validar Enlaces e Inodos
  MAESTRO="/srv/production/app_v1/master.conf"
  HARD_L="/var/log/app_mirror.conf"
  SOFT_L="/etc/app_link.conf"
  if [ -f "$HARD_L" ] && [ -L "$SOFT_L" ]; then
      INODO_M=$(stat -c '%i' "$MAESTRO" 2>/dev/null || echo "1")
      INODO_H=$(stat -c '%i' "$HARD_L" 2>/dev/null || echo "2")
      TARGET_S=$(readlink "$SOFT_L" 2>/dev/null || echo "3")
      
      if [ "$INODO_M" -eq "$INODO_H" ] && [ "$TARGET_S" = "$MAESTRO" ]; then
          echo "✔ [20%] Hito 3: Arquitectura de consistencia de Inodos y enlaces reparada."
          PUNTOS=$((PUNTOS + 20))
      else
          echo "❌ [0%] Hito 3: Los enlaces existen pero no apuntan al Inodo o ruta correcta del maestro."
      fi
  else
      echo "❌ [0%] Hito 3: No se encontraron los archivos de enlace recreados en /var/log o /etc."
  fi

  # 4. Validar Infraestructura SSL/TLS
  KEY="/etc/pki/tls/corp_app/server.key"
  CSR="/etc/pki/tls/corp_app/server.csr"
  CRT="/etc/pki/tls/corp_app/server.crt"
  if [ -f "$KEY" ] && [ -f "$CSR" ] && [ -f "$CRT" ]; then
      CSR_O=$(openssl req -in "$CSR" -text -noout 2>/dev/null | grep "CN = test-app.corp.internal" || true)
      CRT_V=$(openssl x509 -in "$CRT" -text -noout >/dev/null 2>&1 && echo "OK" || echo "BAD")
      if [ -n "$CSR_O" ] && [ "$CRT_V" = "OK" ]; then
          echo "✔ [20%] Hito 4: Certificados TLS re-emitidos y validados criptográficamente mediante OpenSSL."
          PUNTOS=$((PUNTOS + 20))
      else
          echo "❌ [10%] Hito 4: Archivos SSL generados, pero los metadatos o la firma digital están corruptos."
          PUNTOS=$((PUNTOS + 10))
      fi
  else
      echo "❌ [0%] Hito 4: Faltan los componentes de la suite criptográfica en /etc/pki/tls/corp_app/."
  fi

  # 5. Validar Repositorio Git Local y Fusión de Ramas
  GIT_DIR="/opt/scripts_core"
  if [ -d "$GIT_DIR/.git" ]; then
      cd "$GIT_DIR"
      if [ -f "monitor.sh" ] && [ -f "cleanup.sh" ] && git log --all --grep="Initial commit con script de monitoreo" >/dev/null 2>&1; then
          echo "✔ [15%] Hito 5: Repositorio Git re-inicializado y ciclo de vida de ramas unificado."
          PUNTOS=$((PUNTOS + 15))
      else
          echo "❌ [0%] Hito 5: Repositorio Git operativo pero faltan commits históricos o la fusión de 'cleanup.sh'."
      fi
  else
      echo "❌ [0%] Hito 5: El directorio de scripts no ha sido puesto bajo control de versiones (.git ausente)."
  fi

  echo "========================================================="
  echo "🎯 CONTROL DE INCIDENTE COMPLETADO. CALIFICACIÓN: $PUNTOS / 100"
  echo "========================================================="
---

[[Laboratorios del LFCS]]
---
